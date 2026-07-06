(export poo-flow-composition-contract->proof-facts)

(def (poo-flow-composition-rejection-rule failure)
  (case failure
    ((profile-refs) 'composition-rejected-by-profile-refs)
    ((overrides) 'composition-rejected-by-override-scope)
    ((module-order) 'composition-rejected-by-module-order)
    ((scenario-gate) 'composition-rejected-by-scenario-gate)
    ((runtime-execution) 'composition-rejected-by-runtime-execution)
    (else (error "unknown composition proof failure" failure))))

(def (poo-flow-composition-contract-accepted?
      profile-refs-ok
      overrides-scoped-ok
      modules-ordered-ok
      scenario-gate-ok
      no-runtime-execution)
  (and profile-refs-ok
       overrides-scoped-ok
       modules-ordered-ok
       scenario-gate-ok
       no-runtime-execution))

(def (poo-flow-composition-contract->proof-facts
      fact-id
      profile-refs-ok
      overrides-scoped-ok
      modules-ordered-ok
      scenario-gate-ok
      no-runtime-execution
      rejection)
  (let ((accepted?
         (poo-flow-composition-contract-accepted?
          profile-refs-ok
          overrides-scoped-ok
          modules-ordered-ok
          scenario-gate-ok
          no-runtime-execution)))
    (list (cons 'schema 'poo-flow.proof.composition.receipt)
          (cons 'fact-id fact-id)
          (cons 'profile-refs-ok profile-refs-ok)
          (cons 'overrides-scoped-ok overrides-scoped-ok)
          (cons 'modules-ordered-ok modules-ordered-ok)
          (cons 'scenario-gate-ok scenario-gate-ok)
          (cons 'no-runtime-execution no-runtime-execution)
          (cons 'accepted? accepted?)
          (cons 'rejection rejection)
          (cons 'rejection-rule
                (if accepted?
                  #f
                  (poo-flow-composition-rejection-rule rejection)))
          (cons 'ffi-ready? #t))))
