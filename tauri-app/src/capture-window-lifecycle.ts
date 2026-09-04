export type NativeCaptureOutcome<T> = {
  result: T | undefined;
  actionError: unknown | null;
};

/** Run one native capture; Rust owns the macOS hide/restore boundary. */
export async function runNativeCaptureAction<T>(action: () => Promise<T>): Promise<NativeCaptureOutcome<T>> {
  let result: T | undefined;
  let actionError: unknown | null = null;

  try {
    result = await action();
  } catch (error) {
    actionError = error;
  }

  return { result, actionError };
}
