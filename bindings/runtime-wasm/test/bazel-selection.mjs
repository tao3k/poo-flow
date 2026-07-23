import assert from "node:assert/strict";

import { runBazel } from "../scripts/bazel-runner.mjs";

const cwd = new URL("..", import.meta.url);
const missing = (code = "ENOENT") => {
  const error = new Error(code);
  error.code = code;
  return error;
};

function expectConfigurationFailure(bazel, diagnostic, executor) {
  assert.throws(
    () =>
      runBazel(["build", "//selection:test"], {
        cwd,
        env: { ...process.env, BAZEL: bazel },
        executor,
        stdio: ["ignore", "pipe", "pipe"],
      }),
    diagnostic,
  );
}

expectConfigurationFailure(" \t", /BAZEL must name a non-empty executable/);
expectConfigurationFailure(
  "missing-bazel",
  /Configured BAZEL executable is unavailable/,
  () => {
    throw missing();
  },
);
expectConfigurationFailure(
  "non-executable-bazel",
  /Configured BAZEL executable is unavailable/,
  () => {
    throw missing("EACCES");
  },
);

const configuredCalls = [];
assert.equal(
  runBazel(["info", "bazel-bin"], {
    cwd,
    env: { ...process.env, BAZEL: "configured-bazel" },
    executor: (executable, args) => {
      configuredCalls.push([executable, args]);
      return "/configured/bazel-bin";
    },
  }),
  "/configured/bazel-bin",
);
assert.deepEqual(configuredCalls, [
  ["configured-bazel", ["info", "bazel-bin"]],
]);

const precedenceCalls = [];
assert.equal(
  runBazel(["build", "//selection:test"], {
    cwd,
    env: {},
    executables: ["bazelisk", "bazel"],
    executor: (executable) => {
      precedenceCalls.push(executable);
      return "ok";
    },
  }),
  "ok",
);
assert.deepEqual(precedenceCalls, ["bazelisk"]);

const fallbackCalls = [];
assert.equal(
  runBazel(["build", "//selection:test"], {
    cwd,
    env: {},
    executables: ["bazelisk", "bazel"],
    executor: (executable) => {
      fallbackCalls.push(executable);
      if (executable === "bazelisk") throw missing();
      return "ok";
    },
  }),
  "ok",
);
assert.deepEqual(fallbackCalls, ["bazelisk", "bazel"]);

assert.throws(
  () =>
    runBazel(["build", "//selection:test"], {
      cwd,
      env: {},
      executables: ["bazelisk", "bazel"],
      executor: () => {
        throw missing();
      },
    }),
  /Unable to find Bazel executable; tried bazelisk, bazel/,
);
