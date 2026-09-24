;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

((benchmarkKind . scenario-ab)
 (schema . poo-flow.module-import-validation-indexed.v1)
 (sourcePath . "t/scenarios/performance/module-import-validation-indexed/scenario.ss")
 (feature . module-import-validation-name-index)
 (baseline . "one linear available-name scan per named import")
 (candidate . "one traversal-owned native hash index for all named imports")
 (sampleCount . 20)
 (moduleCount . 1000)
 (semanticGate . "candidate missing-import diagnostics equal baseline in source order")
 (performanceGate . "candidate complete-sample p95 is below baseline p95")
 (tags module-system descriptor import-validation hash-index performance))
