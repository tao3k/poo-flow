(export poo-flow-control-plane-handoff-contract->proof-facts)

(def (poo-flow-control-plane-handoff-rejection-rule failure)
  (case failure
    ((policy) 'control-plane-handoff-rejected-by-policy)
    ((composition) 'control-plane-handoff-rejected-by-composition)
    ((graph) 'control-plane-handoff-rejected-by-graph)
    ((runtime-owner) 'control-plane-handoff-rejected-by-runtime-owner)
    ((execution) 'control-plane-handoff-rejected-by-execution)
    ((artifacts) 'control-plane-handoff-rejected-by-artifacts)
    (else (error "unknown control-plane handoff proof failure" failure))))

(def (poo-flow-control-plane-handoff-contract-accepted?
      policy-ready
      composition-accepted
      graph-contract-ok
      runtime-owner-external
      execution-deferred
      artifacts-declared)
  (and policy-ready
       composition-accepted
       graph-contract-ok
       runtime-owner-external
       execution-deferred
       artifacts-declared))

(def (poo-flow-control-plane-handoff-contract->proof-facts
      fact-id
      policy-ready
      composition-accepted
      graph-contract-ok
      runtime-owner-external
      execution-deferred
      artifacts-declared
      rejection)
  (let ((accepted?
         (poo-flow-control-plane-handoff-contract-accepted?
          policy-ready
          composition-accepted
          graph-contract-ok
          runtime-owner-external
          execution-deferred
          artifacts-declared)))
    (list (cons 'schema 'poo-flow.proof.control-plane.handoff)
          (cons 'fact-id fact-id)
          (cons 'policy-ready policy-ready)
          (cons 'composition-accepted composition-accepted)
          (cons 'graph-contract-ok graph-contract-ok)
          (cons 'runtime-owner-external runtime-owner-external)
          (cons 'execution-deferred execution-deferred)
          (cons 'artifacts-declared artifacts-declared)
          (cons 'accepted? accepted?)
          (cons 'rejection rejection)
          (cons 'rejection-rule
                (if accepted?
                  #f
                  (poo-flow-control-plane-handoff-rejection-rule rejection)))
          (cons 'ffi-ready? #t))))
