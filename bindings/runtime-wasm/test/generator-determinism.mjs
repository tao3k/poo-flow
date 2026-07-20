import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const packageRoot = fileURLToPath(new URL("..", import.meta.url));
const outputs = [
  "generated/subagent-workflow.generated.ts",
  "generated/funflow.generated.ts",
];

function generateInFreshProcess() {
  execFileSync("gxi", ["examples/scenario-workflows.ss"], {
    cwd: packageRoot,
    env: { ...process.env, GERBIL_PATH: "../../.gerbil" },
    stdio: "pipe",
  });
  return new Map(outputs.map((path) => [path, readFileSync(`${packageRoot}/${path}`)]));
}

const first = generateInFreshProcess();
const second = generateInFreshProcess();
for (const path of outputs) {
  assert.deepEqual(second.get(path), first.get(path), `${path} must be byte deterministic`);
}
