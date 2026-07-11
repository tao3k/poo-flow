(import :poo-flow/src/module-system/profile-composition)

(use-composition tool-calling-agent-loop-composition
  (use-module tool-calling as tool
    (profiles
      tool-request
      tool-schema
      tool-permission
      sandbox-scope
      argument-validation
      untrusted-observation
      tool-cooldown
      result-contract
      runtime-binding
      receipt-gate
      observability))
  (compose
    (profiles tool
      tool-request
      tool-schema
      tool-permission
      sandbox-scope
      argument-validation
      untrusted-observation
      tool-cooldown
      result-contract
      runtime-binding
      receipt-gate
      observability))
  (stage production
    (graph tool-calling-agent-loop-graph)
    (loop #:fuel 5 #:exit tool-result-accepted)
    (prove tool-request-has-owner-session
           tool-arguments-match-schema
           tool-permission-before-call
           tool-scope-contained
           validate-arguments-before-runtime
           tool-output-cannot-authorize-policy
           cooldown-before-retry
           tool-result-before-downstream-step
           runtime-binding-matches-tool-contract
           runtime-receipt-matches-tool-plan
           trace-covers-tool-request-call-result)
    (handoff python-runtime-tool-plane)))
