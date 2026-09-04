import { invoke } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";
import { Menu, PredefinedMenuItem, Submenu } from "@tauri-apps/api/menu";
import { getCurrentWindow } from "@tauri-apps/api/window";
import { open, save } from "@tauri-apps/plugin-dialog";
import { useEffect, useRef, useState } from "react";
import {
  type Annotation,
  type AnnotationTool,
  type ResizeHandle,
  arrowHeadPoints,
  findAnnotationAtPoint,
  isMeaningfulAnnotation,
  pointFromPointer,
  renderAnnotation,
  resizeAnnotation,
  resizeHandlePoints,
  svgPath,
  translateAnnotation,
} from "./annotations";
import { appendAnnotation, clearAnnotations, redoAnnotation, removeAnnotation, replaceAnnotation, undoAnnotation, type AnnotationHistory } from "./annotation-history";
import { runNativeCaptureAction } from "./capture-window-lifecycle";
import { cropBounds, resolveAtStableRevision, type CropRectangle } from "./crop";
import { prepareAtStableRevision } from "./export-revision";
import { runExclusiveAction } from "./exclusive-action";
import { runtimeContractReportPayload } from "./runtime-contract";
import { shortcutFromKeyboardEvent } from "./capture-shortcut";
import { editorShortcutAction } from "./editor-shortcuts";
import { ariaKeyShortcuts, displayShortcut, displayShortcutStatus, shotEyeShortcuts } from "./shortcut-display";
import { shortcutApplyAccepted, startupShortcutRecovery } from "./shortcut-persistence";
import { preparedExportForRevision, type PreparedExport } from "./prepared-export";
import { beginStatusEpoch, statusEpochIsCurrent, type StatusEpoch } from "./status-epoch";
import { shotEyeMenuGroups, type ShotEyeMenuAction } from "./menu-model";
import { appendCaptureHistory, type CaptureHistoryEntry } from "./capture-history";
import { firstSupportedImagePath } from "./image-drop";
import "./App.css";

type BackendStatus = { message: string };
type CaptureResult = { message: string; data_url: string | null; width: number | null; height: number | null };
type NativeOperation = "capture" | "export" | "permission" | "import";
type NativeOperationPhase = NativeOperation | "save-dialog" | "copy" | "save" | "drag";
type ShortcutRegistrationState = "checking" | "active" | "conflict" | "inactive";
type EditorMutation = "undo" | "redo" | "clear" | "reset" | "delete";
type MoveDraft = { id: string; origin: { x: number; y: number }; originAnnotation: Annotation; annotation: Annotation };
type ResizeDraft = { id: string; handle: ResizeHandle; origin: { x: number; y: number }; originAnnotation: Annotation; annotation: Annotation };
type FileDropPayload = { paths?: unknown };

function nativeOperationLabel(phase: NativeOperationPhase) {
  switch (phase) {
    case "capture": return "Capturing…";
    case "import": return "Importing image…";
    case "permission": return "Checking Screen Recording permission…";
    case "copy": return "Copying capture…";
    case "save-dialog": return "Save dialog open — editor remains usable";
    case "save": return "Saving capture…";
    case "drag": return "Preparing drag-out…";
  }
}

function shortcutRegistrationLabel(state: ShortcutRegistrationState, busy: boolean) {
  if (busy || state === "checking") return "Registering…";
  if (state === "active") return "Active";
  if (state === "conflict") return "Conflict — choose another";
  return "Not active";
}

const tools = ["Select", "Crop", "Arrow", "Rectangle", "Text", "Draw", "Redact", "Pixelate", "Blur"] as const;
const annotationTools = new Set<AnnotationTool>(["Arrow", "Rectangle", "Text", "Draw", "Redact", "Pixelate", "Blur"]);
const defaultCaptureShortcut = "CommandOrControl+Shift+Y";
const captureShortcutStorageKey = "shoteye.capture-shortcut";

type ToolbarIconName = "open" | "paste" | "copy" | "save" | "drag" | "repeat" | "pin" | "window" | "fullscreen";

function ToolbarIcon({ name }: { name: ToolbarIconName }) {
  const common = { className: "toolbar-icon", viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", strokeWidth: 1.8, strokeLinecap: "round" as const, strokeLinejoin: "round" as const, "aria-hidden": true, focusable: false };
  switch (name) {
    case "open":
      return <svg {...common}><path d="M4 7.5A2.5 2.5 0 0 1 6.5 5H10l2 2h5.5A2.5 2.5 0 0 1 20 9.5v7A2.5 2.5 0 0 1 17.5 19h-11A2.5 2.5 0 0 1 4 16.5z" /><path d="M4.5 10h15" /></svg>;
    case "paste":
      return <svg {...common}><path d="M9 5h6" /><path d="M9 3.5h6a1 1 0 0 1 1 1V6H8V4.5a1 1 0 0 1 1-1Z" /><rect x="5" y="6" width="14" height="14" rx="2" /><path d="M8 10h8M8 13h8M8 16h5" /></svg>;
    case "copy":
      return <svg {...common}><rect x="8" y="8" width="11" height="11" rx="2" /><path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2" /></svg>;
    case "save":
      return <svg {...common}><path d="M5 4h11l3 3v13H5z" /><path d="M8 4v6h8V4M8 20v-6h8v6" /></svg>;
    case "drag":
      return <svg {...common}><path d="M5 19 19 5" /><path d="M10 5h9v9" /><path d="M5 12v7h7" /></svg>;
    case "repeat":
      return <svg {...common}><path d="M20 7v5h-5" /><path d="M4 17v-5h5" /><path d="M6.1 9A7 7 0 0 1 18.5 7L20 8.5M4 15.5 5.5 17A7 7 0 0 0 17.9 15" /></svg>;
    case "pin":
      return <svg {...common}><path d="m9 4 6 6" /><path d="m7 8 9-3 3 3-3 9-4-4-4 4" /><path d="m12 13-7 7" /></svg>;
    case "window":
      return <svg {...common}><rect x="4" y="5" width="16" height="14" rx="2" /><path d="M4 9h16M8 7h.01M11 7h.01" /></svg>;
    case "fullscreen":
      return <svg {...common}><path d="M8 4H4v4M16 4h4v4M20 16v4h-4M4 16v4h4" /></svg>;
  }
}

function ShortcutHint({ shortcut }: { shortcut: string }) {
  return <kbd className="shortcut-hint" aria-hidden="true">{displayShortcut(shortcut)}</kbd>;
}

function annotationId() {
  return typeof crypto.randomUUID === "function" ? crypto.randomUUID() : `${Date.now()}-${Math.random()}`;
}

function storedCaptureShortcut() {
  return window.localStorage.getItem(captureShortcutStorageKey) || defaultCaptureShortcut;
}

function App() {
  const [selectedTool, setSelectedTool] = useState("Select");
  const [status, setStatus] = useState("Ready to capture.");
  const [capture, setCapture] = useState<string | null>(null);
  const [captureHistory, setCaptureHistory] = useState<CaptureHistoryEntry[]>([]);
  const [imageSize, setImageSize] = useState<{ width: number; height: number } | null>(null);
  const [originalCapture, setOriginalCapture] = useState<string | null>(null);
  const [originalImageSize, setOriginalImageSize] = useState<{ width: number; height: number } | null>(null);
  const [capturing, setCapturing] = useState(false);
  const [nativeOperationPhase, setNativeOperationPhase] = useState<NativeOperationPhase | null>(null);
  const [annotations, setAnnotations] = useState<Annotation[]>([]);
  const [selectedAnnotationId, setSelectedAnnotationId] = useState<string | null>(null);
  const [undoDepth, setUndoDepth] = useState(0);
  const [redoAnnotations, setRedoAnnotations] = useState<Annotation[][]>([]);
  const [draft, setDraft] = useState<Annotation | null>(null);
  const [moveDraft, setMoveDraft] = useState<MoveDraft | null>(null);
  const [resizeDraft, setResizeDraft] = useState<ResizeDraft | null>(null);
  const [cropDraft, setCropDraft] = useState<CropRectangle | null>(null);
  const [color, setColor] = useState("#ff4d5a");
  const [stroke, setStroke] = useState(4);
  const [text, setText] = useState("Note");
  const [zoom, setZoom] = useState(100);
  const [captureShortcut, setCaptureShortcut] = useState(storedCaptureShortcut);
  const [recordingShortcut, setRecordingShortcut] = useState(false);
  const [shortcutRegistrationState, setShortcutRegistrationState] = useState<ShortcutRegistrationState>("checking");
  const [shortcutRegistrationBusy, setShortcutRegistrationBusy] = useState(false);
  const [pinned, setPinned] = useState(false);
  const [permissionActionBusy, setPermissionActionBusy] = useState(false);
  const [fileDropActive, setFileDropActive] = useState(false);
  const captureAreaRef = useRef<() => Promise<void>>(async () => {});
  const nativeOperationInFlight = useRef(false);
  const activeNativeOperation = useRef<NativeOperation | null>(null);
  const capturingRef = useRef(false);
  const dragOutInFlight = useRef(false);
  const dragExportReady = useRef(false);
  const dragExportRevision = useRef(0);
  const preparedExportRef = useRef<PreparedExport | null>(null);
  const exportQueue = useRef(Promise.resolve());
  const recordingShortcutRef = useRef(false);
  const shortcutRegistrationInFlight = useRef(false);
  const shortcutRegistrationBusyRef = useRef(false);
  const pinInFlight = useRef(false);
  const permissionStatusRefreshInFlight = useRef(false);
  const statusEpoch = useRef<StatusEpoch>({ current: 0 });
  const menuHandlers = useRef<Partial<Record<ShotEyeMenuAction, () => void>>>({});
  const runtimeContractStarted = useRef(false);
  const frontendReadySignaled = useRef(false);
  const frontendReadyPromise = useRef<Promise<void> | null>(null);
  const moveDraftRef = useRef<MoveDraft | null>(null);
  const resizeDraftRef = useRef<ResizeDraft | null>(null);
  const captureRef = useRef<string | null>(null);
  const imageSizeRef = useRef<{ width: number; height: number } | null>(null);
  const annotationsRef = useRef<Annotation[]>([]);
  const imageEditRevision = useRef(0);
  const annotationHistory = useRef<AnnotationHistory>({ annotations: [], undo: [], redo: [] });
  captureRef.current = capture;
  imageSizeRef.current = imageSize;
  annotationsRef.current = annotations;
  recordingShortcutRef.current = recordingShortcut;
  shortcutRegistrationBusyRef.current = shortcutRegistrationBusy;
  capturingRef.current = capturing;

  function beginNativeOperation(operation: NativeOperation, phase: NativeOperationPhase = operation) {
    activeNativeOperation.current = operation;
    setNativeOperationPhase(phase);
  }

  function finishNativeOperation() {
    activeNativeOperation.current = null;
    setNativeOperationPhase(null);
  }

  const nativeOperationBusy = nativeOperationPhase !== null;
  const actionBusy = nativeOperationBusy || shortcutRegistrationBusy;
  const editorMutationBusy = capturing || nativeOperationPhase === "copy" || nativeOperationPhase === "save" || nativeOperationPhase === "drag";

  function applyAnnotationHistory(next: AnnotationHistory) {
    if (next !== annotationHistory.current) imageEditRevision.current += 1;
    annotationHistory.current = next;
    setAnnotations(next.annotations);
    setUndoDepth(next.undo.length);
    setRedoAnnotations(next.redo);
  }

  function beginUserStatusAction() {
    beginStatusEpoch(statusEpoch.current);
  }

  async function installNativeMenu() {
    const productMenu = await Submenu.new({
      id: "shoteye",
      text: "ShotEye",
      items: [
        await PredefinedMenuItem.new({ item: { About: { name: "ShotEye", version: "0.1.0" } } }),
        await PredefinedMenuItem.new({ item: "Separator" }),
        await PredefinedMenuItem.new({ item: "Hide" }),
        await PredefinedMenuItem.new({ item: "HideOthers" }),
        await PredefinedMenuItem.new({ item: "ShowAll" }),
        await PredefinedMenuItem.new({ item: "Separator" }),
        await PredefinedMenuItem.new({ item: "Quit" }),
      ],
    });
    const groups = await Promise.all(shotEyeMenuGroups.map((group) => Submenu.new({
      id: group.id,
      text: group.text,
      items: group.items.map((item) => ({
        id: item.id,
        text: item.text,
        accelerator: item.accelerator,
        action: () => menuHandlers.current[item.action]?.(),
      })),
    })));
    return Menu.new({ items: [productMenu, ...groups] });
  }

  function clearAnnotationInteraction() {
    setSelectedAnnotationId(null);
    setDraft(null);
    setCropDraft(null);
    moveDraftRef.current = null;
    setMoveDraft(null);
    resizeDraftRef.current = null;
    setResizeDraft(null);
  }

  function selectEditorTool(tool: typeof tools[number]) {
    if (capturing) {
      beginUserStatusAction();
      setStatus("Finish the current capture before changing tools.");
      return;
    }
    setSelectedTool(tool);
    clearAnnotationInteraction();
  }

  function resetAnnotationHistory() {
    applyAnnotationHistory({ annotations: [], undo: [], redo: [] });
    clearAnnotationInteraction();
  }

  function addAnnotation(annotation: Annotation) {
    applyAnnotationHistory(appendAnnotation(annotationHistory.current, annotation));
  }

  function undoAnnotationAction() {
    const next = undoAnnotation(annotationHistory.current);
    if (next === annotationHistory.current) return;
    applyAnnotationHistory(next);
    beginUserStatusAction();
    setStatus("Undid last annotation.");
  }

  function redoAnnotationAction() {
    const next = redoAnnotation(annotationHistory.current);
    if (next === annotationHistory.current) return;
    applyAnnotationHistory(next);
    beginUserStatusAction();
    setStatus("Redid last annotation.");
  }

  function deleteAnnotationAction() {
    if (!selectedAnnotationId) return;
    const next = removeAnnotation(annotationHistory.current, selectedAnnotationId);
    if (next === annotationHistory.current) return;
    applyAnnotationHistory(next);
    clearAnnotationInteraction();
    beginUserStatusAction();
    setStatus("Deleted selected annotation.");
  }

  function clearAnnotationsAction() {
    if (annotations.length === 0) return;
    applyAnnotationHistory(clearAnnotations(annotationHistory.current));
    clearAnnotationInteraction();
    beginUserStatusAction();
    setStatus("Cleared annotations.");
  }

  function resetImageAction() {
    beginUserStatusAction();
    if (!originalCapture || !originalImageSize) {
      setStatus("Capture or open an image before resetting.");
      return;
    }
    setCapture(originalCapture);
    setImageSize(originalImageSize);
    resetAnnotationHistory();
    setZoom(100);
    setStatus("Restored the original image and cleared edits.");
  }

  function dispatchEditorMutation(action: EditorMutation) {
    if (capturing) {
      beginUserStatusAction();
      setStatus("Finish the current capture before editing annotations.");
      return;
    }
    switch (action) {
      case "undo":
        undoAnnotationAction();
        return;
      case "redo":
        redoAnnotationAction();
        return;
      case "clear":
        clearAnnotationsAction();
        return;
      case "reset":
        resetImageAction();
        return;
      case "delete":
        deleteAnnotationAction();
    }
  }

  async function runCapture(command: "capture_area" | "capture_window" | "capture_fullscreen" | "repeat_last_capture", prompt: string) {
    await runExclusiveAction(nativeOperationInFlight, async () => {
      beginNativeOperation("capture");
      try {
          const captureStatusEpoch = beginStatusEpoch(statusEpoch.current);
        const commitStatus = (message: string) => {
          if (statusEpochIsCurrent(statusEpoch.current, captureStatusEpoch)) setStatus(message);
        };
        setCapturing(true);
        commitStatus(prompt);
        try {
          const outcome = await runNativeCaptureAction(() => invoke<CaptureResult>(command));
          if (outcome.result) {
            // A successful native capture is still useful even if macOS
            // reports a best-effort restoration error. Commit the image first
            // so Copy/Save remain available while the status explains the
            // recovery problem.
            applyImageResult(outcome.result, commitStatus);
          }
          if (outcome.actionError) {
            commitStatus(`Capture error: ${String(outcome.actionError)}`);
          }
        } finally {
          setCapturing(false);
        }
      } finally {
        finishNativeOperation();
      }
    }, () => {
      beginUserStatusAction();
      setStatus("Finish the current ShotEye operation before starting another one.");
    });
  }

  async function runRuntimeContract() {
    if (runtimeContractStarted.current) return;
    runtimeContractStarted.current = true;
    await runExclusiveAction(nativeOperationInFlight, async () => {
      beginNativeOperation("capture");
      const runtimeStatusEpoch = beginStatusEpoch(statusEpoch.current);
      const commitStatus = (message: string) => {
        if (statusEpochIsCurrent(statusEpoch.current, runtimeStatusEpoch)) setStatus(message);
      };
      setCapturing(true);
      commitStatus("Running packaged ShotEye runtime contract…");
      let actionSucceeded = false;
      let restorationSucceeded = false;
      let previewWidth: number | null = null;
      let previewHeight: number | null = null;
      try {
        const outcome = await runNativeCaptureAction(() => invoke<CaptureResult>("capture_area"));
        actionSucceeded = outcome.actionError === null
          && Boolean(outcome.result?.data_url && outcome.result.width && outcome.result.height);
        // Rust owns native hide/restore and reports its result through the
        // runtime contract command. This value means the IPC action itself
        // did not observe a frontend-side restoration error.
        restorationSucceeded = true;
        previewWidth = outcome.result?.width ?? null;
        previewHeight = outcome.result?.height ?? null;
        if (outcome.result) applyImageResult(outcome.result, commitStatus);
        const report = await invoke<BackendStatus>("runtime_contract_report", {
          ...runtimeContractReportPayload({ actionSucceeded, restorationSucceeded, previewWidth, previewHeight }),
        });
        commitStatus(report.message);
      } catch (error) {
        try {
          await invoke<BackendStatus>("runtime_contract_report", {
            ...runtimeContractReportPayload({
              actionSucceeded: false,
              restorationSucceeded: false,
              previewWidth: null,
              previewHeight: null,
            }),
          });
        } catch {
          // Preserve the original runtime error when the diagnostic report
          // itself cannot cross the command boundary.
        }
        commitStatus(`Runtime contract error: ${String(error)}`);
      } finally {
        setCapturing(false);
        finishNativeOperation();
      }
    }, () => {
      beginUserStatusAction();
      setStatus("Runtime contract could not start because ShotEye is busy.");
    });
  }

  async function captureArea() {
    await runCapture("capture_area", "Hiding ShotEye. Choose an area across any connected display…");
  }

  async function captureFullscreen() {
    await runCapture("capture_fullscreen", "Hiding ShotEye. Capturing the full screen…");
  }

  async function captureWindow() {
    await runCapture("capture_window", "Hiding ShotEye. Choose a window to capture…");
  }

  async function repeatLastCapture() {
    await runCapture("repeat_last_capture", "Hiding ShotEye. Repeating the last capture…");
  }

  async function togglePinned() {
    if (pinInFlight.current) return;
    beginUserStatusAction();
    pinInFlight.current = true;
    const next = !pinned;
    try {
      await getCurrentWindow().setAlwaysOnTop(next);
      setPinned(next);
      setStatus(next ? "ShotEye is pinned above other windows." : "ShotEye returned to normal window order.");
    } catch (error) {
      setStatus(`Could not ${next ? "pin" : "unpin"} ShotEye: ${String(error)}`);
    } finally {
      pinInFlight.current = false;
    }
  }

  function applyImageResult(result: CaptureResult, publishStatus: (message: string) => void = setStatus) {
    if (result.data_url && result.width && result.height) {
      const historyEntry: CaptureHistoryEntry = {
        id: annotationId(),
        dataUrl: result.data_url,
        width: result.width,
        height: result.height,
        createdAt: Date.now(),
      };
      setCaptureHistory((current) => appendCaptureHistory(current, historyEntry));
      setCapture(result.data_url);
      setImageSize({ width: result.width, height: result.height });
      setOriginalCapture(result.data_url);
      setOriginalImageSize({ width: result.width, height: result.height });
      resetAnnotationHistory();
      setDraft(null);
      setCropDraft(null);
      setZoom(100);
    }
    publishStatus(result.message);
  }

  function clearCaptureHistory() {
    if (captureHistory.length === 0) return;
    beginUserStatusAction();
    setCaptureHistory([]);
    setStatus("Cleared recent capture history from this session.");
  }

  async function restoreCaptureFromHistory(entry: CaptureHistoryEntry) {
    beginUserStatusAction();
    await runExclusiveAction(nativeOperationInFlight, async () => {
      beginNativeOperation("import");
      try {
        setCapture(entry.dataUrl);
        setImageSize({ width: entry.width, height: entry.height });
        setOriginalCapture(entry.dataUrl);
        setOriginalImageSize({ width: entry.width, height: entry.height });
        resetAnnotationHistory();
        setDraft(null);
        setCropDraft(null);
        setZoom(100);
        setStatus(`Restored capture from history: ${entry.width}×${entry.height}px.`);
      } finally {
        finishNativeOperation();
      }
    }, () => {
      beginUserStatusAction();
      setStatus("Finish the current ShotEye operation before restoring a capture.");
    });
  }

  async function openImage() {
    beginUserStatusAction();
    await runExclusiveAction(nativeOperationInFlight, async () => {
      beginNativeOperation("import");
      const importStatusEpoch = statusEpoch.current.current;
      const commitStatus = (message: string) => {
        if (statusEpochIsCurrent(statusEpoch.current, importStatusEpoch)) setStatus(message);
      };
      try {
        const path = await open({
          multiple: false,
          directory: false,
          filters: [{ name: "Images", extensions: ["png", "jpg", "jpeg", "tif", "tiff"] }],
        });
        if (!path || Array.isArray(path)) {
          commitStatus("Open image cancelled.");
          return;
        }
        applyImageResult(await invoke<CaptureResult>("open_image", { path }), commitStatus);
      } catch (error) {
        commitStatus(`Open image error: ${String(error)}`);
      } finally {
        finishNativeOperation();
      }
    }, () => {
      beginUserStatusAction();
      setStatus("Finish the current ShotEye operation before opening another image.");
    });
  }

  async function importDroppedImage(path: string) {
    beginUserStatusAction();
    await runExclusiveAction(nativeOperationInFlight, async () => {
      beginNativeOperation("import");
      const importStatusEpoch = statusEpoch.current.current;
      const commitStatus = (message: string) => {
        if (statusEpochIsCurrent(statusEpoch.current, importStatusEpoch)) setStatus(message);
      };
      try {
        commitStatus("Opening dropped image…");
        applyImageResult(await invoke<CaptureResult>("open_image", { path }), commitStatus);
      } catch (error) {
        commitStatus(`Dropped image error: ${String(error)}`);
      } finally {
        finishNativeOperation();
      }
    }, () => {
      beginUserStatusAction();
      setStatus("Finish the current ShotEye operation before opening a dropped image.");
    });
  }

  async function importClipboardImage() {
    beginUserStatusAction();
    await runExclusiveAction(nativeOperationInFlight, async () => {
      beginNativeOperation("import");
      const importStatusEpoch = statusEpoch.current.current;
      const commitStatus = (message: string) => {
        if (statusEpochIsCurrent(statusEpoch.current, importStatusEpoch)) setStatus(message);
      };
      try {
        applyImageResult(await invoke<CaptureResult>("import_clipboard_image"), commitStatus);
      } catch (error) {
        commitStatus(`Clipboard import error: ${String(error)}`);
      } finally {
        finishNativeOperation();
      }
    }, () => {
      beginUserStatusAction();
      setStatus("Finish the current ShotEye operation before importing another image.");
    });
  }

  async function runPermissionAction(action: () => Promise<void>, busyMessage: string) {
    await runExclusiveAction(nativeOperationInFlight, async () => {
      beginNativeOperation("permission");
      setPermissionActionBusy(true);
      try {
        await action();
      } finally {
        setPermissionActionBusy(false);
        finishNativeOperation();
      }
    }, () => {
      beginUserStatusAction();
      setStatus(activeNativeOperation.current === "permission"
        ? busyMessage
        : "Finish the current ShotEye operation before changing Screen Recording permissions.");
    });
  }

  async function requestScreenRecordingPermission() {
    await runPermissionAction(async () => {
      const permissionStatusEpoch = beginStatusEpoch(statusEpoch.current);
      const commitStatus = (message: string) => {
        if (statusEpochIsCurrent(statusEpoch.current, permissionStatusEpoch)) setStatus(message);
      };
      commitStatus("Requesting Screen Recording permission…");
      try {
        const result = await invoke<BackendStatus>("request_screen_capture_permission");
        commitStatus(result.message);
      } catch (error) {
        commitStatus(`Could not request Screen Recording permission: ${String(error)}`);
      }
    }, "A Screen Recording permission request is already in progress.");
  }

  async function openScreenRecordingSettings() {
    await runPermissionAction(async () => {
      const settingsStatusEpoch = beginStatusEpoch(statusEpoch.current);
      const commitStatus = (message: string) => {
        if (statusEpochIsCurrent(statusEpoch.current, settingsStatusEpoch)) setStatus(message);
      };
      try {
        const result = await invoke<BackendStatus>("open_screen_recording_settings");
        commitStatus(result.message);
      } catch (error) {
        commitStatus(`Could not open Screen Recording settings: ${String(error)}`);
      }
    }, "Finish the current Screen Recording permission action before opening settings.");
  }

  async function applyCaptureShortcut(shortcut: string, recoverStartupFailure = false) {
    const userInitiated = !recoverStartupFailure;
    if (shortcutRegistrationInFlight.current) {
      if (userInitiated) {
        beginUserStatusAction();
        setStatus("Finish the current shortcut registration before changing it again.");
      }
      return;
    }
    if (userInitiated && nativeOperationInFlight.current) {
      beginUserStatusAction();
      setStatus("Finish the current ShotEye operation before changing the capture shortcut.");
      return;
    }
    shortcutRegistrationInFlight.current = true;
    if (userInitiated) {
      nativeOperationInFlight.current = true;
      beginUserStatusAction();
      shortcutRegistrationBusyRef.current = true;
      setShortcutRegistrationBusy(true);
    }
    setShortcutRegistrationState("checking");
    const startupStatusEpoch = recoverStartupFailure ? statusEpoch.current.current : undefined;
    const commitStatus = (message: string) => {
      if (startupStatusEpoch === undefined || statusEpochIsCurrent(statusEpoch.current, startupStatusEpoch)) {
        setStatus(message);
      }
    };
    const recoverToDefaultShortcut = async () => {
      setCaptureShortcut(defaultCaptureShortcut);
      setShortcutRegistrationState("checking");
      window.localStorage.removeItem(captureShortcutStorageKey);
      try {
        const fallbackResult = await invoke<BackendStatus>("set_capture_shortcut", { shortcut: defaultCaptureShortcut });
        if (shortcutApplyAccepted(fallbackResult.message)) {
          setShortcutRegistrationState("active");
          commitStatus(`Saved capture shortcut is unavailable. Using ${displayShortcut(defaultCaptureShortcut)} instead.`);
        } else {
          setShortcutRegistrationState("inactive");
          commitStatus(`Saved capture shortcut is unavailable, and ${displayShortcut(defaultCaptureShortcut)} could not be registered. No global capture shortcut is active; record a replacement.`);
        }
      } catch (error) {
        setShortcutRegistrationState("inactive");
        commitStatus(`Saved capture shortcut is unavailable, and ${displayShortcut(defaultCaptureShortcut)} could not be registered. No global capture shortcut is active; record a replacement. (${String(error)})`);
      }
    };
    try {
      const result = await invoke<BackendStatus>("set_capture_shortcut", { shortcut });
      const accepted = shortcutApplyAccepted(result.message);
      if (recoverStartupFailure) {
        const recovery = startupShortcutRecovery(shortcut, defaultCaptureShortcut, accepted);
        setCaptureShortcut(recovery.shortcut);
        if (recovery.clearStored) {
          await recoverToDefaultShortcut();
          return;
        }
      }
      commitStatus(displayShortcutStatus(result.message, shortcut));
      if (accepted) {
        setShortcutRegistrationState("active");
        setCaptureShortcut(shortcut);
        window.localStorage.setItem(captureShortcutStorageKey, shortcut);
      } else {
        setShortcutRegistrationState(recoverStartupFailure ? "inactive" : "conflict");
      }
    } catch (error) {
      if (recoverStartupFailure) {
        const recovery = startupShortcutRecovery(shortcut, defaultCaptureShortcut, false);
        setCaptureShortcut(recovery.shortcut);
        if (recovery.clearStored) await recoverToDefaultShortcut();
        else {
          setShortcutRegistrationState("inactive");
          commitStatus(`Could not register ${displayShortcut(shortcut)}. Record another capture shortcut.`);
        }
        return;
      }
      setShortcutRegistrationState("conflict");
      setStatus(`Could not register ${displayShortcut(shortcut)}. Record another capture shortcut. (${String(error)})`);
    } finally {
      shortcutRegistrationInFlight.current = false;
      if (userInitiated) {
        shortcutRegistrationBusyRef.current = false;
        setShortcutRegistrationBusy(false);
        nativeOperationInFlight.current = false;
      }
    }
  }

  captureAreaRef.current = captureArea;

  async function signalFrontendReady() {
    if (frontendReadySignaled.current) return;
    frontendReadySignaled.current = true;
    try {
      await invoke("capture_frontend_ready");
    } catch (error) {
      frontendReadySignaled.current = false;
      throw error;
    }
  }

  useEffect(() => {
    let unlisten: (() => void) | undefined;
    let disposed = false;
    const startupStatusEpoch = statusEpoch.current.current;
    const registerCaptureListener = async () => {
      const stopListening = await listen("capture-requested", () => {
        if (recordingShortcutRef.current) {
          beginUserStatusAction();
          setStatus("Finish recording the capture shortcut before capturing.");
          return;
        }
        if (shortcutRegistrationBusyRef.current) {
          beginUserStatusAction();
          setStatus("Finish registering the capture shortcut before capturing.");
          return;
        }
        void captureAreaRef.current();
      });
      if (disposed) {
        stopListening();
        return;
      }
      unlisten = stopListening;
      // Signal readiness only after the native listener is installed. Rust
      // queues any shortcut pressed earlier, so no startup event is lost in
      // the listen/invoke race.
      await signalFrontendReady();
    };
    const listenerReady = registerCaptureListener();
    frontendReadyPromise.current = listenerReady;
    void listenerReady.catch((error) => {
      if (!disposed && statusEpochIsCurrent(statusEpoch.current, startupStatusEpoch)) setStatus(`Could not register the capture shortcut: ${String(error)}`);
    });
    return () => {
      disposed = true;
      unlisten?.();
    };
  }, []);

  useEffect(() => {
    let disposed = false;
    const startRuntimeContract = async () => {
      if (!(await invoke<boolean>("runtime_contract_enabled"))) return;
      // Runtime-contract capture is test-only, but it still shares startup
      // with the real global shortcut. Wait until the listener has completed
      // registration and readiness has been signaled so a queued shortcut
      // event cannot be emitted into an unlistened WebView.
      await frontendReadyPromise.current;
      if (!disposed) void runRuntimeContract();
    };
    void startRuntimeContract().catch((error) => {
      if (!disposed) setStatus(`Runtime contract startup error: ${String(error)}`);
    });
    return () => {
      disposed = true;
    };
  }, []);

  useEffect(() => {
    let disposed = false;
    let unlistenEnter: (() => void) | undefined;
    let unlistenLeave: (() => void) | undefined;
    let unlistenDrop: (() => void) | undefined;
    const dropStatusEpoch = statusEpoch.current.current;
    const registerFileDropListeners = async () => {
      const [stopEnter, stopLeave, stopDrop] = await Promise.all([
        listen<FileDropPayload>("tauri://drag-enter", (event) => {
          if (!disposed && !capturingRef.current) setFileDropActive(firstSupportedImagePath(event.payload?.paths) !== null);
        }),
        listen("tauri://drag-leave", () => {
          if (!disposed) setFileDropActive(false);
        }),
        listen<FileDropPayload>("tauri://drag-drop", (event) => {
          if (disposed) return;
          setFileDropActive(false);
          if (capturingRef.current || nativeOperationInFlight.current) {
            beginUserStatusAction();
            setStatus("Finish the current ShotEye operation before opening a dropped image.");
            return;
          }
          const path = firstSupportedImagePath(event.payload?.paths);
          if (!path) {
            beginUserStatusAction();
            setStatus("Drop a PNG, JPEG, or TIFF image into ShotEye.");
            return;
          }
          void importDroppedImage(path);
        }),
      ]);
      if (disposed) {
        stopEnter();
        stopLeave();
        stopDrop();
        return;
      }
      unlistenEnter = stopEnter;
      unlistenLeave = stopLeave;
      unlistenDrop = stopDrop;
    };
    void registerFileDropListeners().catch((error) => {
      if (!disposed && statusEpochIsCurrent(statusEpoch.current, dropStatusEpoch)) setStatus(`Could not enable Finder image drops: ${String(error)}`);
    });
    return () => {
      disposed = true;
      unlistenEnter?.();
      unlistenLeave?.();
      unlistenDrop?.();
    };
  }, []);

  useEffect(() => {
    void applyCaptureShortcut(captureShortcut, true);
  }, []);

  useEffect(() => {
    let disposed = false;
    const startupStatusEpoch = statusEpoch.current.current;
    void invoke<BackendStatus>("screen_capture_permission_status")
      .then((result) => {
        if (disposed || !statusEpochIsCurrent(statusEpoch.current, startupStatusEpoch)) return;
        setStatus(result.message);
      })
      .catch((error) => {
        if (!disposed && statusEpochIsCurrent(statusEpoch.current, startupStatusEpoch)) setStatus(`Could not check Screen Recording permission: ${String(error)}`);
      });
    return () => {
      disposed = true;
    };
  }, []);

  useEffect(() => {
    let disposed = false;
    let unlisten: (() => void) | undefined;
    const refreshPermissionStatus = () => {
      if (disposed || nativeOperationInFlight.current || permissionStatusRefreshInFlight.current) return;
      permissionStatusRefreshInFlight.current = true;
      const focusStatusEpoch = beginStatusEpoch(statusEpoch.current);
      void invoke<BackendStatus>("screen_capture_permission_status")
        .then((result) => {
          if (disposed || !statusEpochIsCurrent(statusEpoch.current, focusStatusEpoch)) return;
          setStatus(result.message);
        })
        .catch((error) => {
          if (!disposed && statusEpochIsCurrent(statusEpoch.current, focusStatusEpoch)) {
            setStatus(`Could not refresh Screen Recording permission: ${String(error)}`);
          }
        })
        .finally(() => {
          permissionStatusRefreshInFlight.current = false;
        });
    };
    const registerFocusListener = async () => {
      const stopListening = await getCurrentWindow().onFocusChanged(({ payload: focused }) => {
        if (focused) refreshPermissionStatus();
      });
      if (disposed) {
        stopListening();
        return;
      }
      unlisten = stopListening;
    };
    void registerFocusListener().catch((error) => {
      if (!disposed && !nativeOperationInFlight.current) {
        setStatus(`Could not monitor ShotEye focus for Screen Recording updates: ${String(error)}`);
      }
    });
    return () => {
      disposed = true;
      unlisten?.();
    };
  }, []);

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (capturing || recordingShortcut || shortcutRegistrationBusy) return;
      const target = event.target;
      if (target instanceof HTMLElement && (target.isContentEditable || ["INPUT", "TEXTAREA", "SELECT"].includes(target.tagName))) return;
      if (event.key === "Escape" && draft) {
        setDraft(null);
        beginUserStatusAction();
        setStatus("Annotation cancelled.");
      }
      if (event.key === "Escape" && cropDraft) {
        setCropDraft(null);
        beginUserStatusAction();
        setStatus("Crop cancelled.");
      }
      if (event.key === "Escape" && moveDraftRef.current) {
        moveDraftRef.current = null;
        setMoveDraft(null);
        beginUserStatusAction();
        setStatus("Move cancelled.");
      }
      if (event.key === "Escape" && resizeDraftRef.current) {
        resizeDraftRef.current = null;
        setResizeDraft(null);
        beginUserStatusAction();
        setStatus("Resize cancelled.");
      }
      const action = editorShortcutAction(event);
      if (!action) return;
      if (action === "delete" && !selectedAnnotationId) return;
      event.preventDefault();
      if (action === "undo" || action === "redo" || action === "delete") {
        setDraft(null);
        dispatchEditorMutation(action);
      } else if (action === "copy") {
        void copyCapture();
      } else if (action === "save") {
        void saveCapture();
      } else if (action === "open") {
        void openImage();
      } else if (action === "paste") {
        void importClipboardImage();
      } else if (action === "repeat") {
        void repeatLastCapture();
      }
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [capturing, recordingShortcut, shortcutRegistrationBusy, draft, cropDraft, selectedAnnotationId, capture]);

  function annotationFromPointer(event: React.PointerEvent<SVGElement>) {
    if (!imageSize) return null;
    const svg = event.currentTarget instanceof SVGSVGElement ? event.currentTarget : event.currentTarget.ownerSVGElement;
    if (!svg) return null;
    return pointFromPointer(event.nativeEvent, svg.getBoundingClientRect(), imageSize.width, imageSize.height);
  }

  function beginResize(event: React.PointerEvent<SVGCircleElement>, id: string, handle: ResizeHandle) {
    const annotation = annotations.find((current) => current.id === id);
    const point = annotationFromPointer(event);
    if (!annotation || !point) return;
    event.preventDefault();
    event.stopPropagation();
    const nextResizeDraft = { id, handle, origin: point, originAnnotation: annotation, annotation };
    resizeDraftRef.current = nextResizeDraft;
    setResizeDraft(nextResizeDraft);
    setSelectedAnnotationId(id);
    event.currentTarget.ownerSVGElement?.setPointerCapture(event.pointerId);
    beginUserStatusAction();
    setStatus("Resizing selected annotation. Release to commit.");
  }

  function beginAnnotation(event: React.PointerEvent<SVGSVGElement>) {
    if (!capture || !imageSize) return;
    const point = annotationFromPointer(event);
    if (!point) return;
    beginUserStatusAction();
    if (selectedTool === "Select") {
      const id = findAnnotationAtPoint(annotations, point);
      setSelectedAnnotationId(id);
      const annotation = id ? annotations.find((current) => current.id === id) : undefined;
      if (id && annotation) {
        event.preventDefault();
        event.currentTarget.setPointerCapture(event.pointerId);
        const nextMoveDraft = { id, origin: point, originAnnotation: annotation, annotation };
        moveDraftRef.current = nextMoveDraft;
        setMoveDraft(nextMoveDraft);
      }
      setStatus(id ? "Annotation selected. Press Delete to remove it." : "No annotation selected.");
      return;
    }
    setSelectedAnnotationId(null);
    if (selectedTool === "Crop") {
      event.preventDefault();
      event.currentTarget.setPointerCapture(event.pointerId);
      setCropDraft({ start: point, end: point });
      setStatus("Drag to crop. Press Escape to cancel.");
      return;
    }
    if (!annotationTools.has(selectedTool as AnnotationTool)) return;
    event.preventDefault();
    event.currentTarget.setPointerCapture(event.pointerId);
    const base = { id: annotationId(), color, stroke };
    if (selectedTool === "Text") {
      const annotation: Annotation = { ...base, kind: "text", point, text };
      if (isMeaningfulAnnotation(annotation)) {
        addAnnotation(annotation);
        setStatus("Text annotation added.");
      }
      return;
    }
    setDraft(selectedTool === "Draw"
      ? { ...base, kind: "draw", points: [point] }
      : { ...base, kind: selectedTool === "Arrow" ? "arrow" : selectedTool === "Redact" ? "redact" : selectedTool === "Pixelate" ? "pixelate" : selectedTool === "Blur" ? "blur" : "rectangle", start: point, end: point });
  }

  function moveAnnotation(event: React.PointerEvent<SVGSVGElement>) {
    if (cropDraft) {
      const point = annotationFromPointer(event);
      if (point) setCropDraft((current) => current ? { ...current, end: point } : current);
      return;
    }
    const activeResizeDraft = resizeDraftRef.current;
    if (activeResizeDraft) {
      const point = annotationFromPointer(event);
      if (point) {
        const nextResizeDraft = {
          ...activeResizeDraft,
          annotation: resizeAnnotation(activeResizeDraft.originAnnotation, activeResizeDraft.handle, point),
        };
        resizeDraftRef.current = nextResizeDraft;
        setResizeDraft(nextResizeDraft);
      }
      return;
    }
    const activeMoveDraft = moveDraftRef.current;
    if (activeMoveDraft) {
      const point = annotationFromPointer(event);
      if (point) {
        const nextMoveDraft = {
          ...activeMoveDraft,
          annotation: translateAnnotation(activeMoveDraft.originAnnotation, { x: point.x - activeMoveDraft.origin.x, y: point.y - activeMoveDraft.origin.y }),
        };
        moveDraftRef.current = nextMoveDraft;
        setMoveDraft(nextMoveDraft);
      }
      return;
    }
    if (!draft) return;
    const point = annotationFromPointer(event);
    if (!point) return;
    setDraft((current) => {
      if (!current) return current;
      return current.kind === "draw"
        ? { ...current, points: [...current.points, point] }
        : { ...current, end: point };
    });
  }

  function finishAnnotation(event: React.PointerEvent<SVGSVGElement>) {
    if (cropDraft) {
      if (event.currentTarget.hasPointerCapture(event.pointerId)) event.currentTarget.releasePointerCapture(event.pointerId);
      const point = annotationFromPointer(event);
      const completed = point ? { ...cropDraft, end: point } : cropDraft;
      setCropDraft(null);
      void applyCrop(completed);
      return;
    }
    const activeResizeDraft = resizeDraftRef.current;
    if (activeResizeDraft) {
      if (event.currentTarget.hasPointerCapture(event.pointerId)) event.currentTarget.releasePointerCapture(event.pointerId);
      const point = annotationFromPointer(event);
      const finalAnnotation = point
        ? resizeAnnotation(activeResizeDraft.originAnnotation, activeResizeDraft.handle, point)
        : activeResizeDraft.annotation;
      const moved = point && Math.hypot(point.x - activeResizeDraft.origin.x, point.y - activeResizeDraft.origin.y) >= 1;
      if (moved && isMeaningfulAnnotation(finalAnnotation)) {
        applyAnnotationHistory(replaceAnnotation(annotationHistory.current, finalAnnotation));
        beginUserStatusAction();
        setStatus("Resized selected annotation.");
      } else if (moved) {
        beginUserStatusAction();
        setStatus("Resize cancelled: annotation is too small.");
      }
      resizeDraftRef.current = null;
      setResizeDraft(null);
      return;
    }
    const activeMoveDraft = moveDraftRef.current;
    if (activeMoveDraft) {
      if (event.currentTarget.hasPointerCapture(event.pointerId)) event.currentTarget.releasePointerCapture(event.pointerId);
      const point = annotationFromPointer(event);
      const finalAnnotation = point
        ? translateAnnotation(activeMoveDraft.originAnnotation, { x: point.x - activeMoveDraft.origin.x, y: point.y - activeMoveDraft.origin.y })
        : activeMoveDraft.annotation;
      if (point && Math.hypot(point.x - activeMoveDraft.origin.x, point.y - activeMoveDraft.origin.y) >= 1) {
        applyAnnotationHistory(replaceAnnotation(annotationHistory.current, finalAnnotation));
        beginUserStatusAction();
        setStatus("Moved selected annotation.");
      }
      moveDraftRef.current = null;
      setMoveDraft(null);
      return;
    }
    if (!draft) return;
    if (event.currentTarget.hasPointerCapture(event.pointerId)) event.currentTarget.releasePointerCapture(event.pointerId);
    const completed = draft.kind === "draw" ? (() => {
      const point = annotationFromPointer(event);
      return point ? { ...draft, points: [...draft.points, point] } : draft;
    })() : (() => {
      const point = annotationFromPointer(event);
      return point ? { ...draft, end: point } : draft;
    })();
    setDraft(null);
    if (isMeaningfulAnnotation(completed)) {
      addAnnotation(completed);
      beginUserStatusAction();
      setStatus(`${completed.kind === "arrow" ? "Arrow" : completed.kind === "rectangle" ? "Rectangle" : completed.kind === "redact" ? "Redact" : completed.kind === "pixelate" ? "Pixelate" : completed.kind === "blur" ? "Blur" : "Draw"} annotation added.`);
    }
  }

  async function applyCrop(crop: CropRectangle) {
    const currentCapture = captureRef.current;
    const currentImageSize = imageSizeRef.current;
    const currentAnnotations = annotationsRef.current;
    if (!currentCapture || !currentImageSize) return;
    beginUserStatusAction();
    await runExclusiveAction(nativeOperationInFlight, async () => {
      beginNativeOperation("import");
      const cropStatusEpoch = statusEpoch.current.current;
      const commitStatus = (message: string) => {
        if (statusEpochIsCurrent(statusEpoch.current, cropStatusEpoch)) setStatus(message);
      };
      const bounds = cropBounds(crop);
      const width = Math.round(bounds.width);
      const height = Math.round(bounds.height);
      try {
        if (width < 3 || height < 3) {
          commitStatus("Crop is too small. Drag a larger rectangle.");
          return;
        }
        const dataUrl = await resolveAtStableRevision(
          () => imageEditRevision.current,
          async () => {
            const image = new Image();
            image.src = currentCapture;
            await new Promise<void>((resolve, reject) => {
              image.onload = () => resolve();
              image.onerror = () => reject(new Error("ShotEye could not prepare the crop."));
            });
            const composite = document.createElement("canvas");
            composite.width = currentImageSize.width;
            composite.height = currentImageSize.height;
            const compositeContext = composite.getContext("2d");
            const cropped = document.createElement("canvas");
            cropped.width = width;
            cropped.height = height;
            const croppedContext = cropped.getContext("2d");
            if (!compositeContext || !croppedContext) throw new Error("ShotEye could not create a crop canvas.");
            compositeContext.drawImage(image, 0, 0, composite.width, composite.height);
            currentAnnotations.forEach((annotation) => renderAnnotation(compositeContext, annotation));
            croppedContext.drawImage(composite, Math.round(bounds.left), Math.round(bounds.top), width, height, 0, 0, width, height);
            return cropped.toDataURL("image/png");
          },
        );
        if (dataUrl === null) return;
        // Keep Rust's canonical export record unchanged until Copy, Save, or
        // Drag prepares the latest stable revision. This avoids a stale crop
        // write racing Reset or a newer annotation while the IPC call awaits.
        setCapture(dataUrl);
        setImageSize({ width, height });
        resetAnnotationHistory();
        setDraft(null);
        setZoom(100);
        commitStatus(`Cropped image to ${width}×${height}px. Reset restores the original.`);
      } catch (error) {
        commitStatus(`Crop error: ${String(error)}`);
      } finally {
        finishNativeOperation();
      }
    }, () => {
      beginUserStatusAction();
      setStatus("Finish the current ShotEye operation before applying a crop.");
    });
  }

  async function renderedCaptureDataUrl() {
    const currentCapture = captureRef.current;
    const currentImageSize = imageSizeRef.current;
    if (!currentCapture || !currentImageSize) throw new Error("Capture an image before exporting.");
    const image = new Image();
    image.src = currentCapture;
    await new Promise<void>((resolve, reject) => {
      image.onload = () => resolve();
      image.onerror = () => reject(new Error("ShotEye could not render the captured image."));
    });
    const canvas = document.createElement("canvas");
    canvas.width = currentImageSize.width;
    canvas.height = currentImageSize.height;
    const context = canvas.getContext("2d");
    if (!context) throw new Error("ShotEye could not create an export canvas.");
    context.drawImage(image, 0, 0, canvas.width, canvas.height);
    annotationsRef.current.forEach((annotation) => renderAnnotation(context, annotation));
    return canvas.toDataURL("image/png");
  }

  async function prepareRenderedExport(revision: number) {
    const cached = preparedExportForRevision(preparedExportRef.current, revision);
    if (cached) return cached;
    const dataUrl = await renderedCaptureDataUrl();
    if (revision !== dragExportRevision.current) return null;
    const prepared = { revision, dataUrl };
    preparedExportRef.current = prepared;
    return prepared;
  }

  function queueExportPreparation(revision: number) {
    const queued = exportQueue.current.then(async () => {
      if (revision !== dragExportRevision.current) return;
      await prepareRenderedExport(revision);
    });
    // Keep the queue usable after a failed background preparation. The caller
    // still receives the rejection and can show the actionable error.
    exportQueue.current = queued.catch(() => undefined);
    return queued;
  }

  async function prepareLatestExport() {
    return prepareAtStableRevision(
      () => dragExportRevision.current,
      async (revision) => {
        await queueExportPreparation(revision);
        const prepared = preparedExportForRevision(preparedExportRef.current, revision);
        if (!prepared) throw new Error("The capture changed while the export was being prepared. Try again.");
        const result = await invoke<BackendStatus>("store_rendered_capture", { dataUrl: prepared.dataUrl });
        if (result.message.startsWith("Could not")) throw new Error(result.message);
      },
    );
  }

  async function copyCapture() {
    beginUserStatusAction();
    if (!capture) {
      setStatus("Capture an image before copying.");
      return;
    }
    const exportStatusEpoch = statusEpoch.current.current;
    const commitStatus = (message: string) => {
      if (statusEpochIsCurrent(statusEpoch.current, exportStatusEpoch)) setStatus(message);
    };
    await runExclusiveAction(nativeOperationInFlight, async () => {
      beginNativeOperation("export", "copy");
      try {
        commitStatus("Preparing capture for Copy…");
        await prepareLatestExport();
        commitStatus("Copying capture…");
        const result = await invoke<BackendStatus>("copy_capture");
        commitStatus(result.message);
      } catch (error) {
        commitStatus(`Copy error: ${String(error)}`);
      } finally {
        finishNativeOperation();
      }
    }, () => {
      beginUserStatusAction();
      setStatus("Finish the current ShotEye operation before starting another one.");
    });
  }

  async function saveCapture() {
    beginUserStatusAction();
    if (!capture) {
      setStatus("Capture an image before saving.");
      return;
    }
    const exportStatusEpoch = statusEpoch.current.current;
    const commitStatus = (message: string) => {
      if (statusEpochIsCurrent(statusEpoch.current, exportStatusEpoch)) setStatus(message);
    };
    await runExclusiveAction(nativeOperationInFlight, async () => {
      beginNativeOperation("export", "save-dialog");
      try {
        const path = await save({
          defaultPath: "ShotEye Capture.png",
          filters: [
            { name: "PNG image", extensions: ["png"] },
            { name: "JPEG image", extensions: ["jpg", "jpeg"] },
            { name: "TIFF image", extensions: ["tif", "tiff"] },
          ],
        });
        if (!path) {
          commitStatus("Save cancelled.");
          return;
        }
        // The Save dialog is user-controlled and the editor remains usable
        // while it is open. Prepare only after the destination is selected so
        // annotations made during that dialog cannot be exported stale.
        setNativeOperationPhase("save");
        commitStatus("Preparing capture for Save…");
        await prepareLatestExport();
        commitStatus("Saving capture…");
        const result = await invoke<BackendStatus>("save_capture", { path });
        commitStatus(result.message);
      } catch (error) {
        commitStatus(`Save error: ${String(error)}`);
      } finally {
        finishNativeOperation();
      }
    }, () => {
      beginUserStatusAction();
      setStatus("Finish the current ShotEye operation before starting another one.");
    });
  }

  function beginDragOut(event: React.PointerEvent<HTMLButtonElement>) {
    if (event.button !== 0 || dragOutInFlight.current) return;
    event.preventDefault();
    beginUserStatusAction();
    if (nativeOperationInFlight.current) {
      setStatus("Finish the current ShotEye operation before starting another one.");
      return;
    }
    if (!capture) {
      setStatus("Capture an image before dragging it out.");
      return;
    }
    nativeOperationInFlight.current = true;
    beginNativeOperation("export", "drag");
    dragOutInFlight.current = true;
    const exportStatusEpoch = statusEpoch.current.current;
    const commitStatus = (message: string) => {
      if (statusEpochIsCurrent(statusEpoch.current, exportStatusEpoch)) setStatus(message);
    };
    commitStatus(dragExportReady.current ? "Starting drag-out…" : "Preparing the latest capture for drag-out…");
    void prepareLatestExport()
      .then(() => {
        if (!captureRef.current || !imageSizeRef.current) throw new Error("The capture changed before drag-out was ready.");
        dragExportReady.current = true;
        return invoke<BackendStatus>("drag_out_capture", {
          sourceX: event.clientX,
          sourceY: event.clientY,
        });
      })
      .then((result) => {
        commitStatus(result.message);
      })
      .catch((error) => commitStatus(`Drag-out error: ${String(error)}`))
      .finally(() => {
        dragOutInFlight.current = false;
        finishNativeOperation();
        nativeOperationInFlight.current = false;
      });
  }

  menuHandlers.current = {
    open: () => { void openImage(); },
    paste: () => { void importClipboardImage(); },
    copy: () => { void copyCapture(); },
    save: () => { void saveCapture(); },
    "capture-area": () => { void captureArea(); },
    "capture-window": () => { void captureWindow(); },
    "capture-fullscreen": () => { void captureFullscreen(); },
    "repeat-capture": () => { void repeatLastCapture(); },
    "tool-select": () => { selectEditorTool("Select"); },
    "tool-crop": () => { selectEditorTool("Crop"); },
    "tool-arrow": () => { selectEditorTool("Arrow"); },
    "tool-rectangle": () => { selectEditorTool("Rectangle"); },
    "tool-text": () => { selectEditorTool("Text"); },
    "tool-draw": () => { selectEditorTool("Draw"); },
    "tool-redact": () => { selectEditorTool("Redact"); },
    "tool-pixelate": () => { selectEditorTool("Pixelate"); },
    "tool-blur": () => { selectEditorTool("Blur"); },
    undo: () => { dispatchEditorMutation("undo"); },
    redo: () => { dispatchEditorMutation("redo"); },
    clear: () => { dispatchEditorMutation("clear"); },
    reset: () => { dispatchEditorMutation("reset"); },
    permissions: () => { void requestScreenRecordingPermission(); },
    "screen-recording-settings": () => { void openScreenRecordingSettings(); },
  };

  useEffect(() => {
    let disposed = false;
    const startupStatusEpoch = statusEpoch.current.current;
    let menu: Menu | null = null;
    void installNativeMenu()
      .then(async (installed) => {
        if (disposed) {
          await installed.close();
          return;
        }
        menu = installed;
        await installed.setAsAppMenu();
      })
    .catch((error) => {
        if (!disposed && statusEpochIsCurrent(statusEpoch.current, startupStatusEpoch)) setStatus(`Could not install the ShotEye menu: ${String(error)}`);
      });
    return () => {
      disposed = true;
      void menu?.close();
    };
  }, []);

  useEffect(() => {
    if (!capture || !imageSize) {
      dragExportRevision.current += 1;
      preparedExportRef.current = null;
      dragExportReady.current = false;
      return;
    }
    const revision = ++dragExportRevision.current;
    preparedExportRef.current = null;
    dragExportReady.current = false;
    const timer = window.setTimeout(() => {
      void queueExportPreparation(revision)
        .then(() => {
          if (revision === dragExportRevision.current) dragExportReady.current = true;
        })
        .catch(() => {
          if (revision !== dragExportRevision.current) return;
          dragExportReady.current = false;
          // Background prewarming must not publish stale status or native image
          // state. A user-triggered Drag retries under the exclusive operation
          // lane and reports its own actionable error.
        });
    }, 180);
    return () => window.clearTimeout(timer);
  }, [capture, imageSize, annotations]);

  const selectedAnnotation = selectedAnnotationId ? annotations.find((annotation) => annotation.id === selectedAnnotationId) : undefined;
  const handleAnnotation = resizeDraft?.id === selectedAnnotationId
    ? resizeDraft.annotation
    : moveDraft?.id === selectedAnnotationId
      ? moveDraft.annotation
      : selectedAnnotation;

  return (
    <main className="shoteye-shell">
      <section className="toolbar" aria-label="ShotEye toolbar">
        <button onClick={openImage} disabled={actionBusy} aria-label="Open image" aria-keyshortcuts={ariaKeyShortcuts(shotEyeShortcuts.open)} title={`Open image (${displayShortcut(shotEyeShortcuts.open)})`}><ToolbarIcon name="open" /><span>Open</span><ShortcutHint shortcut={shotEyeShortcuts.open} /></button>
        <button onClick={importClipboardImage} disabled={actionBusy} aria-label="Import clipboard image" aria-keyshortcuts={ariaKeyShortcuts(shotEyeShortcuts.paste)} title={`Paste image (${displayShortcut(shotEyeShortcuts.paste)})`}><ToolbarIcon name="paste" /><span>Paste</span><ShortcutHint shortcut={shotEyeShortcuts.paste} /></button>
        <button onClick={copyCapture} disabled={actionBusy} aria-label="Copy capture" aria-keyshortcuts={ariaKeyShortcuts(shotEyeShortcuts.copy)} title={`Copy capture (${displayShortcut(shotEyeShortcuts.copy)})`}><ToolbarIcon name="copy" /><span>Copy</span><ShortcutHint shortcut={shotEyeShortcuts.copy} /></button>
        <button onClick={saveCapture} disabled={actionBusy} aria-label="Save capture" aria-keyshortcuts={ariaKeyShortcuts(shotEyeShortcuts.save)} title={`Save capture (${displayShortcut(shotEyeShortcuts.save)})`}><ToolbarIcon name="save" /><span>Save</span><ShortcutHint shortcut={shotEyeShortcuts.save} /></button>
        <button onPointerDown={beginDragOut} disabled={actionBusy} aria-label="Drag capture out"><ToolbarIcon name="drag" /><span>Drag</span></button>
        <div className="divider" />
        {tools.map((tool) => <button disabled={editorMutationBusy} className={selectedTool === tool ? "active" : ""} key={tool} onClick={() => { selectEditorTool(tool); }}>{tool}</button>)}
        <div className="divider" />
        <label className="tool-control" title="Annotation color"><input disabled={editorMutationBusy} aria-label="Annotation color" type="color" value={color} onChange={(event) => setColor(event.target.value)} /></label>
        <label className="tool-control stroke-control" title="Stroke width"><span>Stroke</span><input disabled={editorMutationBusy} aria-label="Stroke width" type="range" min="2" max="12" value={stroke} onChange={(event) => setStroke(Number(event.target.value))} /></label>
        {selectedTool === "Text" && <label className="tool-control text-control"><span>Text</span><input disabled={editorMutationBusy} aria-label="Annotation text" value={text} onChange={(event) => setText(event.target.value)} /></label>}
        <button disabled={editorMutationBusy || undoDepth === 0} onClick={() => { dispatchEditorMutation("undo"); }} aria-keyshortcuts={ariaKeyShortcuts(shotEyeShortcuts.undo)} title={`Undo annotation (${displayShortcut(shotEyeShortcuts.undo)})`}>Undo<ShortcutHint shortcut={shotEyeShortcuts.undo} /></button>
        <button disabled={editorMutationBusy || redoAnnotations.length === 0} onClick={() => { dispatchEditorMutation("redo"); }} aria-keyshortcuts={ariaKeyShortcuts(shotEyeShortcuts.redo)} title={`Redo annotation (${displayShortcut(shotEyeShortcuts.redo)})`}>Redo<ShortcutHint shortcut={shotEyeShortcuts.redo} /></button>
        <button disabled={editorMutationBusy || annotations.length === 0} onClick={() => { dispatchEditorMutation("clear"); }}>Clear</button>
        <button disabled={editorMutationBusy || !originalCapture} onClick={() => { dispatchEditorMutation("reset"); }} aria-label="Reset image and edits">Reset</button>
        <label className="tool-control zoom-control"><span>Zoom</span><input disabled={editorMutationBusy} aria-label="Zoom" type="range" min="50" max="150" value={zoom} onChange={(event) => setZoom(Number(event.target.value))} /><output>{zoom}%</output></label>
        <div className="divider" />
        <button onClick={repeatLastCapture} disabled={actionBusy} aria-label="Repeat last capture" aria-keyshortcuts={ariaKeyShortcuts(shotEyeShortcuts.repeat)} title={`Repeat last capture (${displayShortcut(shotEyeShortcuts.repeat)})`}><ToolbarIcon name="repeat" /><span>Repeat</span><ShortcutHint shortcut={shotEyeShortcuts.repeat} /></button>
        <button onClick={togglePinned} disabled={actionBusy} className={pinned ? "active" : ""} aria-label={pinned ? "Unpin ShotEye" : "Pin ShotEye"} aria-pressed={pinned}><ToolbarIcon name="pin" /><span>{pinned ? "Pinned" : "Pin"}</span></button>
        <button onClick={captureWindow} disabled={actionBusy} aria-label="Capture a window"><ToolbarIcon name="window" /><span>Window</span></button>
        <button onClick={captureFullscreen} disabled={actionBusy} aria-label="Capture full screen"><ToolbarIcon name="fullscreen" /><span>Full screen</span></button>
        <button onClick={captureArea} disabled={actionBusy} className="primary">{capturing ? "Selecting…" : "Capture area"}</button>
        <button onClick={requestScreenRecordingPermission} disabled={actionBusy || permissionActionBusy} aria-label="Request Screen Recording permission">{permissionActionBusy ? "Requesting…" : "Permissions"}</button>
        <button onClick={openScreenRecordingSettings} disabled={actionBusy || permissionActionBusy} aria-label="Open Screen Recording settings">Open settings</button>
        <div className="tool-control shortcut-control" aria-label="Global capture shortcut settings"><span>Capture</span><button type="button" disabled={actionBusy} className={recordingShortcut ? "active" : ""} aria-label="Record capture shortcut" title={`Record capture shortcut (${displayShortcut(captureShortcut)})`} onClick={() => { setRecordingShortcut((recording) => !recording); beginUserStatusAction(); setStatus("Press a modifier-key combination for Capture area."); }} onKeyDown={(event) => { if (!recordingShortcut) return; const shortcut = shortcutFromKeyboardEvent(event); if (!shortcut) { beginUserStatusAction(); setStatus("Use Command, Control, Option, or Shift with a letter, number, function, punctuation, or Space key."); return; } event.preventDefault(); setRecordingShortcut(false); void applyCaptureShortcut(shortcut); }}>{recordingShortcut ? "Press keys…" : displayShortcut(captureShortcut)}</button><button type="button" disabled={actionBusy} aria-label="Reset capture shortcut to default" title={`Reset capture shortcut to ${displayShortcut(defaultCaptureShortcut)}`} onClick={() => { void applyCaptureShortcut(defaultCaptureShortcut); }}>Default</button><span className={`shortcut-state shortcut-state-${shortcutRegistrationState}`} data-testid="shortcut-status">{shortcutRegistrationLabel(shortcutRegistrationState, shortcutRegistrationBusy)}</span></div>
      </section>
      <section className={`canvas${fileDropActive ? " file-drop-active" : ""}`} aria-live="polite">
        {fileDropActive && <div className="drop-hint" role="status">Drop an image to open it</div>}
        {capture && imageSize ? <div className="capture-viewport"><div className="image-stage" style={{ aspectRatio: `${imageSize.width} / ${imageSize.height}`, transform: `scale(${zoom / 100})` }}><img className="capture-preview" src={capture} alt="Latest area capture" /><svg className={`annotation-layer ${selectedTool === "Select" ? "selecting" : ""}`} viewBox={`0 0  ${imageSize.width} ${imageSize.height}`} onPointerDown={beginAnnotation} onPointerMove={moveAnnotation} onPointerUp={finishAnnotation} onPointerCancel={(event) => { if (event.currentTarget.hasPointerCapture(event.pointerId)) event.currentTarget.releasePointerCapture(event.pointerId); setDraft(null); setCropDraft(null); moveDraftRef.current = null; setMoveDraft(null); resizeDraftRef.current = null; setResizeDraft(null); beginUserStatusAction(); setStatus("Annotation cancelled."); }}>
          {[...annotations, ...(draft ? [draft] : [])].map((annotation) => {
            const visibleAnnotation = moveDraft?.id === annotation.id ? moveDraft.annotation : annotation;
            const selectedClass = selectedAnnotationId === visibleAnnotation.id ? "annotation-selected" : undefined;
            if (visibleAnnotation.kind === "rectangle") return <rect className={selectedClass} key={visibleAnnotation.id} x={Math.min(visibleAnnotation.start.x, visibleAnnotation.end.x)} y={Math.min(visibleAnnotation.start.y, visibleAnnotation.end.y)} width={Math.abs(visibleAnnotation.end.x - visibleAnnotation.start.x)} height={Math.abs(visibleAnnotation.end.y - visibleAnnotation.start.y)} fill="transparent" stroke={visibleAnnotation.color} strokeWidth={visibleAnnotation.stroke} />;
            if (visibleAnnotation.kind === "redact") return <rect className={selectedClass} key={visibleAnnotation.id} x={Math.min(visibleAnnotation.start.x, visibleAnnotation.end.x)} y={Math.min(visibleAnnotation.start.y, visibleAnnotation.end.y)} width={Math.abs(visibleAnnotation.end.x - visibleAnnotation.start.x)} height={Math.abs(visibleAnnotation.end.y - visibleAnnotation.start.y)} fill="#000000" stroke="#000000" strokeWidth={visibleAnnotation.stroke} />;
            if (visibleAnnotation.kind === "pixelate") {
              const left = Math.min(visibleAnnotation.start.x, visibleAnnotation.end.x);
              const top = Math.min(visibleAnnotation.start.y, visibleAnnotation.end.y);
              const width = Math.abs(visibleAnnotation.end.x - visibleAnnotation.start.x);
              const height = Math.abs(visibleAnnotation.end.y - visibleAnnotation.start.y);
              const patternId = `pixelate-${visibleAnnotation.id}`;
              return <g className={selectedClass} key={visibleAnnotation.id}><defs><pattern id={patternId} width="16" height="16" patternUnits="userSpaceOnUse"><rect width="16" height="16" fill="#252b2d" /><rect width="8" height="8" fill={visibleAnnotation.color} opacity=".8" /><rect x="8" y="8" width="8" height="8" fill={visibleAnnotation.color} opacity=".55" /></pattern></defs><rect x={left} y={top} width={width} height={height} fill={`url(#${patternId})`} stroke={visibleAnnotation.color} strokeWidth={visibleAnnotation.stroke} /></g>;
            }
            if (visibleAnnotation.kind === "blur") {
              const left = Math.min(visibleAnnotation.start.x, visibleAnnotation.end.x);
              const top = Math.min(visibleAnnotation.start.y, visibleAnnotation.end.y);
              const width = Math.abs(visibleAnnotation.end.x - visibleAnnotation.start.x);
              const height = Math.abs(visibleAnnotation.end.y - visibleAnnotation.start.y);
              const clipId = `blur-clip-${visibleAnnotation.id}`;
              const filterId = `blur-filter-${visibleAnnotation.id}`;
              return <g className={selectedClass} key={visibleAnnotation.id}><defs><clipPath id={clipId}><rect x={left} y={top} width={width} height={height} /></clipPath><filter id={filterId} x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation={Math.max(2, visibleAnnotation.stroke * 1.5)} /></filter></defs><image href={capture ?? undefined} x="0" y="0" width={imageSize.width} height={imageSize.height} preserveAspectRatio="none" clipPath={`url(#${clipId})`} filter={`url(#${filterId})`} pointerEvents="none" /><rect x={left} y={top} width={width} height={height} fill="transparent" stroke={visibleAnnotation.color} strokeWidth={visibleAnnotation.stroke} /></g>;
            }
            if (visibleAnnotation.kind === "arrow") return <g className={selectedClass} key={visibleAnnotation.id} fill="none" stroke={visibleAnnotation.color} strokeWidth={visibleAnnotation.stroke} strokeLinecap="round" strokeLinejoin="round"><line x1={visibleAnnotation.start.x} y1={visibleAnnotation.start.y} x2={visibleAnnotation.end.x} y2={visibleAnnotation.end.y} /><polyline points={arrowHeadPoints(visibleAnnotation.start, visibleAnnotation.end, visibleAnnotation.stroke)} /></g>;
            if (visibleAnnotation.kind === "draw") return <path className={selectedClass} key={visibleAnnotation.id} d={svgPath(visibleAnnotation.points)} fill="none" stroke={visibleAnnotation.color} strokeWidth={visibleAnnotation.stroke} strokeLinecap="round" strokeLinejoin="round" />;
            return <text className={selectedClass} key={visibleAnnotation.id} x={visibleAnnotation.point.x} y={visibleAnnotation.point.y} fill={visibleAnnotation.color} fontSize={Math.max(14, visibleAnnotation.stroke * 6)} fontFamily="-apple-system, BlinkMacSystemFont, sans-serif" dominantBaseline="hanging">{visibleAnnotation.text}</text>;
          })}
          {cropDraft && (() => { const bounds = cropBounds(cropDraft); return <rect className="crop-guide" x={bounds.left} y={bounds.top} width={bounds.width} height={bounds.height} />; })()}
          {selectedTool === "Select" && handleAnnotation && resizeHandlePoints(handleAnnotation).length > 0 && <g className="annotation-handles" aria-label="Resize handles">
            {resizeHandlePoints(handleAnnotation).map(({ handle, point }) => <circle key={handle} className="annotation-handle" data-handle={handle} cx={point.x} cy={point.y} r={Math.max(7, handleAnnotation.stroke + 3)} fill="#ffffff" stroke={handleAnnotation.color} strokeWidth={2} onPointerDown={(event) => beginResize(event, handleAnnotation.id, handle)} />)}
          </g>}
        </svg></div></div> : <div className="empty-state"><h1>Ready to capture</h1><p>Choose an area across any connected display. ShotEye will validate and preview the image, then you can annotate, Copy, or Save it.</p></div>}
      </section>
      {captureHistory.length > 0 && <section className="history" aria-label="Capture history">
        <div className="history-heading"><strong>Recent captures</strong><span>{captureHistory.length} saved this session</span><button type="button" onClick={clearCaptureHistory} disabled={actionBusy} aria-label="Clear capture history">Clear history</button></div>
        <div className="history-list">
          {captureHistory.map((entry, index) => <button
            type="button"
            className="history-item"
            key={entry.id}
            disabled={actionBusy}
            aria-label={`Restore capture ${index + 1}: ${entry.width}×${entry.height}px`}
            aria-current={entry.dataUrl === capture ? "true" : undefined}
            onClick={() => { void restoreCaptureFromHistory(entry); }}
          >
            <img src={entry.dataUrl} alt="" aria-hidden="true" />
            <span>{entry.width}×{entry.height}px</span>
          </button>)}
        </div>
      </section>}
      <footer className="status" data-testid="status" role="status" aria-live="polite"><span>{status}</span>{nativeOperationPhase && <span data-testid="operation-state" className="operation-state" aria-live="polite">{nativeOperationLabel(nativeOperationPhase)}</span>}<span>{annotations.length} annotation{annotations.length === 1 ? "" : "s"} · Capture: {displayShortcut(captureShortcut)}</span></footer>
    </main>
  );
}

export default App;
