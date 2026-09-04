const imageExtensions = new Set(["png", "jpg", "jpeg", "tif", "tiff"]);

/** Return true only for paths the native image importer can decode. */
export function isSupportedImagePath(path: unknown): path is string {
  if (typeof path !== "string") return false;
  const fileName = path.trim().split(/[\\/]/).pop() ?? "";
  const extension = fileName.includes(".") ? fileName.slice(fileName.lastIndexOf(".") + 1).toLowerCase() : "";
  return Boolean(fileName) && imageExtensions.has(extension);
}

/** Select the first supported image from a Tauri file-drop payload. */
export function firstSupportedImagePath(paths: unknown): string | null {
  if (!Array.isArray(paths)) return null;
  return paths.find(isSupportedImagePath) ?? null;
}
