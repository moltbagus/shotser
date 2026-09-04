export type CaptureHistoryEntry = {
  id: string;
  dataUrl: string;
  width: number;
  height: number;
  createdAt: number;
};

export const MAX_CAPTURE_HISTORY = 8;
// Data URLs are base64-backed strings, so an entry costs more memory than the
// decoded PNG alone. Keep session history bounded by both count and payload.
export const MAX_CAPTURE_HISTORY_DATA_BYTES = 128 * 1024 * 1024;

/** Prepend one capture without mutating the existing session history. */
export function appendCaptureHistory(
  history: readonly CaptureHistoryEntry[],
  entry: CaptureHistoryEntry,
  limit = MAX_CAPTURE_HISTORY,
  maxDataUrlBytes = MAX_CAPTURE_HISTORY_DATA_BYTES,
): CaptureHistoryEntry[] {
  if (limit <= 0 || maxDataUrlBytes <= 0) return [];
  const candidates = [entry, ...history.filter((existing) => existing.id !== entry.id)].slice(0, limit);
  let dataUrlBytes = 0;
  return candidates.filter((candidate) => {
    const nextBytes = dataUrlBytes + candidate.dataUrl.length;
    if (nextBytes > maxDataUrlBytes) return false;
    dataUrlBytes = nextBytes;
    return true;
  });
}
