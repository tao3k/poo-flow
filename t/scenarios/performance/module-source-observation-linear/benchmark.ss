;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

((benchmarkKind . scenario-e2e)
 (max_total . 100ms)
 (target_total . 10ms)
 (regression_budget . 90ms)
 (expected_over_input_budget . 0ms)
 (targetRationale . "linear source observation stays below the scenario budget")
 (sampleCount . 20)
 (rule . module-source-observation-linear)
 (feature . module-source-observation-linear-traversal)
 (optimizationFocus . "replace recursive result append with tail-passing accumulation")
 (inputShape . "300-level nested Scheme source datum")
 (expectedOutcome . "candidate preserves source-order observations and beats baseline")
 (measurementPhases . (baseline-traversal candidate-traversal assert-semantic-gate assert-time-gate observe-runtime-memory))
 (baseline . "recursive append of complete child observation lists")
 (candidate . "tail-passing observation accumulation")
 (tags module-system observability scheme-reader linear-traversal performance))
