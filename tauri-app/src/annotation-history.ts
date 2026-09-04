import type { Annotation } from "./annotations";

export type AnnotationHistory = {
  annotations: Annotation[];
  undo: Annotation[][];
  redo: Annotation[][];
};

function commit(history: AnnotationHistory, annotations: Annotation[]): AnnotationHistory {
  if (annotations === history.annotations) return history;
  return { annotations, undo: [...history.undo, history.annotations], redo: [] };
}

export function appendAnnotation(history: AnnotationHistory, annotation: Annotation): AnnotationHistory {
  return commit(history, [...history.annotations, annotation]);
}

export function removeAnnotation(history: AnnotationHistory, id: string): AnnotationHistory {
  const annotations = history.annotations.filter((annotation) => annotation.id !== id);
  return annotations.length === history.annotations.length ? history : commit(history, annotations);
}

export function replaceAnnotation(history: AnnotationHistory, annotation: Annotation): AnnotationHistory {
  const index = history.annotations.findIndex((current) => current.id === annotation.id);
  if (index < 0 || history.annotations[index] === annotation) return history;
  const annotations = history.annotations.slice();
  annotations[index] = annotation;
  return commit(history, annotations);
}

export function clearAnnotations(history: AnnotationHistory): AnnotationHistory {
  return history.annotations.length === 0 ? history : commit(history, []);
}

export function undoAnnotation(history: AnnotationHistory): AnnotationHistory {
  const annotations = history.undo[history.undo.length - 1];
  if (!annotations) return history;
  return { annotations, undo: history.undo.slice(0, -1), redo: [...history.redo, history.annotations] };
}

export function redoAnnotation(history: AnnotationHistory): AnnotationHistory {
  const annotations = history.redo[history.redo.length - 1];
  if (!annotations) return history;
  return { annotations, undo: [...history.undo, history.annotations], redo: history.redo.slice(0, -1) };
}
