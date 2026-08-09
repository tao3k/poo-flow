import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { runBazel } from "../scripts/bazel-runner.mjs";

const packageRoot = resolve(fileURLToPath(new URL("..", import.meta.url)));
const workspaceRoot = resolve(packageRoot, "../..");
const primaryTarget = "//bindings/runtime-wasm:human_capability_bundle";
const independentTarget =
  "//bindings/runtime-wasm:human_capability_bundle_determinism";

runBazel(["build", primaryTarget, independentTarget], {
  cwd: workspaceRoot,
  env: { ...process.env, GERBIL_PATH: "" },
});
const bazelBin = runBazel(["info", "bazel-bin"], { cwd: workspaceRoot });
const outputRoot = join(bazelBin, "bindings/runtime-wasm");

assert.deepEqual(
  readFileSync(join(outputRoot, "human-capability.determinism.descriptor.bin")),
  readFileSync(join(outputRoot, "human-capability.descriptor.bin")),
  "independent descriptor lowering must be byte deterministic",
);
assert.deepEqual(
  readFileSync(join(outputRoot, "human-capability.determinism.arena.bin")),
  readFileSync(join(outputRoot, "human-capability.arena.bin")),
  "independent arena lowering must be byte deterministic",
);
