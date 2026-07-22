export type PooFlowWasmLoadOptions = {
  readonly bytes?: BufferSource;
  readonly fetch?: typeof globalThis.fetch;
  readonly url?: string | URL;
};

export type WorkflowCursorSnapshot = {
  readonly completedSteps: number;
  readonly stepCount: number;
};

export interface WorkflowCursorSession {
  readonly stepCount: number;
  readonly released: boolean;
  position(): WorkflowCursorSnapshot;
  step(): WorkflowCursorSnapshot;
  reset(): WorkflowCursorSnapshot;
  release(): void;
}

export declare class PooFlowWasmRuntime {
  constructor(exports: WebAssembly.Exports);
  readonly handleCapacity: number;
  readonly workflowCursorCapacity: number;
  openWorkflow(stepCount: number): WorkflowCursorSession;
}

export declare const PFW_WASM_STATUS_INVALID_ARGUMENT = 0xffff0001;
export declare const PFW_WASM_STATUS_INVALID_SLOT = 0xffff0002;
export declare const PFW_WASM_STATUS_SLOT_EXHAUSTED = 0xffff0003;

export declare const loadPooFlowWasmRuntime: (
  options?: PooFlowWasmLoadOptions,
) => Promise<PooFlowWasmRuntime>;
