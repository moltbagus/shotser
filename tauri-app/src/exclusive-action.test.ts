import { describe, expect, it, vi } from "vitest";
import { runExclusiveAction } from "./exclusive-action";

describe("runExclusiveAction", () => {
  it("keeps a second action from starting while the first is pending", async () => {
    const state = { current: false };
    const releaseBusy = vi.fn();
    let releaseFirst: (() => void) | undefined;
    const first = runExclusiveAction(
      state,
      () => new Promise<string>((resolve) => { releaseFirst = () => resolve("first"); }),
      releaseBusy,
    );

    expect(state.current).toBe(true);
    const second = await runExclusiveAction(state, async () => "second", releaseBusy);
    expect(second).toBeUndefined();
    expect(releaseBusy).toHaveBeenCalledOnce();
    expect(releaseFirst).toBeDefined();

    releaseFirst?.();
    await expect(first).resolves.toBe("first");
    expect(state.current).toBe(false);
  });

  it("releases the guard when the action rejects", async () => {
    const state = { current: false };
    await expect(runExclusiveAction(state, async () => { throw new Error("failed"); }, vi.fn())).rejects.toThrow("failed");
    expect(state.current).toBe(false);
    await expect(runExclusiveAction(state, async () => "next", vi.fn())).resolves.toBe("next");
  });
});
