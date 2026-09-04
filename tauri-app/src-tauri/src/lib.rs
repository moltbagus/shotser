// Learn more about Tauri commands at https://tauri.app/develop/calling-rust/
use serde::Serialize;
use base64::Engine as _;
use std::{
    fs,
    io::{Cursor, ErrorKind, Write},
    path::{Path, PathBuf},
    process::{Command, ExitStatus},
    sync::{Arc, Mutex},
};
use tauri::{AppHandle, Emitter, Manager, State};
use tauri_plugin_global_shortcut::{GlobalShortcutExt, ShortcutState};

#[cfg(target_os = "macos")]
mod macos_drag;

const DEFAULT_CAPTURE_SHORTCUT: &str = "CommandOrControl+Shift+Y";
const DRAG_OUT_FILE_NAME: &str = "ShotEye Capture.png";

#[cfg(target_os = "macos")]
#[link(name = "ApplicationServices", kind = "framework")]
extern "C" {
    fn CGPreflightScreenCaptureAccess() -> bool;
    fn CGRequestScreenCaptureAccess() -> bool;
}

fn is_png(bytes: &[u8]) -> bool {
    bytes.starts_with(b"\x89PNG\r\n\x1a\n")
}

fn runtime_contract_requested() -> bool {
    std::env::var("SHOT_EYE_RUNTIME_CONTRACT").as_deref() == Ok("1")
}

fn runtime_contract_trace(event: &str) {
    if !runtime_contract_requested() {
        return;
    }
    let Ok(report_path) = std::env::var("SHOT_EYE_RUNTIME_CONTRACT_REPORT") else {
        return;
    };
    let trace_path = PathBuf::from(report_path).with_extension("trace");
    if let Ok(mut trace) = fs::OpenOptions::new().create(true).append(true).open(trace_path) {
        let _ = writeln!(trace, "{event}");
    }
}

#[derive(Serialize)]
struct BackendStatus {
    message: String,
    platform: String,
}

#[derive(Serialize)]
struct CaptureResult {
    message: String,
    data_url: Option<String>,
    width: Option<u32>,
    height: Option<u32>,
}

#[derive(Clone)]
struct CaptureImage {
    bytes: Vec<u8>,
    width: u32,
    height: u32,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum CaptureMode {
    Area,
    Window,
    Fullscreen,
}

#[cfg(target_os = "macos")]
struct CaptureTempLocation {
    directory: PathBuf,
    path: PathBuf,
    cleaned: bool,
}

#[cfg(target_os = "macos")]
impl CaptureTempLocation {
    fn cleanup(&mut self) -> Result<(), String> {
        let mut errors = Vec::new();
        if let Err(error) = fs::remove_file(&self.path) {
            if error.kind() != ErrorKind::NotFound {
                errors.push(format!("could not remove capture file: {error}"));
            }
        }
        if let Err(error) = fs::remove_dir(&self.directory) {
            if error.kind() != ErrorKind::NotFound {
                errors.push(format!("could not remove capture directory: {error}"));
            }
        }
        self.cleaned = errors.is_empty();
        if errors.is_empty() {
            Ok(())
        } else {
            Err(errors.join("; "))
        }
    }
}

#[cfg(target_os = "macos")]
impl Drop for CaptureTempLocation {
    fn drop(&mut self) {
        if !self.cleaned {
            if let Err(error) = self.cleanup() {
                eprintln!("ShotEye temporary capture cleanup warning: {error}");
            }
        }
    }
}

#[cfg(target_os = "macos")]
fn capture_temp_location(mode: CaptureMode) -> std::io::Result<CaptureTempLocation> {
    let file_name = match mode {
        CaptureMode::Area => "area.png",
        CaptureMode::Window => "window.png",
        CaptureMode::Fullscreen => "fullscreen.png",
    };
    private_temp_location(file_name)
}

#[cfg(target_os = "macos")]
fn private_temp_location(file_name: &str) -> std::io::Result<CaptureTempLocation> {
    use std::os::unix::fs::DirBuilderExt;

    let timestamp = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_nanos();
    let root = std::env::temp_dir();
    for attempt in 0..8u8 {
        let directory = root.join(format!(
            "shoteye-capture-{}-{}-{}",
            std::process::id(),
            timestamp,
            attempt
        ));
        let mut builder = fs::DirBuilder::new();
        builder.mode(0o700);
        match builder.create(&directory) {
            Ok(()) => {
                return Ok(CaptureTempLocation {
                    path: directory.join(file_name),
                    directory,
                    cleaned: false,
                })
            }
            Err(error) if error.kind() == ErrorKind::AlreadyExists => continue,
            Err(error) => return Err(error),
        }
    }

    Err(std::io::Error::new(
        ErrorKind::AlreadyExists,
        "ShotEye could not create a private capture directory.",
    ))
}

#[derive(Default)]
struct CaptureStore {
    latest: Mutex<Option<CaptureImage>>,
    last_successful_mode: Mutex<Option<CaptureMode>>,
}

#[derive(Default)]
struct CaptureActivityState {
    active: Mutex<bool>,
}

impl CaptureActivityState {
    fn begin(&self) -> bool {
        let mut active = self.active.lock().expect("capture activity lock poisoned");
        if *active {
            return false;
        }
        *active = true;
        true
    }

    fn is_active(&self) -> bool {
        *self.active.lock().expect("capture activity lock poisoned")
    }

    fn end(&self) {
        *self.active.lock().expect("capture activity lock poisoned") = false;
    }
}

#[derive(Default)]
struct CaptureLifecycleState {
    restoration_succeeded: Mutex<bool>,
}

impl CaptureLifecycleState {
    fn begin(&self) {
        *self
            .restoration_succeeded
            .lock()
            .expect("capture lifecycle lock poisoned") = true;
    }

    fn set_restoration_succeeded(&self, succeeded: bool) {
        *self
            .restoration_succeeded
            .lock()
            .expect("capture lifecycle lock poisoned") = succeeded;
    }

    fn restoration_succeeded(&self) -> bool {
        *self
            .restoration_succeeded
            .lock()
            .expect("capture lifecycle lock poisoned")
    }
}

struct CaptureActivityGuard<'a>(&'a CaptureActivityState);

impl Drop for CaptureActivityGuard<'_> {
    fn drop(&mut self) {
        self.0.end();
    }
}

struct DragOutState {
    #[cfg(target_os = "macos")]
    locations: Mutex<Vec<CaptureTempLocation>>,
}

impl Default for DragOutState {
    fn default() -> Self {
        Self {
            #[cfg(target_os = "macos")]
            locations: Mutex::new(Vec::new()),
        }
    }
}

struct CaptureShortcutState {
    readiness: Mutex<ShortcutReadiness>,
    current_shortcut: Mutex<String>,
    registered: Mutex<bool>,
}

#[derive(Default)]
struct ShortcutReadiness {
    frontend_ready: bool,
    pending_capture: bool,
}

fn record_capture_request(readiness: &mut ShortcutReadiness) -> bool {
    if readiness.frontend_ready {
        true
    } else {
        readiness.pending_capture = true;
        false
    }
}

fn complete_capture_frontend_ready(readiness: &mut ShortcutReadiness) -> bool {
    readiness.frontend_ready = true;
    std::mem::take(&mut readiness.pending_capture)
}

#[cfg(target_os = "macos")]
#[derive(Default)]
struct DragLaunchState {
    cancelled: bool,
    started: bool,
}

fn normalized_capture_shortcut(value: &str) -> Result<String, String> {
    let shortcut = value.trim();
    if shortcut.is_empty() {
        return Err("Choose a key combination before saving the capture shortcut.".to_string());
    }
    if !shortcut.contains('+') {
        return Err("Include at least one modifier with the capture shortcut.".to_string());
    }
    Ok(shortcut.to_string())
}

fn shortcut_requires_registration(current: &str, registered: bool, requested: &str) -> bool {
    !registered || current != requested
}

fn apply_capture_shortcut_registration(
    current: &mut String,
    registered: &mut bool,
    requested: &str,
    mut register: impl FnMut(&str) -> Result<(), String>,
    mut unregister: impl FnMut(&str) -> Result<(), String>,
) -> String {
    if !shortcut_requires_registration(current, *registered, requested) {
        return format!("Capture shortcut is already {requested}.");
    }
    if let Err(error) = register(requested) {
        return format!("ShotEye could not register {requested}. It may be used by another app: {error}");
    }
    if *registered && *current != requested {
        let previous = current.clone();
        if let Err(error) = unregister(&previous) {
            let _ = unregister(requested);
            return format!("ShotEye kept {previous} because the previous shortcut could not be replaced: {error}");
        }
    }
    *current = requested.to_string();
    *registered = true;
    format!("Capture shortcut set to {requested}.")
}

fn request_capture(app: &AppHandle) {
    let state = app.state::<CaptureShortcutState>();
    let should_emit = {
        let mut readiness = state.readiness.lock().expect("shortcut readiness lock poisoned");
        record_capture_request(&mut readiness)
    };
    if should_emit {
        let _ = app.emit("capture-requested", ());
    }
}

fn restore_capture_window(app: &AppHandle) -> Result<(), String> {
    runtime_contract_trace("restore_capture_window:start");
    let mut errors = Vec::new();
    #[cfg(target_os = "macos")]
    {
        if let Err(error) = app.set_activation_policy(tauri::ActivationPolicy::Regular) {
            errors.push(format!("activation policy: {error}"));
        }
    }
    let Some(window) = app.get_webview_window("main") else {
        runtime_contract_trace("restore_capture_window:failed");
        return Err("ShotEye could not find its editor window".to_string());
    };
    if let Err(error) = window.unminimize() {
        errors.push(format!("unminimize: {error}"));
    }
    if let Err(error) = window.show() {
        errors.push(format!("show: {error}"));
    }
    if let Err(error) = window.set_focus() {
        errors.push(format!("focus: {error}"));
    }
    if errors.is_empty() {
        runtime_contract_trace("restore_capture_window:complete");
        Ok(())
    } else {
        runtime_contract_trace("restore_capture_window:failed");
        Err(errors.join("; "))
    }
}

fn hide_capture_window(app: &AppHandle) -> Result<(), String> {
    let window = app
        .get_webview_window("main")
        .ok_or_else(|| "ShotEye could not find its editor window.".to_string())?;
    window
        .hide()
        .map_err(|error| format!("ShotEye could not hide its editor before capture: {error}"))
}

fn reveal_main_window(app: &AppHandle) {
    if app
        .try_state::<CaptureActivityState>()
        .map(|state| state.is_active())
        .unwrap_or(false)
    {
        // A second launch during an intentional hidden capture must not steal
        // focus from the native selector. The capture command's guard drops
        // before the frontend performs its normal show-and-focus restoration.
        return;
    }
    let _ = restore_capture_window(app);
}

fn png_dimensions(bytes: &[u8]) -> Option<(u32, u32)> {
    if !is_png(bytes) || bytes.len() < 24 || &bytes[12..16] != b"IHDR" {
        return None;
    }
    Some((
        u32::from_be_bytes(bytes[16..20].try_into().ok()?),
        u32::from_be_bytes(bytes[20..24].try_into().ok()?),
    ))
}

fn valid_native_capture(bytes: &[u8]) -> bool {
    bytes.len() > 24 && is_png(bytes) && png_dimensions(bytes).is_some()
}

fn helper_exit_is_explicit_permission_denial(code: Option<i32>) -> bool {
    // Exit code 3 is reserved by the bundled helper for a missing TCC grant.
    // The Tauri process may have passed its own preflight while this exact
    // executable has not. Treat that mismatch as an actionable denial rather
    // than launching /usr/sbin/screencapture, which can prompt again.
    code == Some(3)
}

fn helper_launch_error_allows_system_fallback(_kind: ErrorKind) -> bool {
    // The bundled helper is an optimization, not the only capture path. Any
    // failure to spawn it should leave the user with the system selector,
    // including platform-specific `Other` errors such as a malformed Mach-O.
    _kind != ErrorKind::TimedOut
}

fn runtime_contract_passes(
    frontend_ready: bool,
    action_succeeded: bool,
    restoration_succeeded: bool,
    preview_dimensions: Option<(u32, u32)>,
    backend_dimensions: Option<(u32, u32)>,
    capture_activity_released: bool,
) -> bool {
    frontend_ready
        && action_succeeded
        && restoration_succeeded
        && preview_dimensions.is_some()
        && preview_dimensions == backend_dimensions
        && capture_activity_released
}

#[cfg(target_os = "macos")]
fn helper_screen_capture_permission_is_granted(selector: &Path) -> Option<bool> {
    let mut command = Command::new(selector);
    command.arg("--check-permission");
    helper_permission_probe(&mut command, HELPER_PERMISSION_PROBE_TIMEOUT)
}

fn native_capture_exit_message(mode: CaptureMode, code: Option<i32>) -> String {
    match code {
        Some(2) => format!("{} capture cancelled. ShotEye is ready for another capture.", capture_label(mode)),
        Some(4) => "Area capture stopped because the selection crossed a gap between displays. Select visible display pixels only.".to_string(),
        Some(code) => format!("{} capture failed (native selector exit code {code}). Check Screen Recording permission and try again.", capture_label(mode)),
        None => format!("{} capture ended without a status code. Check Screen Recording permission and try again.", capture_label(mode)),
    }
}

fn no_capture_status(action: &str) -> BackendStatus {
    BackendStatus {
        message: format!("Capture a valid image before {action}."),
        platform: std::env::consts::OS.to_string(),
    }
}

fn escape_applescript_string(value: &str) -> String {
    value.replace('\\', "\\\\").replace('"', "\\\"")
}

fn png_clipboard_script(path: &str) -> String {
    format!(
        "set the clipboard to (read POSIX file \"{}\" as «class PNGf»)",
        escape_applescript_string(path)
    )
}

fn clipboard_image_script(path: &str, image_class: &str) -> String {
    let path = escape_applescript_string(path);
    format!(
        "set imageData to the clipboard as {image_class}\nset outputFile to POSIX file \"{path}\"\nset outputHandle to open for access outputFile with write permission\ntry\n  set eof outputHandle to 0\n  write imageData to outputHandle\n  close access outputHandle\non error errorMessage number errorNumber\n  try\n    close access outputHandle\n  end try\n  error errorMessage number errorNumber\nend try"
    )
}

fn latest_capture(store: &State<CaptureStore>) -> Option<CaptureImage> {
    store
        .latest
        .lock()
        .expect("capture store lock poisoned")
        .clone()
}

fn canonical_capture_from_image_bytes(bytes: &[u8]) -> Result<CaptureImage, String> {
    const MAX_CAPTURE_BYTES: usize = 64 * 1024 * 1024;
    if bytes.len() > MAX_CAPTURE_BYTES {
        return Err("The image is too large to import or export.".to_string());
    }
    let image = image::load_from_memory(bytes)
        .map_err(|_| "ShotEye could not decode that image.".to_string())?;
    let (width, height) = (image.width(), image.height());
    if width == 0 || height == 0 {
        return Err("ShotEye could not validate that image's dimensions.".to_string());
    }
    let mut png = Vec::new();
    image
        .to_rgba8()
        .write_to(&mut Cursor::new(&mut png), image::ImageFormat::Png)
        .map_err(|_| "ShotEye could not prepare a PNG export.".to_string())?;
    Ok(CaptureImage { bytes: png, width, height })
}

fn capture_from_png_data_url(data_url: &str) -> Result<CaptureImage, String> {
    const PREFIX: &str = "data:image/png;base64,";
    let encoded = data_url
        .strip_prefix(PREFIX)
        .ok_or_else(|| "ShotEye expected a PNG image export.".to_string())?;
    let bytes = base64::engine::general_purpose::STANDARD
        .decode(encoded)
        .map_err(|_| "ShotEye could not decode the rendered PNG.".to_string())?;
    canonical_capture_from_image_bytes(&bytes)
        .map_err(|_| "ShotEye could not validate the rendered PNG.".to_string())
}

fn save_format_for_path(path: &str) -> Result<image::ImageFormat, String> {
    match PathBuf::from(path)
        .extension()
        .and_then(|extension| extension.to_str())
        .map(|extension| extension.to_ascii_lowercase())
        .as_deref()
    {
        Some("png") => Ok(image::ImageFormat::Png),
        Some("jpg" | "jpeg") => Ok(image::ImageFormat::Jpeg),
        Some("tif" | "tiff") => Ok(image::ImageFormat::Tiff),
        _ => Err("Choose a PNG, JPEG, or TIFF filename before saving.".to_string()),
    }
}

fn encoded_capture_for_path(capture: &CaptureImage, path: &str) -> Result<Vec<u8>, String> {
    let format = save_format_for_path(path)?;
    if format == image::ImageFormat::Png {
        return Ok(capture.bytes.clone());
    }

    let image = image::load_from_memory(&capture.bytes)
        .map_err(|_| "ShotEye could not decode the capture for export.".to_string())?;
    let mut encoded = Vec::new();
    match format {
        image::ImageFormat::Jpeg => {
            let rgb = image.to_rgb8();
            let mut encoder = image::codecs::jpeg::JpegEncoder::new_with_quality(&mut encoded, 92);
            encoder
                .encode_image(&rgb)
                .map_err(|_| "ShotEye could not encode the JPEG export.".to_string())?;
        }
        image::ImageFormat::Tiff => image
            .write_to(&mut Cursor::new(&mut encoded), image::ImageFormat::Tiff)
            .map_err(|_| "ShotEye could not encode the TIFF export.".to_string())?,
        image::ImageFormat::Png => unreachable!("PNG returned before decoding"),
        _ => return Err("ShotEye does not support that export format.".to_string()),
    }
    Ok(encoded)
}

fn write_export_atomically(path: &Path, bytes: &[u8]) -> std::io::Result<()> {
    let parent = path
        .parent()
        .filter(|directory| !directory.as_os_str().is_empty())
        .unwrap_or_else(|| Path::new("."));
    let filename = path
        .file_name()
        .and_then(|name| name.to_str())
        .unwrap_or("capture");
    let timestamp = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_nanos();

    for attempt in 0..8u8 {
        let temporary_path = parent.join(format!(
            ".{filename}.shoteye-{}-{timestamp}-{attempt}.tmp",
            std::process::id()
        ));
        let file = fs::OpenOptions::new()
            .write(true)
            .create_new(true)
            .open(&temporary_path);
        let mut file = match file {
            Ok(file) => file,
            Err(error) if error.kind() == ErrorKind::AlreadyExists => continue,
            Err(error) => return Err(error),
        };

        let result = file.write_all(bytes).and_then(|()| file.sync_all());
        drop(file);
        if let Err(error) = result {
            let _ = fs::remove_file(&temporary_path);
            return Err(error);
        }

        if let Err(error) = fs::rename(&temporary_path, path) {
            let _ = fs::remove_file(&temporary_path);
            return Err(error);
        }
        return Ok(());
    }

    Err(std::io::Error::new(
        ErrorKind::AlreadyExists,
        "ShotEye could not create a unique export staging file.",
    ))
}

fn capture_result(capture: CaptureImage, message: String) -> CaptureResult {
    CaptureResult {
        message,
        data_url: Some(format!(
            "data:image/png;base64,{}",
            base64::engine::general_purpose::STANDARD.encode(&capture.bytes)
        )),
        width: Some(capture.width),
        height: Some(capture.height),
    }
}

fn store_capture_inner(store: &CaptureStore, capture: CaptureImage) {
    *store.latest.lock().expect("capture store lock poisoned") = Some(capture);
}

fn store_capture(store: &State<CaptureStore>, capture: CaptureImage) {
    store_capture_inner(store.inner(), capture);
}

fn store_native_capture_inner(store: &CaptureStore, capture: CaptureImage, mode: CaptureMode) {
    store_capture_inner(store, capture);
    *store
        .last_successful_mode
        .lock()
        .expect("capture mode lock poisoned") = Some(mode);
}

fn screencapture_args(mode: CaptureMode) -> &'static [&'static str] {
    match mode {
        // `-i` operates in macOS's unified display space. Do not add `-m`,
        // which restricts capture to the main monitor; `-J selection` makes
        // the cross-display rectangle selector the deterministic entry mode.
        CaptureMode::Area => &["-i", "-J", "selection", "-x", "-t", "png"],
        CaptureMode::Window => &["-i", "-J", "window", "-x", "-t", "png"],
        CaptureMode::Fullscreen => &["-x", "-t", "png"],
    }
}

fn capture_label(mode: CaptureMode) -> &'static str {
    match mode {
        CaptureMode::Area => "Area",
        CaptureMode::Window => "Window",
        CaptureMode::Fullscreen => "Fullscreen",
    }
}

fn unavailable_screen_capture_permission_message() -> String {
    "Screen capture permission is unavailable for this ShotEye build. ShotEye will not invoke macOS capture again until access is available. In System Settings, enable ShotEye under Screen & System Audio Recording; macOS uses that label even though ShotEye captures screen pixels only and does not record system audio. Open Permissions; if it is already enabled, reset it for this exact installed app and relaunch. Developer ID signing is required for permission continuity across future builds.".to_string()
}

fn helper_permission_mismatch_message() -> String {
    "Screen capture permission is available to ShotEye, but its bundled selector is not authorized. In System Settings, enable the exact ShotEye entry under Screen & System Audio Recording, quit ShotEye, and relaunch this installed build. ShotEye will not invoke another capture selector until access is available.".to_string()
}

fn permission_status_message_for_grants(parent_granted: bool, helper_present: bool, helper_granted: Option<bool>) -> String {
    if !parent_granted && helper_present && helper_granted == Some(true) {
        return "Screen capture permission is available to ShotEye's bundled selector. Area capture is ready.".to_string();
    }
    if !parent_granted {
        return unavailable_screen_capture_permission_message();
    }
    if helper_present {
        match helper_granted {
            Some(false) => return helper_permission_mismatch_message(),
            Some(true) => {}
            None => {
                return "Screen capture permission is available to ShotEye. The bundled selector check was inconclusive; ShotEye will use its safe fallback if needed.".to_string();
            }
        }
    }
    "Screen capture permission is available to ShotEye.".to_string()
}

/// Returns a non-prompting status when the packaged selector is present or the
/// parent process is already authorized. `None` means only an unbundled build
/// may safely ask macOS for the parent's initial consent.
fn permission_request_message_for_grants(
    parent_granted: bool,
    helper_present: bool,
    helper_granted: Option<bool>,
) -> Option<String> {
    if helper_present {
        return Some(match helper_granted {
            Some(true) => "Screen capture permission is already available to ShotEye's bundled selector. Area capture is ready.".to_string(),
            Some(false) => helper_permission_mismatch_message(),
            None if parent_granted => "Screen capture permission is available to ShotEye. The bundled selector check was inconclusive; ShotEye will use its safe fallback if needed.".to_string(),
            None => unavailable_screen_capture_permission_message(),
        });
    }

    parent_granted.then(|| "Screen capture permission is already available to ShotEye.".to_string())
}

fn capture_permission_is_granted_for_mode(
    mode: CaptureMode,
    parent_granted: bool,
    helper_present: bool,
    helper_granted: Option<bool>,
) -> bool {
    match mode {
        CaptureMode::Area if helper_present => helper_granted.unwrap_or(parent_granted),
        _ => parent_granted,
    }
}

fn should_skip_capture_before_hide(runtime_contract: bool, permission_granted: bool) -> bool {
    !runtime_contract && !permission_granted
}

#[cfg(target_os = "macos")]
fn bundled_area_selector(app: &AppHandle) -> Option<PathBuf> {
    let resource_dir = app.path().resource_dir().ok()?;
    [resource_dir.join("native/ShotEyeSelector"), resource_dir.join("ShotEyeSelector")]
        .into_iter()
        .find(|selector| selector.is_file())
}

#[cfg(target_os = "macos")]
const NATIVE_CAPTURE_TIMEOUT: std::time::Duration = std::time::Duration::from_secs(5 * 60);

#[cfg(target_os = "macos")]
const HELPER_PERMISSION_PROBE_TIMEOUT: std::time::Duration = std::time::Duration::from_secs(2);

#[cfg(target_os = "macos")]
const SETTINGS_OPEN_TIMEOUT: std::time::Duration = std::time::Duration::from_secs(10);

#[cfg(target_os = "macos")]
const CLIPBOARD_OPERATION_TIMEOUT: std::time::Duration = std::time::Duration::from_secs(10);

#[cfg(target_os = "macos")]
fn run_command_with_timeout(command: &mut Command, timeout: std::time::Duration) -> std::io::Result<ExitStatus> {
    let mut child = command.spawn()?;
    let deadline = std::time::Instant::now() + timeout;
    loop {
        match child.try_wait() {
            Ok(Some(status)) => return Ok(status),
            Ok(None) => {}
            Err(error) => {
                // A polling error must not release the frontend operation lane
                // while the native selector is still alive. Best-effort kill
                // and reap keep every terminal path from leaking an overlay.
                let _ = child.kill();
                let _ = child.wait();
                return Err(error);
            }
        }
        if std::time::Instant::now() >= deadline {
            // Stop a stuck selector before returning so the frontend's
            // operation guard can always be released and the next capture
            // cannot inherit an orphaned native overlay.
            let _ = child.kill();
            let _ = child.wait();
            return Err(std::io::Error::new(
                ErrorKind::TimedOut,
                "macOS screen capture exceeded its five-minute timeout",
            ));
        }
        std::thread::sleep(std::time::Duration::from_millis(50));
    }
}

#[cfg(target_os = "macos")]
fn helper_permission_probe(command: &mut Command, timeout: std::time::Duration) -> Option<bool> {
    match run_command_with_timeout(command, timeout) {
        Ok(status) if status.success() => Some(true),
        Ok(status) if helper_exit_is_explicit_permission_denial(status.code()) => Some(false),
        Ok(_) => None,
        Err(error) if helper_launch_error_allows_system_fallback(error.kind()) => None,
        Err(_) => None,
    }
}

#[cfg(target_os = "macos")]
fn run_screencapture(path: &PathBuf, mode: CaptureMode) -> std::io::Result<std::process::ExitStatus> {
    let mut command = Command::new("/usr/sbin/screencapture");
    command.args(screencapture_args(mode)).arg(path);
    run_command_with_timeout(&mut command, NATIVE_CAPTURE_TIMEOUT)
}

#[cfg(target_os = "macos")]
fn run_area_selector_with(
    selector: Option<&Path>,
    path: &Path,
    probe: &mut dyn FnMut(&Path) -> Option<bool>,
    helper_runner: &mut dyn FnMut(&Path, &Path) -> std::io::Result<ExitStatus>,
    system_runner: &mut dyn FnMut(&Path) -> std::io::Result<ExitStatus>,
) -> std::io::Result<ExitStatus> {
    if let Some(selector) = selector {
        // Probe the helper before creating a visible overlay. A parent TCC
        // grant does not prove that a separately bundled executable can read
        // display pixels. An explicit helper denial must stop here so the
        // fallback cannot reopen the macOS consent sheet on every capture.
        match probe(selector) {
            Some(true) => match helper_runner(selector, path) {
                Ok(status) => {
                    if helper_exit_is_explicit_permission_denial(status.code()) {
                        return Err(std::io::Error::new(
                            ErrorKind::PermissionDenied,
                            "ShotEye's native selector is not authorized for Screen Recording",
                        ));
                    }
                    return Ok(status);
                }
                Err(error) if helper_launch_error_allows_system_fallback(error.kind()) => {}
                Err(error) => return Err(error),
            },
            Some(false) => {
                return Err(std::io::Error::new(
                    ErrorKind::PermissionDenied,
                    "ShotEye's native selector is not authorized for Screen Recording",
                ));
            }
            None => {}
        }
    }
    system_runner(path)
}

#[cfg(target_os = "macos")]
fn run_area_selector(app: Option<&AppHandle>, path: &Path) -> std::io::Result<ExitStatus> {
    let selector = app.and_then(bundled_area_selector);
    let mut probe = |candidate: &Path| helper_screen_capture_permission_is_granted(candidate);
    let mut helper_runner = |candidate: &Path, output_path: &Path| {
        let output = output_path.to_string_lossy().to_string();
        let mut command = Command::new(candidate);
        command.args(["--output", output.as_str()]);
        run_command_with_timeout(&mut command, NATIVE_CAPTURE_TIMEOUT)
    };
    let mut system_runner = |output_path: &Path| run_screencapture(&output_path.to_path_buf(), CaptureMode::Area);
    run_area_selector_with(selector.as_deref(), path, &mut probe, &mut helper_runner, &mut system_runner)
}

#[cfg(target_os = "macos")]
fn screen_capture_permission_is_granted() -> bool {
    // This non-prompting check must run before spawning `screencapture`, which
    // otherwise can re-open the system consent sheet for every failed attempt.
    unsafe { CGPreflightScreenCaptureAccess() }
}

#[cfg(target_os = "macos")]
fn screen_capture_permission_is_granted_for_mode(app: Option<&AppHandle>, mode: CaptureMode) -> bool {
    let parent_granted = screen_capture_permission_is_granted();
    let selector = (mode == CaptureMode::Area)
        .then(|| app.and_then(bundled_area_selector))
        .flatten();
    let helper_present = selector.is_some();
    let helper_granted = selector
        .as_deref()
        .and_then(helper_screen_capture_permission_is_granted);
    capture_permission_is_granted_for_mode(mode, parent_granted, helper_present, helper_granted)
}

#[tauri::command]
fn request_screen_capture_permission(app: AppHandle) -> BackendStatus {
    #[cfg(target_os = "macos")]
    {
        let parent_granted = screen_capture_permission_is_granted();
        let selector = bundled_area_selector(&app);
        let helper_present = selector.is_some();
        let helper_granted = selector
            .as_deref()
            .and_then(helper_screen_capture_permission_is_granted);

        if let Some(message) = permission_request_message_for_grants(parent_granted, helper_present, helper_granted) {
            return BackendStatus {
                message,
                platform: std::env::consts::OS.to_string(),
            };
        }

        if unsafe { CGRequestScreenCaptureAccess() } {
            return BackendStatus {
                message: "Screen capture permission granted. You can capture an area now.".to_string(),
                platform: std::env::consts::OS.to_string(),
            };
        }

        BackendStatus {
            message: "Screen capture permission was not granted. In System Settings, enable ShotEye under Screen & System Audio Recording; ShotEye captures screen pixels only and does not record system audio. Then relaunch the app.".to_string(),
            platform: std::env::consts::OS.to_string(),
        }
    }

    #[cfg(not(target_os = "macos"))]
    BackendStatus {
        message: "Screen Recording settings are available on macOS only.".to_string(),
        platform: std::env::consts::OS.to_string(),
    }
}

#[tauri::command]
async fn screen_capture_permission_status(app: AppHandle) -> BackendStatus {
    tauri::async_runtime::spawn_blocking(move || {
        #[cfg(target_os = "macos")]
        {
            let parent_granted = screen_capture_permission_is_granted();
            let selector = bundled_area_selector(&app);
            let helper_present = selector.is_some();
            let helper_granted = selector
                .as_deref()
                .and_then(helper_screen_capture_permission_is_granted);
            BackendStatus {
                message: permission_status_message_for_grants(parent_granted, helper_present, helper_granted),
                platform: std::env::consts::OS.to_string(),
            }
        }

        #[cfg(not(target_os = "macos"))]
        {
            BackendStatus {
                message: "Screen capture permission status is available on macOS only.".to_string(),
                platform: std::env::consts::OS.to_string(),
            }
        }
    })
    .await
    .unwrap_or_else(|error| BackendStatus {
        message: format!("Could not check Screen Recording permission: {error}"),
        platform: std::env::consts::OS.to_string(),
    })
}

#[tauri::command]
fn open_screen_recording_settings() -> BackendStatus {
    #[cfg(target_os = "macos")]
    {
        let result = {
            let mut command = Command::new("/usr/bin/open");
            command.arg("x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture");
            run_command_with_timeout(&mut command, SETTINGS_OPEN_TIMEOUT)
        };
        match result {
            Ok(status) if status.success() => BackendStatus {
                message: "Opened Screen & System Audio Recording settings. Enable ShotEye there, then quit and reopen the app. ShotEye captures screen pixels only and does not record system audio.".to_string(),
                platform: std::env::consts::OS.to_string(),
            },
            Err(error) if error.kind() == ErrorKind::TimedOut => BackendStatus {
                message: "Opening Screen & System Audio Recording settings timed out. Open System Settings manually and enable ShotEye there; ShotEye captures screen pixels only and does not record system audio.".to_string(),
                platform: std::env::consts::OS.to_string(),
            },
            Ok(_) => BackendStatus {
                message: "Could not open Screen Recording settings.".to_string(),
                platform: std::env::consts::OS.to_string(),
            },
            Err(error) => BackendStatus {
                message: format!("Could not open Screen Recording settings: {error}"),
                platform: std::env::consts::OS.to_string(),
            },
        }
    }

    #[cfg(not(target_os = "macos"))]
    BackendStatus {
        message: "Screen Recording settings are available on macOS only.".to_string(),
        platform: std::env::consts::OS.to_string(),
    }
}

#[tauri::command]
fn runtime_contract_enabled() -> bool {
    runtime_contract_trace("runtime_contract_enabled");
    runtime_contract_requested()
}

#[tauri::command]
#[allow(clippy::too_many_arguments)] // Tauri IPC fields map directly to the runtime-contract report.
fn runtime_contract_report(
    action_succeeded: bool,
    restoration_succeeded: bool,
    preview_width: Option<u32>,
    preview_height: Option<u32>,
    store: State<CaptureStore>,
    shortcut: State<CaptureShortcutState>,
    activity: State<CaptureActivityState>,
    lifecycle: State<CaptureLifecycleState>,
) -> BackendStatus {
    runtime_contract_trace("runtime_contract_report:start");
    let preview_dimensions = preview_width.zip(preview_height);
    let backend_dimensions = latest_capture(&store).map(|capture| (capture.width, capture.height));
    let frontend_ready = shortcut
        .readiness
        .lock()
        .expect("shortcut readiness lock poisoned")
        .frontend_ready;
    let capture_activity_released = !activity.is_active();
    let restoration_succeeded = restoration_succeeded && lifecycle.restoration_succeeded();
    let passed = runtime_contract_passes(
        frontend_ready,
        action_succeeded,
        restoration_succeeded,
        preview_dimensions,
        backend_dimensions,
        capture_activity_released,
    );
    let report = format!(
        "ShotEye packaged runtime contract\nResult: {}\nFrontend ready: {}\nCapture IPC action succeeded: {}\nWindow restoration succeeded: {}\nPreview dimensions: {:?}\nBackend dimensions: {:?}\nCapture activity released: {}\n",
        if passed { "PASS" } else { "FAIL" },
        frontend_ready,
        action_succeeded,
        restoration_succeeded,
        preview_dimensions,
        backend_dimensions,
        capture_activity_released,
    );
    let report_path = match std::env::var("SHOT_EYE_RUNTIME_CONTRACT_REPORT") {
        Ok(path) if !path.is_empty() => PathBuf::from(path),
        _ => {
            return BackendStatus {
                message: format!("Runtime contract {} but no report path was configured.", if passed { "passed" } else { "failed" }),
                platform: std::env::consts::OS.to_string(),
            }
        }
    };
    match fs::write(&report_path, report) {
        Ok(()) => BackendStatus {
            // Keep the trace append-only so a failed report can still show
            // which command boundary was reached.
            message: format!("Runtime contract {}. Report written to {}.", if passed { "passed" } else { "failed" }, report_path.display()),
            platform: std::env::consts::OS.to_string(),
        },
        Err(error) => BackendStatus {
            message: format!("Runtime contract {} but the report could not be written: {error}", if passed { "passed" } else { "failed" }),
            platform: std::env::consts::OS.to_string(),
        },
    }
}

#[tauri::command]
fn capture_frontend_ready(app: AppHandle, state: State<CaptureShortcutState>) {
    runtime_contract_trace("capture_frontend_ready:start");
    let pending = {
        let mut readiness = state.readiness.lock().expect("shortcut readiness lock poisoned");
        complete_capture_frontend_ready(&mut readiness)
    };
    if pending {
        let _ = app.emit("capture-requested", ());
    }
    runtime_contract_trace("capture_frontend_ready:end");
}

#[tauri::command]
fn set_capture_shortcut(
    app: AppHandle,
    state: State<CaptureShortcutState>,
    shortcut: &str,
) -> BackendStatus {
    let requested = match normalized_capture_shortcut(shortcut) {
        Ok(shortcut) => shortcut,
        Err(message) => {
            return BackendStatus {
                message,
                platform: std::env::consts::OS.to_string(),
            }
        }
    };
    let mut current = state
        .current_shortcut
        .lock()
        .expect("shortcut state lock poisoned");
    let mut registered = state
        .registered
        .lock()
        .expect("shortcut registration state lock poisoned");
    let shortcuts = app.global_shortcut();
    BackendStatus {
        message: apply_capture_shortcut_registration(
            &mut current,
            &mut registered,
            &requested,
            |value| shortcuts.register(value).map_err(|error| error.to_string()),
            |value| shortcuts.unregister(value).map_err(|error| error.to_string()),
        ),
        platform: std::env::consts::OS.to_string(),
    }
}

#[cfg(target_os = "macos")]
fn capture_native_with_runner(
    store: &CaptureStore,
    mode: CaptureMode,
    runner: &mut dyn FnMut(&PathBuf, CaptureMode) -> std::io::Result<ExitStatus>,
) -> CaptureResult {
    let mut temp_location = match capture_temp_location(mode) {
        Ok(location) => location,
        Err(error) => {
            return CaptureResult {
                message: format!("Could not prepare a private capture location: {error}"),
                data_url: None,
                width: None,
                height: None,
            }
        }
    };
    let result = runner(&temp_location.path, mode);

    let capture_result = match result {
        Ok(status) if status.success() => match fs::read(&temp_location.path) {
            Ok(bytes) if valid_native_capture(&bytes) => match canonical_capture_from_image_bytes(&bytes) {
                Ok(capture) => {
                    let message = format!("{} captured: {}x{}px. Use Copy or Save.", capture_label(mode), capture.width, capture.height);
                    store_native_capture_inner(store, capture.clone(), mode);
                    capture_result(capture, message)
                }
                _ => CaptureResult {
                    message: "Capture did not return a valid PNG image.".to_string(),
                    data_url: None,
                    width: None,
                    height: None,
                },
            },
            Ok(_) => CaptureResult {
                message: "Capture did not return a valid PNG image.".to_string(),
                data_url: None,
                width: None,
                height: None,
            },
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => CaptureResult {
                message: format!("{} capture cancelled or unavailable. Check Screen Recording permission, then try again.", capture_label(mode)),
                data_url: None,
                width: None,
                height: None,
            },
            Err(error) => CaptureResult {
                message: format!("Capture completed but the image could not be read: {error}"),
                data_url: None,
                width: None,
                height: None,
            },
        },
        Ok(status) => CaptureResult {
            message: native_capture_exit_message(mode, status.code()),
            data_url: None,
            width: None,
            height: None,
        },
        Err(error) => CaptureResult {
            message: if error.kind() == ErrorKind::TimedOut {
                "macOS screen capture timed out. ShotEye stopped the selector and is ready for another capture.".to_string()
            } else if error.kind() == ErrorKind::PermissionDenied {
                "ShotEye's native selector is not authorized for Screen Recording. Enable ShotEye under Screen & System Audio Recording, then relaunch this exact installed app. ShotEye will not open another capture prompt until access is available.".to_string()
            } else {
                format!("Could not start macOS screen capture: {error}")
            },
            data_url: None,
            width: None,
            height: None,
        },
    };
    if let Err(error) = temp_location.cleanup() {
        let mut capture_result = capture_result;
        capture_result.message.push_str(&format!(" Temporary-file cleanup warning: {error}."));
        return capture_result;
    }
    capture_result
}

fn capture_native(
    app: Option<&AppHandle>,
    store: &CaptureStore,
    activity: &CaptureActivityState,
    lifecycle: &CaptureLifecycleState,
    mode: CaptureMode,
) -> CaptureResult {
    runtime_contract_trace("capture_native:start");
    if !activity.begin() {
        runtime_contract_trace("capture_native:busy");
        return CaptureResult {
            message: format!("{} capture is already in progress. ShotEye is finishing the active selection.", capture_label(mode)),
            data_url: None,
            width: None,
            height: None,
        };
    }
    lifecycle.begin();
    let _activity_guard = CaptureActivityGuard(activity);

    #[cfg(target_os = "macos")]
    if should_skip_capture_before_hide(
        runtime_contract_requested(),
        screen_capture_permission_is_granted_for_mode(app, mode),
    ) {
        runtime_contract_trace("capture_native:permission_unavailable_before_hide");
        return CaptureResult {
            message: unavailable_screen_capture_permission_message(),
            data_url: None,
            width: None,
            height: None,
        };
    }

    if let Some(app) = app {
        if let Err(error) = hide_capture_window(app) {
            runtime_contract_trace("capture_native:hide_failed");
            let restoration = restore_capture_window(app);
            lifecycle.set_restoration_succeeded(restoration.is_ok());
            return CaptureResult {
                message: error,
                data_url: None,
                width: None,
                height: None,
            };
        }
        runtime_contract_trace("capture_native:hidden");
    }

    #[cfg(not(target_os = "macos"))]
    {
        let result = CaptureResult {
            message: "Screen capture is currently supported on macOS only.".to_string(),
            data_url: None,
            width: None,
            height: None,
        };
        if let Some(app) = app {
            let restoration = restore_capture_window(app);
            lifecycle.set_restoration_succeeded(restoration.is_ok());
        }
        return result;
    }

    #[cfg(target_os = "macos")]
    {
        let mut result = if runtime_contract_requested() {
            let mut runner = |path: &PathBuf, _capture_mode: CaptureMode| {
                let mut image = image::RgbaImage::new(32, 24);
                for pixel in image.pixels_mut() {
                    *pixel = image::Rgba([36, 120, 220, 255]);
                }
                let mut bytes = Vec::new();
                image::DynamicImage::ImageRgba8(image)
                    .write_to(&mut Cursor::new(&mut bytes), image::ImageFormat::Png)
                    .map_err(|error| std::io::Error::other(format!("runtime contract PNG: {error}")))?;
                fs::write(path, bytes)?;
                Command::new("/usr/bin/true").status()
            };
            capture_native_with_runner(store, mode, &mut runner)
        } else {
            let mut runner = |path: &PathBuf, capture_mode: CaptureMode| match capture_mode {
                CaptureMode::Area => run_area_selector(app, path),
                CaptureMode::Window | CaptureMode::Fullscreen => run_screencapture(path, capture_mode),
            };
            capture_native_with_runner(store, mode, &mut runner)
        };
        // A hidden WKWebView may be suspended before JavaScript can resume
        // after invoke(). Restore natively before returning and preserve the
        // native result so the frontend cannot mask a restoration failure.
        let restoration = app.map(restore_capture_window).unwrap_or(Ok(()));
        lifecycle.set_restoration_succeeded(restoration.is_ok());
        if let Err(error) = restoration {
            result.message.push_str(&format!(" ShotEye could not fully restore its editor window: {error}."));
        }
        runtime_contract_trace("capture_native:end");
        result
    }
}

async fn run_native_capture(app: AppHandle, mode: CaptureMode) -> CaptureResult {
    tauri::async_runtime::spawn_blocking(move || {
        let store = app.state::<CaptureStore>();
        let activity = app.state::<CaptureActivityState>();
        let lifecycle = app.state::<CaptureLifecycleState>();
        capture_native(Some(&app), store.inner(), activity.inner(), lifecycle.inner(), mode)
    })
    .await
    .unwrap_or_else(|error| CaptureResult {
        message: format!("ShotEye capture worker failed: {error}"),
        data_url: None,
        width: None,
        height: None,
    })
}

#[tauri::command]
async fn capture_area(app: AppHandle) -> CaptureResult {
    run_native_capture(app, CaptureMode::Area).await
}

#[tauri::command]
async fn capture_window(app: AppHandle) -> CaptureResult {
    run_native_capture(app, CaptureMode::Window).await
}

#[tauri::command]
async fn capture_fullscreen(app: AppHandle) -> CaptureResult {
    run_native_capture(app, CaptureMode::Fullscreen).await
}

#[tauri::command]
async fn repeat_last_capture(app: AppHandle) -> CaptureResult {
    let mode = {
        let store = app.state::<CaptureStore>();
        let mode = *store
            .last_successful_mode
            .lock()
            .expect("capture mode lock poisoned");
        mode
    };
    match mode {
        Some(mode) => run_native_capture(app, mode).await,
        None => CaptureResult {
            message: "Capture an area or screen before repeating the last capture.".to_string(),
            data_url: None,
            width: None,
            height: None,
        },
    }
}

#[tauri::command]
fn open_image(path: &str, store: State<CaptureStore>) -> CaptureResult {
    match fs::read(path).map_err(|error| format!("ShotEye could not read that file: {error}"))
        .and_then(|bytes| canonical_capture_from_image_bytes(&bytes)) {
        Ok(capture) => {
            let message = format!("Opened image: {}x{}px. You can annotate, Copy, or Save it.", capture.width, capture.height);
            store_capture(&store, capture.clone());
            capture_result(capture, message)
        }
        Err(message) => CaptureResult { message, data_url: None, width: None, height: None },
    }
}

#[tauri::command]
fn import_clipboard_image(store: State<CaptureStore>) -> CaptureResult {
    #[cfg(not(target_os = "macos"))]
    return CaptureResult {
        message: "Clipboard image import is currently supported on macOS only.".to_string(),
        data_url: None,
        width: None,
        height: None,
    };

    #[cfg(target_os = "macos")]
    {
        let mut temp_location = match private_temp_location("clipboard-import.img") {
            Ok(location) => location,
            Err(error) => {
                return CaptureResult {
                    message: format!("Could not prepare a private clipboard-import location: {error}"),
                    data_url: None,
                    width: None,
                    height: None,
                }
            }
        };
        let path_string = temp_location.path.to_string_lossy().to_string();
        let mut imported = None;
        for image_class in ["«class PNGf»", "TIFF picture"] {
            let _ = fs::remove_file(&temp_location.path);
            let script = clipboard_image_script(&path_string, image_class);
            let mut command = Command::new("/usr/bin/osascript");
            command.args(["-e", &script]);
            let status = run_command_with_timeout(&mut command, CLIPBOARD_OPERATION_TIMEOUT);
            if matches!(status, Ok(result) if result.success()) {
                if let Ok(bytes) = fs::read(&temp_location.path) {
                    imported = Some(canonical_capture_from_image_bytes(&bytes));
                    break;
                }
            }
        }
        if let Err(error) = temp_location.cleanup() {
            eprintln!("ShotEye clipboard import cleanup warning: {error}");
        }
        match imported.unwrap_or_else(|| Err("There is no PNG or TIFF image in the clipboard.".to_string())) {
            Ok(capture) => {
                let message = format!("Imported clipboard image: {}x{}px. You can annotate, Copy, or Save it.", capture.width, capture.height);
                store_capture(&store, capture.clone());
                capture_result(capture, message)
            }
            Err(message) => CaptureResult { message, data_url: None, width: None, height: None },
        }
    }
}

#[tauri::command]
fn store_rendered_capture(data_url: &str, store: State<CaptureStore>) -> BackendStatus {
    match capture_from_png_data_url(data_url) {
        Ok(capture) => {
            let width = capture.width;
            let height = capture.height;
            store_capture(&store, capture);
            BackendStatus {
                message: format!("Prepared annotated export: {width}x{height}px."),
                platform: std::env::consts::OS.to_string(),
            }
        }
        Err(message) => BackendStatus {
            message,
            platform: std::env::consts::OS.to_string(),
        },
    }
}

#[tauri::command]
fn copy_capture(store: State<CaptureStore>) -> BackendStatus {
    #[cfg(not(target_os = "macos"))]
    return BackendStatus {
        message: "Clipboard image copy is currently supported on macOS only.".to_string(),
        platform: std::env::consts::OS.to_string(),
    };

    #[cfg(target_os = "macos")]
    {
        let Some(capture) = latest_capture(&store) else {
            return no_capture_status("copying");
        };
        let mut temp_location = match private_temp_location("clipboard.png") {
            Ok(location) => location,
            Err(error) => {
                return BackendStatus {
                    message: format!("Could not prepare a private clipboard location: {error}"),
                    platform: std::env::consts::OS.to_string(),
                }
            }
        };
        let result = match fs::write(&temp_location.path, &capture.bytes) {
            Ok(()) => {
                let script = png_clipboard_script(&temp_location.path.to_string_lossy());
                let mut command = Command::new("/usr/bin/osascript");
                command.args(["-e", &script]);
                run_command_with_timeout(&mut command, CLIPBOARD_OPERATION_TIMEOUT)
            }
            Err(error) => {
                let _ = temp_location.cleanup();
                return BackendStatus {
                    message: format!("Could not prepare the capture for clipboard copy: {error}"),
                    platform: std::env::consts::OS.to_string(),
                };
            }
        };
        if let Err(error) = temp_location.cleanup() {
            eprintln!("ShotEye clipboard copy cleanup warning: {error}");
        }
        let message = match result {
            Ok(status) if status.success() => "Capture copied to the clipboard.".to_string(),
            Ok(_) => "Could not copy the capture to the clipboard.".to_string(),
            Err(error) if error.kind() == ErrorKind::TimedOut => "Clipboard copy timed out. ShotEye stopped the clipboard helper and is ready for another action.".to_string(),
            Err(error) => format!("Could not start clipboard copy: {error}"),
        };
        BackendStatus { message, platform: std::env::consts::OS.to_string() }
    }
}

#[tauri::command]
fn save_capture(path: &str, store: State<CaptureStore>) -> BackendStatus {
    let Some(capture) = latest_capture(&store) else {
        return no_capture_status("saving");
    };
    let message = match encoded_capture_for_path(&capture, path)
        .and_then(|bytes| {
            write_export_atomically(Path::new(path), &bytes)
                .map_err(|error| format!("Could not save the capture: {error}"))
        })
    {
        Ok(_) => format!(
            "Capture saved to {path} ({}x{}px).",
            capture.width, capture.height
        ),
        Err(error) => error,
    };
    BackendStatus { message, platform: std::env::consts::OS.to_string() }
}

#[cfg(target_os = "macos")]
fn stage_drag_capture(capture: &CaptureImage) -> Result<CaptureTempLocation, String> {
    let mut location = private_temp_location(DRAG_OUT_FILE_NAME)
        .map_err(|error| format!("Could not prepare the capture for dragging: {error}"))?;
    if let Err(error) = fs::write(&location.path, &capture.bytes) {
        let _ = location.cleanup();
        return Err(format!("Could not stage the capture for dragging: {error}"));
    }
    Ok(location)
}

#[tauri::command]
fn drag_out_capture(
    app: AppHandle,
    store: State<CaptureStore>,
    drag_out: State<DragOutState>,
    source_x: Option<f64>,
    source_y: Option<f64>,
) -> BackendStatus {
    #[cfg(not(target_os = "macos"))]
    {
        let _ = (app, store, drag_out, source_x, source_y);
        return BackendStatus {
            message: "Finder drag-out is currently supported on macOS only.".to_string(),
            platform: std::env::consts::OS.to_string(),
        };
    }

    #[cfg(target_os = "macos")]
    {
        let Some(capture) = latest_capture(&store) else {
            return no_capture_status("dragging");
        };
        let location = match stage_drag_capture(&capture) {
            Ok(location) => location,
            Err(message) => {
                return BackendStatus {
                    message,
                    platform: std::env::consts::OS.to_string(),
                };
            }
        };
        let path = location.path.clone();
        let source_point = source_x.zip(source_y);

        // A busy main thread can delay the AppKit closure. Coordinate the
        // timeout with that closure so a late callback never starts a drag
        // after the staged file has already been cleaned up.
        let launch_state = Arc::new(Mutex::new(DragLaunchState::default()));
        let launch_state_on_main = Arc::clone(&launch_state);
        let (sender, receiver) = std::sync::mpsc::sync_channel(1);
        let scheduled = app.run_on_main_thread(move || {
            let should_start = {
                let mut launch_state = launch_state_on_main
                    .lock()
                    .expect("drag launch state lock poisoned");
                if launch_state.cancelled {
                    false
                } else {
                    launch_state.started = true;
                    true
                }
            };
            if should_start {
                let _ = sender.send(macos_drag::start_drag(&path, source_point));
            } else {
                let _ = sender.send(Err("ShotEye cancelled the delayed file drag before AppKit started it.".to_string()));
            }
        });
        if let Err(error) = scheduled {
            return BackendStatus {
                message: format!("Could not start the ShotEye file drag: {error}"),
                platform: std::env::consts::OS.to_string(),
            };
        }
        let result = receiver.recv_timeout(std::time::Duration::from_secs(2));
        match result {
            Ok(Ok(())) => {
                drag_out
                    .locations
                    .lock()
                    .expect("drag-out state lock poisoned")
                    .push(location);
                BackendStatus {
                    message: format!("Dragging {DRAG_OUT_FILE_NAME} — drop it into Finder or another app."),
                    platform: std::env::consts::OS.to_string(),
                }
            }
            Ok(Err(error)) => BackendStatus {
                message: error,
                platform: std::env::consts::OS.to_string(),
            },
            Err(error) => {
                let started = {
                    let mut launch_state = launch_state
                        .lock()
                        .expect("drag launch state lock poisoned");
                    if launch_state.started {
                        true
                    } else {
                        launch_state.cancelled = true;
                        false
                    }
                };
                if started {
                    // AppKit claimed the launch slot but did not answer in
                    // time. Keep the location managed so a late successful
                    // session still has a valid file to consume.
                    drag_out
                        .locations
                        .lock()
                        .expect("drag-out state lock poisoned")
                        .push(location);
                }
                BackendStatus {
                    message: if started {
                        format!("ShotEye is still starting the file drag; drop it into Finder when the drag appears ({error}).")
                    } else {
                        format!("ShotEye cancelled a delayed file drag before it started ({error}).")
                    },
                    platform: std::env::consts::OS.to_string(),
                }
            }
        }
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .manage(CaptureStore::default())
        .manage(CaptureActivityState::default())
        .manage(CaptureLifecycleState::default())
        .manage(DragOutState::default())
        .manage(CaptureShortcutState {
            readiness: Mutex::new(ShortcutReadiness::default()),
            current_shortcut: Mutex::new(DEFAULT_CAPTURE_SHORTCUT.to_string()),
            registered: Mutex::new(false),
        })
        .plugin(tauri_plugin_single_instance::init(|app, _argv, _cwd| {
            reveal_main_window(app);
        }))
        .plugin(
            tauri_plugin_global_shortcut::Builder::new()
                .with_handler(|app, _shortcut, event| {
                    if event.state() == ShortcutState::Pressed {
                        request_capture(app);
                    }
                })
                .build(),
        )
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_dialog::init())
        .setup(|app| {
            let registration = app.global_shortcut().register(DEFAULT_CAPTURE_SHORTCUT);
            let state = app.state::<CaptureShortcutState>();
            match registration {
                Ok(()) => {
                    *state
                        .registered
                        .lock()
                        .expect("shortcut registration state lock poisoned") = true;
                }
                Err(error) => {
                    eprintln!("ShotEye could not register the default capture shortcut: {error}");
                }
            }
            reveal_main_window(app.handle());
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![request_screen_capture_permission, screen_capture_permission_status, open_screen_recording_settings, runtime_contract_enabled, runtime_contract_report, capture_frontend_ready, set_capture_shortcut, capture_area, capture_window, capture_fullscreen, repeat_last_capture, open_image, import_clipboard_image, store_rendered_capture, copy_capture, save_capture, drag_out_capture])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

#[cfg(test)]
mod tests {
        use super::{apply_capture_shortcut_registration, canonical_capture_from_image_bytes, capture_from_png_data_url, capture_permission_is_granted_for_mode, clipboard_image_script, complete_capture_frontend_ready, encoded_capture_for_path, escape_applescript_string, helper_exit_is_explicit_permission_denial, helper_launch_error_allows_system_fallback, helper_permission_probe, is_png, native_capture_exit_message, normalized_capture_shortcut, permission_request_message_for_grants, permission_status_message_for_grants, png_clipboard_script, png_dimensions, record_capture_request, run_command_with_timeout, runtime_contract_passes, save_format_for_path, screencapture_args, shortcut_requires_registration, should_skip_capture_before_hide, stage_drag_capture, unavailable_screen_capture_permission_message, valid_native_capture, write_export_atomically, CaptureActivityState, CaptureImage, CaptureLifecycleState, CaptureMode, CaptureStore, DRAG_OUT_FILE_NAME, ShortcutReadiness};
    #[cfg(target_os = "macos")]
    use super::{capture_native_with_runner, capture_temp_location, private_temp_location, run_area_selector_with};
    use base64::Engine as _;
    use std::{fs, io::{Cursor, ErrorKind}, process::Command, time::Duration};

    fn minimal_png(width: u32, height: u32) -> Vec<u8> {
        let mut bytes = Vec::from(b"\x89PNG\r\n\x1a\n".as_slice());
        bytes.extend_from_slice(&13u32.to_be_bytes());
        bytes.extend_from_slice(b"IHDR");
        bytes.extend_from_slice(&width.to_be_bytes());
        bytes.extend_from_slice(&height.to_be_bytes());
        bytes.extend_from_slice(&[8, 6, 0, 0, 0]);
        bytes
    }

    fn encoded_image(format: image::ImageFormat, width: u32, height: u32) -> Vec<u8> {
        let image = image::DynamicImage::new_rgba8(width, height);
        let mut bytes = Vec::new();
        image.write_to(&mut Cursor::new(&mut bytes), format).expect("fixture encoding succeeds");
        bytes
    }

    #[cfg(target_os = "macos")]
    fn process_exit_status(code: i32) -> std::process::ExitStatus {
        Command::new("/bin/sh")
            .args(["-c", &format!("exit {code}")])
            .status()
            .expect("test process exits")
    }

    #[test]
    fn png_dimensions_reads_ihdr_dimensions() {
        assert_eq!(png_dimensions(&minimal_png(461, 418)), Some((461, 418)));
    }

    #[test]
    fn png_dimensions_rejects_non_png_bytes() {
        assert!(!is_png(b"not a png"));
        assert_eq!(png_dimensions(b"not a png"), None);
    }

    #[test]
    fn applescript_clipboard_path_is_quoted_and_escaped() {
        let script = png_clipboard_script("/tmp/ShotEye \"Capture\".png");
        assert_eq!(
            script,
            "set the clipboard to (read POSIX file \"/tmp/ShotEye \\\"Capture\\\".png\" as «class PNGf»)",
        );
    }

    #[test]
    fn applescript_string_escape_handles_backslash_and_quote() {
        assert_eq!(escape_applescript_string("a\\b\"c"), "a\\\\b\\\"c");
    }

    #[test]
    fn clipboard_script_writes_png_data_to_a_quoted_path() {
        let script = clipboard_image_script("/tmp/ShotEye \"Paste\".img", "«class PNGf»");
        assert!(script.contains("clipboard as «class PNGf»"));
        assert!(script.contains("POSIX file \"/tmp/ShotEye \\\"Paste\\\".img\""));
    }

    #[test]
    fn rendered_png_data_url_preserves_capture_dimensions() {
        let bytes = encoded_image(image::ImageFormat::Png, 461, 418);
        let data_url = format!(
            "data:image/png;base64,{}",
            base64::engine::general_purpose::STANDARD.encode(bytes)
        );
        let capture = capture_from_png_data_url(&data_url).expect("valid PNG data URL");
        assert_eq!((capture.width, capture.height), (461, 418));
    }

    #[test]
    fn rendered_capture_rejects_non_png_data_urls() {
        assert!(capture_from_png_data_url("data:image/jpeg;base64,AAAA").is_err());
    }

    #[test]
    fn jpeg_import_normalizes_to_a_png_capture() {
        let capture = canonical_capture_from_image_bytes(&encoded_image(image::ImageFormat::Jpeg, 19, 23))
            .expect("JPEG fixture imports");
        assert_eq!((capture.width, capture.height), (19, 23));
        assert!(is_png(&capture.bytes));
    }

    #[test]
    fn save_formats_are_selected_from_safe_extensions() {
        assert_eq!(save_format_for_path("capture.PNG"), Ok(image::ImageFormat::Png));
        assert_eq!(save_format_for_path("capture.jpg"), Ok(image::ImageFormat::Jpeg));
        assert_eq!(save_format_for_path("capture.tiff"), Ok(image::ImageFormat::Tiff));
        assert!(save_format_for_path("capture.webp").is_err());
    }

    #[test]
    fn non_png_exports_keep_dimensions_and_use_the_requested_signature() {
        let capture = CaptureImage {
            bytes: encoded_image(image::ImageFormat::Png, 19, 23),
            width: 19,
            height: 23,
        };
        let jpeg = encoded_capture_for_path(&capture, "capture.jpeg").expect("JPEG export");
        assert!(jpeg.starts_with(&[0xff, 0xd8, 0xff]));
        let jpeg_image = image::load_from_memory(&jpeg).expect("JPEG decodes");
        assert_eq!((jpeg_image.width(), jpeg_image.height()), (19, 23));

        let tiff = encoded_capture_for_path(&capture, "capture.tiff").expect("TIFF export");
        assert!(tiff.starts_with(b"II*\0") || tiff.starts_with(b"MM\0*"));
        let tiff_image = image::load_from_memory(&tiff).expect("TIFF decodes");
        assert_eq!((tiff_image.width(), tiff_image.height()), (19, 23));
    }

    #[test]
    fn export_write_replaces_destination_without_leaving_a_staging_file() {
        let directory = std::env::temp_dir().join(format!(
            "shoteye-export-test-{}-{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_nanos()
        ));
        fs::create_dir(&directory).expect("create export test directory");
        let destination = directory.join("capture.png");
        fs::write(&destination, b"previous capture").expect("write previous capture");

        write_export_atomically(&destination, b"latest capture").expect("atomic export write");

        assert_eq!(fs::read(&destination).expect("read exported capture"), b"latest capture");
        let entries = fs::read_dir(&directory).expect("read export directory").count();
        assert_eq!(entries, 1, "temporary staging files must be cleaned by rename");
        fs::remove_file(&destination).expect("remove exported capture");
        fs::remove_dir(&directory).expect("remove export test directory");
    }

    #[test]
    fn corrupt_image_is_rejected() {
        assert!(canonical_capture_from_image_bytes(b"not an image").is_err());
    }

    #[test]
    fn native_capture_modes_use_distinct_native_arguments() {
        assert_eq!(
            screencapture_args(CaptureMode::Area),
            ["-i", "-J", "selection", "-x", "-t", "png"]
        );
        assert_eq!(
            screencapture_args(CaptureMode::Window),
            ["-i", "-J", "window", "-x", "-t", "png"]
        );
        assert_eq!(screencapture_args(CaptureMode::Fullscreen), ["-x", "-t", "png"]);
    }

    #[test]
    fn capture_activity_rejects_overlap_and_guard_releases_after_capture() {
        let activity = CaptureActivityState::default();
        assert!(activity.begin());
        assert!(activity.is_active());
        assert!(!activity.begin());

        {
            let _guard = super::CaptureActivityGuard(&activity);
            assert!(activity.is_active());
        }

        assert!(!activity.is_active());
        assert!(activity.begin());
    }

    #[test]
    fn area_capture_keeps_macos_multi_display_selection_enabled() {
        let args = screencapture_args(CaptureMode::Area);
        assert!(args.contains(&"-i"));
        assert!(args.contains(&"selection"));
        assert!(!args.contains(&"-m"));
        assert!(!args.iter().any(|argument| argument.starts_with("-D")));
    }

    #[test]
    fn native_capture_requires_a_png_with_dimensions() {
        assert!(valid_native_capture(&encoded_image(image::ImageFormat::Png, 17, 23)));
        assert!(!valid_native_capture(&encoded_image(image::ImageFormat::Jpeg, 17, 23)));
        assert!(!valid_native_capture(b"not a png"));
    }

    #[cfg(target_os = "macos")]
    #[test]
    fn native_capture_runner_commits_valid_png_and_cleans_its_private_location() {
        use std::{fs, path::PathBuf};

        let store = CaptureStore::default();
        let bytes = encoded_image(image::ImageFormat::Png, 17, 23);
        let mut output_directory: Option<PathBuf> = None;
        let mut runner = |path: &PathBuf, mode: CaptureMode| {
            assert_eq!(mode, CaptureMode::Window);
            output_directory = path.parent().map(PathBuf::from);
            fs::write(path, &bytes).expect("runner writes its output");
            Ok(process_exit_status(0))
        };

        let result = capture_native_with_runner(&store, CaptureMode::Window, &mut runner);

        assert!(result.data_url.is_some());
        assert_eq!((result.width, result.height), (Some(17), Some(23)));
        assert_eq!(
            store.latest.lock().expect("capture store lock").as_ref().map(|capture| (capture.width, capture.height)),
            Some((17, 23))
        );
        assert_eq!(*store.last_successful_mode.lock().expect("capture mode lock"), Some(CaptureMode::Window));
        assert!(!output_directory.expect("runner saw a temp directory").exists());
    }

    #[cfg(target_os = "macos")]
    #[test]
    fn native_capture_runner_preserves_previous_capture_on_cancel_or_invalid_output() {
        use std::{fs, path::PathBuf};

        let store = CaptureStore::default();
        let previous = CaptureImage {
            bytes: encoded_image(image::ImageFormat::Png, 11, 13),
            width: 11,
            height: 13,
        };
        *store.latest.lock().expect("capture store lock") = Some(previous.clone());

        let mut cancelled_directory: Option<PathBuf> = None;
        let mut cancelled_runner = |path: &PathBuf, _mode: CaptureMode| {
            cancelled_directory = path.parent().map(PathBuf::from);
            Ok(process_exit_status(2))
        };
        let cancelled = capture_native_with_runner(&store, CaptureMode::Area, &mut cancelled_runner);
        assert!(cancelled.message.contains("cancelled"));
        assert!(cancelled.data_url.is_none());
        assert_eq!(store.latest.lock().expect("capture store lock").as_ref().map(|capture| (capture.width, capture.height)), Some((11, 13)));
        assert!(!cancelled_directory.expect("cancel runner saw a temp directory").exists());

        let mut invalid_directory: Option<PathBuf> = None;
        let mut invalid_runner = |path: &PathBuf, _mode: CaptureMode| {
            invalid_directory = path.parent().map(PathBuf::from);
            fs::write(path, b"not a PNG").expect("runner writes invalid output");
            Ok(process_exit_status(0))
        };
        let invalid = capture_native_with_runner(&store, CaptureMode::Area, &mut invalid_runner);
        assert!(invalid.message.contains("valid PNG"));
        assert!(invalid.data_url.is_none());
        assert_eq!(store.latest.lock().expect("capture store lock").as_ref().map(|capture| (capture.width, capture.height)), Some((11, 13)));
        assert!(!invalid_directory.expect("invalid runner saw a temp directory").exists());
    }

    #[cfg(target_os = "macos")]
    #[test]
    fn native_capture_runner_maps_timeout_without_leaving_private_output() {
        use std::path::PathBuf;

        let store = CaptureStore::default();
        let mut output_directory: Option<PathBuf> = None;
        let mut runner = |path: &PathBuf, _mode: CaptureMode| {
            output_directory = path.parent().map(PathBuf::from);
            Err(std::io::Error::new(ErrorKind::TimedOut, "selector timed out"))
        };

        let result = capture_native_with_runner(&store, CaptureMode::Area, &mut runner);

        assert!(result.message.contains("timed out"));
        assert!(result.data_url.is_none());
        assert!(!output_directory.expect("timeout runner saw a temp directory").exists());
    }

    #[cfg(target_os = "macos")]
    #[test]
    fn native_capture_runner_maps_selector_permission_mismatch_without_prompting() {
        use std::path::PathBuf;

        let store = CaptureStore::default();
        let mut runner = |_path: &PathBuf, _mode: CaptureMode| {
            Err(std::io::Error::new(
                ErrorKind::PermissionDenied,
                "ShotEye's native selector is not authorized for Screen Recording",
            ))
        };

        let result = capture_native_with_runner(&store, CaptureMode::Area, &mut runner);

        assert!(result.message.contains("native selector is not authorized"));
        assert!(result.message.contains("will not open another capture prompt"));
        assert!(result.data_url.is_none());
    }

    #[cfg(target_os = "macos")]
    #[test]
    fn area_selector_dispatch_falls_back_only_for_inconclusive_helpers() {
        use std::path::Path;

        let mut probe = |_path: &Path| None;
        let mut helper_calls = 0;
        let mut system_calls = 0;
        let mut helper_runner = |_helper: &Path, _output: &Path| {
            helper_calls += 1;
            Ok(process_exit_status(0))
        };
        let mut system_runner = |_output: &Path| {
            system_calls += 1;
            Ok(process_exit_status(0))
        };

        let result = run_area_selector_with(
            Some(Path::new("/tmp/ShotEyeSelector")),
            Path::new("/tmp/shoteye-output.png"),
            &mut probe,
            &mut helper_runner,
            &mut system_runner,
        )
        .expect("system fallback exits successfully");

        assert_eq!(result.code(), Some(0));
        assert_eq!(helper_calls, 0);
        assert_eq!(system_calls, 1);

        let mut probe = |_path: &Path| Some(false);
        let mut helper_calls = 0;
        let mut system_calls = 0;
        let mut helper_runner = |_helper: &Path, _output: &Path| {
            helper_calls += 1;
            Ok(process_exit_status(0))
        };
        let mut system_runner = |_output: &Path| {
            system_calls += 1;
            Ok(process_exit_status(0))
        };
        let error = run_area_selector_with(
            Some(Path::new("/tmp/ShotEyeSelector")),
            Path::new("/tmp/shoteye-output.png"),
            &mut probe,
            &mut helper_runner,
            &mut system_runner,
        )
        .expect_err("explicit helper denial must stop before system fallback");
        assert_eq!(error.kind(), ErrorKind::PermissionDenied);
        assert_eq!(helper_calls, 0);
        assert_eq!(system_calls, 0);

        let mut probe = |_path: &Path| Some(true);
        let mut helper_calls = 0;
        let mut system_calls = 0;
        let mut helper_runner = |_helper: &Path, _output: &Path| {
            helper_calls += 1;
            Ok(process_exit_status(0))
        };
        let mut system_runner = |_output: &Path| {
            system_calls += 1;
            Ok(process_exit_status(0))
        };
        let result = run_area_selector_with(
            Some(Path::new("/tmp/ShotEyeSelector")),
            Path::new("/tmp/shoteye-output.png"),
            &mut probe,
            &mut helper_runner,
            &mut system_runner,
        )
        .expect("helper exits successfully");
        assert_eq!(result.code(), Some(0));
        assert_eq!(helper_calls, 1);
        assert_eq!(system_calls, 0);
    }

    #[cfg(target_os = "macos")]
    #[test]
    fn area_selector_dispatch_stops_on_helper_permission_exit_without_system_fallback() {
        use std::path::Path;

        let mut probe = |_path: &Path| Some(true);
        let mut helper_calls = 0;
        let mut system_calls = 0;
        let mut helper_runner = |_helper: &Path, _output: &Path| {
            helper_calls += 1;
            Ok(process_exit_status(3))
        };
        let mut system_runner = |_output: &Path| {
            system_calls += 1;
            Ok(process_exit_status(0))
        };

        let error = run_area_selector_with(
            Some(Path::new("/tmp/ShotEyeSelector")),
            Path::new("/tmp/shoteye-output.png"),
            &mut probe,
            &mut helper_runner,
            &mut system_runner,
        )
        .expect_err("helper permission denial must not launch system fallback");

        assert_eq!(error.kind(), ErrorKind::PermissionDenied);
        assert_eq!(helper_calls, 1);
        assert_eq!(system_calls, 0);
    }

    #[cfg(target_os = "macos")]
    #[test]
    fn area_selector_dispatch_preserves_helper_cancel_and_failure() {
        use std::path::Path;

        for exit_code in [2, 1] {
            let mut probe = |_path: &Path| Some(true);
            let mut system_calls = 0;
            let mut helper_runner = |_helper: &Path, _output: &Path| Ok(process_exit_status(exit_code));
            let mut system_runner = |_output: &Path| {
                system_calls += 1;
                Ok(process_exit_status(0))
            };

            let result = run_area_selector_with(
                Some(Path::new("/tmp/ShotEyeSelector")),
                Path::new("/tmp/shoteye-output.png"),
                &mut probe,
                &mut helper_runner,
                &mut system_runner,
            )
            .expect("helper terminal status is returned");

            assert_eq!(result.code(), Some(exit_code));
            assert_eq!(system_calls, 0);
        }
    }

    #[cfg(target_os = "macos")]
    #[test]
    fn area_selector_dispatch_falls_back_on_helper_spawn_failure_but_not_timeout() {
        use std::path::Path;

        let mut probe = |_path: &Path| Some(true);
        let mut system_calls = 0;
        let mut helper_runner = |_helper: &Path, _output: &Path| {
            Err(std::io::Error::new(ErrorKind::NotFound, "helper missing"))
        };
        let mut system_runner = |_output: &Path| {
            system_calls += 1;
            Ok(process_exit_status(0))
        };
        let result = run_area_selector_with(
            Some(Path::new("/tmp/ShotEyeSelector")),
            Path::new("/tmp/shoteye-output.png"),
            &mut probe,
            &mut helper_runner,
            &mut system_runner,
        )
        .expect("system fallback handles a missing helper");
        assert_eq!(result.code(), Some(0));
        assert_eq!(system_calls, 1);

        let mut probe = |_path: &Path| Some(true);
        let mut system_calls = 0;
        let mut helper_runner = |_helper: &Path, _output: &Path| {
            Err(std::io::Error::new(ErrorKind::TimedOut, "helper timed out"))
        };
        let mut system_runner = |_output: &Path| {
            system_calls += 1;
            Ok(process_exit_status(0))
        };
        let error = run_area_selector_with(
            Some(Path::new("/tmp/ShotEyeSelector")),
            Path::new("/tmp/shoteye-output.png"),
            &mut probe,
            &mut helper_runner,
            &mut system_runner,
        )
        .expect_err("timeout must not start a second selector");
        assert_eq!(error.kind(), ErrorKind::TimedOut);
        assert_eq!(system_calls, 0);
    }

    #[test]
    fn helper_permission_exit_is_distinct_from_cancel_and_failure() {
        assert!(helper_exit_is_explicit_permission_denial(Some(3)));
        assert!(!helper_exit_is_explicit_permission_denial(Some(2)));
        assert!(!helper_exit_is_explicit_permission_denial(Some(1)));
    }

    #[test]
    fn unavailable_helper_launch_errors_use_system_fallback() {
        assert!(helper_launch_error_allows_system_fallback(ErrorKind::NotFound));
        assert!(helper_launch_error_allows_system_fallback(ErrorKind::PermissionDenied));
        assert!(helper_launch_error_allows_system_fallback(ErrorKind::InvalidInput));
        assert!(helper_launch_error_allows_system_fallback(ErrorKind::Other));
        assert!(!helper_launch_error_allows_system_fallback(ErrorKind::TimedOut));
    }

    #[cfg(target_os = "macos")]
    #[test]
    fn capture_process_timeout_kills_the_child_and_returns_a_timeout() {
        let mut command = Command::new("/bin/sh");
        command.args(["-c", "sleep 2"]);
        let error = run_command_with_timeout(&mut command, Duration::from_millis(20))
            .expect_err("a sleeping capture child should time out");
        assert_eq!(error.kind(), ErrorKind::TimedOut);
    }

    #[cfg(target_os = "macos")]
    #[test]
    fn helper_permission_probe_timeout_is_treated_as_inconclusive() {
        let mut command = Command::new("/bin/sh");
        command.args(["-c", "sleep 2"]);
        assert_eq!(helper_permission_probe(&mut command, Duration::from_millis(20)), None);
    }

    #[test]
    fn helper_exit_messages_distinguish_cancel_and_failure() {
        assert!(native_capture_exit_message(CaptureMode::Area, Some(2)).contains("cancelled"));
        assert!(native_capture_exit_message(CaptureMode::Area, Some(1)).contains("failed"));
        assert!(native_capture_exit_message(CaptureMode::Area, None).contains("without a status code"));
    }

    #[cfg(target_os = "macos")]
    #[test]
    fn native_capture_location_is_private_and_unique() {
        use std::{fs, os::unix::fs::PermissionsExt};
        let first = capture_temp_location(CaptureMode::Area).expect("first temp location");
        let second = capture_temp_location(CaptureMode::Area).expect("second temp location");
        let first_mode = fs::metadata(&first.directory).expect("first directory metadata").permissions().mode() & 0o777;
        let second_mode = fs::metadata(&second.directory).expect("second directory metadata").permissions().mode() & 0o777;
        assert_eq!(first_mode, 0o700);
        assert_eq!(second_mode, 0o700);
        assert_ne!(first.directory, second.directory);
        assert!(first.path.starts_with(&first.directory));
        assert!(second.path.starts_with(&second.directory));
        let first_dir = first.directory.clone();
        let second_dir = second.directory.clone();
        drop(first);
        drop(second);
        assert!(!first_dir.exists());
        assert!(!second_dir.exists());
    }

    #[cfg(target_os = "macos")]
    #[test]
    fn clipboard_staging_uses_a_private_requested_filename() {
        use std::{fs, os::unix::fs::PermissionsExt};
        let location = private_temp_location("clipboard.png").expect("private clipboard location");
        assert_eq!(location.path.file_name().and_then(|name| name.to_str()), Some("clipboard.png"));
        assert_eq!(fs::metadata(&location.directory).expect("clipboard directory metadata").permissions().mode() & 0o777, 0o700);
        let directory = location.directory.clone();
        drop(location);
        assert!(!directory.exists());
    }

    #[cfg(target_os = "macos")]
    #[test]
    fn drag_out_stages_a_product_named_png_in_private_state() {
        use std::{fs, os::unix::fs::PermissionsExt};
        let capture = CaptureImage {
            bytes: minimal_png(17, 23),
            width: 17,
            height: 23,
        };
        let location = stage_drag_capture(&capture).expect("drag staging succeeds");
        let path = location.path.clone();
        assert_eq!(path.file_name().and_then(|name| name.to_str()), Some(DRAG_OUT_FILE_NAME));
        assert!(path.is_file());
        let directory_mode = fs::metadata(path.parent().expect("staging directory"))
            .expect("staging metadata")
            .permissions()
            .mode()
            & 0o777;
        assert_eq!(directory_mode, 0o700);
    }

    #[test]
    fn capture_shortcut_requires_a_modifier_combination() {
        assert_eq!(
            normalized_capture_shortcut(" CommandOrControl+Shift+Y ").as_deref(),
            Ok("CommandOrControl+Shift+Y")
        );
        assert!(normalized_capture_shortcut("Y").is_err());
        assert!(normalized_capture_shortcut("   ").is_err());
    }

    #[test]
    fn shortcut_registration_retries_an_unregistered_current_value() {
        assert!(!shortcut_requires_registration(
            "CommandOrControl+Shift+Y",
            true,
            "CommandOrControl+Shift+Y"
        ));
        assert!(shortcut_requires_registration(
            "CommandOrControl+Shift+Y",
            false,
            "CommandOrControl+Shift+Y"
        ));
        assert!(shortcut_requires_registration(
            "CommandOrControl+Shift+Y",
            true,
            "CommandOrControl+Shift+U"
        ));
    }

    #[test]
    fn shortcut_registration_conflict_preserves_the_last_working_binding() {
        let mut current = "CommandOrControl+Shift+Y".to_string();
        let mut registered = true;
        let message = apply_capture_shortcut_registration(
            &mut current,
            &mut registered,
            "Command+Alt+F18",
            |_| Err("occupied".to_string()),
            |_| Ok(()),
        );
        assert!(message.contains("could not register Command+Alt+F18"));
        assert_eq!(current, "CommandOrControl+Shift+Y");
        assert!(registered);
    }

    #[test]
    fn shortcut_registration_rolls_back_when_removing_the_previous_binding_fails() {
        let mut current = "CommandOrControl+Shift+Y".to_string();
        let mut registered = true;
        let message = apply_capture_shortcut_registration(
            &mut current,
            &mut registered,
            "Command+Alt+F18",
            |_| Ok(()),
            |value| if value == "CommandOrControl+Shift+Y" { Err("still owned".to_string()) } else { Ok(()) },
        );
        assert!(message.contains("kept CommandOrControl+Shift+Y"));
        assert_eq!(current, "CommandOrControl+Shift+Y");
        assert!(registered);
    }

    #[test]
    fn shortcut_registration_commits_an_accepted_replacement() {
        let mut current = "CommandOrControl+Shift+Y".to_string();
        let mut registered = true;
        let message = apply_capture_shortcut_registration(
            &mut current,
            &mut registered,
            "Command+Alt+F18",
            |_| Ok(()),
            |_| Ok(()),
        );
        assert_eq!(message, "Capture shortcut set to Command+Alt+F18.");
        assert_eq!(current, "Command+Alt+F18");
        assert!(registered);
    }

    #[test]
    fn runtime_contract_requires_frontend_ipc_capture_and_restoration() {
        assert!(runtime_contract_passes(
            true,
            true,
            true,
            Some((32, 24)),
            Some((32, 24)),
            true,
        ));
        assert!(!runtime_contract_passes(
            true,
            true,
            true,
            Some((32, 24)),
            Some((31, 24)),
            true,
        ));
        assert!(!runtime_contract_passes(
            true,
            true,
            false,
            Some((32, 24)),
            Some((32, 24)),
            true,
        ));
    }

    #[test]
    fn capture_lifecycle_state_tracks_native_restoration() {
        let state = CaptureLifecycleState::default();
        state.begin();
        assert!(state.restoration_succeeded());
        state.set_restoration_succeeded(false);
        assert!(!state.restoration_succeeded());
        state.begin();
        assert!(state.restoration_succeeded());
    }

    #[test]
    fn shortcut_requests_are_queued_until_the_listener_is_ready() {
        let mut readiness = ShortcutReadiness::default();
        assert!(!record_capture_request(&mut readiness));
        assert!(readiness.pending_capture);
        assert!(complete_capture_frontend_ready(&mut readiness));
        assert!(!readiness.pending_capture);
        assert!(record_capture_request(&mut readiness));
        assert!(!readiness.pending_capture);
    }

    #[test]
    fn unavailable_permission_message_prevents_repeat_prompt_confusion() {
        let message = unavailable_screen_capture_permission_message();
        assert!(message.contains("will not invoke macOS capture again"));
        assert!(message.contains("Developer ID signing"));
        assert!(message.contains("Screen & System Audio Recording"));
        assert!(message.contains("does not record system audio"));
    }

    #[test]
    fn permission_status_message_is_non_prompting_and_actionable() {
        assert!(permission_status_message_for_grants(true, false, None).contains("available"));
        let unavailable = permission_status_message_for_grants(false, false, None);
        assert!(unavailable.contains("Open Permissions"));
        assert!(unavailable.contains("will not invoke macOS capture again"));
    }

    #[test]
    fn permission_status_distinguishes_parent_and_selector_identity() {
        let mismatch = permission_status_message_for_grants(true, true, Some(false));
        assert!(mismatch.contains("bundled selector is not authorized"));
        assert!(mismatch.contains("exact ShotEye entry"));

        let inconclusive = permission_status_message_for_grants(true, true, None);
        assert!(inconclusive.contains("selector check was inconclusive"));
        assert!(inconclusive.contains("safe fallback"));

        let available = permission_status_message_for_grants(true, true, Some(true));
        assert_eq!(available, "Screen capture permission is available to ShotEye.");
    }

    #[test]
    fn permission_status_accepts_authorized_selector_when_parent_preflight_is_stale() {
        let message = permission_status_message_for_grants(false, true, Some(true));
        assert!(message.contains("available"));
        assert!(!message.contains("unavailable"));
    }

    #[test]
    fn permission_action_does_not_repeat_consent_when_selector_is_present() {
        let available = permission_request_message_for_grants(false, true, Some(true))
            .expect("authorized selector should produce a status");
        assert!(available.contains("bundled selector"));
        assert!(permission_request_message_for_grants(false, true, Some(false))
            .expect("denied selector should produce guidance")
            .contains("exact ShotEye entry"));
        assert!(permission_request_message_for_grants(false, true, None)
            .expect("inconclusive selector should fail closed")
            .contains("will not invoke macOS capture again"));
        assert!(permission_request_message_for_grants(true, true, None)
            .expect("authorized parent should produce safe-fallback guidance")
            .contains("safe fallback"));
        assert!(permission_request_message_for_grants(true, false, None)
            .expect("authorized parent should produce a status")
            .contains("already available"));
        assert!(permission_request_message_for_grants(false, false, None).is_none());
    }

    #[test]
    fn area_capture_uses_selector_grant_but_preserves_fail_closed_paths() {
        assert!(capture_permission_is_granted_for_mode(
            CaptureMode::Area,
            false,
            true,
            Some(true),
        ));
        assert!(!capture_permission_is_granted_for_mode(
            CaptureMode::Area,
            true,
            true,
            Some(false),
        ));
        assert!(capture_permission_is_granted_for_mode(
            CaptureMode::Area,
            true,
            true,
            None,
        ));
        assert!(!capture_permission_is_granted_for_mode(
            CaptureMode::Area,
            false,
            true,
            None,
        ));
        assert!(!capture_permission_is_granted_for_mode(
            CaptureMode::Fullscreen,
            false,
            true,
            Some(true),
        ));
    }

    #[test]
    fn denied_capture_is_rejected_before_the_editor_is_hidden() {
        assert!(should_skip_capture_before_hide(false, false));
        assert!(!should_skip_capture_before_hide(true, false));
        assert!(!should_skip_capture_before_hide(false, true));
    }

    #[test]
    fn screen_capture_usage_description_covers_all_capture_modes_without_audio() {
        let usage_description = include_str!("../Info.plist");
        assert!(usage_description.contains("for screenshots"));
        assert!(usage_description.contains("does not record system audio"));
    }
}
