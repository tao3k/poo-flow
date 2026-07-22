import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const packageRoot = fileURLToPath(new URL("..", import.meta.url));

function materializeInFreshProcess() {
  const output = mkdtempSync(join(tmpdir(), "poo-flow-human-capability-"));
  const descriptorPath = join(output, "descriptor.bin");
  const arenaPath = join(output, "arena.bin");
  try {
    execFileSync("gxi", ["examples/human-capability.ss"], {
      cwd: packageRoot,
      env: {
        ...process.env,
        GERBIL_PATH: "../../.gerbil",
        POO_FLOW_BUNDLE_V1_ID: "human-capability",
        POO_FLOW_BUNDLE_V1_EPOCH: "1",
        POO_FLOW_BUNDLE_V1_DESCRIPTOR_OUT: descriptorPath,
        POO_FLOW_BUNDLE_V1_ARENA_OUT: arenaPath,
      },
      stdio: "pipe",
    });
    return {
      descriptor: readFileSync(descriptorPath),
      arena: readFileSync(arenaPath),
    };
  } finally {
    rmSync(output, { recursive: true, force: true });
  }
}

const first = materializeInFreshProcess();
const second = materializeInFreshProcess();
assert.deepEqual(second.descriptor, first.descriptor, "descriptor must be byte deterministic");
assert.deepEqual(second.arena, first.arena, "arena must be byte deterministic");
