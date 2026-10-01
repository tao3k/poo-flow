;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Immutable conclusion revisions and inert active-pointer plans.
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element?)
        (only-in :std/list/list every))

(export PooFlowTemporalConclusionRevision PooFlowTemporalConclusionJournal
        PooFlowTemporalSelectionObservation PooFlowTemporalSelectionPlan
        poo-flow-temporal-conclusion-revision?
        poo-flow-temporal-conclusion-journal?
        poo-flow-temporal-selection-observation?
        poo-flow-temporal-selection-plan?)

(def (text? value) (and (string? value) (> (string-length value) 0)))
(def (natural? value)
  (and (integer? value) (exact? value) (>= value 0)))
(def (slots? value names)
  (and (object? value) (every (lambda (name) (.slot? value name)) names)))

(def (revision-shape? value)
  (and (slots? value '(kind identity subject-identity scope-identity
                             cut-digest projection-digest policy-identity
                             generation-identity
                             operation predecessor-identity result-identity
                             proof-identity invalidation-index-digest))
       (eq? (.ref value 'kind) 'poo-flow.temporal-causality.conclusion-revision)
       (every text? (list (.ref value 'identity) (.ref value 'subject-identity)
                          (.ref value 'scope-identity) (.ref value 'cut-digest)
                          (.ref value 'projection-digest)
                          (.ref value 'policy-identity)
                          (.ref value 'generation-identity)
                          (.ref value 'proof-identity)))
       (case (.ref value 'operation)
         ((assert)
          (and (not (.ref value 'predecessor-identity))
               (text? (.ref value 'result-identity))
               (not (.ref value 'invalidation-index-digest))))
         ((correct)
          (and (text? (.ref value 'predecessor-identity))
               (text? (.ref value 'result-identity))
               (text? (.ref value 'invalidation-index-digest))))
         ((retract)
          (and (text? (.ref value 'predecessor-identity))
               (not (.ref value 'result-identity))
               (text? (.ref value 'invalidation-index-digest))))
         (else #f))))
(define-type (PooFlowTemporalConclusionRevision @ Type.)
  .element?: revision-shape?)
(def (poo-flow-temporal-conclusion-revision? value)
  (element? PooFlowTemporalConclusionRevision value))

(def (journal-shape? value)
  (and (slots? value '(kind identity semantic-digest revisions))
       (eq? (.ref value 'kind) 'poo-flow.temporal-causality.conclusion-journal)
       (text? (.ref value 'identity))
       (text? (.ref value 'semantic-digest))
       (list? (.ref value 'revisions))
       (every poo-flow-temporal-conclusion-revision?
              (.ref value 'revisions))))
(define-type (PooFlowTemporalConclusionJournal @ Type.)
  .element?: journal-shape?)
(def (poo-flow-temporal-conclusion-journal? value)
  (element? PooFlowTemporalConclusionJournal value))

(def (observation-shape? value)
  (and (slots? value '(kind identity subject-identity scope-identity
                             version selected-revision-identity))
       (eq? (.ref value 'kind) 'poo-flow.temporal-causality.selection-observation)
       (every text? (list (.ref value 'identity) (.ref value 'subject-identity)
                          (.ref value 'scope-identity)))
       (natural? (.ref value 'version))
       (or (not (.ref value 'selected-revision-identity))
           (text? (.ref value 'selected-revision-identity)))))
(define-type (PooFlowTemporalSelectionObservation @ Type.)
  .element?: observation-shape?)
(def (poo-flow-temporal-selection-observation? value)
  (element? PooFlowTemporalSelectionObservation value))

(def (plan-shape? value)
  (and (slots? value '(kind journal-digest observation-identity
                             subject-identity scope-identity
                             expected-version expected-revision-identity
                             observed-version observed-revision-identity
                             proposed-version proposed-revision-identity
                             change-proof-identity status
                             requires-atomic-cas? runtime-executed?))
       (eq? (.ref value 'kind) 'poo-flow.temporal-causality.selection-plan)
       (every text? (list (.ref value 'journal-digest)
                          (.ref value 'observation-identity)
                          (.ref value 'subject-identity)
                          (.ref value 'scope-identity)
                          (.ref value 'expected-revision-identity)
                          (.ref value 'proposed-revision-identity)
                          (.ref value 'change-proof-identity)))
       (natural? (.ref value 'expected-version))
       (natural? (.ref value 'observed-version))
       (or (not (.ref value 'observed-revision-identity))
           (text? (.ref value 'observed-revision-identity)))
       (memq (.ref value 'status) '(cas-ready conflict))
       (if (eq? (.ref value 'status) 'cas-ready)
         (and (natural? (.ref value 'proposed-version))
              (= (.ref value 'proposed-version)
                 (+ 1 (.ref value 'expected-version))))
         (not (.ref value 'proposed-version)))
       (eq? (.ref value 'requires-atomic-cas?) #t)
       (eq? (.ref value 'runtime-executed?) #f)))
(define-type (PooFlowTemporalSelectionPlan @ Type.)
  .element?: plan-shape?)
(def (poo-flow-temporal-selection-plan? value)
  (element? PooFlowTemporalSelectionPlan value))
