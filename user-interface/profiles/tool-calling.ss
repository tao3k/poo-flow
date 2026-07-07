(.o (tool-request
     (.o (name 'tool-calling-request)
         (contract 'agent-requests-declared-tool)
         (policy 'tool-request-has-owner-session)))
    (tool-schema
     (.o (name 'tool-calling-schema)
         (contract 'typed-tool-arguments)
         (policy 'tool-arguments-match-schema)))
    (tool-permission
     (.o (name 'tool-calling-permission)
         (contract 'capability-gated-tool)
         (policy 'tool-permission-before-call)))
    (sandbox-scope
     (.o (name 'tool-calling-sandbox-scope)
         (contract 'tool-runs-inside-sandbox-scope)
         (policy 'tool-scope-contained)))
    (argument-validation
     (.o (name 'tool-calling-argument-validation)
         (contract 'validated-tool-arguments)
         (policy 'validate-arguments-before-runtime)))
    (untrusted-observation
     (.o (name 'tool-calling-untrusted-observation)
         (contract 'tool-output-is-observation)
         (policy 'tool-output-cannot-authorize-policy)))
    (tool-cooldown
     (.o (name 'tool-calling-cooldown)
         (contract 'rate-limited-tool-use)
         (policy 'cooldown-before-retry)))
    (result-contract
     (.o (name 'tool-calling-result-contract)
         (contract 'typed-tool-result)
         (policy 'tool-result-before-downstream-step)))
    (runtime-binding
     (.o (name 'tool-calling-runtime-binding)
         (contract 'runtime-language-tool-binding)
         (policy 'runtime-binding-matches-tool-contract)))
    (receipt-gate
     (.o (name 'tool-calling-receipt-gate)
         (contract 'tool-call-runtime-receipt)
         (policy 'runtime-receipt-matches-tool-plan)))
    (observability
     (.o (name 'tool-calling-observability)
         (contract 'tool-call-trace)
         (policy 'trace-covers-tool-request-call-result))))
