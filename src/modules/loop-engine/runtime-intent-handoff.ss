;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Assembles the final runtime handoff facts from one materialized request.
;;; This owner depends on request and proof identities without rebuilding them.
(import "core.ss"
        "runtime-base.ss"
        "runtime-intent-receipts.ss"
        "runtime-intent-request.ss"
        "runtime-intent-manifest.ss")

(export poo-flow-user-loop-engine-intent-runtime-handoff-facts
        poo-flow-user-loop-engine-runtime-handoff-facts/from-request)

(def (poo-flow-user-loop-engine-runtime-handoff-facts/from-request
      intent
      request)
  (let* ((workflow-agreement
          (poo-flow-user-loop-engine-intent-workflow-agreement intent))
         (sandbox-agreement
          (poo-flow-user-loop-engine-intent-sandbox-handoff-agreement
           intent))
         (workflow-valid?
          (poo-flow-user-loop-engine-intent-ref
           workflow-agreement
           'valid?
           #f))
         (sandbox-ready?
          (poo-flow-user-loop-engine-intent-ref
           sandbox-agreement
           'handoff-ready?
           #f)))
    (append
     (list
      (cons 'kind 'loop-engine-runtime-handoff)
      (cons 'contract 'poo-flow.loop-governor.runtime-handoff.v1)
      (cons 'runtime-handoff
            (poo-flow-user-loop-engine-intent-ref
             intent
             'runtime-handoff
             'loop-governor-marlin-runtime-manifest))
      (cons 'runtime-command-contract
            +poo-flow-user-loop-engine-runtime-command-contract+)
      (cons 'object-families
            +poo-flow-user-loop-engine-runtime-object-families+)
      (cons 'receipt-contracts
            +poo-flow-user-loop-engine-receipt-contracts+)
      (cons 'runtime-packet-contracts
            +poo-flow-user-loop-engine-runtime-packet-contracts+)
      (cons 'workflow-ref
            (poo-flow-user-loop-engine-intent-workflow-ref intent))
      (cons 'action-kind
            (poo-flow-user-loop-engine-intent-runtime-action-kind intent))
      (cons 'workflow-valid? workflow-valid?)
      (cons 'sandbox-handoff-ready? sandbox-ready?)
      (cons 'handoff-ready? (and workflow-valid? sandbox-ready?))
      (cons 'proof-manifest
            (poo-flow-user-loop-engine-intent-proof-manifest intent))
      (cons 'descriptor-realized? #f)
      (cons 'runtime-owner "marlin-agent-core")
      (cons 'runtime-executed #f))
     request)))

(def (poo-flow-user-loop-engine-intent-runtime-handoff-facts intent)
  (poo-flow-user-loop-engine-runtime-handoff-facts/from-request
   intent
   (poo-flow-user-loop-engine-intent-runtime-request intent)))
