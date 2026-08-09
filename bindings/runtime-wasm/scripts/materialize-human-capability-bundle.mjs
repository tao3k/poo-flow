import { rmSync } from "node:fs";
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
const target = "//bindings/runtime-wasm:human_capability_bundle";

runBazel(["build", target], { cwd: workspaceRoot });
const bazelBin = runBazel(["info", "bazel-bin"], { cwd: workspaceRoot });

const outputs = [
  ["human-capability.descriptor.bin", "workflows/human-capability.descriptor.bin"],
  ["human-capability.arena.bin", "workflows/human-capability.arena.bin"],
];

const staged = [];
try {
  for (const [sourceName, targetName] of outputs) {
    const source = join(bazelBin, "bindings/runtime-wasm", sourceName);
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
