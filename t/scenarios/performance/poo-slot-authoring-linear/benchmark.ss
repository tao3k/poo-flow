;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

((benchmarkKind . scenario-ab)
 (schema . poo-flow.poo-slot-authoring-linear.v1)
 (sourcePath . "t/scenarios/performance/poo-slot-authoring-linear/scenario.ss")
 (feature . poo-slot-authoring-linear-traversal)
 (baseline . "recursive append of complete child binding lists")
 (candidate . "tail-passing binding accumulation")
 (sampleCount . 20)
 (nestingDepth . 300)
 (semanticGate . "candidate bindings equal baseline bindings in source order")
 (performanceGate . "candidate complete-sample p95 is below baseline p95")
 (tags module-system observability poo scheme-reader linear-traversal performance))
