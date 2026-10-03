;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :clan/poo/object .o .ref) :std/test
        :poo-flow/modules/temporal-causality/types
        :poo-flow/modules/temporal-causality/objects
        :poo-flow/modules/temporal-causality/funs
        :poo-flow/modules/temporal-causality/truth-maintenance/interface
        :poo-flow/modules/temporal-causality/conclusions/interface
        :poo-flow/modules/temporal-causality/behavior/interface
        "fixtures/temporal-behaviors.ss")
(export temporal-evaluation-test)
(def (model cause-position)
  (poo-flow-temporal-model "inventory" (list (poo-flow-temporal-clock-domain "clock" 'logical-version))
    (list (poo-flow-temporal-model-observation "cause" "clock" cause-position "source" 'observed)
          (poo-flow-temporal-model-observation "effect" "clock" 2 "source" 'observed))
    (list (poo-flow-temporal-hypothesis "target" "cause" "effect" '())) #t))
(def query (poo-flow-temporal-query "q" "target" #f))
(def (evaluate m cut generation)
  (poo-flow-temporal-evaluate m query "subject" "scope" cut "projection" "policy" generation))
(def temporal-evaluation-test
  (test-suite "scoped finite evaluator proof admission"
    (poo-flow-test-case "native replay rejects rewritten classifications scope and query"
      (let ((evidence (evaluate (model 1) "cut-1" "generation-1")))
        (check (.ref evidence 'classification) => 'necessary)
        (check (.ref evidence 'admitted?) => #t)
        (for-each (lambda (forged) (check-exception (poo-flow-temporal-evaluation-replay forged) true))
          (list (.o (:: @ evidence) classification: 'possible)
                (.o (:: @ evidence) scope: "other")
                (.o (:: @ evidence) query: (poo-flow-temporal-query "other" "target" #f))))))
    (poo-flow-test-case "opaque proof identifiers and wrong results cannot enter publication"
      (let* ((m (model 1)) (evidence (evaluate m "cut-1" "generation-1"))
             (revision (poo-flow-temporal-conclusion-root "root" "subject" "scope" "cut-1" "projection"
                          "policy" "generation-1" "necessary" (.ref evidence 'identity)))
             (journal (poo-flow-temporal-conclusion-journal "journal" (list revision))))
        (check (.ref (poo-flow-temporal-publication journal revision m "nonce" 100 evaluation: evidence) 'proof)
               => (.ref evidence 'identity))
        (check-exception (poo-flow-temporal-publication journal revision m "nonce" 100) true)
        (check-exception (poo-flow-temporal-evaluation-admit evidence
                           (.o (:: @ revision) result-identity: "domain-decision") m journal) true)))
    (poo-flow-test-case "unfinished behavior search cannot be made publishable by changing its flag"
      (let* ((m (medication-model '()))
             (property (poo-flow-temporal-property "goal" 'reachability
                         (list (poo-flow-temporal-condition "condition" "administration" "given")) 2))
             (q (poo-flow-temporal-behavior-query "bounded" property #f node-limit: 1))
             (evidence (poo-flow-temporal-evaluate m q "subject" "scope" "cut" "projection" "policy" "generation")))
        (check (.ref evidence 'classification) => 'unknown)
        (check (.ref evidence 'admitted?) => #f)
        (check-exception (poo-flow-temporal-evaluation-replay (.o (:: @ evidence) admitted?: #t)) true)))
    (poo-flow-test-case "retraction requires the same prior statement and a recomputed refutation"
      (let* ((old-model (model 1)) (new-model (model 3))
             (old-proof (evaluate old-model "cut-1" "generation-1"))
             (new-proof (evaluate new-model "cut-2" "generation-2"))
             (root (poo-flow-temporal-conclusion-root "root" "subject" "scope" "cut-1" "projection"
                     "policy" "generation-1" "necessary" (.ref old-proof 'identity)))
             (index (poo-flow-temporal-dependency-index "index" "cut-1" "projection" #t
                      (list (poo-flow-temporal-derivation "root" "cut-1" "projection" "policy" '("source-event") '()))))
             (impact (poo-flow-temporal-reverse-dependency-plan index "cut-2" "projection" '("source-event")))
             (retraction (poo-flow-temporal-conclusion-change "withdrawn" root impact 'retract #f
                           (.ref new-proof 'identity) "policy" "generation-2"))
             (journal (poo-flow-temporal-conclusion-journal "journal" (list root retraction)))
             (observed (poo-flow-temporal-selection-observation "observation" "subject" "scope" 1 "root"))
             (plan (poo-flow-temporal-selection-prepare journal retraction observed 1)))
        (check (.ref new-proof 'classification) => 'refuted)
        (check (.ref (poo-flow-temporal-publication journal retraction new-model "nonce" 100
                     evaluation: new-proof prior-evaluation: old-proof plan: plan observation: observed) 'operation) => "retract")
        (check-exception (poo-flow-temporal-publication journal retraction new-model "nonce" 100
                          evaluation: new-proof plan: plan observation: observed) true)
        (check-exception (poo-flow-temporal-evaluation-admit new-proof retraction new-model journal
                          prior: (.o (:: @ old-proof) statement-digest: "other")) true)))))
