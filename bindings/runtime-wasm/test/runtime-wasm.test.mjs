import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

const loadRuntime = async () => {
  const bytes = await readFile(new URL("../dist/poo_flow_runtime.wasm", import.meta.url));
  const { instance } = await WebAssembly.instantiate(bytes, {
    env: { emscripten_notify_memory_growth: () => undefined },
  });
  return instance.exports;
};

test("standalone runtime creates and releases an instance through slots", async () => {
  const runtime = await loadRuntime();
  assert.equal(typeof runtime.memory, "object");
  assert.equal(runtime.pfw_handle_capacity(), 1023);

  const slotPointer = runtime.malloc(4);
  assert.notEqual(slotPointer, 0);
  try {
    assert.equal(runtime.pfw_instance_create(slotPointer), 0);
    const slot = new DataView(runtime.memory.buffer).getUint32(slotPointer, true);
    assert.ok(slot > 0);
    assert.equal(runtime.pfw_instance_release(slot), 0);
    assert.equal(runtime.pfw_instance_release(slot) >>> 0, 0xffff0002);
  } finally {
    runtime.free(slotPointer);
  }
});

test("workflow cursor advances, saturates, resets, and releases", async () => {
  const exports = await loadRuntime();
  const pointer = exports.malloc(8);
  assert.notEqual(pointer, 0);

  try {
    assert.equal(exports.pfw_workflow_cursor_capacity(), 1023);
    assert.equal(exports.pfw_workflow_cursor_open(3, pointer), 0);
    const cursorHandle = new Uint32Array(exports.memory.buffer, pointer, 1)[0];
    assert.notEqual(cursorHandle, 0);

    assert.equal(exports.pfw_workflow_cursor_position(cursorHandle, pointer, pointer + 4), 0);
    assert.deepEqual([...new Uint32Array(exports.memory.buffer, pointer, 2)], [0, 3]);

    for (const completedSteps of [1, 2, 3, 3]) {
      assert.equal(exports.pfw_workflow_cursor_step(cursorHandle, pointer), 0);
      assert.equal(new Uint32Array(exports.memory.buffer, pointer, 1)[0], completedSteps);
    }

    assert.equal(exports.pfw_workflow_cursor_reset(cursorHandle), 0);
    assert.equal(exports.pfw_workflow_cursor_position(cursorHandle, pointer, pointer + 4), 0);
    assert.deepEqual([...new Uint32Array(exports.memory.buffer, pointer, 2)], [0, 3]);

    assert.equal(exports.pfw_workflow_cursor_release(cursorHandle), 0);
    assert.equal(exports.pfw_workflow_cursor_release(cursorHandle) >>> 0, 0xffff0002);
  } finally {
    exports.free(pointer);
  }
});

test("ESM runtime exposes a typed workflow cursor session", async () => {
  const [{ loadPooFlowWasmRuntime }, bytes] = await Promise.all([
    import("../dist/index.mjs"),
    readFile(new URL("../dist/poo_flow_runtime.wasm", import.meta.url)),
  ]);
  const runtime = await loadPooFlowWasmRuntime({ bytes });
  const session = runtime.openWorkflow(2);

  assert.deepEqual(session.position(), { completedSteps: 0, stepCount: 2 });
  assert.deepEqual(session.step(), { completedSteps: 1, stepCount: 2 });
  assert.deepEqual(session.step(), { completedSteps: 2, stepCount: 2 });
  assert.deepEqual(session.reset(), { completedSteps: 0, stepCount: 2 });
  session.release();
  session.release();
  assert.equal(session.released, true);
});

test("Scheme plan compiler emits an executable typed workflow module", async () => {
  const { workflow, workflowTopology } = await import(
    "../generated/browser-contribution.generated.ts"
  );

  assert.equal(workflow.id, "browser-contribution");
  assert.equal(workflow.steps.length, 6);
  assert.equal(workflow.edges.length, 5);
  assert.equal(workflowTopology[0], 1);
  assert.equal(workflowTopology[1], workflow.steps.length);
  assert.equal(workflowTopology[2], workflow.edges.length);
  assert.deepEqual(
    workflow.steps.slice(1).map(({ dependencies }) => dependencies.length),
    [1, 1, 1, 1, 1],
  );
});
