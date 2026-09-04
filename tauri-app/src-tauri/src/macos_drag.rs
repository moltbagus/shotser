#![allow(deprecated, unexpected_cfgs)]

use cocoa::appkit::NSApp;
use cocoa::base::{id, nil};
use cocoa::foundation::{NSArray, NSAutoreleasePool, NSPoint, NSRect, NSSize, NSString, NSURL};
use objc::declare::ClassDecl;
use objc::runtime::{Class, Object, Sel};
use objc::{class, msg_send, sel, sel_impl};
use once_cell::sync::OnceCell;
use std::path::Path;
use std::ptr;

const NS_DRAG_OPERATION_COPY: u64 = 1;

fn view_point_from_web_client(
    client_x: f64,
    client_y: f64,
    bounds: NSRect,
    is_flipped: bool,
) -> NSPoint {
    let y = if is_flipped {
        bounds.origin.y + client_y
    } else {
        bounds.origin.y + bounds.size.height - client_y
    };
    NSPoint::new(bounds.origin.x + client_x, y)
}

/// Starts an AppKit file drag for a path that already exists on disk.
///
/// The path is intentionally staged by the caller in a private directory and
/// retained until AppKit reports that the drag session ended. Finder consumes
/// the NSURL through the normal NSPasteboardWriting path, so the drag carries
/// an actual file rather than a WebKit data URL.
pub fn start_drag(path: &Path, source_point: Option<(f64, f64)>) -> Result<(), String> {
    unsafe {
        let pool = NSAutoreleasePool::new(nil);
        let app = NSApp();
        if app == nil {
            pool.drain();
            return Err("ShotEye could not access its macOS application object.".to_string());
        }

        let window: id = msg_send![app, keyWindow];
        if window == nil {
            pool.drain();
            return Err("ShotEye could not find its editor window.".to_string());
        }
        let view: id = msg_send![window, contentView];
        if view == nil {
            pool.drain();
            return Err("ShotEye could not access its editor view.".to_string());
        }

        let path_string = path.to_string_lossy();
        let path_ns = NSString::alloc(nil).init_str(&path_string);
        let url: id = NSURL::fileURLWithPath_(nil, path_ns);
        if url == nil {
            let _: () = msg_send![path_ns, release];
            pool.drain();
            return Err("ShotEye could not prepare the capture for dragging.".to_string());
        }

        let source_class = dragging_source_class();
        let source: id = msg_send![source_class, new];
        if source == nil {
            let _: () = msg_send![path_ns, release];
            pool.drain();
            return Err("ShotEye could not create the native drag source.".to_string());
        }
        let retained_path: id = msg_send![path_ns, copy];
        (*source).set_ivar("path", retained_path);
        let _: id = msg_send![path_ns, autorelease];

        let item_alloc: id = msg_send![class!(NSDraggingItem), alloc];
        let item: id = msg_send![item_alloc, initWithPasteboardWriter: url];
        if item == nil {
            release_drag_source(source);
            let _: () = msg_send![item_alloc, release];
            pool.drain();
            return Err("ShotEye could not create the native drag item.".to_string());
        }

        // Use the pointer location captured by the WebView when available.
        // IPC can outlive the WebView's original NSEvent and the user may have
        // already moved toward Finder, so sampling NSEvent.mouseLocation here
        // can incorrectly start the native drag at the drop target.
        let bounds: NSRect = msg_send![view, bounds];
        let is_flipped: i8 = msg_send![view, isFlipped];
        let source_view_point = source_point
            .map(|(x, y)| view_point_from_web_client(x, y, bounds, is_flipped != 0))
            .unwrap_or_else(|| {
                let current_screen_location: NSPoint = msg_send![class!(NSEvent), mouseLocation];
                let window_location: NSPoint =
                    msg_send![window, convertScreenToBase: current_screen_location];
                msg_send![view, convertPoint: window_location fromView: nil]
            });
        let window_location: NSPoint = msg_send![view, convertPoint: source_view_point toView: nil];
        let window_number: i64 = msg_send![window, windowNumber];
        let event: id = msg_send![
            class!(NSEvent),
            mouseEventWithType: 1u64
            // NSEvent's location is in the window's base coordinate system.
            location: window_location
            modifierFlags: 0u64
            timestamp: 0.0f64
            windowNumber: window_number
            context: nil
            eventNumber: 0i64
            clickCount: 1i64
            pressure: 1.0f32
        ];
        if event == nil {
            release_drag_source(source);
            let _: () = msg_send![item, release];
            pool.drain();
            return Err("ShotEye could not create the native drag event.".to_string());
        }

        let location_in_view = source_view_point;
        let frame = NSRect::new(
            NSPoint::new(location_in_view.x - 48.0, location_in_view.y - 48.0),
            NSSize::new(96.0, 96.0),
        );
        let image_alloc: id = msg_send![class!(NSImage), alloc];
        let image: id = msg_send![image_alloc, initWithContentsOfFile: path_ns];
        let _: () = msg_send![item, setDraggingFrame: frame contents: image];
        if image != nil {
            let _: () = msg_send![image, release];
        } else {
            let _: () = msg_send![image_alloc, release];
        }

        let items = NSArray::arrayWithObject(nil, item);
        let session: id =
            msg_send![view, beginDraggingSessionWithItems: items event: event source: source];

        if session == nil {
            release_drag_source(source);
            if item != nil {
                let _: () = msg_send![item, release];
            }
            pool.drain();
            return Err("ShotEye could not start the native file drag.".to_string());
        }

        // NSDraggingSession retains the source and item for the lifetime of
        // the drag. Release the +1 references created above after the session
        // has accepted them.
        let _: () = msg_send![source, release];
        let _: () = msg_send![item, release];
        pool.drain();
    }
    Ok(())
}

fn dragging_source_class() -> &'static Class {
    static CLASS: OnceCell<&'static Class> = OnceCell::new();
    CLASS.get_or_init(|| unsafe {
        let mut declaration = ClassDecl::new("ShotEyeDragSource", class!(NSObject))
            .expect("ShotEyeDragSource class name is available");
        declaration.add_ivar::<*mut Object>("path");
        declaration.add_protocol(
            objc::runtime::Protocol::get("NSDraggingSource")
                .expect("NSDraggingSource protocol is available"),
        );

        extern "C" fn source_operation_mask(
            _this: &Object,
            _sel: Sel,
            _session: id,
            _context: u64,
        ) -> u64 {
            NS_DRAG_OPERATION_COPY
        }
        declaration.add_method(
            sel!(draggingSession:sourceOperationMaskForDraggingContext:),
            source_operation_mask as extern "C" fn(&Object, Sel, id, u64) -> u64,
        );

        extern "C" fn source_operation_mask_local(_this: &Object, _sel: Sel, _is_local: i8) -> u64 {
            NS_DRAG_OPERATION_COPY
        }
        declaration.add_method(
            sel!(draggingSourceOperationMaskForLocal:),
            source_operation_mask_local as extern "C" fn(&Object, Sel, i8) -> u64,
        );

        extern "C" fn dragging_ended(
            this: &mut Object,
            _sel: Sel,
            _session: id,
            _point: NSPoint,
            _operation: u64,
        ) {
            let result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| unsafe {
                let path_ptr: *mut Object = *this.get_ivar("path");
                if path_ptr.is_null() {
                    return;
                }
                let path_ns: id = path_ptr as id;
                // Keep the staged URL alive after AppKit reports the session
                // ended. Finder can finish consuming a file URL after this
                // callback; DragOutState owns cleanup when ShotEye exits.
                let _: () = msg_send![path_ns, release];
                (*this).set_ivar("path", ptr::null_mut::<Object>());
            }));
            if result.is_err() {
                eprintln!("ShotEye drag cleanup failed without crossing the Objective-C boundary");
            }
        }
        declaration.add_method(
            sel!(draggingSession:endedAtPoint:operation:),
            dragging_ended as extern "C" fn(&mut Object, Sel, id, NSPoint, u64),
        );

        declaration.register()
    })
}

unsafe fn release_drag_source(source: id) {
    if source.is_null() {
        return;
    }
    let path_ptr: *mut Object = *(*source).get_ivar("path");
    if !path_ptr.is_null() {
        let _: () = msg_send![path_ptr as id, release];
        (*source).set_ivar("path", ptr::null_mut::<Object>());
    }
    let _: () = msg_send![source, release];
}

#[cfg(test)]
mod tests {
    use super::view_point_from_web_client;
    use cocoa::foundation::{NSPoint, NSRect, NSSize};

    #[test]
    fn web_client_coordinates_map_to_a_flipped_view() {
        let bounds = NSRect::new(NSPoint::new(4.0, 8.0), NSSize::new(200.0, 100.0));
        let point = view_point_from_web_client(12.0, 18.0, bounds, true);
        assert!((point.x - 16.0).abs() < f64::EPSILON);
        assert!((point.y - 26.0).abs() < f64::EPSILON);
    }

    #[test]
    fn web_client_coordinates_map_from_top_left_in_a_unflipped_view() {
        let bounds = NSRect::new(NSPoint::new(4.0, 8.0), NSSize::new(200.0, 100.0));
        let point = view_point_from_web_client(12.0, 18.0, bounds, false);
        assert!((point.x - 16.0).abs() < f64::EPSILON);
        assert!((point.y - 90.0).abs() < f64::EPSILON);
    }
}
