export type PreparedExport = {
  revision: number;
  dataUrl: string;
};

/** Return a rendered export only when it belongs to the visible image revision. */
export function preparedExportForRevision(
  prepared: PreparedExport | null,
  revision: number,
): PreparedExport | null {
  return prepared?.revision === revision ? prepared : null;
}
