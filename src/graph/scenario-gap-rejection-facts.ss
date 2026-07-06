(export poo-flow-scenario-gap-runtime-contract->proof-facts)

(def (poo-flow-scenario-gap-rejection-rule failure)
  (case failure
    ((plan) 'runtime-row-rejected-by-plan)
    ((rejections) 'runtime-row-rejected-by-rejections)
    ((accepted) 'runtime-row-rejected-by-accepted)
    (else (error "unknown scenario gap rejection failure" failure))))

(def (poo-flow-scenario-gap-runtime-contract->proof-facts
      fact-id
      plan-ok
      rejections-ok
      accepted-ok
      failure)
  (let ((accepted? (and plan-ok rejections-ok accepted-ok)))
    (list (cons 'schema 'poo-flow.proof.scenario-gap.runtime-row)
          (cons 'fact-id fact-id)
          (cons 'plan-ok plan-ok)
          (cons 'rejections-ok rejections-ok)
          (cons 'accepted-ok accepted-ok)
          (cons 'accepted? accepted?)
          (cons 'rejection failure)
          (cons 'rejection-rule
                (if accepted?
                  #f
                  (poo-flow-scenario-gap-rejection-rule failure)))
          (cons 'ffi-ready? #t))))
