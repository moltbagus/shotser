export type ExclusiveActionState = { current: boolean };

/** Run one user-triggered async action at a time and release the guard on every exit path. */
export async function runExclusiveAction<T>(
  state: ExclusiveActionState,
  action: () => Promise<T>,
  onBusy: () => void,
): Promise<T | undefined> {
  if (state.current) {
    onBusy();
    return undefined;
  }
  state.current = true;
  try {
    return await action();
  } finally {
    state.current = false;
  }
}
