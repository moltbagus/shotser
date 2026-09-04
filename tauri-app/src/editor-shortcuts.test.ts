import { describe, expect, it } from "vitest";
import { editorShortcutAction } from "./editor-shortcuts";

describe("editorShortcutAction", () => {
  it("maps macOS undo and redo", () => {
    expect(editorShortcutAction({ key: "z", metaKey: true })).toBe("undo");
    expect(editorShortcutAction({ key: "z", metaKey: true, shiftKey: true })).toBe("redo");
  });

  it("maps common file and clipboard actions", () => {
    expect(editorShortcutAction({ key: "c", metaKey: true })).toBe("copy");
    expect(editorShortcutAction({ key: "s", metaKey: true })).toBe("save");
    expect(editorShortcutAction({ key: "o", metaKey: true })).toBe("open");
    expect(editorShortcutAction({ key: "v", metaKey: true })).toBe("paste");
  });

  it("maps the repeat-capture chord", () => {
    expect(editorShortcutAction({ key: "r", metaKey: true, shiftKey: true })).toBe("repeat");
    expect(editorShortcutAction({ key: "r", ctrlKey: true, shiftKey: true })).toBe("repeat");
  });

  it("supports control-key equivalents and delete", () => {
    expect(editorShortcutAction({ key: "z", ctrlKey: true })).toBe("undo");
    expect(editorShortcutAction({ key: "Delete" })).toBe("delete");
  });

  it("does not steal option chords or unrelated keys", () => {
    expect(editorShortcutAction({ key: "c", metaKey: true, altKey: true })).toBeNull();
    expect(editorShortcutAction({ key: "Escape" })).toBeNull();
  });
});
