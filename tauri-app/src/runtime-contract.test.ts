import { describe, expect, it } from "vitest";
import { runtimeContractReportPayload } from "./runtime-contract";

describe("runtimeContractReportPayload", () => {
  it("uses Tauri's camelCase command argument contract", () => {
    expect(runtimeContractReportPayload({
      actionSucceeded: true,
      restorationSucceeded: true,
      previewWidth: 32,
      previewHeight: 24,
    })).toEqual({
      actionSucceeded: true,
      restorationSucceeded: true,
      previewWidth: 32,
      previewHeight: 24,
    });
  });
});
