import assert from "node:assert/strict";
import { readFileSync, rmSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { randomUUID } from "node:crypto";
import { fileURLToPath } from "node:url";

import { runBazel } from "./bazel-runner.mjs";
import { acquirePublicationLock } from "./publication-lock.mjs";
import {
  publishFilePair,
  stagePublicationFile,
} from "./publication-transaction.mjs";

const packageRoot = resolve(fileURLToPath(new URL("..", import.meta.url)));
const workspaceRoot = resolve(packageRoot, "../..");
const primaryTarget = "//bindings/runtime-wasm:human_capability_bundle";
const independentTarget =
  "//bindings/runtime-wasm:human_capability_bundle_determinism";

runBazel(["build", primaryTarget, independentTarget], { cwd: workspaceRoot });
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

const outputs = [
  ["human-capability.descriptor.bin", "workflows/human-capability.descriptor.bin"],
  ["human-capability.arena.bin", "workflows/human-capability.arena.bin"],
];

const staged = [];
try {
  for (const [sourceName, targetName] of outputs) {
    const source = join(outputRoot, sourceName);
    const destination = join(packageRoot, targetName);
    const temporary = join(
      dirname(destination),
      `.${sourceName}.${process.pid}-${randomUUID()}.tmp`,
    );
    staged.push({ staged: temporary, destination });
    stagePublicationFile(source, temporary);
  }
  const releasePublicationLock = await acquirePublicationLock(packageRoot);
  try {
    publishFilePair(
      staged,
      join(packageRoot, "workflows/.human-capability.publication.json"),
    );
  } finally {
    await releasePublicationLock();
  }
} finally {
  for (const entry of staged) {
    rmSync(entry.staged, { force: true });
  }
}
