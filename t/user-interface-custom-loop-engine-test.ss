;;; -*- Gerbil -*-
;;; Boundary: tests verify custom user-interface loop-engine declarations.
;;; Invariant: custom loop cases project intent data and never execute loops.

(import (only-in :std/test
                 check
                 check-eq?
                 check-equal?
                 check-false
                 check-not-equal?
                 check-output
                 check-true
                 run-tests!
                 test-case
                 test-error
                 test-suite)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/facade
        (only-in :poo-flow/user-interface/custom/my-module/config
                 poo-flow-custom-my-module-loop-engine-case
                 poo-flow-custom-my-module-loops-module))

(export user-interface-custom-loop-engine-test)

;;; Intent rows are projected as alists for presentation only. The helper keeps
;;; the test at the public presentation boundary instead of reaching into the
;;; loop-engine module constructors.
;; | LoopEngineIntentRow = Alist
;; | LoopEngineIntentKey = Symbol
;; : (-> LoopEngineIntentRow LoopEngineIntentKey MaybeValue)
(def (test-ref alist key)
  (let (entry (assoc key alist))
    (if entry (cdr entry) #f)))

;;; Name extraction keeps repeated profile/harness assertions about the object
;;; graph shape instead of duplicating alist traversal at each check site.
;; : (-> [Alist] Symbol [Value])
(def (test-field-values rows key)
  (map (lambda (row) (test-ref row key)) rows))

;; : [Symbol]
(def expected-loop-engine-agent-names
  '(ci-audit-agent
    build-verifier-agent
    ci-loop-governor
    human-audit))

;; : [Symbol]
(def expected-loop-engine-object-families
  '(agent-profile
    agent-harness
    agent-session
    workflow-run
    dispatch-receipt
    agent-operation
    lineage-receipt
    selector-receipt
    resource-dispatch-receipt
    capability-receipt
    memory-receipt
    runtime-snapshot))

;; : Alist
(def expected-loop-engine-receipt-contracts
  '((lineage-receipt
     . poo-flow.loop-engine.lineage-receipt.v1)
    (selector-receipt
     . poo-flow.loop-engine.selector-receipt.v1)
    (resource-dispatch-receipt
     . poo-flow.loop-engine.resource-dispatch-receipt.v1)
    (capability-receipt
     . poo-flow.loop-engine.capability-receipt.v1)
    (memory-receipt
     . poo-flow.loop-engine.memory-receipt.v1)
    (sandbox-handoff-agreement
     . poo-flow.loop-engine.sandbox-handoff-agreement.v1)))

;; : Symbol
(def expected-loop-engine-human-audit-result-contract
  'poo-flow.loop-governor.human-audit-decision.v1)

;; : Symbol
(def expected-loop-engine-profile-human-audit-result-contract
  'poo-flow.loop-governor.profile-human-audit-decision.v1)

;; : [Symbol]
(def expected-loop-engine-required-result-fields
  '(decision summary evidence))

;; : [Symbol]
(def expected-loop-engine-profile-required-result-fields
  '(decision summary evidence action-items))

;;; Invalid result contract fixture is intentionally minimal: it exercises the
;;; result-contract validator without introducing unrelated sandbox resolution.
;; : [PooUserModuleSelection]
(def custom-loop-invalid-result-module
  (use-module loop-engine
    :config
    (.def (invalid-result-loop @ loop-engine-use-case name workflow)
      name: 'invalid-result-loop
      workflow: 'funflow-cicd)

    (.def (invalid-result-human-audit @ loop-engine-human-audit actions)
      actions: '(+manual-gate))

    (.def (invalid-result-contract @ loop-engine-result
                                   human-audit format required-fields)
      human-audit: 'bad-contract
      format: 'structured-alist
      required-fields: '())

    (.def (invalid-result-runtime @ loop-engine-runtime capabilities)
      capabilities: '(+manifest-handoff))

    (.def (invalid-result-profile @ loop-engine-profile
                                  use-case human-audit result runtime)
      use-case: invalid-result-loop
      human-audit: invalid-result-human-audit
      result: invalid-result-contract
      runtime: invalid-result-runtime)))

;;; Invalid POO slot fixture covers fail-fast structural validation before
;;; malformed objects can be lowered into intent rows or manifests.
;; : (-> [PooUserModuleSelection])
(def (custom-loop-invalid-poo-slot-module)
  (use-module loop-engine
    :config
    (.def (invalid-poo-slot-loop @ loop-engine-use-case name workflow)
      name: 'invalid-poo-slot-loop
      workflow: 'funflow-cicd)

    (.def (invalid-poo-slot-governor @ loop-engine-governor capabilities)
      capabilities: '+strategy)

    (.def (invalid-poo-slot-profile @ loop-engine-profile
                                     use-case governor)
      use-case: invalid-poo-slot-loop
      governor: invalid-poo-slot-governor)))

;;; Memory policy slot validation is intentionally structural: recall and
;;; commit must be symbol lists before the runtime manifest is projected.
;; : (-> [PooUserModuleSelection])
(def (custom-loop-invalid-memory-slot-module)
  (use-module loop-engine
    :config
    (.def (invalid-memory-slot-loop @ loop-engine-use-case name workflow)
      name: 'invalid-memory-slot-loop
      workflow: 'funflow-cicd)

    (.def (invalid-memory-slot-policy @ loop-engine-memory-policy recall)
      recall: 'bad-recall)

    (.def (invalid-memory-slot-profile @ loop-engine-profile
                                        use-case memory-policy)
      use-case: invalid-memory-slot-loop
      memory-policy: invalid-memory-slot-policy)))

;;; Invalid capability backend fixture protects the sandbox backend contract:
;;; user-facing backend names are sandbox modules, not the Marlin runtime owner.
;; : [PooUserModuleSelection]
(def custom-loop-invalid-capability-module
  (use-module loop-engine
    :config
    (.def (invalid-capability-loop @ loop-engine-use-case name workflow)
      name: 'invalid-capability-loop
      workflow: 'funflow-cicd)

    (.def (invalid-capability-policy @ loop-engine-capability-policy
                                      backend required)
      backend: 'marlin-sandbox
      required: '(command-run))

    (.def (invalid-capability-profile @ loop-engine-profile
                                      use-case capability-policy)
      use-case: invalid-capability-loop
      capability-policy: invalid-capability-policy)))

;;; Custom loop fixtures are tested through the same config presentation used
;;; by downstream user declarations. This helper avoids constructing a module
;;; descriptor or executing loop runtime code in the test.
;; : (-> [PooUserModuleSelection] POOObject)
(def (custom-loop-presentation/bundles module-bundles)
  (pooFlowUserConfigPresentation
   (pooFlowUserConfig
    (poo-flow-user-module-bundles->modules module-bundles)
    (poo-flow-settings))))

;; : (-> [PooUserModuleSelection] POOObject)
(def (custom-loop-presentation module-bundle)
  (custom-loop-presentation/bundles (list module-bundle)))

;;; The concrete context centralizes projection setup so each assertion helper
;;; stays under one boundary: declaration shape, agent graph, runtime manifest,
;;; or presentation aggregation.
;; : (-> Alist)
(def (custom-loop-concrete-context)
  (let* ((presentation
          (custom-loop-presentation
           poo-flow-custom-my-module-loop-engine-case))
         (intent
          (car (.ref presentation 'loop-engine-intents)))
         (runtime-manifest
          (test-ref intent 'runtime-command-manifest)))
    (list (cons 'presentation presentation)
          (cons 'intent intent)
          (cons 'runtime-manifest runtime-manifest)
          (cons 'runtime-manifest-request
                (test-ref runtime-manifest 'request))
          (cons 'runtime-manifest-summary
                (test-ref intent 'runtime-command-manifest-summary))
          (cons 'runtime-snapshot
                (test-ref intent 'runtime-snapshot)))))

;;; Profile modules should still read like user declarations: one loop-engine
;;; row, ordered use-cases, sandbox refs, and no runtime execution.
;; : TestCase
(def user-interface-custom-loop-engine-profile-case
  (test-case "projects custom loop-engine profile use cases"
    (let* ((presentation
            (custom-loop-presentation
             poo-flow-custom-my-module-loops-module))
           (intent
            (car (.ref presentation 'loop-engine-intents)))
           (result-contract
            (test-ref intent 'result-contract)))
      (check-equal? (.ref presentation 'module-count) 1)
      (check-equal? (.ref presentation 'module-keys)
                    '((flow . loop-engine)))
      (check-equal? (.ref presentation 'loop-engine-intent-count) 1)
      (check-equal? (test-ref intent 'workflow-owned?) #t)
      (check-equal? (test-ref intent 'governor)
                    '(+strategy +policy +node-graph))
      (check-equal? (map car (test-ref intent 'use-cases))
                    '(repo-doctor pull-request-review release-approval))
      (check-equal? (test-ref intent 'sandbox)
                    '((repo-doctor . agent/task)
                      (pull-request-review . agent/task-cache)
                      (release-approval . ci/build)))
      (check-equal? (test-ref (test-ref intent 'lineage-policy)
                              'lineage-kind)
                    'profile-loop)
      (check-equal? (test-ref (test-ref intent 'selector-policy)
                              'selected-branch)
                    'repo-doctor)
      (check-equal? (test-ref (test-ref intent 'resource-policy)
                              'dispatch-groups)
                    '(((inspect-policy write-report) . serial)
                      ((run-harness) . serial)))
      (check-equal? (test-ref (test-ref intent 'capability-policy)
                              'optional)
                    '(stream-events memory-recall compression-handoff))
      (check-equal? (test-ref (test-ref intent 'memory-policy)
                              'scope)
                    'profile)
      (check-equal? (test-ref (test-ref intent 'memory-policy)
                              'commit)
                    '(audit-summary selected-branch release-decision))
      (check-equal? (test-ref intent 'result)
                    '((default
                       . poo-flow.loop-governor.profile-node-result.v1)
                      (auditor
                       . poo-flow.loop-governor.profile-audit-result.v1)
                      (verifier
                       . poo-flow.loop-governor.profile-review-result.v1)
                      (governor
                       . poo-flow.loop-governor.profile-governor-result.v1)
                      (human-audit
                       . poo-flow.loop-governor.profile-human-audit-decision.v1)
                      (format . structured-alist)
                      (required-fields
                       decision
                       summary
                       evidence
                       action-items)))
      (check-equal? (test-ref result-contract 'valid?) #t)
      (check-equal? (test-ref result-contract 'human-audit)
                    expected-loop-engine-profile-human-audit-result-contract)
      (check-equal? (test-ref result-contract 'required-fields)
                    expected-loop-engine-profile-required-result-fields)
      (check-equal? (car (.ref presentation 'loop-engine-result-contracts))
                    result-contract)
      (check-equal? (test-ref intent 'runtime-handoff)
                    'loop-governor-marlin-runtime-manifest)
      (check-equal? (test-ref intent 'runtime-handoff-contracts)
                    '(start-workflow-run
                      admit-dispatch
                      open-agent-session
                      execute-agent-operation
                      stream-events
                      read-runtime-snapshot))
      (check-equal? (test-ref intent 'runtime-executed) #f))))

;;; Declaration assertions guard the user-facing case shape before any derived
;;; receipt rows are inspected.
;; : (-> POOObject Alist)
(def (check-custom-loop-concrete-declaration presentation intent)
  (check-equal? (.ref presentation 'module-count) 1)
  (check-equal? (test-ref intent 'use-case)
                '(current-system-build-loop
                  (level . l2)
                  (mode . guarded-handoff)
                  (workflow . funflow-cicd)))
  (check-equal? (test-ref intent 'agent-judges)
                '((auditor ci-audit-agent)
                  (verifier build-verifier-agent)
                  (governor ci-loop-governor)))
  (check-equal? (test-ref intent 'human-audit)
                '(+manual-gate +changes-requested))
  (check-equal? (test-ref intent 'sandbox)
                '((profile . ci/build)
                  (isolation . project-copy)))
  (check-equal? (test-ref (test-ref intent 'lineage-policy)
                          'parent-session-refs)
                '(incoming-ci-request-session))
  (check-equal? (test-ref (test-ref intent 'lineage-policy)
                          'lineage-kind)
                'guarded-handoff)
  (check-equal? (test-ref (test-ref intent 'selector-policy)
                          'selected-branch)
                'current-system-build-loop)
  (check-equal? (test-ref (test-ref intent 'resource-policy)
                          'dispatch-groups)
                '(((run-shell-command) . serial)
                  ((write-workspace-file read-workspace-file) . serial)))
  (check-equal? (test-ref (test-ref intent 'capability-policy)
                          'required)
                '(command-run files-read files-write))
  (check-equal? (test-ref (test-ref intent 'capability-policy)
                          'unsupported-behavior)
                'handoff-diagnostic)
  (check-equal? (test-ref (test-ref intent 'memory-policy)
                          'recall)
                '(last-user-message build-context prior-failure))
  (check-equal? (test-ref (test-ref intent 'memory-policy)
                          'retention)
                'report-only)
  (check-equal? (test-ref intent 'result)
                '((default . poo-flow.loop-governor.node-result.v1)
                  (auditor . poo-flow.loop-governor.audit-result.v1)
                  (verifier . poo-flow.loop-governor.review-result.v1)
                  (governor . poo-flow.loop-governor.governor-result.v1)
                  (human-audit
                   . poo-flow.loop-governor.human-audit-decision.v1)
                  (format . structured-alist)
                  (required-fields decision summary evidence)))
  (check-equal? (test-ref intent 'sandbox-profile-refs) '(ci/build))
  (check-equal? (test-ref intent 'sandbox-runtime-summaries) '())
  (check-equal? (test-ref intent 'sandbox-handoff-summaries) '())
  (check-equal? (test-ref intent 'sandbox-unresolved-profile-refs) '(ci/build)))

;;; Agent-boundary assertions prove Flue-style profile, harness, and session
;;; rows are projected before the runtime handoff without becoming execution.
;; : (-> Alist)
(def (check-custom-loop-agent-boundary intent)
  (let ((handoff (test-ref intent 'runtime-handoff-facts))
        (result-contract (test-ref intent 'result-contract))
        (sandbox-agreement (test-ref intent 'sandbox-handoff-agreement))
        (agent-profiles (test-ref intent 'agent-profiles))
        (agent-harnesses (test-ref intent 'agent-harnesses))
        (agent-sessions (test-ref intent 'agent-sessions))
        (lineage-receipt (test-ref intent 'lineage-receipt))
        (selector-receipt (test-ref intent 'selector-receipt))
        (resource-dispatch-receipt
         (test-ref intent 'resource-dispatch-receipt))
        (capability-receipt
         (test-ref intent 'capability-receipt))
        (memory-receipt
         (test-ref intent 'memory-receipt)))
    (check-equal? (test-ref handoff 'contract)
                  'poo-flow.loop-governor.runtime-handoff.v1)
    (check-equal? (test-ref handoff 'workflow-ref) 'funflow-cicd)
    (check-equal? (test-field-values agent-profiles 'name)
                  expected-loop-engine-agent-names)
    (check-equal? (test-ref result-contract 'contract)
                  'poo-flow.loop-governor.result-contract.v1)
    (check-equal? (test-ref result-contract 'valid?) #t)
    (check-equal? (test-ref result-contract 'diagnostic-count) 0)
    (check-equal? (test-ref result-contract 'diagnostics) '())
    (check-equal? (test-ref result-contract 'human-audit)
                  expected-loop-engine-human-audit-result-contract)
    (check-equal? (test-ref result-contract 'required-fields)
                  expected-loop-engine-required-result-fields)
    (check-equal? (test-ref sandbox-agreement 'valid?) #f)
    (check-equal? (test-ref sandbox-agreement 'unresolved-profile-refs)
                  '(ci/build))
    (check-equal? (test-ref sandbox-agreement 'diagnostic-count) 1)
    (check-equal? (test-field-values
                   (test-ref sandbox-agreement 'diagnostics)
                   'code)
                  '(unresolved-sandbox-profile-refs))
    (check-equal? (test-ref (test-ref (car agent-profiles) 'loop-policy)
                            'result-contract)
                  'poo-flow.loop-governor.audit-result.v1)
    (check-equal? (test-field-values agent-harnesses 'profile)
                  expected-loop-engine-agent-names)
    (check-equal? (test-field-values agent-sessions 'kind)
                  '(agent-session agent-session agent-session agent-session))
    (check-equal? (test-ref (car agent-profiles) 'runtime-executed) #f)
    (check-equal? (test-ref (car agent-harnesses) 'runtime-executed) #f)
    (check-equal? (test-ref (test-ref (car agent-sessions) 'metadata)
                            'runtime-executed)
                  #f)
    (check-equal? (test-ref lineage-receipt 'lineage-kind)
                  'guarded-handoff)
    (check-equal? (test-ref selector-receipt 'selected-branch)
                  'current-system-build-loop)
    (check-equal? (test-ref resource-dispatch-receipt 'dispatch-groups)
                  '(((run-shell-command) . serial)
                    ((write-workspace-file read-workspace-file) . serial)))
    (check-equal? (test-ref capability-receipt 'backend) 'nono-sandbox)
    (check-equal? (test-ref capability-receipt 'supported-backends)
                  '(nono-sandbox cube-sandbox))
    (check-equal? (test-ref capability-receipt 'valid?) #t)
    (check-equal? (test-ref capability-receipt 'diagnostics) '())
    (check-equal? (test-ref capability-receipt 'required)
                  '(command-run files-read files-write))
    (check-equal? (test-ref capability-receipt 'sandbox-ref) 'ci/build)
    (check-equal? (test-ref memory-receipt 'store) 'project-memory)
    (check-equal? (test-ref memory-receipt 'scope) 'session)
    (check-equal? (test-ref memory-receipt 'recall)
                  '(last-user-message build-context prior-failure))
    (check-equal? (test-ref memory-receipt 'commit)
                  '(decision-summary evidence-index handoff-receipt))
    (check-equal? (test-ref memory-receipt 'retention) 'report-only)
    (check-equal? (test-ref memory-receipt 'runtime-executed) #f)
    (check-equal? (test-ref handoff 'agent-profiles) agent-profiles)
    (check-equal? (test-ref handoff 'agent-harnesses) agent-harnesses)
    (check-equal? (test-ref handoff 'agent-sessions) agent-sessions)
    (check-equal? (test-ref handoff 'receipt-contracts)
                  expected-loop-engine-receipt-contracts)
    (check-equal? (test-ref handoff 'lineage-receipt) lineage-receipt)
    (check-equal? (test-ref handoff 'selector-receipt) selector-receipt)
    (check-equal? (test-ref handoff 'resource-dispatch-receipt)
                  resource-dispatch-receipt)
    (check-equal? (test-ref handoff 'capability-receipt)
                  capability-receipt)
    (check-equal? (test-ref handoff 'memory-receipt) memory-receipt)
    (check-equal? (test-ref handoff 'result-contract) result-contract)
    (check-equal? (test-ref handoff 'runtime-executed) #f)))

;;; Operation assertions keep workflow runs, dispatch receipts, canonical
;;; agent operations, and readable delegated-operation rows separate.
;; : (-> Alist)
(def (check-custom-loop-operation-boundary intent)
  (let ((workflow-run (test-ref intent 'workflow-run))
        (dispatch-receipt (test-ref intent 'dispatch-receipt))
        (agent-operation (test-ref intent 'agent-operation))
        (delegated-operation (test-ref intent 'delegated-operation)))
    (check-equal? (test-ref workflow-run 'kind) 'workflow-run)
    (check-equal? (test-ref workflow-run 'workflow-ref) 'funflow-cicd)
    (check-equal? (test-ref workflow-run 'status) 'waiting-human)
    (check-equal? (test-ref dispatch-receipt 'kind) 'dispatch-receipt)
    (check-equal? (test-ref dispatch-receipt 'target-agent) 'ci-audit-agent)
    (check-equal? (test-ref dispatch-receipt 'admission-status) 'admitted)
    (check-equal? (test-ref agent-operation 'kind) 'agent-operation)
    (check-equal? (test-ref agent-operation 'operation-kind) 'human-audit)
    (check-equal? (test-ref agent-operation 'result-contract)
                  expected-loop-engine-human-audit-result-contract)
    (check-equal? (test-ref agent-operation 'status) 'waiting-human)
    (check-equal? (test-ref (test-ref agent-operation 'runtime-intent)
                            'executes-runtime)
                  #f)
    (check-equal? (test-ref delegated-operation 'kind) 'delegated-operation)
    (check-equal? (test-ref delegated-operation 'contract)
                  'poo-flow.loop-engine.delegated-operation.v1)
    (check-equal? (test-ref delegated-operation 'object-family)
                  'agent-operation)
    (check-equal? (test-ref delegated-operation 'operation-ref)
                  (test-ref agent-operation 'id))
    (check-equal? (test-ref delegated-operation 'session-ref)
                  (test-ref agent-operation 'parent-session))
    (check-equal? (test-ref delegated-operation 'workflow-run-ref)
                  (test-ref workflow-run 'run-id))
    (check-equal? (test-ref delegated-operation 'workflow-ref) 'funflow-cicd)
    (check-equal? (test-ref delegated-operation 'governor-agent)
                  'ci-loop-governor)
    (check-equal? (test-ref delegated-operation 'reviewer-agent)
                  'build-verifier-agent)
    (check-equal? (test-ref delegated-operation 'reviewer-role) 'verifier)
    (check-equal? (test-ref delegated-operation 'auditor-agent)
                  'ci-audit-agent)
    (check-equal? (test-ref delegated-operation 'human-audit)
                  '(+manual-gate +changes-requested))
    (check-equal? (test-ref delegated-operation 'human-audit-profile)
                  'human-audit)
    (check-equal? (test-ref delegated-operation 'human-audit-required?) #t)
    (check-equal? (test-ref (test-ref delegated-operation 'result-contract)
                            'human-audit)
                  expected-loop-engine-human-audit-result-contract)
    (check-equal? (test-ref delegated-operation 'structured-result-contract)
                  expected-loop-engine-human-audit-result-contract)
    (check-equal? (test-ref delegated-operation 'status) 'waiting-human)
    (check-equal? (test-ref delegated-operation 'descriptor-realized?) #f)
    (check-equal? (test-ref delegated-operation 'runtime-executed) #f)
    (check-equal? (test-ref (test-ref delegated-operation 'runtime-intent)
                            'executes-runtime)
                  #f)))

;;; Manifest assertions prove the handoff payload carries the expanded agent
;;; object families while remaining an inert runtime-adapter request.
;; : (-> Alist Alist Alist Alist)
(def (check-custom-loop-runtime-manifest intent
                                         runtime-manifest
                                         runtime-manifest-request
                                         runtime-manifest-summary)
  (check-equal? (test-ref runtime-manifest 'schema)
                'poo-flow.runtime-command-descriptor.v1)
  (check-equal? (test-ref runtime-manifest 'request-schema)
                'poo-flow.runtime-request.v1)
  (check-equal? (test-ref runtime-manifest 'operation)
                'loop-engine-handoff)
  (check-equal? (test-ref runtime-manifest 'executable)
                "marlin-agent-core")
  (check-equal? (test-ref runtime-manifest 'argv)
                '("marlin-agent-core"
                  "poo-flow"
                  "runtime"
                  "loop-engine-handoff"))
  (check-equal? (test-ref runtime-manifest-request 'kind)
                'loop-engine-runtime-handoff-request)
  (check-equal? (test-ref runtime-manifest-request 'contract)
                'poo-flow.loop-governor.runtime-command-manifest.v1)
  (check-equal? (test-ref (test-ref runtime-manifest-request
                                     'result-contract)
                          'human-audit)
                expected-loop-engine-human-audit-result-contract)
  (check-equal? (test-ref (test-ref runtime-manifest-request
                                     'result-contract)
                          'valid?)
                #t)
  (check-equal? (test-ref runtime-manifest-request 'object-families)
                expected-loop-engine-object-families)
  (check-equal? (test-ref runtime-manifest-request 'receipt-contracts)
                expected-loop-engine-receipt-contracts)
  (check-equal? (test-ref (test-ref runtime-manifest-request
                                     'lineage-receipt)
                          'lineage-kind)
                'guarded-handoff)
  (check-equal? (test-ref (test-ref runtime-manifest-request
                                     'selector-receipt)
                          'selected-branch)
                'current-system-build-loop)
  (check-equal? (test-ref (test-ref runtime-manifest-request
                                     'resource-dispatch-receipt)
                          'runtime-executed)
                #f)
  (check-equal? (test-ref (test-ref runtime-manifest-request
                                     'capability-receipt)
                          'unsupported-behavior)
                'handoff-diagnostic)
  (check-equal? (test-ref (test-ref runtime-manifest-request
                                     'capability-receipt)
                          'valid?)
                #t)
  (check-equal? (test-ref (test-ref runtime-manifest-request
                                     'memory-receipt)
                          'commit)
                '(decision-summary evidence-index handoff-receipt))
  (check-equal? (test-ref (test-ref runtime-manifest-request
                                     'memory-receipt)
                          'runtime-executed)
                #f)
  (check-equal? (test-field-values (test-ref runtime-manifest-request
                                             'agent-profiles)
                                   'name)
                expected-loop-engine-agent-names)
  (check-equal? (test-field-values (test-ref runtime-manifest-request
                                             'agent-sessions)
                                   'workflow-run?)
                '(#f #f #f #f))
  (check-equal? (test-ref runtime-manifest-request 'sandbox-profile-refs)
                '(ci/build))
  (check-equal? (test-ref runtime-manifest-request 'sandbox-runtime-summaries)
                '())
  (check-equal? (test-ref runtime-manifest-request
                          'sandbox-unresolved-profile-refs)
                '(ci/build))
  (check-equal? (test-ref (test-ref runtime-manifest-request
                                     'sandbox-handoff-agreement)
                          'valid?)
                #f)
  (check-equal? (test-ref (test-ref runtime-manifest-request
                                     'agent-operation)
                          'operation-kind)
                'human-audit)
  (check-equal? (test-ref (test-ref runtime-manifest-request
                                     'delegated-operation)
                          'reviewer-agent)
                'build-verifier-agent)
  (check-equal? (test-ref (test-ref runtime-manifest 'metadata) 'contract)
                'poo-flow.loop-governor.runtime-command-manifest.v1)
  (check-equal? (test-ref runtime-manifest-summary 'kind)
                'runtime-command-manifest-summary)
  (check-equal? (test-ref runtime-manifest-summary 'operation)
                'loop-engine-handoff)
  (check-equal? (test-ref runtime-manifest-summary 'object-families)
                expected-loop-engine-object-families)
  (check-equal? (test-ref runtime-manifest-summary 'receipt-contracts)
                expected-loop-engine-receipt-contracts)
  (check-equal? (test-ref intent 'runtime-executed) #f))

;;; Presentation assertions verify the public doctor view exposes the same
;;; object graph rows that the runtime manifest carries.
;; : (-> POOObject Alist Alist)
(def (check-custom-loop-presentation-boundary presentation
                                              intent
                                              runtime-snapshot)
  (check-equal? (test-ref runtime-snapshot 'kind) 'runtime-snapshot)
  (check-equal? (test-ref runtime-snapshot 'subject-kind) 'loop-engine)
  (check-equal? (test-ref runtime-snapshot 'subject-id)
                'current-system-build-loop)
  (check-equal? (test-ref runtime-snapshot 'status) 'waiting-human)
  (check-equal? (test-ref (test-ref runtime-snapshot 'metadata)
                          'handoff-ready?)
                #f)
  (check-equal? (.ref presentation 'loop-engine-runtime-snapshot-count) 1)
  (check-equal? (car (.ref presentation 'loop-engine-agent-profiles))
                (test-ref intent 'agent-profiles))
  (check-equal? (car (.ref presentation 'loop-engine-result-contracts))
                (test-ref intent 'result-contract))
  (check-equal? (car (.ref presentation 'loop-engine-receipt-contracts))
                expected-loop-engine-receipt-contracts)
  (check-equal? (car (.ref presentation
                            'loop-engine-sandbox-handoff-agreements))
                (test-ref intent 'sandbox-handoff-agreement))
  (check-equal? (car (.ref presentation 'loop-engine-agent-harnesses))
                (test-ref intent 'agent-harnesses))
  (check-equal? (car (.ref presentation 'loop-engine-agent-sessions))
                (test-ref intent 'agent-sessions))
  (check-equal? (test-ref (car (.ref presentation
                                  'loop-engine-runtime-snapshots))
                          'status)
                'waiting-human)
  (check-equal? (test-ref (car (.ref presentation
                                  'loop-engine-agent-operations))
                          'operation-kind)
                'human-audit)
  (check-equal? (test-ref (car (.ref presentation
                                  'loop-engine-delegated-operations))
                          'governor-agent)
                'ci-loop-governor)
  (check-equal? (test-ref (car (.ref presentation
                                  'loop-engine-delegated-operations))
                          'runtime-executed)
                #f)
  (check-equal? (test-ref (car (.ref presentation
                                  'loop-engine-lineage-receipts))
                          'lineage-kind)
                'guarded-handoff)
  (check-equal? (test-ref (car (.ref presentation
                                  'loop-engine-selector-receipts))
                          'selected-branch)
                'current-system-build-loop)
  (check-equal? (test-ref (car (.ref presentation
                                  'loop-engine-resource-dispatch-receipts))
                          'runtime-executed)
                #f)
  (check-equal? (test-ref (car (.ref presentation
                                  'loop-engine-capability-receipts))
                          'backend)
                'nono-sandbox)
  (check-equal? (test-ref (car (.ref presentation
                                  'loop-engine-memory-receipts))
                          'store)
                'project-memory)
  (check-equal? (test-ref (car (.ref presentation
                                  'loop-engine-runtime-command-manifests))
                          'operation)
                'loop-engine-handoff)
  (check-equal? (test-ref (car (.ref presentation
                                  'loop-engine-runtime-command-manifest-summaries))
                          'contract)
                'poo-flow.loop-governor.runtime-command-manifest.v1))

;;; Invalid result contracts remain reportable config data: presentation and
;;; runtime manifests surface diagnostics, but no runtime work is executed.
;; : TestCase
(def user-interface-custom-loop-engine-invalid-result-case
  (test-case "diagnoses invalid loop-engine result contract"
    (let* ((presentation
            (custom-loop-presentation custom-loop-invalid-result-module))
           (intent
            (car (.ref presentation 'loop-engine-intents)))
           (result-contract
            (test-ref intent 'result-contract))
           (runtime-manifest
            (test-ref intent 'runtime-command-manifest))
           (runtime-manifest-request
            (test-ref runtime-manifest 'request))
           (diagnostics
            (test-ref result-contract 'diagnostics)))
      (check-equal? (test-ref result-contract 'valid?) #f)
      (check-equal? (test-ref result-contract 'diagnostic-count) 1)
      (check-equal? (test-field-values diagnostics 'code)
                    '(invalid-result-required-fields))
      (check-equal? (test-ref (test-ref runtime-manifest-request
                                         'result-contract)
                              'valid?)
                    #f)
      (check-equal? (car (.ref presentation 'loop-engine-result-contracts))
                    result-contract)
      (check-equal? (test-ref intent 'runtime-executed) #f))))

;;; POO object slot contracts fail before presentation can emit bad intent rows.
;; : TestCase
(def user-interface-custom-loop-engine-invalid-poo-slot-case
  (test-case "rejects invalid loop-engine POO object slot types"
    (check-equal?
     (with-catch
      (lambda (_) #t)
      (lambda ()
        (custom-loop-presentation (custom-loop-invalid-poo-slot-module))
        #f))
     #t)))

;;; Memory policy gets the same POO slot contract treatment as other loop
;;; objects: malformed recall/commit declarations never become receipts.
;; : TestCase
(def user-interface-custom-loop-engine-invalid-memory-slot-case
  (test-case "rejects invalid loop-engine memory-policy slot types"
    (check-equal?
     (with-catch
      (lambda (_) #t)
      (lambda ()
        (custom-loop-presentation
         (custom-loop-invalid-memory-slot-module))
        #f))
     #t)))

;;; Capability policy validates backend names as sandbox backends. Marlin is the
;;; runtime owner, not a sandbox backend value.
;; : TestCase
(def user-interface-custom-loop-engine-invalid-capability-case
  (test-case "diagnoses invalid loop-engine capability backend"
    (let* ((presentation
            (custom-loop-presentation custom-loop-invalid-capability-module))
           (intent
            (car (.ref presentation 'loop-engine-intents)))
           (capability-receipt
            (test-ref intent 'capability-receipt))
           (runtime-manifest
            (test-ref intent 'runtime-command-manifest))
           (runtime-manifest-request
            (test-ref runtime-manifest 'request))
           (diagnostics
            (test-ref capability-receipt 'diagnostics)))
      (check-equal? (test-ref capability-receipt 'backend) 'marlin-sandbox)
      (check-equal? (test-ref capability-receipt 'valid?) #f)
      (check-equal? (test-ref capability-receipt 'diagnostic-count) 1)
      (check-equal? (test-field-values diagnostics 'code)
                    '(unsupported-capability-backend))
      (check-equal? (test-ref capability-receipt 'supported-backends)
                    '(nono-sandbox cube-sandbox))
      (check-equal? (test-ref (test-ref runtime-manifest-request
                                         'capability-receipt)
                              'valid?)
                    #f)
      (check-equal? (car (.ref presentation
                            'loop-engine-capability-receipts))
                    capability-receipt)
      (check-equal? (test-ref intent 'runtime-executed) #f))))

;;; The concrete case is the Flue-alignment proof: one compact loop-engine row
;;; projects the full report-only object graph without runtime execution.
;; : TestCase
(def user-interface-custom-loop-engine-concrete-case
  (test-case "projects custom concrete loop-engine case"
    (let* ((context (custom-loop-concrete-context))
           (presentation (test-ref context 'presentation))
           (intent (test-ref context 'intent))
           (runtime-manifest (test-ref context 'runtime-manifest))
           (runtime-manifest-request
            (test-ref context 'runtime-manifest-request))
           (runtime-manifest-summary
            (test-ref context 'runtime-manifest-summary))
           (runtime-snapshot (test-ref context 'runtime-snapshot)))
      (check-custom-loop-concrete-declaration presentation intent)
      (check-custom-loop-agent-boundary intent)
      (check-custom-loop-operation-boundary intent)
      (check-custom-loop-runtime-manifest intent
                                         runtime-manifest
                                         runtime-manifest-request
                                         runtime-manifest-summary)
      (check-custom-loop-presentation-boundary presentation
                                               intent
                                               runtime-snapshot))))

;; : TestSuite
(def user-interface-custom-loop-engine-test
  (test-suite "poo-flow custom user-interface loop-engine cases"
    user-interface-custom-loop-engine-profile-case
    user-interface-custom-loop-engine-concrete-case
    user-interface-custom-loop-engine-invalid-result-case
    user-interface-custom-loop-engine-invalid-poo-slot-case
    user-interface-custom-loop-engine-invalid-memory-slot-case
    user-interface-custom-loop-engine-invalid-capability-case))

(run-tests! user-interface-custom-loop-engine-test)
