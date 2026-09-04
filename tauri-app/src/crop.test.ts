import { describe, expect, it } from "vitest";
import { cropBounds, cropResultIsCurrent, resolveAtStableRevision } from "./crop";
import { pointFromPointer } from "./annotations";

describe("cropBounds", () => {
  it("keeps a conventional top-left to bottom-right drag in image coordinates", () => {
    expect(cropBounds({ start: { x: 120, y: 80 }, end: { x: 620, y: 410 } })).toEqual({
      left: 120,
      top: 80,
      width: 500,
      height: 330,
    });
  });

  it("normalizes a reverse drag before it reaches canvas drawImage", () => {
    expect(cropBounds({ start: { x: 620, y: 410 }, end: { x: 120, y: 80 } })).toEqual({
      left: 120,
      top: 80,
      width: 500,
      height: 330,
    });
  });

  it("clamps pointer-derived crop endpoints to the source image", () => {
    const bounds = { left: 50, top: 25, width: 500, height: 250 } as DOMRect;
    const start = pointFromPointer({ clientX: 0, clientY: 0 }, bounds, 1000, 500);
    const end = pointFromPointer({ clientX: 700, clientY: 400 }, bounds, 1000, 500);

    expect(cropBounds({ start, end })).toEqual({ left: 0, top: 0, width: 1000, height: 500 });
  });
});

describe("cropResultIsCurrent", () => {
  it("allows a delayed crop to commit when the source revision is unchanged", () => {
    expect(cropResultIsCurrent(4, 4)).toBe(true);
  });

  it("rejects a delayed crop after reset or another image edit advances the revision", () => {
    expect(cropResultIsCurrent(4, 5)).toBe(false);
  });
});

describe("resolveAtStableRevision", () => {
  it("returns the delayed crop result when no edit interleaves", async () => {
    await expect(resolveAtStableRevision(() => 4, async () => "cropped-data")).resolves.toBe("cropped-data");
  });

  it("rejects a delayed Crop result after Reset advances the image revision", async () => {
    let revision = 4;
    let release!: () => void;
    const delayed = new Promise<string>((resolve) => { release = () => resolve("stale-after-reset"); });
    const pending = resolveAtStableRevision(() => revision, async () => delayed);

    revision += 1;
    release();

    await expect(pending).resolves.toBeNull();
  });

  it("rejects a delayed Crop result after an annotation advances the image revision", async () => {
    let revision = 8;
    let release!: () => void;
    const delayed = new Promise<string>((resolve) => { release = () => resolve("stale-after-annotation"); });
    const pending = resolveAtStableRevision(() => revision, async () => delayed);

    revision += 1;
    release();

    await expect(pending).resolves.toBeNull();
  });
});
