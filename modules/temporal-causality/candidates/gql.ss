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
        (only-in :poo-flow/modules/temporal-causality/candidates/types
                 poo-flow-candidate-scope?)
        (only-in :poo-flow/modules/temporal-causality/candidates/funs
                 poo-flow-candidate-receipt))
(export poo-flow-gql-candidate-receipt)

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
