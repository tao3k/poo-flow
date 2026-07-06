(import :poo-flow/src/proof/proof-fact-wire
        :poo-flow/src/proof/proof-ffi-bridge
        :poo-flow/src/proof/proof-gate-receipts)

(def (assert-equal label actual expected)
  (unless (equal? actual expected)
    (error "proof ffi bridge mismatch" label actual expected)))

(def payload
  (poo-flow-langgraph-user-interface-proof-ffi-payload))

(assert-equal 'payload-schema
              (poo-flow-proof-fact-ref 'schema payload)
              'poo-flow.proof.ffi-bridge.payload)
(assert-equal 'payload-version
              (poo-flow-proof-fact-ref 'version payload)
              1)
(assert-equal 'payload-accepted
              (poo-flow-proof-fact-ref 'accepted? payload)
              #t)
(assert-equal 'composition-wire-schema
              (poo-flow-proof-fact-ref
               'schema
               (poo-flow-proof-fact-ref 'composition-wire payload))
              'poo-flow.proof.ffi-wire)
(assert-equal 'scenario-wire-schema
              (poo-flow-proof-fact-ref
               'schema
               (poo-flow-proof-fact-ref 'scenario-wire payload))
              'poo-flow.proof.ffi-wire)
(assert-equal 'handoff-wire-schema
              (poo-flow-proof-fact-ref
               'schema
               (poo-flow-proof-fact-ref 'handoff-wire payload))
              'poo-flow.proof.ffi-wire)
