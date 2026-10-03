;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :clan/poo/object .o .ref) :std/test
        :poo-flow/modules/temporal-causality/behavior/interface)
(export temporal-behavior-test)
(def (fixture vocabulary interventions)
  (poo-flow-temporal-behavior-model
   vocabulary
   (list (poo-flow-temporal-state-variable "trigger" '("absent" "present") "absent")
         (poo-flow-temporal-state-variable "effect" '("absent" "present") "absent")
         (poo-flow-temporal-state-variable "control" '("unchanged" "changed") "unchanged"))
   (list (poo-flow-temporal-mechanism
          "trigger-event" '() (list (poo-flow-temporal-assignment "trigger-write" "trigger" "present")) "declared-trigger")
         (poo-flow-temporal-mechanism
          "propagate" (list (poo-flow-temporal-condition "guard" "trigger" "present"))
          (list (poo-flow-temporal-assignment "effect-write" "effect" "present")) "declared-propagation"))
   interventions 2))
(def (query kind variable value limit)
  (poo-flow-temporal-behavior-query
   "query" (poo-flow-temporal-property "property" kind
              (list (poo-flow-temporal-condition "goal" variable value)) 2) limit))
(def temporal-behavior-test
  (test-suite "finite Temporal behaviors and intervention scope"
    (poo-flow-test-case "native step tables bind every reachable logical state and reject rewritten rows"
      (let* ((model (fixture "steps" '()))
             (table (poo-flow-temporal-behavior-step-table model))
             (limited (poo-flow-temporal-behavior-step-table model node-limit: 1))
             (edges (.ref table 'steps)))
        (check (.ref table 'exhausted?) => #t)
        (check (.ref table 'initial-values) => '("unchanged" "absent" "absent"))
        (check (.ref (poo-flow-temporal-behavior-step-table-replay table model) 'identity) => (.ref table 'identity))
        (check (.ref limited 'exhausted?) => #f)
        (check-exception (poo-flow-temporal-behavior-step-table-replay (.o (:: @ limited) exhausted?: #t) model) true)
        (check-exception (poo-flow-temporal-behavior-step-table-replay
                          (.o (:: @ table) steps: (cons (.o (:: @ (car edges)) coordinate: 99) (cdr edges))) model) true)))
    (poo-flow-test-case "two domains share bounded safety reachability and progress semantics"
      (for-each
       (lambda (vocabulary)
         (let* ((model (fixture vocabulary '()))
                (safety (poo-flow-temporal-behavior-explore model (query 'safety "control" "unchanged" #f)))
                (reach (poo-flow-temporal-behavior-explore model (query 'reachability "effect" "present" #f)))
                (progress (poo-flow-temporal-behavior-explore model (query 'bounded-progress "effect" "present" #f))))
           (check (.ref safety 'classification) => 'necessary)
           (check (.ref safety 'explored-worlds) => 9)
           (check (.ref safety 'exhausted?) => #t)
           (check (.ref reach 'classification) => 'possible)
           (check (.ref (.ref reach 'witness) 'schedule) => '("trigger-event" "propagate"))
           (check (.ref progress 'classification) => 'possible)
           (check (.ref progress 'fairness) => 'none)
           (check (.ref progress 'actual-causation?) => #f)
           (check (.ref (poo-flow-temporal-behavior-replay reach model) 'identity) => (.ref reach 'identity))))
       '("care" "software")))
    (poo-flow-test-case "persistent intervention clamps the declared variable without editing a control"
      (let* ((intervention (poo-flow-temporal-intervention
                            "suppress-trigger" 0
                            (list (poo-flow-temporal-assignment "clamp" "trigger" "absent"))
                            '("control") "declared-intervention"))
             (baseline (fixture "care" '()))
             (model (fixture "care" (list intervention)))
             (reach (poo-flow-temporal-behavior-explore model (query 'reachability "effect" "present" #f))))
        (check (.ref reach 'classification) => 'refuted)
        (check (equal? (.ref baseline 'semantic-digest) (.ref model 'semantic-digest)) => #f)
        (check (.ref (poo-flow-temporal-behavior-explore model (query 'safety "control" "unchanged" #f))
                     'classification) => 'necessary)))
    (poo-flow-test-case "world and node limits preserve unknown frontiers and model identity"
      (let* ((model (fixture "release" '()))
             (limited (poo-flow-temporal-behavior-explore model (query 'reachability "effect" "present" 1)))
             (node-query (poo-flow-temporal-behavior-query
                          "node-bound" (.ref (query 'reachability "effect" "present" #f) 'property)
                          #f node-limit: 1))
             (node-limited (poo-flow-temporal-behavior-explore model node-query)))
        (check (.ref limited 'classification) => 'unknown)
        (check (.ref limited 'exhausted?) => #f)
        (check (.ref node-limited 'classification) => 'unknown)
        (check (.ref node-limited 'explored-worlds) => 0)
        (check (.ref node-limited 'model-digest) => (.ref model 'semantic-digest))))
    (poo-flow-test-case "a forged receipt and a protected direct edit are rejected"
      (let* ((model (fixture "release" '()))
             (receipt (poo-flow-temporal-behavior-explore model (query 'safety "control" "unchanged" #f))))
        (check-exception
         (poo-flow-temporal-behavior-replay (.o (:: @ receipt) classification: 'refuted) model) true)
        (check-exception
         (poo-flow-temporal-behavior-replay
           (.o (:: @ receipt) property: (poo-flow-temporal-property "forged-property" 'reachability
             (list (poo-flow-temporal-condition "forged-condition" "effect" "present")) 2)) model) true))
      (check-exception
       (fixture "release"
                (list (poo-flow-temporal-intervention
                       "bad-control" 0
                       (list (poo-flow-temporal-assignment "edit" "control" "changed"))
                       '("control") "unsupported-control-edit"))) true))))
