;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

((benchmarkKind . scenario-ab)
 (schema . poo-flow.module-interface-schema-indexed.v1)
 (sourcePath . "t/scenarios/performance/module-interface-schema-indexed/scenario.ss")
 (feature . module-interface-derived-schema-index-slot)
 (baseline . "one linear projected-schema scan per option lookup")
 (candidate . "one Interface-owned native hash index reused by every lookup")
 (sampleCount . 20)
 (schemaCount . 1000)
 (semanticGate . "candidate values equal projected baseline values in schema order")
 (performanceGate . "candidate complete-sample p95 is below baseline p95")
 (tags module-system interface poo slot schema hash-index performance))
