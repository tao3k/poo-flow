(import :poo-flow/src/proof/proof-fact-wire
        :poo-flow/src/module-system/composition-proof-facts
        :poo-flow/src/graph/control-plane-handoff-facts
        :poo-flow/src/graph/scenario-gap-rejection-facts)

(export poo-flow-proof-wire-field-ref
        poo-flow-proof-gate-bundle
        poo-flow-proof-gate-bundle-valid?
        poo-flow-langgraph-proof-gate-bundle
        poo-flow-langgraph-runtime-owner-rejected-bundle
        poo-flow-langgraph-missing-capability-rejected-bundle)

(def (poo-flow-proof-wire-field-ref key wire)
  (let ((entry (assq key (poo-flow-proof-fact-ref 'fields wire))))
    (if entry
      (cdr entry)
      (error "missing proof wire field" key wire))))

(def (poo-flow-proof-wire-accepted? wire)
  (poo-flow-proof-fact-ref 'accepted? wire))

(def (poo-flow-proof-gate-runtime-boundary-ok? handoff-wire)
  (and (poo-flow-proof-wire-field-ref 'runtime-owner-external handoff-wire)
       (poo-flow-proof-wire-field-ref 'execution-deferred handoff-wire)))

(def (poo-flow-proof-gate-bundle composition-facts scenario-facts handoff-facts)
  (let* ((composition-wire (poo-flow-proof-facts->ffi-wire composition-facts))
         (scenario-wire (poo-flow-proof-facts->ffi-wire scenario-facts))
         (handoff-wire (poo-flow-proof-facts->ffi-wire handoff-facts))
         (runtime-boundary-ok?
          (poo-flow-proof-gate-runtime-boundary-ok? handoff-wire))
         (accepted?
          (and (poo-flow-proof-wire-accepted? composition-wire)
               (poo-flow-proof-wire-accepted? scenario-wire)
               (poo-flow-proof-wire-accepted? handoff-wire)
               runtime-boundary-ok?)))
    (list (cons 'schema 'poo-flow.proof.gate.bundle)
          (cons 'version 1)
          (cons 'composition composition-wire)
          (cons 'scenario scenario-wire)
          (cons 'handoff handoff-wire)
          (cons 'runtime-boundary-ok? runtime-boundary-ok?)
          (cons 'accepted? accepted?))))

(def (poo-flow-proof-gate-bundle-valid? bundle)
  (and (eq? (poo-flow-proof-fact-ref 'schema bundle)
            'poo-flow.proof.gate.bundle)
       (equal? (poo-flow-proof-fact-ref 'version bundle) 1)
       (poo-flow-proof-facts-ffi-wire-valid?
        (poo-flow-proof-fact-ref 'composition bundle))
       (poo-flow-proof-facts-ffi-wire-valid?
        (poo-flow-proof-fact-ref 'scenario bundle))
       (poo-flow-proof-facts-ffi-wire-valid?
        (poo-flow-proof-fact-ref 'handoff bundle))))

(def (poo-flow-langgraph-composition-facts)
  (poo-flow-composition-contract->proof-facts
   'langgraph-composition
   #t #t #t #t #t #f))

(def (poo-flow-langgraph-scenario-facts)
  (poo-flow-scenario-gap-runtime-contract->proof-facts
   'langgraph-scenario-gap
   #t #t #t #f))

(def (poo-flow-langgraph-handoff-facts)
  (poo-flow-control-plane-handoff-contract->proof-facts
   'langgraph-control-plane-handoff
   #t #t #t #t #t #t #f))

(def (poo-flow-langgraph-proof-gate-bundle)
  (poo-flow-proof-gate-bundle
   (poo-flow-langgraph-composition-facts)
   (poo-flow-langgraph-scenario-facts)
   (poo-flow-langgraph-handoff-facts)))

(def (poo-flow-langgraph-runtime-owner-rejected-bundle)
  (poo-flow-proof-gate-bundle
   (poo-flow-langgraph-composition-facts)
   (poo-flow-langgraph-scenario-facts)
   (poo-flow-control-plane-handoff-contract->proof-facts
    'langgraph-runtime-owned-here
    #t #t #t #f #t #t 'runtime-owner)))

(def (poo-flow-langgraph-missing-capability-rejected-bundle)
  (poo-flow-proof-gate-bundle
   (poo-flow-langgraph-composition-facts)
   (poo-flow-scenario-gap-runtime-contract->proof-facts
    'langgraph-scenario-missing-capability
    #t #t #f 'accepted)
   (poo-flow-langgraph-handoff-facts)))
