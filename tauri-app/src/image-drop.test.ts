import { describe, expect, it } from "vitest";
import { firstSupportedImagePath, isSupportedImagePath } from "./image-drop";

describe("image file drops", () => {
  it.each(["/tmp/Capture.png", "/tmp/photo.JPG", "C:\\Users\\me\\scan.tiff"])("accepts %s", (path) => {
    expect(isSupportedImagePath(path)).toBe(true);
  });

  it.each(["/tmp/Capture.pdf", "/tmp/no-extension", "", null, 42])("rejects %s", (path) => {
    expect(isSupportedImagePath(path)).toBe(false);
  });

  it("selects the first supported image and ignores unrelated files", () => {
    expect(firstSupportedImagePath(["/tmp/notes.txt", "/tmp/Capture.PNG", "/tmp/other.jpg"])).toBe("/tmp/Capture.PNG");
  });

  it("fails closed for malformed or empty payloads", () => {
    expect(firstSupportedImagePath(undefined)).toBeNull();
    expect(firstSupportedImagePath({ paths: ["/tmp/Capture.png"] })).toBeNull();
    expect(firstSupportedImagePath([])).toBeNull();
  });
});
