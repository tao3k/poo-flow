;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

((benchmarkKind . scenario-ab)
 (schema . poo-flow.module-source-observation-linear.v1)
 (sourcePath . "t/scenarios/performance/module-source-observation-linear/scenario.ss")
 (feature . module-source-observation-linear-traversal)
 (baseline . "recursive append of complete child observation lists")
 (candidate . "tail-passing observation accumulation")
 (sampleCount . 20)
 (nestingDepth . 300)
 (semanticGate . "candidate observations equal baseline observations in source order")
 (performanceGate . "candidate complete-sample p95 is below baseline p95")
 (tags module-system observability scheme-reader linear-traversal performance))
