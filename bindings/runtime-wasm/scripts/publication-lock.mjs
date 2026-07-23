import { createHash } from "node:crypto";
import { createServer } from "node:net";

const firstEphemeralPort = 49_152;
const ephemeralPortCount = 16_384;

function lockPort(scope) {
  const digest = createHash("sha256").update(scope).digest();
  return firstEphemeralPort + (digest.readUInt16BE(0) % ephemeralPortCount);
}

function listenOnce(port) {
  return new Promise((resolve) => {
    const server = createServer();
    server.once("error", (error) => resolve({ error }));
    server.listen({ host: "127.0.0.1", port, exclusive: true }, () => {
      resolve({ server });
    });
  });
}

function delay(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

export async function acquirePublicationLock(scope, timeoutMs = 30_000) {
  const port = lockPort(scope);
  const deadline = Date.now() + timeoutMs;
  for (;;) {
    const attempt = await listenOnce(port);
    if (attempt.server) {
      return () =>
        new Promise((resolve, reject) => {
          attempt.server.close((error) => {
            if (error) reject(error);
            else resolve();
          });
        });
    }
    if (attempt.error?.code !== "EADDRINUSE") throw attempt.error;
    if (Date.now() >= deadline) {
      throw new Error(
        `Timed out waiting for workflow publication lock on port ${port}`,
      );
    }
    await delay(50);
  }
}
