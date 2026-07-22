export const PFW_WASM_STATUS_INVALID_ARGUMENT = 0xffff0001;
export const PFW_WASM_STATUS_INVALID_SLOT = 0xffff0002;
export const PFW_WASM_STATUS_SLOT_EXHAUSTED = 0xffff0003;

const defaultWasmUrl = new URL("./poo_flow_runtime.wasm", import.meta.url);

const instantiate = async ({ bytes, fetch: fetchImplementation, url = defaultWasmUrl } = {}) => {
  const imports = { env: { emscripten_notify_memory_growth() {} } };
  if (bytes != null) {
    return WebAssembly.instantiate(bytes, imports);
  }
  const fetchWasm = fetchImplementation ?? globalThis.fetch;
  if (typeof fetchWasm !== "function") {
    throw new Error("PFW-WASM-E001 fetch is unavailable; provide bytes or a fetch implementation");
  }
  const response = await fetchWasm(url);
  if (!response.ok) {
    throw new Error(`PFW-WASM-E002 failed to load runtime: ${response.status} ${response.statusText}`);
  }
  if (typeof WebAssembly.instantiateStreaming === "function") {
    return WebAssembly.instantiateStreaming(response, imports);
  }
  return WebAssembly.instantiate(await response.arrayBuffer(), imports);
};

const assertStatus = (status, operation) => {
  const normalizedStatus = status >>> 0;
  if (normalizedStatus !== 0) {
    throw new Error(
      `PFW-WASM-E003 ${operation} failed with status 0x${normalizedStatus.toString(16)}`,
    );
  }
};

class WorkflowCursorSession {
  #exports;
  #handle;
  #stepCount;
  #released = false;

  constructor(exports, handle, stepCount) {
    this.#exports = exports;
    this.#handle = handle;
    this.#stepCount = stepCount;
  }

  get stepCount() {
    return this.#stepCount;
  }

  get released() {
    return this.#released;
  }

  #withU32(count, operation) {
    if (this.#released) {
      throw new Error("PFW-WASM-E004 workflow cursor has been released");
    }
    const pointer = this.#exports.malloc(count * Uint32Array.BYTES_PER_ELEMENT);
    if (pointer === 0) {
      throw new Error("PFW-WASM-E005 workflow cursor allocation failed");
    }
    try {
      const status = operation(pointer);
      assertStatus(status, "workflow cursor operation");
      return new Uint32Array(this.#exports.memory.buffer, pointer, count).slice();
    } finally {
      this.#exports.free(pointer);
    }
  }

  position() {
    const values = this.#withU32(2, (pointer) =>
      this.#exports.pfw_workflow_cursor_position(this.#handle, pointer, pointer + 4),
    );
    return { completedSteps: values[0], stepCount: values[1] };
  }

  step() {
    const values = this.#withU32(1, (pointer) =>
      this.#exports.pfw_workflow_cursor_step(this.#handle, pointer),
    );
    return { completedSteps: values[0], stepCount: this.#stepCount };
  }

  reset() {
    if (this.#released) {
      throw new Error("PFW-WASM-E004 workflow cursor has been released");
    }
    assertStatus(this.#exports.pfw_workflow_cursor_reset(this.#handle), "workflow cursor reset");
    return { completedSteps: 0, stepCount: this.#stepCount };
  }

  release() {
    if (this.#released) return;
    assertStatus(this.#exports.pfw_workflow_cursor_release(this.#handle), "workflow cursor release");
    this.#released = true;
  }
}

export class PooFlowWasmRuntime {
  #exports;

  constructor(exports) {
    this.#exports = exports;
  }

  get handleCapacity() {
    return this.#exports.pfw_handle_capacity();
  }

  get workflowCursorCapacity() {
    return this.#exports.pfw_workflow_cursor_capacity();
  }

  openWorkflow(stepCount) {
    if (!Number.isSafeInteger(stepCount) || stepCount <= 0 || stepCount > 0xffffffff) {
      throw new TypeError("PFW-WASM-E006 stepCount must be a positive uint32");
    }
    const pointer = this.#exports.malloc(Uint32Array.BYTES_PER_ELEMENT);
    if (pointer === 0) {
      throw new Error("PFW-WASM-E005 workflow cursor allocation failed");
    }
    try {
      const status = this.#exports.pfw_workflow_cursor_open(stepCount, pointer);
      assertStatus(status, "workflow cursor open");
      const handle = new Uint32Array(this.#exports.memory.buffer, pointer, 1)[0];
      return new WorkflowCursorSession(this.#exports, handle, stepCount);
    } finally {
      this.#exports.free(pointer);
    }
  }
}

export const loadPooFlowWasmRuntime = async (options) => {
  const instantiated = await instantiate(options);
  return new PooFlowWasmRuntime(instantiated.instance.exports);
};
