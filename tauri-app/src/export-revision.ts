/** Prepare an async export and only succeed when the visible input stayed current. */
export async function prepareAtStableRevision(
  getRevision: () => number,
  prepare: (revision: number) => Promise<void>,
  maxAttempts = 4,
): Promise<number> {
  for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
    const revision = getRevision();
    await prepare(revision);
    if (getRevision() === revision) return revision;
  }
  throw new Error("The capture changed while the export was being prepared. Try again.");
}
