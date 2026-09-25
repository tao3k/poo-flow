;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: semantic equivalence checks for indexed DomainCase resolution.

(import (only-in :poo-flow/src/module-system/observability/testing-case poo-flow-test-case)
         :std/test
        (only-in :clan/poo/object .ref)
        :poo-flow/src/feature-system/domain-case/contracts)

(export domain-case-indexed-resolution-test)

(def (slot-contract slot-id owner-id
                    (override-owner-ids '())
                    (witness-id #f))
  (poo-flow-case-slot-contract
   slot-id owner-id 'value 'required 'replace
   override-owner-ids witness-id (lambda (_value) #t)))

(def (method-contract contract-id subject-id
                      (kind 'method)
                      (refines-contract-ids '())
                      (witness-id #f)
                      (witness #f))
  (poo-flow-case-method-contract
   contract-id contract-id subject-id kind 'Resolution
   'any 'receipt (lambda (_context) #t)
   refines-contract-ids witness-id witness))

(def domain-case-indexed-resolution-test
  (test-suite "DomainCase indexed resolution semantics"
    (poo-flow-test-case "slot replacement keeps the reference source order"
      (let* ((first-a (slot-contract 'a 'owner-a))
             (slot-b (slot-contract 'b 'owner-b))
             (replacement-a
              (slot-contract 'a 'owner-a2 '(owner-a) 'a-compatible-v1)))
        (let-values (((effective diagnostics)
                      (domain-case-resolve-slots
                       (list first-a slot-b replacement-a))))
          (check (map (lambda (slot) (.ref slot 'owner-id)) effective)
                 => '(owner-b owner-a2))
          (check diagnostics => '()))))

    (poo-flow-test-case "method replacement retains interleaved state contracts"
      (let* ((base (method-contract 'run-base 'run))
             (state (method-contract 'state-ready 'ready 'state))
             (refined
              (method-contract
               'run-refined 'run 'method '(run-base) 'run-compatible-v1
               (lambda (_candidate _inherited) #t))))
        (let-values (((effective diagnostics)
                      (domain-case-resolve-method-contracts
                       (list base state refined))))
          (check (map (lambda (contract) (.ref contract 'contract-id))
                      effective)
                 => '(state-ready run-refined))
          (check diagnostics => '()))))))
