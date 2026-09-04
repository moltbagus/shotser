const modifierSymbols: Record<string, string> = {
  CommandOrControl: "⌘",
  Command: "⌘",
  Control: "⌃",
  Alt: "⌥",
  Option: "⌥",
  Shift: "⇧",
};

const ariaModifierNames: Record<string, string> = {
  CommandOrControl: "Meta",
  Command: "Meta",
  Control: "Control",
  Alt: "Alt",
  Option: "Alt",
  Shift: "Shift",
};

/** Canonical editor shortcuts shared by the DOM, toolbar, and native menu. */
export const shotEyeShortcuts = {
  open: "CommandOrControl+O",
  paste: "CommandOrControl+V",
  copy: "CommandOrControl+C",
  save: "CommandOrControl+S",
  undo: "CommandOrControl+Z",
  redo: "CommandOrControl+Shift+Z",
  repeat: "CommandOrControl+Shift+R",
} as const;

export function nativeMenuShortcut(shortcut: string): string {
  return shortcut.replace("CommandOrControl", "CmdOrCtrl");
}

export const repeatCaptureShortcut = shotEyeShortcuts.repeat;
export const repeatCaptureMenuAccelerator = nativeMenuShortcut(repeatCaptureShortcut);

/** Converts the global-shortcut registration syntax into familiar macOS notation. */
export function displayShortcut(shortcut: string): string {
  return shortcut
    .split("+")
    .map((part) => modifierSymbols[part] ?? (part === "Space" ? "Space" : part))
    .join("");
}

/** Converts registration syntax into the WAI-ARIA key-shortcuts syntax. */
export function ariaKeyShortcuts(shortcut: string): string {
  return shortcut
    .split("+")
    .map((part) => ariaModifierNames[part] ?? part)
    .join("+");
}

export function displayShortcutStatus(message: string, shortcut: string): string {
  if (message.startsWith("Capture shortcut set to")) return `Capture shortcut set to ${displayShortcut(shortcut)}.`;
  if (message.startsWith("Capture shortcut is already")) return `Capture shortcut is already ${displayShortcut(shortcut)}.`;
  return message.split(shortcut).join(displayShortcut(shortcut));
}
