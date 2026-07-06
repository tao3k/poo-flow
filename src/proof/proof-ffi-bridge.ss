(import :poo-flow/src/proof/proof-fact-wire
        :poo-flow/src/proof/proof-gate-decision)

(export poo-flow-proof-gate-decision->ffi-payload
        poo-flow-proof-gate-receipts->ffi-payload
        poo-flow-langgraph-user-interface-proof-ffi-payload)

(def (poo-flow-proof-gate-decision->ffi-payload decision)
  (let ((bundle (poo-flow-proof-fact-ref 'bundle decision)))
    (list (cons 'schema 'poo-flow.proof.ffi-bridge.payload)
          (cons 'version 1)
          (cons 'accepted? (poo-flow-proof-fact-ref 'accepted? decision))
          (cons 'runtime-boundary-ok?
                (poo-flow-proof-fact-ref 'runtime-boundary-ok? decision))
          (cons 'rejection-reasons
                (poo-flow-proof-fact-ref 'rejection-reasons decision))
          (cons 'composition-wire
                (poo-flow-proof-fact-ref 'composition bundle))
          (cons 'scenario-wire
                (poo-flow-proof-fact-ref 'scenario bundle))
          (cons 'handoff-wire
                (poo-flow-proof-fact-ref 'handoff bundle)))))

(def (poo-flow-proof-gate-receipts->ffi-payload receipts)
  (poo-flow-proof-gate-decision->ffi-payload
   (poo-flow-proof-gate-receipts->decision receipts)))

(def (poo-flow-langgraph-user-interface-proof-ffi-payload)
  (poo-flow-proof-gate-decision->ffi-payload
   (poo-flow-langgraph-user-interface-proof-gate-decision)))
