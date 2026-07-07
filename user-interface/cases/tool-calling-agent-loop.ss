(import :poo-flow/src/module-system/profile-composition)

(use-composition tool-calling-agent-loop-composition
  (modules
    (use-profile tool-calling #:as tool))
  (stage production
    (compose
      (profile tool tool-request)
      (profile tool tool-schema)
      (profile tool tool-permission)
      (profile tool sandbox-scope)
      (profile tool argument-validation)
      (profile tool untrusted-observation)
      (profile tool tool-cooldown)
      (profile tool result-contract)
      (profile tool runtime-binding)
      (profile tool receipt-gate)
      (profile tool observability))
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
