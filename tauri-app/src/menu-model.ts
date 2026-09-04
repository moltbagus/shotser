import { nativeMenuShortcut, repeatCaptureMenuAccelerator, shotEyeShortcuts } from "./shortcut-display";

export type ShotEyeMenuAction =
  | "open"
  | "paste"
  | "copy"
  | "save"
  | "capture-area"
  | "capture-window"
  | "capture-fullscreen"
  | "repeat-capture"
  | "tool-select"
  | "tool-crop"
  | "tool-arrow"
  | "tool-rectangle"
  | "tool-text"
  | "tool-draw"
  | "tool-redact"
  | "tool-pixelate"
  | "tool-blur"
  | "undo"
  | "redo"
  | "clear"
  | "reset"
  | "permissions"
  | "screen-recording-settings";

export type ShotEyeMenuItem = {
  id: string;
  text: string;
  action: ShotEyeMenuAction;
  accelerator?: string;
};

export type ShotEyeMenuGroup = {
  id: string;
  text: string;
  items: readonly ShotEyeMenuItem[];
};

/** Product commands exposed in the native macOS menu bar. */
export const shotEyeMenuGroups: readonly ShotEyeMenuGroup[] = [
  {
    id: "file",
    text: "File",
    items: [
      { id: "open-image", text: "Open Image…", action: "open", accelerator: nativeMenuShortcut(shotEyeShortcuts.open) },
      { id: "paste-image", text: "Paste Image", action: "paste", accelerator: nativeMenuShortcut(shotEyeShortcuts.paste) },
      { id: "copy-capture", text: "Copy Capture", action: "copy", accelerator: nativeMenuShortcut(shotEyeShortcuts.copy) },
      { id: "save-capture", text: "Save Capture…", action: "save", accelerator: nativeMenuShortcut(shotEyeShortcuts.save) },
    ],
  },
  {
    id: "capture",
    text: "Capture",
    items: [
      { id: "capture-area", text: "Capture Area", action: "capture-area" },
      { id: "capture-window", text: "Capture Window", action: "capture-window" },
      { id: "capture-fullscreen", text: "Capture Full Screen", action: "capture-fullscreen" },
      { id: "repeat-capture", text: "Repeat Last Capture", action: "repeat-capture", accelerator: repeatCaptureMenuAccelerator },
    ],
  },
  {
    id: "edit",
    text: "Edit",
    items: [
      { id: "undo", text: "Undo Annotation", action: "undo", accelerator: nativeMenuShortcut(shotEyeShortcuts.undo) },
      { id: "redo", text: "Redo Annotation", action: "redo", accelerator: nativeMenuShortcut(shotEyeShortcuts.redo) },
      { id: "clear-annotations", text: "Clear Annotations", action: "clear" },
      { id: "reset-image", text: "Reset Image", action: "reset" },
    ],
  },
  {
    id: "tools",
    text: "Tools",
    items: [
      { id: "tool-select", text: "Select", action: "tool-select" },
      { id: "tool-crop", text: "Crop", action: "tool-crop" },
      { id: "tool-arrow", text: "Arrow", action: "tool-arrow" },
      { id: "tool-rectangle", text: "Rectangle", action: "tool-rectangle" },
      { id: "tool-text", text: "Text", action: "tool-text" },
      { id: "tool-draw", text: "Draw", action: "tool-draw" },
      { id: "tool-redact", text: "Redact", action: "tool-redact" },
      { id: "tool-pixelate", text: "Pixelate", action: "tool-pixelate" },
      { id: "tool-blur", text: "Blur", action: "tool-blur" },
    ],
  },
  {
    id: "help",
    text: "Help",
    items: [
      { id: "permissions", text: "Permissions", action: "permissions" },
      { id: "screen-recording-settings", text: "Open Screen Recording Settings", action: "screen-recording-settings" },
    ],
  },
];
