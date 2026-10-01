;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Immutable evidence history; active selection is a pure as-of projection.
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element?)
        (only-in :std/list/list every)
        (only-in :poo-flow/modules/temporal-causality/time/types
                 poo-flow-temporal-instant? poo-flow-temporal-interval?))

(export poo-flow-temporal-evidence-revision-kind
        poo-flow-temporal-evidence-journal-kind
        poo-flow-temporal-evidence-snapshot-kind
        PooFlowTemporalEvidenceRevision PooFlowTemporalEvidenceJournal
        PooFlowTemporalEvidenceSnapshot
        poo-flow-temporal-evidence-revision?
        poo-flow-temporal-evidence-journal?
        poo-flow-temporal-evidence-snapshot?)

(def poo-flow-temporal-evidence-revision-kind
  'poo-flow.temporal-causality.evidence-revision)
(def poo-flow-temporal-evidence-journal-kind
  'poo-flow.temporal-causality.evidence-journal)
(def poo-flow-temporal-evidence-snapshot-kind
  'poo-flow.temporal-causality.evidence-snapshot)

(def (text? value)
  (and (string? value) (> (string-length value) 0)))
(def (slots? value names)
  (and (object? value) (every (lambda (name) (.slot? value name)) names)))
(def (text-list? value)
  (and (list? value) (every text? value)))

(def (revision-shape? value)
  (and (slots? value '(kind identity subject-identity operation
                             predecessor-identity admission-instant
                             valid-interval content-identity))
       (eq? (.ref value 'kind) poo-flow-temporal-evidence-revision-kind)
       (text? (.ref value 'identity))
       (text? (.ref value 'subject-identity))
       (poo-flow-temporal-instant? (.ref value 'admission-instant))
       (eq? (.ref (.ref value 'admission-instant) 'modality) 'observed)
       (case (.ref value 'operation)
         ((assert)
          (and (not (.ref value 'predecessor-identity))
               (poo-flow-temporal-interval? (.ref value 'valid-interval))
               (text? (.ref value 'content-identity))))
         ((correct)
          (and (text? (.ref value 'predecessor-identity))
               (poo-flow-temporal-interval? (.ref value 'valid-interval))
               (text? (.ref value 'content-identity))))
         ((retract)
          (and (text? (.ref value 'predecessor-identity))
               (not (.ref value 'valid-interval))
               (not (.ref value 'content-identity))))
         (else #f))))

(define-type (PooFlowTemporalEvidenceRevision @ Type.)
  .element?: revision-shape?)
(def (poo-flow-temporal-evidence-revision? value)
  (element? PooFlowTemporalEvidenceRevision value))

(def (journal-shape? value)
  (and (slots? value '(kind identity semantic-digest admission-domain-identity
                             revisions))
       (eq? (.ref value 'kind) poo-flow-temporal-evidence-journal-kind)
       (every text? (list (.ref value 'identity)
                          (.ref value 'semantic-digest)
                          (.ref value 'admission-domain-identity)))
       (list? (.ref value 'revisions))
       (every poo-flow-temporal-evidence-revision?
              (.ref value 'revisions))))

(define-type (PooFlowTemporalEvidenceJournal @ Type.)
  .element?: journal-shape?)
(def (poo-flow-temporal-evidence-journal? value)
  (element? PooFlowTemporalEvidenceJournal value))

(def (snapshot-shape? value)
  (and (slots? value
               '(kind journal-digest cut-digest projection-digest
                      as-of-instant-identity valid-at-instant-identity
                      valid-at-instant-digest active-revision-identities
                      retracted-subject-identities conflicted-subject-identities
                      outside-valid-subject-identities uncertain-subject-identities
                      incomparable-subject-identities
                      visible-revision-identities future-revision-identities
                      runtime-executed?))
       (eq? (.ref value 'kind) poo-flow-temporal-evidence-snapshot-kind)
       (every text? (list (.ref value 'journal-digest)
                          (.ref value 'cut-digest)
                          (.ref value 'projection-digest)
                          (.ref value 'as-of-instant-identity)))
       (or (not (.ref value 'valid-at-instant-identity))
           (text? (.ref value 'valid-at-instant-identity)))
       (or (and (not (.ref value 'valid-at-instant-identity))
                (not (.ref value 'valid-at-instant-digest)))
           (and (text? (.ref value 'valid-at-instant-identity))
                (text? (.ref value 'valid-at-instant-digest))))
       (every (lambda (slot) (text-list? (.ref value slot)))
              '(active-revision-identities retracted-subject-identities
                conflicted-subject-identities outside-valid-subject-identities
                uncertain-subject-identities incomparable-subject-identities
                visible-revision-identities
                future-revision-identities))
       (eq? (.ref value 'runtime-executed?) #f)))

(define-type (PooFlowTemporalEvidenceSnapshot @ Type.)
  .element?: snapshot-shape?)
(def (poo-flow-temporal-evidence-snapshot? value)
  (element? PooFlowTemporalEvidenceSnapshot value))
