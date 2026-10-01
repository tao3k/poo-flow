;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :clan/poo/object .ref)
        :std/test
        :poo-flow/modules/temporal-causality/interface)
(export temporal-model-test)

(def clock (poo-flow-temporal-clock-domain "revision-clock" 'logical-version))
(def second-clock
  (poo-flow-temporal-clock-domain "external-clock" 'logical-version))

(def (observation id domain position)
  (poo-flow-temporal-model-observation
   id domain position (string-append id "/ledger") 'observed))

(def (candidate id cause effect)
  (poo-flow-temporal-hypothesis id cause effect '()))

(def (two-explanations name domain-b position-b complete?)
  (poo-flow-temporal-model
   name (list clock second-clock)
   (list (observation "source-a" "revision-clock" 1)
         (observation "source-b" domain-b position-b)
         (observation "result" "revision-clock" 3))
   (list (candidate "via-a" "source-a" "result")
         (candidate "via-b" "source-b" "result"))
   complete?))

(def temporal-model-test
  (test-suite "open temporal model"
    (poo-flow-test-case "medication vocabulary admits two candidate explanations"
      (let* ((domain (poo-flow-temporal-clock-domain
                      "care-sequence" 'logical-version))
             (model
              (poo-flow-temporal-model
               "medication-analysis" (list domain)
               (list (observation "prescription" "care-sequence" 1)
                     (observation "review" "care-sequence" 2)
                     (observation "administration" "care-sequence" 3))
               (list (candidate "via-prescription"
                                "prescription" "administration")
                     (candidate "via-review" "review" "administration"))
               #t))
             (query (poo-flow-temporal-query
                     "why-administration" "via-prescription" 2))
             (receipt (poo-flow-temporal-model-classify model query)))
        (check (poo-flow-temporal-model? model) => #t)
        (check (poo-flow-temporal-model-receipt? receipt) => #t)
        (check (.ref receipt 'classification) => 'possible)
        (check (.ref receipt 'admissible-hypothesis-ids)
               => '("via-prescription" "via-review"))
        (check (.ref receipt 'exhausted?) => #t)
        (check (.ref receipt 'assumption) => 'exclusive-explanations)))

    (poo-flow-test-case "new evidence refutes one candidate and changes identity"
      (let* ((before (two-explanations "build-flow"
                                       "revision-clock" 2 #t))
             (after (two-explanations "build-flow"
                                      "revision-clock" 4 #t))
             (query (poo-flow-temporal-query "why-result" "via-a" 2))
             (receipt (poo-flow-temporal-model-classify after query)))
        (check (equal? (.ref before 'semantic-digest)
                       (.ref after 'semantic-digest)) => #f)
        (check (.ref receipt 'classification) => 'necessary)
        (check (.ref receipt 'refuted-hypothesis-ids) => '("via-b"))
        (check (.ref receipt 'model-digest)
               => (.ref after 'semantic-digest))))

    (poo-flow-test-case "software release vocabulary uses the same POO API"
      (let* ((domain (poo-flow-temporal-clock-domain
                      "build-sequence" 'logical-version))
             (model
              (poo-flow-temporal-model
               "release-analysis" (list domain)
               (list (observation "commit" "build-sequence" 1)
                     (observation "canary" "build-sequence" 2)
                     (observation "deploy" "build-sequence" 3)
                     (observation "verification" "build-sequence" 4))
               (list
                (poo-flow-temporal-hypothesis
                 "via-canary" "canary" "deploy"
                 (list (poo-flow-temporal-constraint
                        "commit-before-canary" 'before "commit" "canary")))
                (candidate "via-verification" "verification" "deploy"))
               #t))
             (receipt
              (poo-flow-temporal-model-classify
               model (poo-flow-temporal-query "release-why" "via-canary" 2))))
        (check (.ref receipt 'classification) => 'necessary)
        (check (.ref receipt 'refuted-hypothesis-ids)
               => '("via-verification"))))

    (poo-flow-test-case "incomparable clocks and bounds preserve unknown frontier"
      (let* ((model (two-explanations "build-flow"
                                      "external-clock" 2 #t))
             (full (poo-flow-temporal-model-classify
                    model (poo-flow-temporal-query "full" "via-a" 2)))
             (bounded (poo-flow-temporal-model-classify
                       model (poo-flow-temporal-query "bounded" "via-b" 1))))
        (check (.ref full 'classification) => 'possible)
        (check (.ref full 'unknown-hypothesis-ids) => '("via-b"))
        (check (.ref bounded 'classification) => 'unknown)
        (check (.ref bounded 'unexplored-hypothesis-ids) => '("via-b"))
        (check (.ref bounded 'exhausted?) => #f)))

    (poo-flow-test-case "input order does not change identity or bounded traversal"
      (let* ((observations
              (list (observation "source-a" "revision-clock" 1)
                    (observation "source-b" "revision-clock" 2)
                    (observation "result" "revision-clock" 3)))
             (hypotheses
              (list (candidate "via-a" "source-a" "result")
                    (candidate "via-b" "source-b" "result")))
             (forward (poo-flow-temporal-model
                       "stable" (list clock) observations hypotheses #t))
             (reverse-input (poo-flow-temporal-model
                             "stable" (list clock) (reverse observations)
                             (reverse hypotheses) #t))
             (query (poo-flow-temporal-query "bounded" "via-b" 1)))
        (check (.ref forward 'semantic-digest)
               => (.ref reverse-input 'semantic-digest))
        (check (.ref (poo-flow-temporal-model-classify forward query)
                     'unexplored-hypothesis-ids)
               => (.ref (poo-flow-temporal-model-classify reverse-input query)
                        'unexplored-hypothesis-ids))))

    (poo-flow-test-case "incomplete family cannot imply necessity"
      (let* ((model (two-explanations "build-flow"
                                      "revision-clock" 4 #f))
             (receipt (poo-flow-temporal-model-classify
                       model (poo-flow-temporal-query "open" "via-a" 2))))
        (check (.ref receipt 'classification) => 'possible)
        (check (.ref receipt 'family-complete?) => #f)))

    (poo-flow-test-case "unbounded query exhausts the finite family"
      (let* ((model (two-explanations "unbounded" "revision-clock" 4 #t))
             (receipt (poo-flow-temporal-model-classify
                       model (poo-flow-temporal-query "all" "via-a" #f))))
        (check (.ref receipt 'classification) => 'necessary)
        (check (.ref receipt 'exhausted?) => #t)
        (check (.ref receipt 'unexplored-hypothesis-ids) => '())))

    (poo-flow-test-case "new clock roles are POO data, not core branches"
      (let ((domain (poo-flow-temporal-clock-domain
                     "satellite-revision" 'satellite-epoch)))
        (check (poo-flow-temporal-clock-domain? domain) => #t)))

    (poo-flow-test-case "missing observations remain unresolved"
      (let* ((model
              (poo-flow-temporal-model
               "partial" (list clock)
               (list (observation "result" "revision-clock" 3))
               (list (candidate "unseen-cause" "missing" "result")) #t))
             (receipt (poo-flow-temporal-model-classify
                       model (poo-flow-temporal-query
                              "partial-why" "unseen-cause" 1))))
        (check (.ref receipt 'classification) => 'unknown)
        (check (.ref receipt 'unknown-hypothesis-ids)
               => '("unseen-cause"))))

    (poo-flow-test-case "an explicit inconsistent constraint refutes its candidate"
      (let* ((model
              (poo-flow-temporal-model
               "constrained" (list clock)
               (list (observation "source" "revision-clock" 1)
                     (observation "result" "revision-clock" 3))
               (list
                (poo-flow-temporal-hypothesis
                 "candidate" "source" "result"
                 (list (poo-flow-temporal-constraint
                        "result-before-source" 'before "result" "source"))))
               #t))
             (receipt (poo-flow-temporal-model-classify
                       model (poo-flow-temporal-query "why" "candidate" 1))))
        (check (.ref receipt 'classification) => 'refuted)
        (check (.ref receipt 'refuted-hypothesis-ids)
               => '("candidate"))))

    (poo-flow-test-case "empty candidate family is invalid"
      (check-exception
       (poo-flow-temporal-model "empty" (list clock) '() '() #t)
       true))

    (poo-flow-test-case "duplicate candidate identities are invalid"
      (check-exception
       (poo-flow-temporal-model
        "duplicate" (list clock) '()
        (list (candidate "same" "a" "result")
              (candidate "same" "b" "result")) #t)
       true))))
