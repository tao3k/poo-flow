;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

((benchmarkKind . scenario-e2e)
 (max_total . 2000us)
 (target_total . 1000us)
 (regression_budget . 1000us)
 (expected_over_input_budget . 0us)
 (sampleCount . 20)
 (targetRationale . "Measure Scheme semi-naive copy and indexed join rules over a 20-node chain.")
 (unit . "us")
 (sourcePath . "t/performance/ascent-binary-program-performance-test.ss")
 (rule . GERBIL-SCHEME-AGENT-R031)
 (feature . ascent-binary-program)
 (optimizationFocus . "POO persistent sets and indexed semi-naive binary joins")
 (inputShape . "19 edge facts, two relations, copy plus recursive join")
 (expectedOutcome . "190 sorted reachability pairs")
 (expectedRepair . "reuse the existing indexed Scheme relation and standard POO collections")
 (baseline . "specialized Scheme reachability closure")
 (candidate . "Scheme POO positive binary rule evaluator")
 (measurementPhases candidate-evaluation assert-semantic-gate assert-time-gate)
 (tags poo ascent rules stdlib performance))
