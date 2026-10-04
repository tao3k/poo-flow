;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Pure admission relative to an explicitly trusted source-owner snapshot.
(import (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element? validate)
        (only-in :std/list/list every)
        (only-in :std/crypto/digest sha256)
        (only-in :std/encoding/hex hex-encode)
        (only-in :poo-flow/modules/temporal-causality/types
                 poo-flow-temporal-model? poo-flow-temporal-query?)
        (only-in :poo-flow/modules/temporal-causality/funs
                 poo-flow-temporal-model-replay poo-flow-temporal-model-classify)
        (only-in :poo-flow/modules/temporal-causality/conclusions/types
                 poo-flow-temporal-conclusion-revision?)
        (only-in :poo-flow/modules/temporal-causality/conclusions/funs
                 poo-flow-temporal-conclusion-root))
(export PooFlowTemporalSourceSnapshot PooFlowTemporalFamilyAdmission
        poo-flow-temporal-source-snapshot? poo-flow-temporal-family-admission?
        poo-flow-temporal-source-snapshot poo-flow-temporal-source-snapshot-replay
        poo-flow-temporal-family-admit)

(def (text? v) (and (string? v) (< 0 (string-length v) 129)))
(def (slots? v names)
  (and (object? v) (every (lambda (s) (.slot? v s)) names)))
(def metadata '(identity authority-identity subject-identity scope-identity
                       cut-digest projection-digest policy-identity generation))
(def (snapshot-shape? v)
  (and (slots? v (append '(kind semantic-digest model) metadata))
       (eq? (.ref v 'kind) 'poo-flow.temporal-causality.source-snapshot.v1)
       (every text? (map (lambda (s) (.ref v s)) (reverse (cdr (reverse metadata)))))
       (string? (.ref v 'semantic-digest))
       (exact-integer? (.ref v 'generation)) (>= (.ref v 'generation) 0)
       (poo-flow-temporal-model? (.ref v 'model))))
(define-type (PooFlowTemporalSourceSnapshot @ Type.) .element?: snapshot-shape?)
(def (poo-flow-temporal-source-snapshot? v) (element? PooFlowTemporalSourceSnapshot v))
(def (admission-shape? v)
  (and (slots? v '(kind semantic-digest source-digest model-digest query-identity
                        classification conclusion source-authenticated? action-authorized?))
       (eq? (.ref v 'kind) 'poo-flow.temporal-causality.family-admission.v1)
       (every string? (map (lambda (s) (.ref v s))
                          '(semantic-digest source-digest model-digest query-identity)))
       (memq (.ref v 'classification) '(possible necessary refuted))
       (poo-flow-temporal-conclusion-revision? (.ref v 'conclusion))
       (eq? (.ref v 'source-authenticated?) #f)
       (eq? (.ref v 'action-authorized?) #f)))
(define-type (PooFlowTemporalFamilyAdmission @ Type.) .element?: admission-shape?)
(def (poo-flow-temporal-family-admission? v) (element? PooFlowTemporalFamilyAdmission v))
(def (digest row)
  (string-append "sha256:" (hex-encode (sha256 (string->utf8
    (call-with-output-string (lambda (p) (write row p))))))))
(def (evidence-row model)
  (let (model (poo-flow-temporal-model-replay model))
    (list
     (map (lambda (d) (list (.ref d 'identity) (.ref d 'clock-role))) (.ref model 'domains))
     (map (lambda (o)
            (map (lambda (s) (.ref o s))
                 '(identity domain-identity logical-position provenance-identity modality)))
          (.ref model 'observations)))))

;;; The authority assertion is an explicit premise. Runtime must choose this
;;; snapshot from its host control lane, not accept it from a model payload.
(def (poo-flow-temporal-source-snapshot id authority subject scope cut projection policy generation-value model)
  (unless (and (every text? (list id authority subject scope cut projection policy))
               (exact-integer? generation-value) (>= generation-value 0))
    (error "invalid source snapshot scope"))
  (let* ((canonical (poo-flow-temporal-model-replay model))
         (binding (digest (list 'poo-flow.temporal-source-snapshot.v1 id authority
                                subject scope cut projection policy generation-value
                                (evidence-row canonical)))))
    (validate PooFlowTemporalSourceSnapshot
      (.o kind: 'poo-flow.temporal-causality.source-snapshot.v1
          identity: id authority-identity: authority subject-identity: subject
          scope-identity: scope cut-digest: cut projection-digest: projection
          policy-identity: policy generation: generation-value model: canonical
          semantic-digest: binding))))
(def (poo-flow-temporal-source-snapshot-replay source)
  (unless (poo-flow-temporal-source-snapshot? source) (error "invalid source snapshot"))
  (let (replayed (apply poo-flow-temporal-source-snapshot
                       (append (map (lambda (s) (.ref source s)) metadata)
                               (list (.ref source 'model)))))
    (unless (equal? (.ref replayed 'semantic-digest) (.ref source 'semantic-digest))
      (error "source snapshot digest mismatch"))
    replayed))

(def (poo-flow-temporal-family-admit model query source conclusion-id)
  (unless (and (poo-flow-temporal-query? query) (text? conclusion-id))
    (error "invalid family admission query"))
  (poo-flow-temporal-source-snapshot-replay source)
  (unless (equal? (evidence-row model) (evidence-row (.ref source 'model)))
    (error "family observations differ from registered source"))
  (let* ((receipt (poo-flow-temporal-model-classify model query))
         (classification-value (.ref receipt 'classification))
         (_ (when (eq? classification-value 'unknown)
              (error "unresolved family cannot admit a conclusion")))
         (proof (digest (list 'poo-flow.temporal-family-proof.v1
                             (.ref source 'semantic-digest) (.ref model 'semantic-digest)
                             (.ref query 'identity) (.ref query 'hypothesis-identity)
                             (.ref query 'exploration-limit) classification-value
                             (.ref receipt 'admissible-hypothesis-ids)
                             (.ref receipt 'refuted-hypothesis-ids)
                             (.ref receipt 'unknown-hypothesis-ids)
                             (.ref receipt 'unexplored-hypothesis-ids)
                             (.ref receipt 'exhausted?))))
         (revision-id
          (digest (list 'poo-flow.temporal-admitted-conclusion.v1 conclusion-id proof)))
         (conclusion-value
          (poo-flow-temporal-conclusion-root
           revision-id (.ref source 'subject-identity) (.ref source 'scope-identity)
           (.ref source 'cut-digest) (.ref source 'projection-digest)
           (.ref source 'policy-identity) (number->string (.ref source 'generation))
           proof proof)))
    (validate PooFlowTemporalFamilyAdmission
      (.o kind: 'poo-flow.temporal-causality.family-admission.v1
          semantic-digest: (digest (list proof conclusion-id))
          source-digest: (.ref source 'semantic-digest)
          model-digest: (.ref model 'semantic-digest)
          query-identity: (.ref query 'identity) classification: classification-value
          conclusion: conclusion-value source-authenticated?: #f action-authorized?: #f))))
