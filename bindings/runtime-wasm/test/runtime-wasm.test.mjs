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
