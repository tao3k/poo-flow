;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Historical conclusions are values. Selection is only a CAS proposal;
;;; no proof, authorization, pointer update or effect is executed here.
(import (only-in :clan/poo/object .ref)
        (only-in :std/crypto/digest sha256)
        (only-in :std/encoding/hex hex-encode)
        (only-in :std/list/list every find)
        (only-in :poo-flow/modules/temporal-causality/truth-maintenance/types
                 poo-flow-temporal-invalidation-plan?)
        (only-in :poo-flow/modules/temporal-causality/conclusions/types
                 poo-flow-temporal-conclusion-revision?
                 poo-flow-temporal-conclusion-journal?
                 poo-flow-temporal-selection-observation?)
        (only-in :poo-flow/modules/temporal-causality/conclusions/objects
                 poo-flow-temporal-conclusion-revision-value
                 poo-flow-temporal-conclusion-journal-value
                 poo-flow-temporal-selection-plan-value))

(export poo-flow-temporal-conclusion-root
        poo-flow-temporal-conclusion-change
        poo-flow-temporal-conclusion-journal
        poo-flow-temporal-conclusion-journal-extend
        poo-flow-temporal-selection-prepare)

(def (text? value)
  (and (string? value) (> (string-length value) 0)))
(def (natural? value)
  (and (integer? value) (exact? value) (>= value 0)))
(def (digest datum)
  (string-append
   "sha256:"
   (hex-encode
    (sha256
     (string->utf8
      (call-with-output-string (lambda (port) (write datum port))))))))

;;; A root conclusion carries an evaluator-owned proof identity. This type
;;; validates the envelope, not the theorem or domain result it names.
(def (poo-flow-temporal-conclusion-root
      identity subject scope cut projection policy generation result proof)
  (poo-flow-temporal-conclusion-revision-value
   identity subject scope cut projection policy generation
   'assert #f result proof #f))

;;; The invalidation plan establishes only the reevaluation frontier. The
;;; caller supplies a separate proof identity for the corrected/retracted
;;; result; the actual proof admission remains with its evaluator.
(def (poo-flow-temporal-conclusion-change
      identity previous plan operation result proof policy generation)
  (unless (and (poo-flow-temporal-conclusion-revision? previous)
               (poo-flow-temporal-invalidation-plan? plan)
               (text? identity) (text? proof) (text? policy)
               (text? generation)
               (not (equal? identity (.ref previous 'identity)))
               (memq operation '(correct retract))
               (not (eq? (.ref previous 'operation) 'retract))
               (eq? (.ref plan 'status) 'scoped-complete)
               (member (.ref previous 'identity)
                       (.ref plan 'affected-conclusion-identities))
               (equal? (.ref previous 'cut-digest)
                       (.ref plan 'previous-cut-digest))
               (equal? (.ref previous 'projection-digest)
                       (.ref plan 'previous-projection-digest))
               (or (not (equal? (.ref previous 'cut-digest)
                                (.ref plan 'revised-cut-digest)))
                   (not (equal? (.ref previous 'projection-digest)
                                (.ref plan 'revised-projection-digest))))
               (if (eq? operation 'correct) (text? result) (not result)))
    (error "conclusion change lacks a complete affected frontier or proof binding"))
  (poo-flow-temporal-conclusion-revision-value
   identity (.ref previous 'subject-identity) (.ref previous 'scope-identity)
   (.ref plan 'revised-cut-digest) (.ref plan 'revised-projection-digest)
   policy generation operation
   (.ref previous 'identity) result proof (.ref plan 'index-digest)))

(def (revision-row revision)
  (map (lambda (slot) (.ref revision slot))
       '(identity subject-identity scope-identity cut-digest projection-digest
         policy-identity
         generation-identity operation predecessor-identity result-identity
         proof-identity invalidation-index-digest)))

;;; A journal is a finite immutable graph. Correction branches are retained;
;;; they are not resolved by identity order or a latest-value rule.
(def (poo-flow-temporal-conclusion-journal identity revisions)
  (unless (and (text? identity) (list? revisions)
               (every poo-flow-temporal-conclusion-revision? revisions))
    (error "invalid temporal conclusion journal"))
  (let ((index (make-hash-table))
        (color (make-hash-table)))
    (for-each
     (lambda (revision)
       (let (id (.ref revision 'identity))
         (when (hash-get index id)
           (error "duplicate temporal conclusion revision" id))
         (hash-put! index id revision)))
     revisions)
    (for-each
     (lambda (revision)
       (let (predecessor-id (.ref revision 'predecessor-identity))
         (when predecessor-id
           (let (predecessor (hash-get index predecessor-id))
             (unless (and predecessor
                          (equal? (.ref predecessor 'subject-identity)
                                  (.ref revision 'subject-identity))
                          (equal? (.ref predecessor 'scope-identity)
                                  (.ref revision 'scope-identity))
                          (not (eq? (.ref predecessor 'operation) 'retract))
                          (or (not (equal? (.ref predecessor 'cut-digest)
                                           (.ref revision 'cut-digest)))
                              (not (equal? (.ref predecessor 'projection-digest)
                                           (.ref revision 'projection-digest)))))
               (error "invalid temporal conclusion supersession" predecessor-id))))))
     revisions)
    (def (visit! revision)
      (let (id (.ref revision 'identity))
        (case (hash-get color id)
          ((done) (void))
          ((visiting) (error "cyclic temporal conclusion supersession" id))
          (else
           (hash-put! color id 'visiting)
           (let (predecessor-id (.ref revision 'predecessor-identity))
             (when predecessor-id (visit! (hash-get index predecessor-id))))
           (hash-put! color id 'done)))))
    (for-each visit! revisions)
    (let (canonical
          (list-sort (lambda (a b)
                       (string<? (.ref a 'identity) (.ref b 'identity)))
                     revisions))
      (poo-flow-temporal-conclusion-journal-value
       identity
       (digest (list 'poo-flow.temporal-conclusion-journal.v1
                     identity (map revision-row canonical)))
       canonical))))

;;; Preserve every old row when admitting a new set of revision envelopes.
(def (poo-flow-temporal-conclusion-journal-extend journal additions)
  (unless (and (poo-flow-temporal-conclusion-journal? journal)
               (list? additions) (pair? additions)
               (every poo-flow-temporal-conclusion-revision? additions))
    (error "invalid temporal conclusion journal extension"))
  (poo-flow-temporal-conclusion-journal
   (.ref journal 'identity)
   (append (.ref journal 'revisions) additions)))

;;; Prepare an external compare-and-swap over a versioned active pointer.
;;; A ready plan can still lose a race before the runtime commits it.
(def (poo-flow-temporal-selection-prepare
      journal proposed observation expected-version)
  (unless (and (poo-flow-temporal-conclusion-journal? journal)
               (poo-flow-temporal-conclusion-revision? proposed)
               (poo-flow-temporal-selection-observation? observation)
               (natural? expected-version)
               (memq (.ref proposed 'operation) '(correct retract))
               (equal? (.ref proposed 'subject-identity)
                       (.ref observation 'subject-identity))
               (equal? (.ref proposed 'scope-identity)
                       (.ref observation 'scope-identity)))
    (error "invalid temporal active-selection request"))
  (let (stored
        (find (lambda (entry)
                (equal? (.ref entry 'identity) (.ref proposed 'identity)))
              (.ref journal 'revisions)))
    (unless (and stored (equal? (revision-row stored) (revision-row proposed)))
      (error "selected revision differs from journal evidence")))
  (let* ((expected-id (.ref proposed 'predecessor-identity))
         (ready? (and (= expected-version (.ref observation 'version))
                      (equal? expected-id
                              (.ref observation 'selected-revision-identity)))))
    (poo-flow-temporal-selection-plan-value
     (.ref journal 'semantic-digest) (.ref observation 'identity)
     (.ref proposed 'subject-identity) (.ref proposed 'scope-identity)
     expected-version expected-id
     (and ready? (+ expected-version 1))
     (.ref observation 'version)
     (.ref observation 'selected-revision-identity)
     (.ref proposed 'identity) (.ref proposed 'proof-identity)
     (if ready? 'cas-ready 'conflict))))
