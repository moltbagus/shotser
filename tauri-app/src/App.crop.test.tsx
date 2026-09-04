// @vitest-environment jsdom

import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const invokeMock = vi.hoisted(() => vi.fn());
const listenMock = vi.hoisted(() => vi.fn(async (..._args: unknown[]) => () => {}));
const openMock = vi.hoisted(() => vi.fn());
const saveMock = vi.hoisted(() => vi.fn());
const focusChangedCallback = vi.hoisted(() => ({ current: undefined as ((event: { payload: boolean }) => void) | undefined }));
const fileDropCallback = vi.hoisted(() => ({ current: undefined as ((event: { payload: { paths?: unknown } }) => void) | undefined }));
const currentWindowMock = vi.hoisted(() => ({
  setAlwaysOnTop: vi.fn(async () => {}),
  onFocusChanged: vi.fn(async (callback: (event: { payload: boolean }) => void) => {
    focusChangedCallback.current = callback;
    return () => {};
  }),
}));
const menuNewMock = vi.hoisted(() => vi.fn(async () => ({ setAsAppMenu: vi.fn(async () => {}), close: vi.fn(async () => {}) })));
const createdSubmenuOptions = vi.hoisted(() => ({ current: [] as Array<{ id?: string; items?: Array<{ id?: string; action?: () => void }> }> }));
const submenuNewMock = vi.hoisted(() => vi.fn(async (options: { id?: string; items?: Array<{ id?: string; action?: () => void }> } = {}) => {
  createdSubmenuOptions.current.push(options);
  return {};
}));
const predefinedMenuItemNewMock = vi.hoisted(() => vi.fn(async () => ({})));

vi.mock("@tauri-apps/api/core", () => ({ invoke: invokeMock }));
vi.mock("@tauri-apps/api/event", () => ({ listen: listenMock }));
vi.mock("@tauri-apps/api/menu", () => ({
  Menu: { new: menuNewMock },
  PredefinedMenuItem: { new: predefinedMenuItemNewMock },
  Submenu: { new: submenuNewMock },
}));
vi.mock("@tauri-apps/api/window", () => ({ getCurrentWindow: () => currentWindowMock }));
vi.mock("@tauri-apps/plugin-dialog", () => ({ open: openMock, save: saveMock }));

import App from "./App";

const originalCapture = "data:image/png;base64,original";
const staleCropCapture = "data:image/png;base64,stale-crop";
let captureAreaResult: Promise<{ message: string; data_url: string | null; width: number | null; height: number | null }> | undefined;
let runtimeContractEnabled = false;
let screenCapturePermissionMessage = "Screen capture permission available.";
let screenCapturePermissionResult: Promise<{ message: string }> | undefined;
const pendingImages: Array<{ onload: (() => void) | null; onerror: (() => void) | null; src: string }> = [];
const originalImageConstructor = globalThis.Image;
const originalCreateElement = document.createElement.bind(document);
const createdContexts: Array<{ strokeRect: ReturnType<typeof vi.fn>; fillRect: ReturnType<typeof vi.fn> }> = [];

class DeferredImage {
  onload: (() => void) | null = null;
  onerror: (() => void) | null = null;
  private currentSrc = "";

  get src() {
    return this.currentSrc;
  }

  set src(value: string) {
    this.currentSrc = value;
    pendingImages.push(this);
  }
}

function createCanvas() {
  const canvas = {
    width: 0,
    height: 0,
    getContext: vi.fn(),
    toDataURL: vi.fn(() => staleCropCapture),
  };
  const context = {
    beginPath: vi.fn(),
    canvas,
    drawImage: vi.fn(),
    fillRect: vi.fn(),
    fillText: vi.fn(),
    getImageData: vi.fn((_: number, __: number, width: number, height: number) => ({ data: new Uint8ClampedArray(width * height * 4), width, height })),
    putImageData: vi.fn(),
    restore: vi.fn(),
    save: vi.fn(),
    stroke: vi.fn(),
    strokeRect: vi.fn(),
  };
  canvas.getContext.mockReturnValue(context);
  createdContexts.push(context);
  return canvas;
}

function configureInvokeMock() {
  invokeMock.mockImplementation(async (command: string) => {
    switch (command) {
      case "runtime_contract_enabled":
        return runtimeContractEnabled;
      case "capture_frontend_ready":
        return { message: "Ready" };
      case "screen_capture_permission_status":
        return screenCapturePermissionResult ?? { message: screenCapturePermissionMessage };
      case "set_capture_shortcut":
        return { message: "Capture shortcut set to CommandOrControl+Shift+Y." };
      case "import_clipboard_image":
        return { message: "Clipboard image imported.", data_url: originalCapture, width: 100, height: 100 };
      case "open_image":
        return { message: "Opened image.", data_url: originalCapture, width: 100, height: 100 };
      case "capture_area":
      case "capture_window":
      case "capture_fullscreen":
      case "repeat_last_capture":
        return captureAreaResult ?? { message: "Capture cancelled.", data_url: null, width: null, height: null };
      case "store_rendered_capture":
        return { message: "Rendered capture stored." };
      case "copy_capture":
        return { message: "Copied capture." };
      case "save_capture":
        return { message: "Saved capture." };
      case "drag_out_capture":
        return { message: "Drag started." };
      default:
        return { message: "OK" };
    }
  });
}

function stubPointerAndCanvas() {
  Object.defineProperty(Element.prototype, "setPointerCapture", { configurable: true, value: vi.fn() });
  Object.defineProperty(Element.prototype, "hasPointerCapture", { configurable: true, value: vi.fn(() => true) });
  Object.defineProperty(Element.prototype, "releasePointerCapture", { configurable: true, value: vi.fn() });
  Object.defineProperty(SVGElement.prototype, "getBoundingClientRect", {
    configurable: true,
    value: () => ({ left: 0, top: 0, width: 100, height: 100, right: 100, bottom: 100, x: 0, y: 0, toJSON: () => ({}) }),
  });
  vi.spyOn(document, "createElement").mockImplementation(((localName: string, options?: ElementCreationOptions) => {
    if (localName.toLowerCase() === "canvas") return createCanvas() as unknown as HTMLElement;
    return originalCreateElement(localName, options);
  }) as typeof document.createElement);
}

async function renderWithCapture() {
  const rendered = render(<App />);
  fireEvent.click(screen.getByRole("button", { name: "Import clipboard image" }));
  await waitFor(() => expect(screen.getByRole("img", { name: "Latest area capture" })).toBeTruthy());
  return rendered;
}

async function beginDeferredCrop() {
  const rendered = await renderWithCapture();
  fireEvent.click(screen.getByRole("button", { name: "Crop" }));
  const svg = rendered.container.querySelector("svg.annotation-layer");
  expect(svg).toBeTruthy();
  fireEvent.pointerDown(svg!, { clientX: 10, clientY: 10, pointerId: 1 });
  fireEvent.pointerMove(svg!, { clientX: 80, clientY: 80, pointerId: 1 });
  fireEvent.pointerUp(svg!, { clientX: 80, clientY: 80, pointerId: 1 });
  await waitFor(() => expect(pendingImages).toHaveLength(1));
  return rendered;
}

async function addRectangleAnnotation() {
  const rendered = await renderWithCapture();
  fireEvent.click(screen.getByRole("button", { name: "Rectangle" }));
  const svg = rendered.container.querySelector("svg.annotation-layer");
  expect(svg).toBeTruthy();
  fireEvent.pointerDown(svg!, { clientX: 10, clientY: 10, pointerId: 4 });
  fireEvent.pointerUp(svg!, { clientX: 80, clientY: 80, pointerId: 4 });
  await waitFor(() => expect(screen.getByTestId("status").textContent).toContain("Rectangle annotation added"));
  return rendered;
}

async function addRedactAnnotation() {
  const rendered = await renderWithCapture();
  fireEvent.click(screen.getByRole("button", { name: "Redact" }));
  const svg = rendered.container.querySelector("svg.annotation-layer");
  expect(svg).toBeTruthy();
  fireEvent.pointerDown(svg!, { clientX: 10, clientY: 10, pointerId: 7 });
  fireEvent.pointerUp(svg!, { clientX: 80, clientY: 80, pointerId: 7 });
  await waitFor(() => expect(screen.getByTestId("status").textContent).toContain("Redact annotation added"));
  return rendered;
}

async function addPixelateAnnotation() {
  const rendered = await renderWithCapture();
  fireEvent.click(screen.getByRole("button", { name: "Pixelate" }));
  const svg = rendered.container.querySelector("svg.annotation-layer");
  expect(svg).toBeTruthy();
  fireEvent.pointerDown(svg!, { clientX: 10, clientY: 10, pointerId: 8 });
  fireEvent.pointerUp(svg!, { clientX: 80, clientY: 80, pointerId: 8 });
  await waitFor(() => expect(screen.getByTestId("status").textContent).toContain("Pixelate annotation added"));
  return rendered;
}

async function addBlurAnnotation() {
  const rendered = await renderWithCapture();
  fireEvent.click(screen.getByRole("button", { name: "Blur" }));
  const svg = rendered.container.querySelector("svg.annotation-layer");
  expect(svg).toBeTruthy();
  fireEvent.pointerDown(svg!, { clientX: 12, clientY: 12, pointerId: 9 });
  fireEvent.pointerUp(svg!, { clientX: 78, clientY: 78, pointerId: 9 });
  await waitFor(() => expect(screen.getByTestId("status").textContent).toContain("Blur annotation added"));
  return rendered;
}

async function waitForNativeExport(command: string) {
  await waitFor(() => {
    pendingImages.filter((image) => image.onload).forEach((image) => {
      const onload = image.onload;
      image.onload = null;
      onload?.();
    });
    expect(invokeMock.mock.calls.some(([name]) => name === command)).toBe(true);
  });
}

beforeEach(() => {
  pendingImages.length = 0;
  createdContexts.length = 0;
  captureAreaResult = undefined;
  runtimeContractEnabled = false;
  screenCapturePermissionMessage = "Screen capture permission available.";
  screenCapturePermissionResult = undefined;
  focusChangedCallback.current = undefined;
  fileDropCallback.current = undefined;
  createdSubmenuOptions.current.length = 0;
  window.localStorage.clear();
  invokeMock.mockReset();
  listenMock.mockReset();
  listenMock.mockImplementation(async (eventName: unknown, callback: unknown) => {
    if (eventName === "tauri://drag-drop") {
      fileDropCallback.current = callback as (event: { payload: { paths?: unknown } }) => void;
    }
    return () => {};
  });
  openMock.mockReset();
  saveMock.mockReset();
  currentWindowMock.setAlwaysOnTop.mockClear();
  currentWindowMock.onFocusChanged.mockClear();
  configureInvokeMock();
  Object.defineProperty(globalThis, "Image", { configurable: true, writable: true, value: DeferredImage });
  stubPointerAndCanvas();
});

afterEach(() => {
  cleanup();
  document.createElement = originalCreateElement;
  Object.defineProperty(globalThis, "Image", { configurable: true, writable: true, value: originalImageConstructor });
});

describe("App crop lifecycle", () => {
  it("keeps Reset state when deferred crop work resolves afterward", async () => {
    await beginDeferredCrop();

    fireEvent.click(screen.getByRole("button", { name: "Reset image and edits" }));
    expect(screen.getByTestId("status").textContent).toContain("Restored the original image");

    pendingImages[0]!.onload!();
    await waitFor(() => expect(screen.getByRole("img", { name: "Latest area capture" }).getAttribute("src")).toBe(originalCapture));
    expect(screen.getByTestId("status").textContent).toContain("Restored the original image");
    expect(invokeMock).not.toHaveBeenCalledWith("store_rendered_capture", expect.anything());
  });

  it("keeps a newer annotation when deferred crop work resolves afterward", async () => {
    await beginDeferredCrop();

    const svg = document.querySelector("svg.annotation-layer");
    fireEvent.click(screen.getByRole("button", { name: "Text" }));
    fireEvent.pointerDown(svg!, { clientX: 20, clientY: 20, pointerId: 2 });
    fireEvent.pointerUp(svg!, { clientX: 20, clientY: 20, pointerId: 2 });
    expect(screen.getByTestId("status").textContent).toContain("Text annotation added");
    expect(screen.getByTestId("status").textContent).toContain("1 annotation");

    pendingImages[0]!.onload!();
    await waitFor(() => expect(screen.getByRole("img", { name: "Latest area capture" }).getAttribute("src")).toBe(originalCapture));
    expect(screen.getByTestId("status").textContent).toContain("Text annotation added");
    expect(screen.getByTestId("status").textContent).toContain("1 annotation");
  });
});

describe("App capture lifecycle", () => {
  it("imports the first supported image dropped from Finder", async () => {
    render(<App />);

    await waitFor(() => expect(fileDropCallback.current).toBeTypeOf("function"));
    fileDropCallback.current!({ payload: { paths: ["/tmp/notes.txt", "/tmp/Capture.PNG"] } });

    await waitFor(() => expect(invokeMock).toHaveBeenCalledWith("open_image", { path: "/tmp/Capture.PNG" }));
    await waitFor(() => expect(screen.getByRole("img", { name: "Latest area capture" }).getAttribute("src")).toBe(originalCapture));
    expect(screen.getByTestId("status").textContent).toContain("Opened image.");
  });

  it("shows the selecting state and commits a valid native capture preview", async () => {
    let resolveCapture!: (result: { message: string; data_url: string; width: number; height: number }) => void;
    captureAreaResult = new Promise((resolve) => { resolveCapture = resolve; });
    render(<App />);

    const captureButton = screen.getByRole("button", { name: "Capture area" }) as HTMLButtonElement;
    fireEvent.click(captureButton);
    await waitFor(() => expect(captureButton.disabled).toBe(true));
    expect(screen.getByTestId("status").textContent).toContain("Hiding ShotEye");

    resolveCapture({ message: "Area captured.", data_url: originalCapture, width: 100, height: 100 });
    await waitFor(() => expect(screen.getByRole("img", { name: "Latest area capture" }).getAttribute("src")).toBe(originalCapture));
    expect(captureButton.disabled).toBe(false);
    expect(screen.getByTestId("status").textContent).toContain("Area captured.");
  });

  it("does not start a second native capture while the first request is pending", async () => {
    let resolveCapture!: (result: { message: string; data_url: string; width: number; height: number }) => void;
    captureAreaResult = new Promise((resolve) => { resolveCapture = resolve; });
    render(<App />);

    const captureButton = screen.getByRole("button", { name: "Capture area" }) as HTMLButtonElement;
    fireEvent.click(captureButton);
    await waitFor(() => expect(captureButton.disabled).toBe(true));
    await waitFor(() => expect(listenMock).toHaveBeenCalledWith("capture-requested", expect.any(Function)));
    const captureRequested = listenMock.mock.calls.find(([eventName]) => eventName === "capture-requested")?.[1] as (() => void) | undefined;
    expect(captureRequested).toBeTypeOf("function");
    captureRequested!();

    expect(invokeMock.mock.calls.filter(([command]) => command === "capture_area")).toHaveLength(1);
    await waitFor(() => expect(screen.getByTestId("status").textContent).toContain("Finish the current ShotEye operation"));
    resolveCapture({ message: "Area captured.", data_url: originalCapture, width: 100, height: 100 });
    await waitFor(() => expect(captureButton.disabled).toBe(false));
  });

  it("restores an actionable editor state after native capture cancellation", async () => {
    captureAreaResult = Promise.reject(new Error("Selection cancelled."));
    render(<App />);

    const captureButton = screen.getByRole("button", { name: "Capture area" }) as HTMLButtonElement;
    fireEvent.click(captureButton);
    await waitFor(() => expect(screen.getByTestId("status").textContent).toContain("Capture error"));
    expect(captureButton.disabled).toBe(false);
  });

  it("restores an actionable editor state after a native cancellation result", async () => {
    captureAreaResult = Promise.resolve({ message: "Capture cancelled.", data_url: null, width: null, height: null });
    render(<App />);

    const captureButton = screen.getByRole("button", { name: "Capture area" }) as HTMLButtonElement;
    fireEvent.click(captureButton);
    await waitFor(() => expect(screen.getByTestId("status").textContent).toContain("Capture cancelled."));
    expect(captureButton.disabled).toBe(false);
  });

  it.each([
    ["Capture a window", "capture_window", "Window captured."],
    ["Capture full screen", "capture_fullscreen", "Full screen captured."],
    ["Repeat last capture", "repeat_last_capture", "Repeated capture."],
  ])("dispatches the %s action through the shared capture lifecycle", async (buttonName, command, message) => {
    captureAreaResult = Promise.resolve({ message, data_url: originalCapture, width: 100, height: 100 });
    render(<App />);

    const captureButton = screen.getByRole("button", { name: buttonName }) as HTMLButtonElement;
    fireEvent.click(captureButton);
    await waitFor(() => expect(invokeMock).toHaveBeenCalledWith(command));
    await waitFor(() => expect(screen.getByRole("img", { name: "Latest area capture" }).getAttribute("src")).toBe(originalCapture));
    expect(captureButton.disabled).toBe(false);
    expect(screen.getByTestId("status").textContent).toContain(message);
  });

  it("dispatches Command-Shift-R through the repeat capture action", async () => {
    captureAreaResult = Promise.resolve({ message: "Repeated capture.", data_url: originalCapture, width: 100, height: 100 });
    render(<App />);

    fireEvent.keyDown(window, { key: "r", metaKey: true, shiftKey: true });

    await waitFor(() => expect(invokeMock).toHaveBeenCalledWith("repeat_last_capture"));
    await waitFor(() => expect(screen.getByRole("img", { name: "Latest area capture" }).getAttribute("src")).toBe(originalCapture));
    expect(screen.getByTestId("status").textContent).toContain("Repeated capture.");
  });

  it("advertises the repeat shortcut on the toolbar control", () => {
    render(<App />);

    const repeatButton = screen.getByRole("button", { name: "Repeat last capture" });
    expect(repeatButton.getAttribute("aria-keyshortcuts")).toBe("Meta+Shift+R");
    expect(repeatButton.getAttribute("title")).toContain("⌘⇧R");
    expect(repeatButton.querySelector("kbd")?.textContent).toBe("⌘⇧R");
  });

  it("advertises primary editor shortcuts on the toolbar controls", () => {
    render(<App />);

    const controls = [
      ["Open image", "Meta+O", "⌘O"],
      ["Import clipboard image", "Meta+V", "⌘V"],
      ["Copy capture", "Meta+C", "⌘C"],
      ["Save capture", "Meta+S", "⌘S"],
      ["Undo", "Meta+Z", "⌘Z"],
      ["Redo", "Meta+Shift+Z", "⌘⇧Z"],
    ] as const;

    for (const [name, ariaShortcut, display] of controls) {
      const button = screen.getByRole("button", { name });
      expect(button.getAttribute("aria-keyshortcuts")).toBe(ariaShortcut);
      expect(button.getAttribute("title")).toContain(display);
      expect(button.querySelector("kbd")?.textContent).toBe(display);
    }
  });

  it("keeps the active shortcut during a conflict and gates capture while registering", async () => {
    render(<App />);
    await waitFor(() => expect(invokeMock).toHaveBeenCalledWith("set_capture_shortcut", { shortcut: "CommandOrControl+Shift+Y" }));

    let resolveRegistration!: (result: { message: string }) => void;
    invokeMock.mockImplementation(async (command: string) => {
      if (command === "set_capture_shortcut") return new Promise((resolve) => { resolveRegistration = resolve; });
      return { message: "OK" };
    });

    const shortcutButton = screen.getByRole("button", { name: "Record capture shortcut" }) as HTMLButtonElement;
    fireEvent.click(shortcutButton);
    fireEvent.keyDown(shortcutButton, { key: "K", code: "KeyK", metaKey: true, shiftKey: true });

    await waitFor(() => expect(screen.getByTestId("shortcut-status").textContent).toContain("Registering"));
    expect((screen.getByRole("button", { name: "Capture area" }) as HTMLButtonElement).disabled).toBe(true);

    await waitFor(() => expect(createdSubmenuOptions.current.some(({ id }) => id === "capture")).toBe(true));
    const captureMenu = createdSubmenuOptions.current.find(({ id }) => id === "capture");
    captureMenu?.items?.find(({ id }) => id === "capture-area")?.action?.();
    await waitFor(() => expect(screen.getByTestId("status").textContent).toContain("Finish the current ShotEye operation"));
    expect(invokeMock.mock.calls.filter(([command]) => command === "capture_area")).toHaveLength(0);

    resolveRegistration({ message: "ShotEye could not register Command+Shift+K. It may be used by another app." });
    await waitFor(() => expect(screen.getByTestId("shortcut-status").textContent).toContain("Conflict"));
    expect(screen.getByTestId("status").textContent).toContain("⌘⇧K");
    expect(shortcutButton.textContent).toContain("⌘⇧Y");
    expect((screen.getByRole("button", { name: "Capture area" }) as HTMLButtonElement).disabled).toBe(false);
  });

  it("restores an earlier capture from the session history", async () => {
    await renderWithCapture();

    const newerCapture = "data:image/png;base64,newer";
    captureAreaResult = Promise.resolve({ message: "Area captured.", data_url: newerCapture, width: 120, height: 90 });
    fireEvent.click(screen.getByRole("button", { name: "Capture area" }));
    await waitFor(() => expect(screen.getByRole("img", { name: "Latest area capture" }).getAttribute("src")).toBe(newerCapture));

    fireEvent.click(screen.getByRole("button", { name: /Restore capture 2: 100×100px/ }));
    await waitFor(() => expect(screen.getByRole("img", { name: "Latest area capture" }).getAttribute("src")).toBe(originalCapture));
    expect(screen.getByTestId("status").textContent).toContain("Restored capture from history: 100×100px.");
  });

  it("forgets session history without removing the current image", async () => {
    await renderWithCapture();

    fireEvent.click(screen.getByRole("button", { name: "Clear capture history" }));

    expect(screen.queryByRole("button", { name: "Clear capture history" })).toBeNull();
    expect(screen.getByRole("img", { name: "Latest area capture" }).getAttribute("src")).toBe(originalCapture);
    expect(screen.getByTestId("status").textContent).toContain("Cleared recent capture history");
  });
});

describe("App startup readiness lifecycle", () => {
  it("routes a native Tools menu action through the current editor state", async () => {
    render(<App />);

    await waitFor(() => expect(createdSubmenuOptions.current.some(({ id }) => id === "tools")).toBe(true));
    const toolsMenu = createdSubmenuOptions.current.find(({ id }) => id === "tools");
    const blurMenuItem = toolsMenu?.items?.find(({ id }) => id === "tool-blur");
    expect(blurMenuItem?.action).toBeTypeOf("function");

    blurMenuItem?.action?.();

    await waitFor(() => expect(screen.getByRole("button", { name: "Blur" }).className).toContain("active"));
  });

  it("exposes the status footer as a live recovery region", () => {
    render(<App />);

    const status = screen.getByTestId("status");
    expect(status.getAttribute("role")).toBe("status");
    expect(status.getAttribute("aria-live")).toBe("polite");
  });

  it("refreshes Screen Recording status when the editor regains focus", async () => {
    render(<App />);

    await waitFor(() => expect(focusChangedCallback.current).toBeTypeOf("function"));
    await waitFor(() => expect(invokeMock).toHaveBeenCalledWith("screen_capture_permission_status"));
    const statusChecksBeforeFocus = invokeMock.mock.calls.filter(([command]) => command === "screen_capture_permission_status").length;

    focusChangedCallback.current!({ payload: false });
    expect(invokeMock.mock.calls.filter(([command]) => command === "screen_capture_permission_status")).toHaveLength(statusChecksBeforeFocus);

    screenCapturePermissionMessage = "Screen capture permission is now available to ShotEye.";
    focusChangedCallback.current!({ payload: true });

    await waitFor(() => expect(screen.getByTestId("status").textContent).toContain("now available to ShotEye"));
    expect(invokeMock.mock.calls.filter(([command]) => command === "screen_capture_permission_status")).toHaveLength(statusChecksBeforeFocus + 1);
  });

  it("coalesces duplicate focus refreshes while the permission check is pending", async () => {
    render(<App />);

    await waitFor(() => expect(focusChangedCallback.current).toBeTypeOf("function"));
    await waitFor(() => expect(invokeMock).toHaveBeenCalledWith("screen_capture_permission_status"));
    const statusChecksBeforeFocus = invokeMock.mock.calls.filter(([command]) => command === "screen_capture_permission_status").length;
    let resolveFocusRefresh!: (result: { message: string }) => void;
    screenCapturePermissionResult = new Promise((resolve) => { resolveFocusRefresh = resolve; });

    focusChangedCallback.current!({ payload: true });
    focusChangedCallback.current!({ payload: true });

    await waitFor(() => expect(invokeMock.mock.calls.filter(([command]) => command === "screen_capture_permission_status")).toHaveLength(statusChecksBeforeFocus + 1));
    resolveFocusRefresh({ message: "Focus refresh completed once." });
    await waitFor(() => expect(screen.getByTestId("status").textContent).toContain("Focus refresh completed once."));
  });

  it("releases the focus refresh lane after a rejected permission check", async () => {
    render(<App />);

    await waitFor(() => expect(focusChangedCallback.current).toBeTypeOf("function"));
    await waitFor(() => expect(invokeMock).toHaveBeenCalledWith("screen_capture_permission_status"));
    const statusChecksBeforeFocus = invokeMock.mock.calls.filter(([command]) => command === "screen_capture_permission_status").length;
    screenCapturePermissionResult = Promise.reject(new Error("temporary status failure"));

    focusChangedCallback.current!({ payload: true });
    await waitFor(() => expect(screen.getByTestId("status").textContent).toContain("Could not refresh Screen Recording permission"));

    screenCapturePermissionResult = Promise.resolve({ message: "Focus refresh recovered." });
    focusChangedCallback.current!({ payload: true });
    await waitFor(() => expect(screen.getByTestId("status").textContent).toContain("Focus refresh recovered."));
    expect(invokeMock.mock.calls.filter(([command]) => command === "screen_capture_permission_status")).toHaveLength(statusChecksBeforeFocus + 2);
  });

  it("waits for the capture listener before signaling frontend readiness", async () => {
    runtimeContractEnabled = true;
    let resolveListener!: () => void;
    const listenerReady = new Promise<void>((resolve) => { resolveListener = resolve; });
    listenMock.mockImplementation(async () => {
      await listenerReady;
      return () => {};
    });

    render(<App />);
    await waitFor(() => expect(invokeMock).toHaveBeenCalledWith("runtime_contract_enabled"));
    expect(invokeMock.mock.calls.filter(([command]) => command === "capture_frontend_ready")).toHaveLength(0);

    resolveListener();
    await waitFor(() => expect(invokeMock.mock.calls.filter(([command]) => command === "capture_frontend_ready")).toHaveLength(1));
  });
});

describe("App annotated export lifecycle", () => {
  it("rasterizes the current annotation before Copy", async () => {
    await addRectangleAnnotation();

    fireEvent.click(screen.getByRole("button", { name: "Copy capture" }));
    await waitForNativeExport("copy_capture");

    expect(invokeMock).toHaveBeenCalledWith("store_rendered_capture", { dataUrl: staleCropCapture });
    expect(invokeMock).toHaveBeenCalledWith("copy_capture");
    expect(screen.getByTestId("status").textContent).toContain("Copied capture.");
    expect(createdContexts.some((context) => context.strokeRect.mock.calls.length > 0)).toBe(true);
  });

  it("waits for the Save destination before preparing the latest annotated export", async () => {
    saveMock.mockResolvedValue("/tmp/ShotEye Capture.png");
    await addRectangleAnnotation();

    fireEvent.click(screen.getByRole("button", { name: "Save capture" }));
    await waitFor(() => expect(saveMock).toHaveBeenCalledTimes(1));
    await waitForNativeExport("save_capture");

    expect(invokeMock).toHaveBeenCalledWith("store_rendered_capture", { dataUrl: staleCropCapture });
    expect(invokeMock).toHaveBeenCalledWith("save_capture", { path: "/tmp/ShotEye Capture.png" });
    expect(screen.getByTestId("status").textContent).toContain("Saved capture.");
  });

  it("keeps Drag on the same annotated export path after background prewarming", async () => {
    await addRectangleAnnotation();

    fireEvent.pointerDown(screen.getByRole("button", { name: "Drag capture out" }), { button: 0, pointerId: 6 });
    await waitForNativeExport("drag_out_capture");

    expect(invokeMock).toHaveBeenCalledWith("store_rendered_capture", { dataUrl: staleCropCapture });
    expect(invokeMock).toHaveBeenCalledWith("drag_out_capture", { sourceX: 0, sourceY: 0 });
    expect(screen.getByTestId("status").textContent).toContain("Drag started.");
  });

  it("rasterizes Redact as an opaque black block before Copy", async () => {
    await addRedactAnnotation();

    fireEvent.click(screen.getByRole("button", { name: "Copy capture" }));
    await waitForNativeExport("copy_capture");

    expect(createdContexts.some((context) => context.fillRect.mock.calls.some(([x, y, width, height]) => [x, y, width, height].every((value) => typeof value === "number")))).toBe(true);
    expect(screen.getByTestId("status").textContent).toContain("Copied capture.");
  });

  it("adds Pixelate through the editor and keeps it on the shared export path", async () => {
    await addPixelateAnnotation();

    expect(screen.getByTestId("status").textContent).toContain("1 annotation");
    expect(document.querySelector("pattern[id^=\"pixelate-\"]")).toBeTruthy();

    fireEvent.click(screen.getByRole("button", { name: "Copy capture" }));
    await waitForNativeExport("copy_capture");

    expect(invokeMock).toHaveBeenCalledWith("store_rendered_capture", { dataUrl: staleCropCapture });
    expect(screen.getByTestId("status").textContent).toContain("Copied capture.");
  });

  it("adds Blur through the editor and keeps it on the shared export path", async () => {
    await addBlurAnnotation();

    expect(screen.getByTestId("status").textContent).toContain("1 annotation");
    expect(document.querySelector("filter[id^=\"blur-filter-\"]")).toBeTruthy();

    fireEvent.click(screen.getByRole("button", { name: "Copy capture" }));
    await waitForNativeExport("copy_capture");

    expect(invokeMock).toHaveBeenCalledWith("store_rendered_capture", { dataUrl: staleCropCapture });
    expect(screen.getByTestId("status").textContent).toContain("Copied capture.");
  });

  it("shows Copy progress and blocks competing native actions until export completes", async () => {
    await addRectangleAnnotation();
    let resolveCopy!: (result: { message: string }) => void;
    invokeMock.mockImplementation(async (command: string) => {
      if (command === "copy_capture") return new Promise((resolve) => { resolveCopy = resolve; });
      return { message: "OK" };
    });

    fireEvent.click(screen.getByRole("button", { name: "Copy capture" }));
    await waitFor(() => expect(screen.getByTestId("operation-state").textContent).toContain("Copying capture"));
    expect(screen.getByRole("button", { name: "Save capture" })).toHaveProperty("disabled", true);
    expect(screen.getByRole("button", { name: "Capture area" })).toHaveProperty("disabled", true);

    await waitForNativeExport("copy_capture");
    expect(resolveCopy).toBeTypeOf("function");
    resolveCopy({ message: "Copied capture." });
    await waitFor(() => expect(screen.queryByTestId("operation-state")).toBeNull());
    expect(screen.getByTestId("status").textContent).toContain("Copied capture.");
  });

  it("keeps annotation tools usable while the Save dialog is open", async () => {
    await renderWithCapture();
    let resolveSave!: (path: string | undefined) => void;
    saveMock.mockImplementation(() => new Promise((resolve) => { resolveSave = resolve; }));

    fireEvent.click(screen.getByRole("button", { name: "Save capture" }));
    await waitFor(() => expect(screen.getByTestId("operation-state").textContent).toContain("Save dialog open"));
    expect(screen.getByRole("button", { name: "Rectangle" })).toHaveProperty("disabled", false);
    expect(screen.getByRole("button", { name: "Copy capture" })).toHaveProperty("disabled", true);

    resolveSave(undefined);
    await waitFor(() => expect(screen.queryByTestId("operation-state")).toBeNull());
    expect(screen.getByTestId("status").textContent).toContain("Save cancelled.");
  });

  it("shows Drag progress and releases the native lane after completion", async () => {
    await addRectangleAnnotation();
    let resolveDrag!: (result: { message: string }) => void;
    invokeMock.mockImplementation(async (command: string) => {
      if (command === "drag_out_capture") return new Promise((resolve) => { resolveDrag = resolve; });
      return { message: "OK" };
    });

    fireEvent.pointerDown(screen.getByRole("button", { name: "Drag capture out" }), { button: 0, pointerId: 10 });
    await waitFor(() => expect(screen.getByTestId("operation-state").textContent).toContain("drag"));
    expect(screen.getByRole("button", { name: "Copy capture" })).toHaveProperty("disabled", true);

    await waitForNativeExport("drag_out_capture");
    expect(resolveDrag).toBeTypeOf("function");
    resolveDrag({ message: "Drag started." });
    await waitFor(() => expect(screen.queryByTestId("operation-state")).toBeNull());
    expect(screen.getByTestId("status").textContent).toContain("Drag started.");
  });
});
