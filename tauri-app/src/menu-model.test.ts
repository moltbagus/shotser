import { describe, expect, it } from "vitest";
import { shotEyeMenuGroups } from "./menu-model";

describe("ShotEye native menu model", () => {
  it("exposes every primary workflow without duplicate ids", () => {
    const items = shotEyeMenuGroups.flatMap((group) => group.items);
    const ids = items.map((item) => item.id);

    expect(new Set(ids).size).toBe(ids.length);
    expect(items.map((item) => item.action)).toEqual(expect.arrayContaining([
      "open",
      "paste",
      "copy",
      "save",
      "capture-area",
      "capture-window",
      "capture-fullscreen",
      "repeat-capture",
      "tool-select",
      "tool-crop",
      "tool-arrow",
      "tool-rectangle",
      "tool-text",
      "tool-draw",
      "tool-redact",
      "tool-pixelate",
      "tool-blur",
      "undo",
      "redo",
      "permissions",
      "screen-recording-settings",
    ]));
  });

  it("uses platform-neutral accelerator syntax for menu shortcuts", () => {
    const items = shotEyeMenuGroups.flatMap((group) => group.items);
    expect(items.find((item) => item.action === "open")?.accelerator).toBe("CmdOrCtrl+O");
    expect(items.find((item) => item.action === "undo")?.accelerator).toBe("CmdOrCtrl+Z");
    expect(items.find((item) => item.action === "repeat-capture")?.accelerator).toBe("CmdOrCtrl+Shift+R");
  });
});
