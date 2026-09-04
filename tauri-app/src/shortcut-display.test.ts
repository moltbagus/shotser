import { describe, expect, it } from "vitest";
import { ariaKeyShortcuts, displayShortcut, displayShortcutStatus, nativeMenuShortcut, shotEyeShortcuts } from "./shortcut-display";

describe("displayShortcut", () => {
  it("renders the default capture shortcut in macOS notation", () => {
    expect(displayShortcut("CommandOrControl+Shift+Y")).toBe("⌘⇧Y");
  });

  it("preserves the key while converting mixed modifier combinations", () => {
    expect(displayShortcut("CommandOrControl+Alt+Shift+Space")).toBe("⌘⌥⇧Space");
  });

  it("keeps an unknown key label readable", () => {
    expect(displayShortcut("Control+F13")).toBe("⌃F13");
  });

  it("does not leak the registration syntax through status messages", () => {
    expect(displayShortcutStatus("Capture shortcut is already CommandOrControl+Shift+Y.", "CommandOrControl+Shift+Y")).toBe("Capture shortcut is already ⌘⇧Y.");
  });

  it("formats rejected shortcut values in user-facing errors", () => {
    expect(displayShortcutStatus("ShotEye could not register Command+Shift+K. It may be used by another app.", "Command+Shift+K")).toBe("ShotEye could not register ⌘⇧K. It may be used by another app.");
  });

  it("keeps the repeat shortcut representations aligned across surfaces", () => {
    expect(shotEyeShortcuts.repeat).toBe("CommandOrControl+Shift+R");
    expect(nativeMenuShortcut(shotEyeShortcuts.repeat)).toBe("CmdOrCtrl+Shift+R");
    expect(ariaKeyShortcuts(shotEyeShortcuts.repeat)).toBe("Meta+Shift+R");
  });

  it("defines the primary toolbar shortcut contract once", () => {
    expect(shotEyeShortcuts).toMatchObject({
      open: "CommandOrControl+O",
      paste: "CommandOrControl+V",
      copy: "CommandOrControl+C",
      save: "CommandOrControl+S",
      undo: "CommandOrControl+Z",
      redo: "CommandOrControl+Shift+Z",
    });
  });
});
