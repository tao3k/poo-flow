;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Optional module role: relations spanning Provider and capability values.
(import (only-in :clan/poo/object .o .ref)
        (only-in :std/crypto/digest sha256)
        (only-in :std/srfi/1 delete-duplicates every find)
        (only-in :std/text/hex hex-encode)
        (only-in :poo-flow/src/modules/authorization/types
                 poo-flow-authorization-provider?
                 poo-flow-authorization-capability?))

(export poo-flow-authorization-capabilities-digest
        poo-flow-authorization-capability-contract)

(def (require-authorization-values provider capabilities)
  (unless (poo-flow-authorization-provider? provider)
    (error "authorization contract requires a Provider" provider))
  (unless (and (pair? capabilities)
               (every poo-flow-authorization-capability? capabilities))
    (error "authorization contract requires typed capabilities" capabilities)))

(def (authorization-capabilities-digest provider capabilities)
  (string-append
   "sha256:"
   (hex-encode
    (sha256
     (call-with-output-string
      (lambda (port)
        (write
         (list 'poo-flow.authorization-capability-contract.v1
               (.ref provider 'identity)
               (.ref provider 'engines)
               (.ref provider 'arbitration)
               (.ref provider 'runtime-owner)
               (map (lambda (capability)
                      (list (.ref capability 'identity)
                            (.ref capability 'action)
                            (.ref capability 'event-kind)
                            (.ref capability 'risk)))
                    capabilities))
         port)))))))

(def (poo-flow-authorization-capabilities-digest provider capabilities)
  (require-authorization-values provider capabilities)
  (authorization-capabilities-digest provider capabilities))

(def (poo-flow-authorization-capability-contract
      provider-value capability-values)
  (require-authorization-values provider-value capability-values)
  (unless (= (length (.ref provider-value 'engines))
             (length (delete-duplicates (.ref provider-value 'engines))))
    (error "authorization Provider engine identities must be distinct"
           (.ref provider-value 'engines)))
  (unless (or (not (find (lambda (capability)
                           (eq? (.ref capability 'risk) 'elevated))
                         capability-values))
              (eq? (.ref provider-value 'arbitration) 'strict-lockstep))
    (error "elevated authority requires strict lockstep" capability-values))
  (.o kind: 'poo-flow.authorization-capability-contract
      provider: (.ref provider-value 'identity)
      capability-identities:
      (map (lambda (capability) (.ref capability 'identity)) capability-values)
      contract-digest:
      (authorization-capabilities-digest provider-value capability-values)
      admitted?: #t
      runtime-executed?: #f))
