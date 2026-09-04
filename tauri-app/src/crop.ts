import type { Point } from "./annotations";

export type CropRectangle = { start: Point; end: Point };

export type CropBounds = {
  left: number;
  top: number;
  width: number;
  height: number;
};

/** Normalizes a two-point drag into image-space crop bounds. */
export function cropBounds(crop: CropRectangle): CropBounds {
  return {
    left: Math.min(crop.start.x, crop.end.x),
    top: Math.min(crop.start.y, crop.end.y),
    width: Math.abs(crop.end.x - crop.start.x),
    height: Math.abs(crop.end.y - crop.start.y),
  };
}

/** Allows an async crop result to commit only if its source image is still current. */
export function cropResultIsCurrent(expectedRevision: number, currentRevision: number): boolean {
  return expectedRevision === currentRevision;
}

/**
 * Resolve async crop work only when the image edit revision is still current.
 * A null result is a deliberate no-op for callers whose source image changed
 * while browser image or canvas work was pending.
 */
export async function resolveAtStableRevision<T>(
  getRevision: () => number,
  resolve: () => Promise<T>,
): Promise<T | null> {
  const expectedRevision = getRevision();
  const result = await resolve();
  return cropResultIsCurrent(expectedRevision, getRevision()) ? result : null;
}
