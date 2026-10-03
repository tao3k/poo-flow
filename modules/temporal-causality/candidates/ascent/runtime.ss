;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .ref)
 (only-in :std/crypto/digest sha256) (only-in :std/encoding/hex hex-encode)
 (only-in :std/list/list find)
 (only-in :gerbil-ascent/candidate/reasoning reasoning-source-snapshot reasoning-attempt reasoning-receipt?
  reasoning-receipt-bound? reasoning-receipt-status reasoning-receipt-candidate-digest reasoning-receipt-rows reasoning-receipt-proof)
 (only-in :gerbil-ascent/candidate/program candidate-inspect)
 (only-in :gerbil-ascent/candidate/provenance positive-proof? positive-proof-status candidate-verify-positive-proof
  positive-proof-snapshot-identity positive-proof-snapshot-generation positive-proof-snapshot-digest
  positive-proof-candidate-digest positive-proof-query positive-proof-work-budget positive-proof-nodes positive-proof-roots
  proof-node-id proof-node-kind proof-node-relation proof-node-row proof-node-label proof-node-inputs)
 (only-in :poo-flow/modules/temporal-causality/candidates/funs poo-flow-candidate-receipt poo-flow-candidate-check poo-flow-candidate-exchange)
 (only-in :poo-flow/modules/temporal-causality/time/authority-funs poo-flow-temporal-source-authenticate)
 (only-in :poo-flow/modules/temporal-causality/time/authority-types poo-flow-temporal-source-authority?)
 (only-in :poo-flow/modules/temporal-causality/conclusions/evaluation-funs poo-flow-temporal-evaluate)
 "types.ss" "objects.ss" "funs.ss")
(export poo-flow-ascent-candidate-execute! poo-flow-ascent-candidate-verify poo-flow-ascent-candidate-admission)
(def (digest v) (string-append "sha256:" (hex-encode (sha256 (string->utf8 (object->string v))))))
;;; Injective IDs stay constants, including identities that contain '?'.
(def (proof-content proof)
 (and (positive-proof? proof)
  (list (positive-proof-status proof) (positive-proof-snapshot-identity proof)
        (positive-proof-snapshot-generation proof) (positive-proof-snapshot-digest proof)
        (positive-proof-candidate-digest proof) (positive-proof-query proof) (positive-proof-work-budget proof)
        (map (lambda (n) (list (proof-node-id n) (proof-node-kind n) (proof-node-relation n)
                              (proof-node-row n) (proof-node-label n) (proof-node-inputs n))) (positive-proof-nodes proof))
        (positive-proof-roots proof))))
(def (key id) (string->symbol (string-append "temporal/" id)))
(def (native-inputs request)
 (let* ((scope (.ref request 'scope)) (model (.ref request 'model)) (query (.ref request 'query))
        (h (find (lambda (h) (equal? (.ref h 'identity) (.ref query 'hypothesis-identity))) (.ref model 'hypotheses))))
  (values
   (reasoning-source-snapshot (.ref request 'binding-digest) (.ref scope 'generation)
    (list (list 'observation 4
      (map (lambda (o) (list (key (.ref o 'identity)) (key (.ref o 'domain-identity))
                            (.ref o 'logical-position) (key (.ref o 'provenance-identity))))
           (filter (lambda (o) (eq? (.ref o 'modality) 'observed)) (.ref model 'observations))))
     (list 'hypothesis 3 (map (lambda (h) (map key (map (lambda (s) (.ref h s))
                                           '(identity cause-observation-id effect-observation-id)))) (.ref model 'hypotheses)))))
   (list 'candidate '(relation consistent 3)
    '(rule (consistent ?h ?c ?e) (hypothesis ?h ?c ?e)
           (observation ?c ?d ?tc ?sc) (observation ?e ?d ?te ?se) (where (< ?tc ?te)))
    (list 'query 'consistent (key (.ref h 'identity)) (key (.ref h 'cause-observation-id)) (key (.ref h 'effect-observation-id)))
    (list 'limits (.ref request 'iterations) (.ref request 'derived-limit) (.ref request 'output-limit))))))
;;; Explicit provider execution boundary; completed preparation emits progress.
(def (poo-flow-ascent-candidate-execute! request)
 (let (request (poo-flow-ascent-candidate-request-replay request))
  (displayln "ASCENT-REQUEST-REPLAYED " (.ref request 'semantic-digest)) (force-output)
  (let-values (((snapshot proposal) (native-inputs request)))
   (displayln "ASCENT-SNAPSHOT-BUILT " (.ref request 'binding-digest)) (force-output)
   (poo-flow-ascent-execution-value (.ref request 'semantic-digest)
     (reasoning-attempt snapshot proposal (.ref request 'proof-work))))))
;;; Rebuild exact inputs and run ASCENT's independent proof interpreter.
;;; No caller-supplied verdict/basis and no receipt means of granting authority.
(def (poo-flow-ascent-candidate-verify request execution)
 (let (request (poo-flow-ascent-candidate-request-replay request))
  (unless (and (poo-flow-ascent-candidate-execution? execution)
               (equal? (.ref execution 'request-digest) (.ref request 'semantic-digest)))
    (error "ASCENT execution names another request"))
  (let-values (((snapshot proposal) (native-inputs request)))
   (let (native (.ref execution 'native-receipt))
    (unless (and (reasoning-receipt? native) (reasoning-receipt-bound? native snapshot proposal))
     (error "ASCENT receipt names another snapshot or program"))
    (let* ((status (reasoning-receipt-status native)) (proof (reasoning-receipt-proof native))
           (rows (reasoning-receipt-rows native))
           (verdict (cond ((and (positive-proof? proof) (not (= (positive-proof-work-budget proof) (.ref request 'proof-work)))) 'invalid)
                          ((not (eq? status 'complete)) 'unknown)
                          ((or (not (positive-proof? proof)) (not (eq? (positive-proof-status proof) 'complete))) 'unknown)
                          ((not (candidate-verify-positive-proof snapshot (candidate-inspect snapshot proposal)
                              (reasoning-receipt-candidate-digest native) status rows proof (.ref request 'proof-nodes))) 'invalid)
                          ((null? rows) 'unknown) ; no closed-absence claim in this profile
                          (else 'valid)))
           (scope (.ref request 'scope))
           (receipt (poo-flow-candidate-receipt (string-append (.ref request 'identity) "/receipt")
                       (.ref (.ref request 'query) 'hypothesis-identity) scope 'ascent (.ref request 'semantic-digest)
                       (.ref request 'binding-digest) (digest rows) (length rows) (eq? status 'complete)))
           (check (poo-flow-candidate-check (string-append (.ref request 'identity) "/check") receipt
                        "gerbil-ascent/positive-proof-v1" verdict
                        (digest (list (.ref request 'semantic-digest) (reasoning-receipt-candidate-digest native)
                                      status rows (proof-content proof))))))
      (poo-flow-candidate-exchange (string-append (.ref request 'identity) "/exchange")
        (.ref (.ref request 'query) 'hypothesis-identity) scope (list receipt) (list check)))))))
(def (poo-flow-ascent-candidate-admission request execution authority assertion as-of subject projection policy)
 (let* ((request (poo-flow-ascent-candidate-request-replay request))
        (exchange (poo-flow-ascent-candidate-verify request execution)) (scope (.ref request 'scope))
        (verified (and (poo-flow-temporal-source-authority? authority)
                   (equal? (.ref authority 'source) (.ref request 'source-identity))
                   (equal? (.ref scope 'source-coverage-digest) (.ref request 'binding-digest))
                   (poo-flow-temporal-source-authenticate authority assertion 'candidate-source-model-binding
                     (.ref request 'binding-digest) as-of)))
        (evaluation (and verified (eq? (.ref exchange 'status) 'reviewable)
                      (poo-flow-temporal-evaluate (.ref request 'model) (.ref request 'query) subject
                        (.ref scope 'identity) (.ref scope 'evidence-cut-digest) projection policy
                        (string-append "ascent-generation/" (number->string (.ref scope 'generation)))))))
  (poo-flow-ascent-admission-value exchange verified evaluation)))
