(import :std/test
        :clan/poo/object
        :poo-flow/src/feature-system/interface)

(export feature-system-syntax-test)

(def syntax-session-mode-schema
  (feature-option-schema 'mode 'symbol 'durable #f))

(def syntax-session-options
  (feature-option-values
   (feature-option-value 'mode 'ephemeral)))

(defpoo-feature syntax-memory-feature
  (feature-id 'syntax-memory)
  (owner-module-id 'poo-flow-test/memory)
  (category 'agent-runtime)
  (schema-version 1))

(defpoo-feature syntax-telemetry-feature
  (feature-id 'syntax-telemetry)
  (owner-module-id 'poo-flow-test/telemetry)
  (category 'observability))

(defpoo-feature syntax-legacy-session-feature
  (feature-id 'syntax-legacy-session)
  (owner-module-id 'poo-flow-test/legacy-session)
  (category 'legacy))

(defpoo-feature syntax-session-feature
  (feature-id 'syntax-session)
  (owner-module-id 'poo-flow-test/session)
  (schema-version 2)
  (requires syntax-memory-feature)
  (optional-requires syntax-telemetry-feature)
  (conflicts syntax-legacy-session-feature)
  (option-schemas syntax-session-mode-schema)
  (policy-contributions 'session-policy)
  (strategy-contributions 'session-strategy)
  (adapter-requirements 'python-runtime-v1)
  (projections 'runtime-v1))

(defpoo-feature-profile syntax-agent-profile
  (profile-id 'syntax-agent)
  (selections
   (select syntax-session-feature (options syntax-session-options))
   (select syntax-memory-feature)
   (select syntax-telemetry-feature))
  (contracts 'agent-profile-contract))

(def syntax-agent-plan
  (resolve-feature-profile syntax-agent-profile))

(def feature-system-syntax-test
  (test-suite "POO-native Feature declaration macros"
    (test-case "defpoo-feature lowers to a module-owned descriptor"
      (check-equal? (.ref syntax-session-feature 'kind)
                    'feature-descriptor)
      (check-equal? (.ref syntax-session-feature 'feature-id)
                    'syntax-session)
      (check-equal? (.ref syntax-session-feature 'schema-version) 2)
      (check-equal? (.ref syntax-session-feature 'owner-module-id)
                    'poo-flow-test/session)
      (check-equal? (.ref syntax-session-feature 'requires)
                    '(syntax-memory))
      (check-equal? (.ref syntax-session-feature 'optional-requires)
                    '(syntax-telemetry))
      (check-equal? (.ref syntax-session-feature 'conflicts)
                    '(syntax-legacy-session))
      (check-eq? (car (.ref syntax-session-feature 'option-schemas))
                 syntax-session-mode-schema)
      (check-equal? (.ref syntax-session-mode-schema 'kind)
                    'feature-option-schema))

    (test-case "Feature clauses preserve POO contribution values"
      (check-equal? (.ref syntax-session-feature 'policy-contributions)
                    '(session-policy))
      (check-equal? (.ref syntax-session-feature 'strategy-contributions)
                    '(session-strategy))
      (check-equal? (.ref syntax-session-feature 'adapter-requirements)
                    '(python-runtime-v1))
      (check-equal? (.ref syntax-session-feature 'projections)
                    '(runtime-v1)))

    (test-case "defpoo-feature-profile lowers selections to a pure plan"
      (check-equal? (.ref syntax-agent-profile 'kind) 'feature-profile)
      (check-equal? (.ref syntax-agent-profile 'contracts)
                    '(agent-profile-contract))
      (check-eq?
       (.ref (car (.ref syntax-agent-profile 'selections)) 'option-values)
       syntax-session-options)
      (check-equal? (.ref syntax-agent-plan 'status) 'ready)
      (check-equal? (.ref syntax-agent-plan 'feature-ids)
                    '(syntax-memory syntax-telemetry syntax-session)))))
