import { execFileSync } from "node:child_process";

const fallbackExecutables = ["bazelisk", "bazel"];

function execute(executable, args, cwd, env, stdio) {
  return execFileSync(executable, args, {
    cwd,
    env,
    encoding: "utf8",
    stdio,
  }).trim();
}

export function runBazel(
  args,
  {
    cwd,
    env = process.env,
    executables = fallbackExecutables,
    executor = execute,
    stdio = ["ignore", "pipe", "inherit"],
  } = {},
) {
  const configuredBazel = env.BAZEL;
  if (configuredBazel !== undefined) {
    const executable = configuredBazel.trim();
    if (executable === "") {
      throw new Error("BAZEL must name a non-empty executable");
    }
    try {
      return executor(executable, args, cwd, env, stdio);
    } catch (error) {
      if (error?.code === "ENOENT" || error?.code === "EACCES") {
        throw new Error(
          `Configured BAZEL executable is unavailable: ${configuredBazel}`,
          { cause: error },
        );
      }
      throw error;
    }
  }

  const missing = [];
  for (const executable of executables) {
    try {
      return executor(executable, args, cwd, env, stdio);
    } catch (error) {
      if (error?.code !== "ENOENT") throw error;
      missing.push(executable);
    }
  }
  throw new Error(`Unable to find Bazel executable; tried ${missing.join(", ")}`);
}
