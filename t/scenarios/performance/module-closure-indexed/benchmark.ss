;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

((benchmarkKind . scenario-ab)
 (schema . poo-flow.module-closure-indexed.v1)
 (sourcePath . "t/scenarios/performance/module-closure-indexed/scenario.ss")
 (feature . module-closure-shared-admission-index)
 (baseline . "branch-local name lists with linear membership scans")
 (candidate . "one traversal-owned native hash index with explicit DFS frames")
 (sampleCount . 20)
 (moduleCount . 1000)
 (semanticGate . "candidate unique-module order equals baseline on distinct inputs")
 (performanceGate . "candidate complete-sample p95 is below baseline p95")
 (tags module-system descriptor closure hash-index dfs performance))
