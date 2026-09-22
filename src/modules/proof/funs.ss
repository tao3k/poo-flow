;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: pure Proof indexing, freshness and admission functions.
(import (only-in :clan/poo/object .o .ref)
        (only-in :clan/poo/mop validate)
        (only-in :std/crypto/digest sha256)
        (only-in :std/list/list every)
        (only-in :std/encoding/hex hex-encode)
        "types.ss")

(export poo-flow-proof-digest
        poo-flow-proof-artifact-index
        poo-flow-proof-receipt-index
        poo-flow-proof-refinement-current?
        poo-flow-proof-assurance)

(def (poo-flow-proof-digest value)
  (string-append
   "sha256:"
   (hex-encode
    (sha256
     (string->utf8
      (call-with-output-string (lambda (port) (write value port))))))))

(def (proof-index values identity-slot label)
  (let (index (make-hash-table))
    (for-each
     (lambda (value)
       (let (identity (.ref value identity-slot))
         (when (hash-get index identity)
           (error "duplicate Proof identity" label identity))
         (hash-put! index identity value)))
     values)
    index))

(def (poo-flow-proof-artifact-index artifacts)
  (unless (every poo-flow-proof-artifact? artifacts)
    (error "invalid Proof artifact collection"))
  (proof-index artifacts 'identity 'artifact))

(def (poo-flow-proof-receipt-index receipts)
  (unless (every poo-flow-proof-receipt? receipts)
    (error "invalid Proof receipt collection"))
  (proof-index receipts 'identity 'receipt))

(def (poo-flow-proof-refinement-current? binding artifact-index receipt-index)
  (and (poo-flow-proof-refinement-binding? binding)
       (let* ((upstream
               (hash-get artifact-index
                         (.ref binding 'upstream-artifact-identity)))
              (downstream
               (hash-get artifact-index
                         (.ref binding 'downstream-artifact-identity)))
              (receipt
               (hash-get receipt-index (.ref binding 'receipt-identity)))
              (impact (.ref binding 'impact-binding)))
         (and upstream downstream receipt
              (equal? (.ref upstream 'content-digest)
                      (.ref binding 'upstream-content-digest))
              (equal? (.ref downstream 'content-digest)
                      (.ref binding 'downstream-content-digest))
              (equal? (.ref receipt 'artifact-identity)
                      (.ref downstream 'identity))
              (equal? (.ref receipt 'artifact-content-digest)
                      (.ref downstream 'content-digest))
              (.ref receipt 'admitted?)
              (.ref binding 'admitted?)
              (equal? (.ref impact 'upstream-content-digest)
                      (.ref upstream 'content-digest))
              (equal? (.ref impact 'downstream-content-digest)
                      (.ref downstream 'content-digest))
              (eq? (.ref impact 'stale-downstream-policy) 'reject)))))

(def (poo-flow-proof-assurance identity-value artifact-values receipt-values
                               refinement-values)
  (unless (and (poo-flow-proof-text? identity-value)
               (pair? artifact-values) (pair? receipt-values)
               (pair? refinement-values)
               (every poo-flow-proof-artifact? artifact-values)
               (every poo-flow-proof-receipt? receipt-values)
               (every poo-flow-proof-refinement-binding? refinement-values))
    (error "Proof assurance requires artifacts, receipts and refinements"
           identity-value))
  (let* ((artifact-index-value
          (poo-flow-proof-artifact-index artifact-values))
         (receipt-index-value
          (poo-flow-proof-receipt-index receipt-values))
         (current-value
          (every
           (lambda (binding)
             (poo-flow-proof-refinement-current?
              binding artifact-index-value receipt-index-value))
           refinement-values))
         (digest-value
          (poo-flow-proof-digest
           (list
            'poo-flow.proof-assurance.v1 identity-value
            (map (lambda (artifact)
                   (list (.ref artifact 'identity)
                         (.ref artifact 'content-digest)))
                 artifact-values)
            (map (lambda (receipt)
                   (list (.ref receipt 'identity)
                         (.ref receipt 'artifact-content-digest)
                         (.ref receipt 'evidence-digest)
                         (.ref receipt 'admitted?)))
                 receipt-values)
            (map (lambda (binding)
                   (list (.ref binding 'identity)
                         (.ref binding 'upstream-content-digest)
                         (.ref binding 'downstream-content-digest)
                         (.ref binding 'receipt-identity)))
                 refinement-values)))))
    (validate
     PooFlowProofAssurance
     (.o kind: +poo-flow-proof-assurance-kind+
         identity: identity-value
         artifacts: artifact-values
         receipts: receipt-values
         refinements: refinement-values
         artifact-index: artifact-index-value
         receipt-index: receipt-index-value
         current?: current-value
         admitted?: current-value
         assurance-digest: digest-value
         runtime-executed?: #f))))
