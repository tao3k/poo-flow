;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; Pure proof-bound revisions; no durable append, current-pointer CAS or effect.
(import (only-in :clan/poo/object .ref)
        (only-in :std/list/list every)
        (only-in :std/crypto/digest sha256)
        (only-in :std/encoding/hex hex-encode)
        (only-in :poo-flow/modules/temporal-causality/admission/interface
                 poo-flow-temporal-family-admission-replay)
        (only-in :poo-flow/modules/temporal-causality/conclusions/funs
                 poo-flow-temporal-conclusion-change poo-flow-temporal-conclusion-journal)
        (only-in :poo-flow/modules/temporal-causality/lifecycle/types
                 poo-flow-temporal-family-revision?)
        (only-in :poo-flow/modules/temporal-causality/lifecycle/objects
                 poo-flow-temporal-family-revision-value))
(export poo-flow-temporal-family-revision-root poo-flow-temporal-family-revision-change
        poo-flow-temporal-family-revision-replay poo-flow-temporal-family-revision-journal)
(def revision-slots
  '(identity subject-identity scope-identity cut-digest projection-digest policy-identity
    generation-identity operation predecessor-identity result-identity proof-identity
    invalidation-index-digest))
(def frontier-slots
  '(index-identity index-digest previous-cut-digest revised-cut-digest
    previous-projection-digest revised-projection-digest changed-subject-identities
    affected-conclusion-identities status inventory-complete? trigger))
(def (row value slots) (map (lambda (slot) (.ref value slot)) slots))
(def (digest value)
  (string-append "sha256:" (hex-encode (sha256 (string->utf8
    (call-with-output-string (lambda (port) (write value port))))))))
(def (make-revision admission revision predecessor frontier)
  (poo-flow-temporal-family-revision-value
   (digest (list 'poo-flow.temporal-family-revision.v1
                 (.ref admission 'semantic-digest) (row revision revision-slots)
                 (and predecessor (.ref predecessor 'semantic-digest))
                 (and frontier (row frontier frontier-slots))))
   admission revision predecessor frontier))
(def (poo-flow-temporal-family-revision-root admission)
  (let (canonical (poo-flow-temporal-family-admission-replay admission))
    (make-revision canonical (.ref canonical 'conclusion) #f #f)))
(def (change previous admission frontier operation)
  (let* ((old (.ref previous 'admission))
         (prior-source (.ref old 'source)) (source (.ref admission 'source))
         (revision (.ref previous 'revision))
         (proof (.ref (.ref admission 'conclusion) 'proof-identity)))
    (unless (and (memq operation '(correct retract))
                 (every (lambda (slot) (equal? (.ref prior-source slot) (.ref source slot)))
                        '(identity authority-identity subject-identity scope-identity))
                 (equal? (.ref old 'conclusion-identity) (.ref admission 'conclusion-identity))
                 (equal? (.ref (.ref old 'model) 'identity) (.ref (.ref admission 'model) 'identity))
                 (equal? (row (.ref old 'query) '(identity hypothesis-identity exploration-limit))
                         (row (.ref admission 'query) '(identity hypothesis-identity exploration-limit)))
                 (> (.ref source 'generation) (.ref prior-source 'generation))
                 (eq? (.ref frontier 'inventory-complete?) #t)
                 (equal? (.ref source 'cut-digest) (.ref frontier 'revised-cut-digest))
                 (equal? (.ref source 'projection-digest) (.ref frontier 'revised-projection-digest))
                 ;; Refutation is scoped to this replayed family query. A frontier alone
                 ;; does not authorize withdrawal or prove support stabilization.
                 (or (eq? operation 'correct)
                     (and (memq (.ref old 'classification) '(possible necessary))
                          (eq? (.ref admission 'classification) 'refuted))))
      (error "family revision scope, generation, cut or retraction proof differs"))
    (let (proposed
          (poo-flow-temporal-conclusion-change
           (digest (list 'poo-flow.temporal-family-change.v1 (.ref revision 'identity)
                         (.ref admission 'semantic-digest) operation (row frontier frontier-slots)))
           revision frontier operation (and (eq? operation 'correct) proof) proof
           (.ref source 'policy-identity) (number->string (.ref source 'generation))))
      (make-revision admission proposed previous frontier))))
(def (poo-flow-temporal-family-revision-change previous admission frontier operation)
  (change (poo-flow-temporal-family-revision-replay previous)
          (poo-flow-temporal-family-admission-replay admission) frontier operation))
(def (poo-flow-temporal-family-revision-replay value)
  (def (walk value ancestors)
    (unless (poo-flow-temporal-family-revision? value) (error "invalid family revision"))
    (let (id (.ref (.ref value 'revision) 'identity))
      (when (member id ancestors) (error "cyclic family revision predecessor"))
      (let* ((admission (poo-flow-temporal-family-admission-replay (.ref value 'admission)))
             (canonical
              (if (.ref value 'predecessor)
                (change (walk (.ref value 'predecessor) (cons id ancestors))
                        admission (.ref value 'frontier) (.ref (.ref value 'revision) 'operation))
                (poo-flow-temporal-family-revision-root admission))))
        (unless (and (equal? (.ref canonical 'semantic-digest) (.ref value 'semantic-digest))
                     (equal? (row (.ref canonical 'revision) revision-slots)
                             (row (.ref value 'revision) revision-slots)))
          (error "family revision proof or journal binding mismatch"))
        canonical)))
  (walk value '()))
(def (poo-flow-temporal-family-revision-journal identity values)
  (poo-flow-temporal-conclusion-journal
   identity (map (lambda (value)
                   (.ref (poo-flow-temporal-family-revision-replay value) 'revision)) values)))
