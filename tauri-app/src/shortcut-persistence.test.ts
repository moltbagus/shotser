import { describe, expect, it } from "vitest";
import { shortcutApplyAccepted, startupShortcutRecovery } from "./shortcut-persistence";

describe("shortcut persistence", () => {
  it("recognizes only successful native shortcut responses", () => {
    expect(shortcutApplyAccepted("Capture shortcut set to Command+Shift+Y.")).toBe(true);
    expect(shortcutApplyAccepted("Capture shortcut is already Command+Shift+Y.")).toBe(true);
    expect(shortcutApplyAccepted("ShotEye could not register Command+Shift+Y.")).toBe(false);
  });

  it("returns to the known active default when a saved shortcut is rejected at startup", () => {
    expect(startupShortcutRecovery("Control+Shift+Y", "CommandOrControl+Shift+Y", false)).toEqual({
      shortcut: "CommandOrControl+Shift+Y",
      clearStored: true,
    });
  });

  it("does not clear the default when startup already uses it", () => {
    expect(startupShortcutRecovery("CommandOrControl+Shift+Y", "CommandOrControl+Shift+Y", false)).toEqual({
      shortcut: "CommandOrControl+Shift+Y",
      clearStored: false,
    });
  });

  it("keeps an accepted saved shortcut", () => {
    expect(startupShortcutRecovery("Control+Shift+Y", "CommandOrControl+Shift+Y", true)).toEqual({
      shortcut: "Control+Shift+Y",
      clearStored: false,
    });
  });
});
