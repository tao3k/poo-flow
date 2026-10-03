;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :clan/poo/object .o .ref) (only-in :std/misc/ports read-all-as-string) :std/test
        :poo-flow/modules/temporal-causality/types
        :poo-flow/modules/temporal-causality/objects
        :poo-flow/modules/temporal-causality/funs
        :poo-flow/modules/temporal-causality/conclusions/interface)
(export temporal-publication-test fixture-publication main)
(def fixture-model
  (poo-flow-temporal-model "model" (list (poo-flow-temporal-clock-domain "clock" 'logical-version))
    (list (poo-flow-temporal-model-observation "cause" "clock" 1 "source" 'observed)
          (poo-flow-temporal-model-observation "effect" "clock" 2 "source" 'observed))
    (list (poo-flow-temporal-hypothesis "hypothesis" "cause" "effect" '())) #t))
(def fixture-evaluation
  (poo-flow-temporal-evaluate fixture-model (poo-flow-temporal-query "query" "hypothesis" #f)
    "领域/subject:with,delimiters" "scope" "cut" "projection" "policy" "generation"))
(def fixture-revision
  (poo-flow-temporal-conclusion-root "root" "领域/subject:with,delimiters" "scope" "cut" "projection"
    "policy" "generation" "necessary" (.ref fixture-evaluation 'identity)))
(def fixture-journal (poo-flow-temporal-conclusion-journal "journal" (list fixture-revision)))
(def fixture-publication
  (poo-flow-temporal-publication fixture-journal fixture-revision fixture-model "nonce-root" 4611686018427387904 evaluation: fixture-evaluation))
(def (main path)
  (poo-flow-temporal-publication-replay fixture-publication fixture-journal fixture-revision fixture-model evaluation: fixture-evaluation)
  (call-with-output-file path (lambda (p) (display (.ref fixture-publication 'wire-payload) p)))
  (displayln "PUBLICATION-FIXTURE-OK " path) (force-output))
(def temporal-publication-test
  (test-suite "pure temporal publication projection"
    (poo-flow-test-case "root handoff is inert and bound to replayed journal revision and model"
      (check (.ref (poo-flow-temporal-publication-replay fixture-publication fixture-journal fixture-revision fixture-model evaluation: fixture-evaluation)
                   'wire-payload) => (.ref fixture-publication 'wire-payload))
      (check (call-with-input-file "packages/python-runtime/tests/fixtures/temporal-publication-v1.netstring" read-all-as-string)
             => (.ref fixture-publication 'wire-payload))
      (check (.ref fixture-publication 'expected-version) => 0)
      (check (.ref fixture-publication 'action-authorized?) => #f)
      (check (.ref fixture-publication 'runtime-executed?) => #f))
    (poo-flow-test-case "relabeling the revision or publication bytes fails closed"
      (check-exception (poo-flow-temporal-publication fixture-journal
                         (.o (:: @ fixture-revision) policy-identity: "other") fixture-model "nonce" 100) true)
      (check-exception (poo-flow-temporal-publication-replay
                         (.o (:: @ fixture-publication) wire-payload: "forged") fixture-journal fixture-revision fixture-model evaluation: fixture-evaluation) true))))
