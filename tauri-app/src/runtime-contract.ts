export type RuntimeContractReportInput = {
  actionSucceeded: boolean;
  restorationSucceeded: boolean;
  previewWidth: number | null;
  previewHeight: number | null;
};

/** Tauri maps Rust command arguments to camelCase at the JavaScript boundary. */
export function runtimeContractReportPayload(input: RuntimeContractReportInput) {
  return {
    actionSucceeded: input.actionSucceeded,
    restorationSucceeded: input.restorationSucceeded,
    previewWidth: input.previewWidth,
    previewHeight: input.previewHeight,
  };
}
