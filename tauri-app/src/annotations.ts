export type Point = { x: number; y: number };

export type AnnotationTool = "Arrow" | "Rectangle" | "Text" | "Draw" | "Redact" | "Pixelate" | "Blur";
export type ResizeHandle = "start" | "end" | "nw" | "ne" | "se" | "sw";

type AnnotationBase = {
  id: string;
  color: string;
  stroke: number;
};

export type Annotation =
  | (AnnotationBase & { kind: "arrow"; start: Point; end: Point })
  | (AnnotationBase & { kind: "rectangle"; start: Point; end: Point })
  | (AnnotationBase & { kind: "redact"; start: Point; end: Point })
  | (AnnotationBase & { kind: "pixelate"; start: Point; end: Point })
  | (AnnotationBase & { kind: "blur"; start: Point; end: Point })
  | (AnnotationBase & { kind: "draw"; points: Point[] })
  | (AnnotationBase & { kind: "text"; point: Point; text: string });

export function translateAnnotation(annotation: Annotation, delta: Point): Annotation {
  const move = (point: Point): Point => ({ x: point.x + delta.x, y: point.y + delta.y });
  switch (annotation.kind) {
    case "draw":
      return { ...annotation, points: annotation.points.map(move) };
    case "text":
      return { ...annotation, point: move(annotation.point) };
    case "arrow":
    case "rectangle":
    case "redact":
    case "pixelate":
    case "blur":
      return { ...annotation, start: move(annotation.start), end: move(annotation.end) };
  }
}

export function resizeAnnotation(annotation: Annotation, handle: ResizeHandle, point: Point): Annotation {
  switch (annotation.kind) {
    case "arrow":
      if (handle === "start") return { ...annotation, start: point };
      if (handle === "end") return { ...annotation, end: point };
      return annotation;
    case "rectangle":
    case "redact":
    case "pixelate":
    case "blur": {
      const left = Math.min(annotation.start.x, annotation.end.x);
      const right = Math.max(annotation.start.x, annotation.end.x);
      const top = Math.min(annotation.start.y, annotation.end.y);
      const bottom = Math.max(annotation.start.y, annotation.end.y);
      switch (handle) {
        case "nw": return { ...annotation, start: point, end: { x: right, y: bottom } };
        case "ne": return { ...annotation, start: { x: left, y: point.y }, end: { x: point.x, y: bottom } };
        case "se": return { ...annotation, start: { x: left, y: top }, end: point };
        case "sw": return { ...annotation, start: { x: point.x, y: top }, end: { x: right, y: point.y } };
        default: return annotation;
      }
    }
    case "draw":
    case "text":
      return annotation;
  }
}

export function resizeHandlePoints(annotation: Annotation): Array<{ handle: ResizeHandle; point: Point }> {
  switch (annotation.kind) {
    case "arrow":
      return [{ handle: "start", point: annotation.start }, { handle: "end", point: annotation.end }];
    case "rectangle":
    case "redact":
    case "pixelate":
    case "blur": {
      const left = Math.min(annotation.start.x, annotation.end.x);
      const right = Math.max(annotation.start.x, annotation.end.x);
      const top = Math.min(annotation.start.y, annotation.end.y);
      const bottom = Math.max(annotation.start.y, annotation.end.y);
      return [
        { handle: "nw", point: { x: left, y: top } },
        { handle: "ne", point: { x: right, y: top } },
        { handle: "se", point: { x: right, y: bottom } },
        { handle: "sw", point: { x: left, y: bottom } },
      ];
    }
    case "draw":
    case "text":
      return [];
  }
}

export function pointFromPointer(
  event: Pick<PointerEvent, "clientX" | "clientY">,
  bounds: DOMRect,
  imageWidth: number,
  imageHeight: number,
): Point {
  return {
    x: Math.max(0, Math.min(imageWidth, ((event.clientX - bounds.left) / bounds.width) * imageWidth)),
    y: Math.max(0, Math.min(imageHeight, ((event.clientY - bounds.top) / bounds.height) * imageHeight)),
  };
}

export function isMeaningfulAnnotation(annotation: Annotation): boolean {
  switch (annotation.kind) {
    case "draw":
      return annotation.points.length > 1;
    case "text":
      return annotation.text.trim().length > 0;
    case "arrow":
    case "rectangle":
    case "redact":
    case "pixelate":
    case "blur":
      return Math.hypot(annotation.end.x - annotation.start.x, annotation.end.y - annotation.start.y) >= 3;
  }
}

function distanceToSegment(point: Point, start: Point, end: Point): number {
  const dx = end.x - start.x;
  const dy = end.y - start.y;
  if (dx === 0 && dy === 0) return Math.hypot(point.x - start.x, point.y - start.y);
  const t = Math.max(0, Math.min(1, ((point.x - start.x) * dx + (point.y - start.y) * dy) / (dx * dx + dy * dy)));
  return Math.hypot(point.x - (start.x + t * dx), point.y - (start.y + t * dy));
}

/** Hit-tests topmost annotations in source-image coordinates. */
export function findAnnotationAtPoint(annotations: Annotation[], point: Point, tolerance = 10): string | null {
  for (let index = annotations.length - 1; index >= 0; index -= 1) {
    const annotation = annotations[index];
    if (!annotation) continue;
    if (annotation.kind === "text") {
      const width = Math.max(14, annotation.stroke * 6) * Math.max(1, annotation.text.length * 0.6);
      const height = Math.max(14, annotation.stroke * 6);
      if (point.x >= annotation.point.x - tolerance && point.x <= annotation.point.x + width + tolerance && point.y >= annotation.point.y - tolerance && point.y <= annotation.point.y + height + tolerance) return annotation.id;
      continue;
    }
    if (annotation.kind === "draw") {
      for (let pointIndex = 1; pointIndex < annotation.points.length; pointIndex += 1) {
        if (distanceToSegment(point, annotation.points[pointIndex - 1]!, annotation.points[pointIndex]!) <= tolerance + annotation.stroke / 2) return annotation.id;
      }
      continue;
    }
    if (annotation.kind === "arrow") {
      if (distanceToSegment(point, annotation.start, annotation.end) <= tolerance + annotation.stroke / 2) return annotation.id;
      continue;
    }
    const left = Math.min(annotation.start.x, annotation.end.x) - tolerance;
    const right = Math.max(annotation.start.x, annotation.end.x) + tolerance;
    const top = Math.min(annotation.start.y, annotation.end.y) - tolerance;
    const bottom = Math.max(annotation.start.y, annotation.end.y) + tolerance;
    if (point.x >= left && point.x <= right && point.y >= top && point.y <= bottom) return annotation.id;
  }
  return null;
}

function drawArrow(context: CanvasRenderingContext2D, start: Point, end: Point, stroke: number) {
  const angle = Math.atan2(end.y - start.y, end.x - start.x);
  const head = Math.max(12, stroke * 4);
  context.moveTo(start.x, start.y);
  context.lineTo(end.x, end.y);
  context.moveTo(end.x, end.y);
  context.lineTo(end.x - head * Math.cos(angle - Math.PI / 6), end.y - head * Math.sin(angle - Math.PI / 6));
  context.moveTo(end.x, end.y);
  context.lineTo(end.x - head * Math.cos(angle + Math.PI / 6), end.y - head * Math.sin(angle + Math.PI / 6));
}

function drawPixelate(context: CanvasRenderingContext2D, annotation: Extract<Annotation, { kind: "pixelate" }>) {
  const left = Math.max(0, Math.floor(Math.min(annotation.start.x, annotation.end.x)));
  const top = Math.max(0, Math.floor(Math.min(annotation.start.y, annotation.end.y)));
  const width = Math.min(
    Math.ceil(Math.abs(annotation.end.x - annotation.start.x)),
    Math.max(0, context.canvas.width - left),
  );
  const height = Math.min(
    Math.ceil(Math.abs(annotation.end.y - annotation.start.y)),
    Math.max(0, context.canvas.height - top),
  );
  if (width <= 0 || height <= 0) return;

  try {
    const imageData = context.getImageData(left, top, width, height);
    const blockSize = Math.max(4, Math.round(annotation.stroke * 3));
    for (let blockY = 0; blockY < height; blockY += blockSize) {
      for (let blockX = 0; blockX < width; blockX += blockSize) {
        const blockWidth = Math.min(blockSize, width - blockX);
        const blockHeight = Math.min(blockSize, height - blockY);
        const sampleX = blockX + Math.floor((blockWidth - 1) / 2);
        const sampleY = blockY + Math.floor((blockHeight - 1) / 2);
        const sampleIndex = (sampleY * width + sampleX) * 4;
        for (let y = blockY; y < blockY + blockHeight; y += 1) {
          for (let x = blockX; x < blockX + blockWidth; x += 1) {
            const destinationIndex = (y * width + x) * 4;
            imageData.data[destinationIndex] = imageData.data[sampleIndex]!;
            imageData.data[destinationIndex + 1] = imageData.data[sampleIndex + 1]!;
            imageData.data[destinationIndex + 2] = imageData.data[sampleIndex + 2]!;
            imageData.data[destinationIndex + 3] = imageData.data[sampleIndex + 3]!;
          }
        }
      }
    }
    context.putImageData(imageData, left, top);
  } catch {
    // If pixel reads are blocked, fail closed so private content is not
    // accidentally exported unredacted.
    context.fillStyle = "#000000";
    context.fillRect(left, top, width, height);
  }
}

function drawBlur(context: CanvasRenderingContext2D, annotation: Extract<Annotation, { kind: "blur" }>) {
  const left = Math.max(0, Math.floor(Math.min(annotation.start.x, annotation.end.x)));
  const top = Math.max(0, Math.floor(Math.min(annotation.start.y, annotation.end.y)));
  const width = Math.min(
    Math.ceil(Math.abs(annotation.end.x - annotation.start.x)),
    Math.max(0, context.canvas.width - left),
  );
  const height = Math.min(
    Math.ceil(Math.abs(annotation.end.y - annotation.start.y)),
    Math.max(0, context.canvas.height - top),
  );
  if (width <= 0 || height <= 0) return;

  try {
    const imageData = context.getImageData(left, top, width, height);
    const source = new Uint8ClampedArray(imageData.data);
    const horizontal = new Uint8ClampedArray(source.length);
    const radius = Math.max(2, Math.round(annotation.stroke * 2));
    const windowSize = radius * 2 + 1;
    const clamped = (value: number, limit: number) => Math.max(0, Math.min(limit - 1, value));

    for (let y = 0; y < height; y += 1) {
      const sums = [0, 0, 0, 0];
      for (let offset = -radius; offset <= radius; offset += 1) {
        const sourceIndex = (y * width + clamped(offset, width)) * 4;
        for (let channel = 0; channel < 4; channel += 1) sums[channel] += source[sourceIndex + channel]!;
      }
      for (let x = 0; x < width; x += 1) {
        const destinationIndex = (y * width + x) * 4;
        for (let channel = 0; channel < 4; channel += 1) horizontal[destinationIndex + channel] = Math.round(sums[channel]! / windowSize);
        const outgoingIndex = (y * width + clamped(x - radius, width)) * 4;
        const incomingIndex = (y * width + clamped(x + radius + 1, width)) * 4;
        for (let channel = 0; channel < 4; channel += 1) sums[channel] += source[incomingIndex + channel]! - source[outgoingIndex + channel]!;
      }
    }

    for (let x = 0; x < width; x += 1) {
      const sums = [0, 0, 0, 0];
      for (let offset = -radius; offset <= radius; offset += 1) {
        const sourceIndex = (clamped(offset, height) * width + x) * 4;
        for (let channel = 0; channel < 4; channel += 1) sums[channel] += horizontal[sourceIndex + channel]!;
      }
      for (let y = 0; y < height; y += 1) {
        const destinationIndex = (y * width + x) * 4;
        for (let channel = 0; channel < 4; channel += 1) imageData.data[destinationIndex + channel] = Math.round(sums[channel]! / windowSize);
        const outgoingIndex = (clamped(y - radius, height) * width + x) * 4;
        const incomingIndex = (clamped(y + radius + 1, height) * width + x) * 4;
        for (let channel = 0; channel < 4; channel += 1) sums[channel] += horizontal[incomingIndex + channel]! - horizontal[outgoingIndex + channel]!;
      }
    }
    context.putImageData(imageData, left, top);
  } catch {
    // If pixel reads are blocked, fail closed so private content is not
    // accidentally exported unblurred.
    context.fillStyle = "#000000";
    context.fillRect(left, top, width, height);
  }
}

export function renderAnnotation(context: CanvasRenderingContext2D, annotation: Annotation) {
  context.save();
  context.strokeStyle = annotation.color;
  context.fillStyle = annotation.color;
  context.lineWidth = annotation.stroke;
  context.lineCap = "round";
  context.lineJoin = "round";
  context.beginPath();

  switch (annotation.kind) {
    case "rectangle": {
      const { start, end } = annotation;
      context.strokeRect(start.x, start.y, end.x - start.x, end.y - start.y);
      break;
    }
    case "redact": {
      const left = Math.min(annotation.start.x, annotation.end.x);
      const top = Math.min(annotation.start.y, annotation.end.y);
      const width = Math.abs(annotation.end.x - annotation.start.x);
      const height = Math.abs(annotation.end.y - annotation.start.y);
      context.fillStyle = "#000000";
      context.fillRect(left, top, width, height);
      break;
    }
    case "pixelate": {
      drawPixelate(context, annotation);
      context.strokeStyle = annotation.color;
      context.strokeRect(
        Math.min(annotation.start.x, annotation.end.x),
        Math.min(annotation.start.y, annotation.end.y),
        Math.abs(annotation.end.x - annotation.start.x),
        Math.abs(annotation.end.y - annotation.start.y),
      );
      break;
    }
    case "blur": {
      drawBlur(context, annotation);
      context.strokeStyle = annotation.color;
      context.strokeRect(
        Math.min(annotation.start.x, annotation.end.x),
        Math.min(annotation.start.y, annotation.end.y),
        Math.abs(annotation.end.x - annotation.start.x),
        Math.abs(annotation.end.y - annotation.start.y),
      );
      break;
    }
    case "arrow":
      drawArrow(context, annotation.start, annotation.end, annotation.stroke);
      context.stroke();
      break;
    case "draw":
      annotation.points.forEach((point, index) => {
        if (index === 0) context.moveTo(point.x, point.y);
        else context.lineTo(point.x, point.y);
      });
      context.stroke();
      break;
    case "text":
      context.font = `${Math.max(14, annotation.stroke * 6)}px -apple-system, BlinkMacSystemFont, sans-serif`;
      context.textBaseline = "top";
      context.fillText(annotation.text, annotation.point.x, annotation.point.y);
      break;
  }
  context.restore();
}

export function svgPath(points: Point[]): string {
  return points.map((point, index) => `${index === 0 ? "M" : "L"}${point.x} ${point.y}`).join(" ");
}

export function arrowHeadPoints(start: Point, end: Point, stroke: number): string {
  const angle = Math.atan2(end.y - start.y, end.x - start.x);
  const head = Math.max(12, stroke * 4);
  const left = {
    x: end.x - head * Math.cos(angle - Math.PI / 6),
    y: end.y - head * Math.sin(angle - Math.PI / 6),
  };
  const right = {
    x: end.x - head * Math.cos(angle + Math.PI / 6),
    y: end.y - head * Math.sin(angle + Math.PI / 6),
  };
  return `${left.x},${left.y} ${end.x},${end.y} ${right.x},${right.y}`;
}
