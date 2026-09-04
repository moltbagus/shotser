import { describe, expect, it } from "vitest";
import { prepareAtStableRevision } from "./export-revision";
import { preparedExportForRevision, type PreparedExport } from "./prepared-export";

describe("prepareAtStableRevision", () => {
  it("returns after preparation completes without a revision change", async () => {
    const prepared: number[] = [];

    await expect(prepareAtStableRevision(() => 4, async (revision) => { prepared.push(revision); })).resolves.toBe(4);
    expect(prepared).toEqual([4]);
  });

  it("retries when the visible revision changes during preparation", async () => {
    let revision = 4;
    const prepared: number[] = [];

    await expect(prepareAtStableRevision(() => revision, async (current) => {
      prepared.push(current);
      if (current === 4) revision = 5;
    })).resolves.toBe(5);
    expect(prepared).toEqual([4, 5]);
  });

  it("fails instead of returning a perpetually stale export", async () => {
    let revision = 1;

    await expect(prepareAtStableRevision(() => revision, async () => { revision += 1; }, 2))
      .rejects.toThrow("changed while the export was being prepared");
  });
});

describe("preparedExportForRevision", () => {
  it("returns cached bytes only for the matching image revision", () => {
    const prepared: PreparedExport = { revision: 7, dataUrl: "data:image/png;base64,latest" };

    expect(preparedExportForRevision(prepared, 7)).toBe(prepared);
    expect(preparedExportForRevision(prepared, 8)).toBeNull();
  });
});
