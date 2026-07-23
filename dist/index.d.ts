export type PooFlowWasmLoadOptions = {
  readonly bytes?: BufferSource;
  readonly fetch?: typeof globalThis.fetch;
  readonly url?: string | URL;
};

export type PooFlowCompactId = {
  readonly high: bigint;
  readonly low: bigint;
  readonly key: string;
};

export type PooFlowTopologyComponent = {
  readonly caseId: PooFlowCompactId;
  readonly componentId: PooFlowCompactId;
  readonly objectId: PooFlowCompactId;
  readonly typeId: PooFlowCompactId;
  readonly contractId: PooFlowCompactId;
  readonly roleId: PooFlowCompactId;
  readonly capabilityId: PooFlowCompactId;
  readonly policyId: PooFlowCompactId;
  readonly strategyId: PooFlowCompactId;
  readonly adapterId: PooFlowCompactId;
  readonly projectionId: PooFlowCompactId;
  readonly compositionOrder: bigint;
  readonly flags: number;
};

export type PooFlowTopologyEdge = {
  readonly caseId: PooFlowCompactId;
  readonly sourceComponentId: PooFlowCompactId;
  readonly targetComponentId: PooFlowCompactId;
  readonly relationId: PooFlowCompactId;
  readonly compositionOrder: bigint;
  readonly flags: number;
};

export type PooFlowTopologySymbol = {
  readonly id: PooFlowCompactId;
  readonly value: string;
  readonly kind: number;
  readonly flags: number;
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

export declare class PooFlowTopology {
  constructor(exports: WebAssembly.Exports, handle: number);
  readonly released: boolean;
  readonly componentCount: number;
  readonly edgeCount: number;
  readonly symbolCount: number;
  componentAt(index: number): PooFlowTopologyComponent;
  edgeAt(index: number): PooFlowTopologyEdge;
  symbolAt(index: number): PooFlowTopologySymbol;
  components(): readonly PooFlowTopologyComponent[];
  edges(): readonly PooFlowTopologyEdge[];
  symbols(): readonly PooFlowTopologySymbol[];
  openCursor(): WorkflowCursorSession;
  release(): void;
}

export declare class PooFlowWasmRuntime {
  constructor(exports: WebAssembly.Exports);
  readonly handleCapacity: number;
  readonly workflowCursorCapacity: number;
  openTopology(input: {
    readonly descriptor: BufferSource;
    readonly arena: BufferSource;
  }): PooFlowTopology;
}

export declare const PFW_WASM_STATUS_INVALID_ARGUMENT = 0xffff0001;
export declare const PFW_WASM_STATUS_INVALID_SLOT = 0xffff0002;
export declare const PFW_WASM_STATUS_SLOT_EXHAUSTED = 0xffff0003;

export declare const loadPooFlowWasmRuntime: (
  options?: PooFlowWasmLoadOptions,
) => Promise<PooFlowWasmRuntime>;
