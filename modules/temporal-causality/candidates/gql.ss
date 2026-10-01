;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Bind a Query source receipt to an exact Temporal cut.  This projects
;;; declared provider metadata; it cannot verify result rows or execution.
(import (only-in :clan/poo/object .ref)
        (only-in :std/crypto/digest sha256)
        (only-in :std/encoding/hex hex-encode)
        (only-in :poo-flow/modules/query/types
                 poo-flow-query? poo-flow-query-element-space?
                 poo-flow-query-provider?
                 poo-flow-source-query-receipt?)
        (only-in :poo-flow/modules/query/funs poo-flow-query-admit)
        (only-in :poo-flow/modules/query/contracts
                 poo-flow-query-source-content-identity
                 poo-flow-query-bind-execution-receipt)
        (only-in :poo-flow/modules/query/objects
                 poo-flow-query-execution-candidate)
        (only-in :poo-flow/modules/query/results/types
                 poo-flow-query-result-set?)
        (only-in :poo-flow/modules/query/results/funs
                 poo-flow-query-result-set-replay)
        (only-in :poo-flow/modules/temporal-causality/candidates/types
                 poo-flow-candidate-scope? poo-flow-candidate-receipt?)
        (only-in :poo-flow/modules/temporal-causality/candidates/funs
                 poo-flow-candidate-receipt poo-flow-candidate-check))
(export poo-flow-gql-candidate-receipt poo-flow-gql-candidate-row-check)

(def (receipt-digest receipt)
  (string-append
   "sha256:"
   (hex-encode
    (sha256
     (string->utf8
      (call-with-output-string
       (lambda (port)
         (write
          (cons 'poo-flow.gql-source-receipt.v1
                (map (lambda (slot) (.ref receipt slot))
                     '(provider-identity query-identity query-version
                       semantic-revision source-content-identity
                       parser-identity provenance-root result-digest
                       result-count complete? result-contract-identity
                       admitted? diagnostics runtime-executed?
                       mutation-authority? action-authority?)))
          port))))))))

(def (poo-flow-gql-candidate-receipt id candidate scope query element-space
                                     provider source-receipt)
  (unless (and (poo-flow-candidate-scope? scope)
               (poo-flow-query? query)
               (poo-flow-query-element-space? element-space)
               (poo-flow-query-provider? provider)
               (poo-flow-source-query-receipt? source-receipt))
    (error "invalid GQL candidate bridge input"))
  (let* ((admission (poo-flow-query-admit query element-space))
         (source-digest (poo-flow-query-source-content-identity query))
         (execution-candidate
          (poo-flow-query-execution-candidate
           (.ref source-receipt 'provider-identity)
           (.ref source-receipt 'query-identity)
           (.ref source-receipt 'query-version)
           (.ref source-receipt 'semantic-revision)
           (.ref source-receipt 'source-content-identity)
           (.ref source-receipt 'parser-identity)
           (.ref source-receipt 'provenance-root)
           (.ref source-receipt 'result-digest)
           (.ref source-receipt 'result-count)
           (.ref source-receipt 'complete?)))
         (rebound
          (poo-flow-query-bind-execution-receipt
           provider query admission execution-candidate)))
    (unless (and (memq 'gql (.ref scope 'required-providers))
                 (equal? (.ref scope 'evidence-cut-digest)
                         (.ref element-space 'semantic-revision))
                 (.ref element-space 'complete?)
                 (.ref admission 'accepted?)
                 (.ref source-receipt 'admitted?)
                 (.ref rebound 'admitted?)
                 (equal? (receipt-digest source-receipt)
                         (receipt-digest rebound)))
      (error "GQL candidate receipt does not match Temporal cut and Query"))
    (poo-flow-candidate-receipt
     id candidate scope 'gql source-digest (receipt-digest source-receipt)
     (.ref source-receipt 'result-digest)
     (.ref source-receipt 'result-count)
     (.ref source-receipt 'complete?))))

;;; Only checks the supplied scalar rows against a declared result digest.
;;; It cannot attest that a Provider produced either the rows or the digest.
(def (poo-flow-gql-candidate-row-check id candidate-receipt query result-set)
  (unless (and (poo-flow-candidate-receipt? candidate-receipt)
               (poo-flow-query? query)
               (poo-flow-query-result-set? result-set))
    (error "invalid GQL candidate row-check input"))
  (let (result-set
        (poo-flow-query-result-set-replay
         result-set (.ref query 'result-contract)))
    (unless (and (>= (string-length (.ref candidate-receipt 'result-digest)) 29)
                 (string=?
                  (substring (.ref candidate-receipt 'result-digest) 0 29)
                  "poo-flow.query.scalar-row-v1:")
                 (eq? (.ref candidate-receipt 'provider-identity) 'gql)
                 (equal? (.ref candidate-receipt 'request-digest)
                         (poo-flow-query-source-content-identity query))
                 (equal? (.ref result-set 'query-identity)
                         (.ref query 'identity))
                 (equal? (.ref result-set 'query-version)
                         (.ref query 'version))
                 (equal? (.ref result-set 'semantic-revision)
                         (.ref query 'semantic-revision)))
      (error "GQL result set does not match candidate Query"))
    (poo-flow-candidate-check
     id candidate-receipt "poo-flow/query/scalar-row-check-v1"
     (cond ((or (not (equal? (.ref candidate-receipt 'result-digest)
                             (.ref result-set 'result-digest)))
                (not (= (.ref candidate-receipt 'result-count)
                        (.ref result-set 'result-count)))
                (not (eq? (.ref candidate-receipt 'complete?)
                          (.ref result-set 'complete?))))
            'invalid)
           ((not (.ref result-set 'complete?)) 'unknown)
           (else 'valid))
     (.ref result-set 'semantic-digest))))
