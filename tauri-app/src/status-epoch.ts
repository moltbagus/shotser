export type StatusEpoch = { current: number };

/** Advance the epoch whenever a user action owns the status line. */
export function beginStatusEpoch(epoch: StatusEpoch): number {
  epoch.current += 1;
  return epoch.current;
}

/** Return true only while an asynchronous status update is still current. */
export function statusEpochIsCurrent(epoch: StatusEpoch, expected: number): boolean {
  return epoch.current === expected;
}
