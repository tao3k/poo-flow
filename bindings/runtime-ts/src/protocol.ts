import type { RuntimeEvent, RuntimeEventInput } from "./batch.ts";

export type RuntimeWorkerRequest =
  | { id: number; kind: "load"; wasmUrl: string }
  | { id: number; kind: "instance-create" }
  | { id: number; kind: "instance-release"; slot: number }
  | { id: number; kind: "negotiate"; instanceSlot: number; runtimeIdentity?: string }
  | { id: number; kind: "profile-release"; instanceSlot: number; profileSlot: number }
  | { id: number; kind: "bundle-open"; instanceSlot: number; profileSlot: number }
  | { id: number; kind: "bundle-release"; instanceSlot: number; bundleSlot: number }
  | { id: number; kind: "session-open"; instanceSlot: number; bundleSlot: number }
  | { id: number; kind: "session-cancel"; instanceSlot: number; sessionSlot: number }
  | { id: number; kind: "session-close"; instanceSlot: number; sessionSlot: number; disposition?: number }
  | { id: number; kind: "session-release"; instanceSlot: number; sessionSlot: number }
  | {
      id: number;
      kind: "batch-run";
      instanceSlot: number;
      sessionSlot: number;
      events: RuntimeEventInput[];
    };

export type RuntimeWorkerResponse =
  | { id: number; ok: true; kind: "loaded" }
  | { id: number; ok: true; kind: "instance-created"; slot: number }
  | { id: number; ok: true; kind: "instance-released"; slot: number }
  | { id: number; ok: true; kind: "profile-created"; slot: number; abiMajor: number; abiMinor: number; capabilities: bigint }
  | { id: number; ok: true; kind: "profile-released"; slot: number }
  | { id: number; ok: true; kind: "bundle-opened"; slot: number }
  | { id: number; ok: true; kind: "bundle-released"; slot: number }
  | { id: number; ok: true; kind: "session-opened"; slot: number }
  | { id: number; ok: true; kind: "session-cancelled"; slot: number }
  | { id: number; ok: true; kind: "session-closed"; slot: number }
  | { id: number; ok: true; kind: "session-released"; slot: number }
  | {
      id: number;
      ok: true;
      kind: "batch-complete";
      publishedCount: bigint;
      acceptedCount: bigint;
      rejectedCount: bigint;
      acceptedWatermark: bigint;
      events: RuntimeEvent[];
    }
  | { id: number; ok: false; kind: "error"; message: string; status?: number };
