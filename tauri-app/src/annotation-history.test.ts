import { describe, expect, it } from "vitest";
import { appendAnnotation, clearAnnotations, redoAnnotation, removeAnnotation, replaceAnnotation, undoAnnotation } from "./annotation-history";
import type { Annotation } from "./annotations";

const first: Annotation = { id: "first", kind: "rectangle", color: "#ff4d5a", stroke: 4, start: { x: 1, y: 2 }, end: { x: 30, y: 40 } };
const second: Annotation = { id: "second", kind: "text", color: "#ff4d5a", stroke: 4, point: { x: 10, y: 12 }, text: "Note" };
const history = { annotations: [first, second], undo: [[first]], redo: [] };

describe("annotation history", () => {
  it("undoes and redoes the most recent annotation in order", () => {
    const undone = undoAnnotation(history);

    expect(undone).toEqual({ annotations: [first], undo: [], redo: [[first, second]] });
    expect(redoAnnotation(undone)).toEqual(history);
  });

  it("clears redo when a new annotation diverges from history", () => {
    const undone = undoAnnotation(history);

    expect(appendAnnotation(undone, second)).toEqual({ annotations: [first, second], undo: [[first]], redo: [] });
  });

  it("records deletion so Undo can restore a selected annotation", () => {
    const deleted = removeAnnotation(history, "first");

    expect(deleted).toEqual({ annotations: [second], undo: [[first], [first, second]], redo: [] });
    expect(undoAnnotation(deleted).annotations).toEqual([first, second]);
  });

  it("records a moved annotation as one undoable state", () => {
    const moved = { ...first, start: { x: 11, y: 12 }, end: { x: 40, y: 50 } };
    const next = replaceAnnotation(history, moved);

    expect(next.annotations[0]).toEqual(moved);
    expect(next.undo).toEqual([[first], [first, second]]);
    expect(undoAnnotation(next).annotations).toEqual([first, second]);
  });

  it("makes Clear undoable and leaves empty history unchanged", () => {
    expect(clearAnnotations(history)).toEqual({ annotations: [], undo: [[first], [first, second]], redo: [] });
    const empty = { annotations: [], undo: [], redo: [] };
    expect(undoAnnotation(empty)).toBe(empty);
    expect(redoAnnotation(empty)).toBe(empty);
    expect(clearAnnotations(empty)).toBe(empty);
  });
});
