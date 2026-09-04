import { describe, expect, it } from "vitest";
import { shortcutFromKeyboardEvent } from "./capture-shortcut";

describe("shortcutFromKeyboardEvent", () => {
  it("keeps Command and Control distinct on macOS", () => {
    expect(shortcutFromKeyboardEvent({ key: "Y", code: "KeyY", metaKey: true, shiftKey: true })).toBe("Command+Shift+Y");
    expect(shortcutFromKeyboardEvent({ key: "Y", code: "KeyY", ctrlKey: true, shiftKey: true })).toBe("Control+Shift+Y");
  });

  it("supports function, punctuation, and numpad keys", () => {
    expect(shortcutFromKeyboardEvent({ key: "F8", code: "F8", metaKey: true })).toBe("Command+F8");
    expect(shortcutFromKeyboardEvent({ key: ";", code: "Semicolon", altKey: true })).toBe("Alt+Semicolon");
    expect(shortcutFromKeyboardEvent({ key: "4", code: "Numpad4", shiftKey: true })).toBe("Shift+Numpad4");
  });

  it("requires a non-modifier key and at least one modifier", () => {
    expect(shortcutFromKeyboardEvent({ key: "Shift", code: "ShiftLeft", shiftKey: true })).toBeNull();
    expect(shortcutFromKeyboardEvent({ key: "Y", code: "KeyY" })).toBeNull();
  });
});
