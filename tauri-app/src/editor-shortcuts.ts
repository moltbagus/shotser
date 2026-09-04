export type EditorShortcutAction = "undo" | "redo" | "copy" | "save" | "open" | "paste" | "repeat" | "delete";

type ShortcutEvent = {
  key: string;
  metaKey?: boolean;
  ctrlKey?: boolean;
  shiftKey?: boolean;
  altKey?: boolean;
};

/** Maps familiar macOS/Windows editor chords to existing ShotEye actions. */
export function editorShortcutAction(event: ShortcutEvent): EditorShortcutAction | null {
  if (event.altKey) return null;
  if (event.metaKey || event.ctrlKey) {
    switch (event.key.toLowerCase()) {
      case "z":
        return event.shiftKey ? "redo" : "undo";
      case "r":
        return event.shiftKey ? "repeat" : null;
      case "c":
        return "copy";
      case "s":
        return "save";
      case "o":
        return "open";
      case "v":
        return "paste";
      default:
        return null;
    }
  }
  if (event.key === "Backspace" || event.key === "Delete") return "delete";
  return null;
}
