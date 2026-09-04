import { describe, expect, it } from "vitest";
import { appendCaptureHistory, MAX_CAPTURE_HISTORY, MAX_CAPTURE_HISTORY_DATA_BYTES, type CaptureHistoryEntry } from "./capture-history";

function entry(id: string): CaptureHistoryEntry {
  return { id, dataUrl: `data:image/png;base64,${id}`, width: 100, height: 80, createdAt: 1 };
}

describe("capture history", () => {
  it("prepends the newest capture and leaves the input untouched", () => {
    const previous = [entry("old")];
    const next = appendCaptureHistory(previous, entry("new"));

    expect(next.map((capture) => capture.id)).toEqual(["new", "old"]);
    expect(previous.map((capture) => capture.id)).toEqual(["old"]);
  });

  it("keeps the most recent entries within the configured limit", () => {
    const previous = [entry("two"), entry("one")];
    const next = appendCaptureHistory(previous, entry("three"), 2);

    expect(next.map((capture) => capture.id)).toEqual(["three", "two"]);
  });

  it("replaces a repeated id without duplicating it", () => {
    const previous = [entry("same"), entry("older")];
    const replacement = { ...entry("same"), width: 200 };
    const next = appendCaptureHistory(previous, replacement);

    expect(next).toHaveLength(2);
    expect(next[0]).toEqual(replacement);
    expect(next[1]?.id).toBe("older");
  });

  it("returns an empty history for a non-positive limit", () => {
    expect(appendCaptureHistory([entry("old")], entry("new"), 0)).toEqual([]);
    expect(MAX_CAPTURE_HISTORY).toBe(8);
  });

  it("evicts older entries when the encoded data budget is exhausted", () => {
    const previous = [{ ...entry("old"), dataUrl: "o".repeat(8) }];
    const newest = { ...entry("new"), dataUrl: "n".repeat(8) };

    expect(appendCaptureHistory(previous, newest, MAX_CAPTURE_HISTORY, 12).map((capture) => capture.id)).toEqual(["new"]);
    expect(MAX_CAPTURE_HISTORY_DATA_BYTES).toBe(128 * 1024 * 1024);
  });
});
