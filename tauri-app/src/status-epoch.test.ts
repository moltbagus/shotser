import { describe, expect, it } from "vitest";
import { beginStatusEpoch, statusEpochIsCurrent, type StatusEpoch } from "./status-epoch";

describe("status epochs", () => {
  it("invalidates stale asynchronous status updates after a user action", () => {
    const epoch: StatusEpoch = { current: 0 };
    const startupEpoch = epoch.current;

    beginStatusEpoch(epoch);

    expect(statusEpochIsCurrent(epoch, startupEpoch)).toBe(false);
    expect(statusEpochIsCurrent(epoch, epoch.current)).toBe(true);
  });
});
