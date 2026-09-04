import { describe, expect, it, vi } from "vitest";
import { findAnnotationAtPoint, renderAnnotation, resizeAnnotation, type Annotation } from "./annotations";

const rectangle: Annotation = { id: "rectangle", kind: "rectangle", color: "#ff4d5a", stroke: 4, start: { x: 20, y: 20 }, end: { x: 120, y: 100 } };
const arrow: Annotation = { id: "arrow", kind: "arrow", color: "#ff4d5a", stroke: 4, start: { x: 200, y: 200 }, end: { x: 320, y: 260 } };
const text: Annotation = { id: "text", kind: "text", color: "#ff4d5a", stroke: 4, point: { x: 400, y: 300 }, text: "Note" };
const redact: Annotation = { id: "redact", kind: "redact", color: "#ff4d5a", stroke: 4, start: { x: 90, y: 80 }, end: { x: 30, y: 20 } };
const pixelate: Annotation = { id: "pixelate", kind: "pixelate", color: "#ff4d5a", stroke: 4, start: { x: 90, y: 80 }, end: { x: 30, y: 20 } };
const blur: Annotation = { id: "blur", kind: "blur", color: "#ff4d5a", stroke: 4, start: { x: 90, y: 80 }, end: { x: 30, y: 20 } };

describe("findAnnotationAtPoint", () => {
  it("selects a rectangle by its interior", () => {
    expect(findAnnotationAtPoint([rectangle], { x: 70, y: 60 })).toBe("rectangle");
  });

  it("selects an arrow by its line and prefers the topmost annotation", () => {
    expect(findAnnotationAtPoint([arrow], { x: 260, y: 230 })).toBe("arrow");
    expect(findAnnotationAtPoint([rectangle, rectangle], { x: 70, y: 60 })).toBe("rectangle");
  });

  it("selects text near its rendered bounds and ignores distant points", () => {
    expect(findAnnotationAtPoint([text], { x: 405, y: 305 })).toBe("text");
    expect(findAnnotationAtPoint([text], { x: 700, y: 500 })).toBeNull();
  });

  it("resizes a rectangle from a corner while keeping the opposite corner fixed", () => {
    const resized = resizeAnnotation(rectangle, "se", { x: 180, y: 140 });
    expect(resized).toMatchObject({ start: { x: 20, y: 20 }, end: { x: 180, y: 140 } });
  });

  it("resizes an arrow by moving only the selected endpoint", () => {
    const resized = resizeAnnotation(arrow, "end", { x: 360, y: 300 });
    expect(resized).toMatchObject({ start: arrow.start, end: { x: 360, y: 300 } });
  });

  it("selects and resizes a redact region like a rectangle", () => {
    expect(findAnnotationAtPoint([redact], { x: 60, y: 50 })).toBe("redact");
    expect(resizeAnnotation(redact, "nw", { x: 10, y: 5 })).toMatchObject({ start: { x: 10, y: 5 }, end: { x: 90, y: 80 } });
  });

  it("selects and resizes a pixelate region like a rectangle", () => {
    expect(findAnnotationAtPoint([pixelate], { x: 60, y: 50 })).toBe("pixelate");
    expect(resizeAnnotation(pixelate, "nw", { x: 10, y: 5 })).toMatchObject({ start: { x: 10, y: 5 }, end: { x: 90, y: 80 } });
  });

  it("selects and resizes a blur region like a rectangle", () => {
    expect(findAnnotationAtPoint([blur], { x: 60, y: 50 })).toBe("blur");
    expect(resizeAnnotation(blur, "nw", { x: 10, y: 5 })).toMatchObject({ start: { x: 10, y: 5 }, end: { x: 90, y: 80 } });
  });

  it("renders redact as an opaque black fill", () => {
    const context = {
      beginPath: () => {},
      fillRect: (..._args: number[]) => {},
      restore: () => {},
      save: () => {},
    } as unknown as CanvasRenderingContext2D;
    const fillRect = vi.spyOn(context, "fillRect");
    renderAnnotation(context, redact);
    expect(fillRect).toHaveBeenCalledWith(30, 20, 60, 60);
    expect(context.fillStyle).toBe("#000000");
  });

  it("renders pixelate by replacing each block with one source color", () => {
    const source = new Uint8ClampedArray(16 * 16 * 4);
    for (let index = 0; index < source.length; index += 4) {
      source[index] = (index / 4) % 256;
      source[index + 1] = Math.floor(index / 64);
      source[index + 2] = 128;
      source[index + 3] = 255;
    }
    const original = source.slice();
    const imageData = { data: source, width: 16, height: 16 };
    const context = {
      beginPath: () => {},
      getImageData: () => imageData,
      putImageData: vi.fn(),
      restore: () => {},
      save: () => {},
      strokeRect: vi.fn(),
      canvas: { width: 16, height: 16 },
    } as unknown as CanvasRenderingContext2D;
    renderAnnotation(context, { ...pixelate, start: { x: 0, y: 0 }, end: { x: 16, y: 16 } });
    expect(context.putImageData).toHaveBeenCalledWith(imageData, 0, 0);
    expect(imageData.data.slice(0, 4)).not.toEqual(original.slice(0, 4));
    expect(imageData.data.slice(0, 4)).toEqual(imageData.data.slice((16 + 1) * 4, (16 + 1) * 4 + 4));
    expect(imageData.data[3]).toBe(255);
  });

  it("renders blur by averaging a sharp source boundary", () => {
    const source = new Uint8ClampedArray(16 * 16 * 4);
    for (let y = 0; y < 16; y += 1) {
      for (let x = 0; x < 16; x += 1) {
        const index = (y * 16 + x) * 4;
        source[index] = x < 8 ? 0 : 255;
        source[index + 3] = 255;
      }
    }
    const imageData = { data: source, width: 16, height: 16 };
    const context = {
      beginPath: () => {},
      getImageData: () => imageData,
      putImageData: vi.fn(),
      restore: () => {},
      save: () => {},
      strokeRect: vi.fn(),
      canvas: { width: 16, height: 16 },
    } as unknown as CanvasRenderingContext2D;

    renderAnnotation(context, { ...blur, start: { x: 0, y: 0 }, end: { x: 16, y: 16 } });

    const boundaryRed = imageData.data[(8 * 4)]!;
    expect(context.putImageData).toHaveBeenCalledWith(imageData, 0, 0);
    expect(boundaryRed).toBeGreaterThan(0);
    expect(boundaryRed).toBeLessThan(255);
    expect(imageData.data[3]).toBe(255);
  });

  it("fails closed to an opaque block when pixel reads are unavailable", () => {
    const fillRect = vi.fn();
    const context = {
      beginPath: () => {},
      canvas: { width: 100, height: 100 },
      fillRect,
      getImageData: () => { throw new Error("SecurityError"); },
      restore: () => {},
      save: () => {},
      strokeRect: vi.fn(),
    } as unknown as CanvasRenderingContext2D;

    renderAnnotation(context, pixelate);

    expect(fillRect).toHaveBeenCalledWith(30, 20, 60, 60);
    expect(context.fillStyle).toBe("#000000");
  });

  it("fails closed to an opaque block when blur pixel reads are unavailable", () => {
    const fillRect = vi.fn();
    const context = {
      beginPath: () => {},
      canvas: { width: 100, height: 100 },
      fillRect,
      getImageData: () => { throw new Error("SecurityError"); },
      restore: () => {},
      save: () => {},
      strokeRect: vi.fn(),
    } as unknown as CanvasRenderingContext2D;

    renderAnnotation(context, blur);

    expect(fillRect).toHaveBeenCalledWith(30, 20, 60, 60);
    expect(context.fillStyle).toBe("#000000");
  });
});
