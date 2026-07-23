import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";

import { acquirePublicationLock } from "../scripts/publication-lock.mjs";

const scope = `poo-flow-publication-lock-test:${randomUUID()}`;
let active = 0;
let maximumActive = 0;

await Promise.all(
  Array.from({ length: 4 }, async () => {
    const release = await acquirePublicationLock(scope);
    try {
      active += 1;
      maximumActive = Math.max(maximumActive, active);
      await new Promise((resolve) => setTimeout(resolve, 25));
      active -= 1;
    } finally {
      await release();
    }
  }),
);

assert.equal(active, 0);
assert.equal(maximumActive, 1, "publication lock must serialize four writers");

const heldScope = `poo-flow-publication-lock-timeout-test:${randomUUID()}`;
const releaseHeldLock = await acquirePublicationLock(heldScope);
try {
  await assert.rejects(
    acquirePublicationLock(heldScope, 25),
    /Timed out waiting for workflow publication lock/,
  );
} finally {
  await releaseHeldLock();
}
