import { describe, expect, it, vi } from "vitest";
import { runNativeCaptureAction } from "./capture-window-lifecycle";

describe("runNativeCaptureAction", () => {
  it("runs the native action and leaves window restoration to Rust", async () => {
    const action = vi.fn(async () => "capture");

    await expect(runNativeCaptureAction(action)).resolves.toEqual({
      result: "capture",
      actionError: null,
    });
    expect(action).toHaveBeenCalledOnce();
  });

  it("captures action failures without swallowing them", async () => {
    const action = vi.fn(async () => { throw new Error("capture failed"); });

    const outcome = await runNativeCaptureAction(action);
    expect(outcome.result).toBeUndefined();
    expect(outcome.actionError).toEqual(new Error("capture failed"));
    expect(action).toHaveBeenCalledOnce();
  });
});
