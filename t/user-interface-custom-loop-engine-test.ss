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
                 poo-flow-custom-my-module-loop-engine-case))

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
    (compression-receipt
     . poo-flow.loop-engine.compression-receipt.v1)
    (policy-extension-receipt
     . poo-flow.loop-engine.policy-extension-receipt.v1)
    (sandbox-handoff-agreement
     . poo-flow.loop-engine.sandbox-handoff-agreement.v1)))

;; : Symbol
(def expected-loop-engine-human-audit-result-contract
  'poo-flow.loop-governor.human-audit-decision.v1)

;; : [Symbol]
(def expected-loop-engine-required-result-fields
  '(decision summary evidence))

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
;;; stays under one boundary: declaration shape, agent graph, operation rows,
;;; or presentation aggregation.
;; : (-> Alist)
(def (custom-loop-concrete-context)
  (let* ((presentation
          (custom-loop-presentation
           poo-flow-custom-my-module-loop-engine-case))
         (intent
          (car (.ref presentation 'loop-engine-intents))))
    (list (cons 'presentation presentation)
          (cons 'intent intent)
          (cons 'runtime-snapshot
                (test-ref intent 'runtime-snapshot)))))

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
  (let ((memory-policies (test-ref intent 'memory-policies)))
    (check-equal? (test-field-values memory-policies 'use-case)
                  '(current-system-build-loop))
    (check-equal? (test-ref (car memory-policies) 'state-path)
                  "loop-state/current-system-build.org")
    (check-equal? (test-ref (car memory-policies) 'recall)
                  '(last-user-message build-context prior-failure))
    (check-equal? (test-ref (car memory-policies) 'retention)
                  'report-only))
  (check-equal? (test-ref (test-ref intent 'compression-policy)
                          'strategy)
                'handoff-summary)
  (check-equal? (test-ref (test-ref intent 'compression-policy)
                          'lineage-kind)
                'compressed-ci-session)
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

;;; Agent graph assertions prove profile, harness, and session rows are
;;; projected before the runtime handoff without becoming execution.
;; : (-> Alist Alist Alist Alist Alist)
(def (check-custom-loop-agent-graph-boundary handoff
                                             result-contract
                                             sandbox-agreement
                                             agent-profiles
                                             agent-harnesses
                                             agent-sessions)
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
                #f))

;;; Policy receipt assertions keep lineage, selection, resource, memory, and
;;; compression facts report-only while preserving their selected loop branch.
;; : (-> Alist Alist Alist Alist Alist Alist)
(def (check-custom-loop-policy-receipt-boundary lineage-receipt
                                                selector-receipt
                                                resource-dispatch-receipt
                                                capability-receipt
                                                memory-receipt
                                                compression-receipt)
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
  (check-equal? (test-ref memory-receipt 'selected-use-case)
                'current-system-build-loop)
  (check-equal? (test-ref memory-receipt 'use-case)
                'current-system-build-loop)
  (check-equal? (test-ref memory-receipt 'store) 'project-memory)
  (check-equal? (test-ref memory-receipt 'state-path)
                "loop-state/current-system-build.org")
  (check-equal? (test-ref memory-receipt 'scope) 'session)
  (check-equal? (test-ref memory-receipt 'recall)
                '(last-user-message build-context prior-failure))
  (check-equal? (test-ref memory-receipt 'commit)
                '(decision-summary evidence-index handoff-receipt))
  (check-equal? (test-ref memory-receipt 'retention) 'report-only)
  (check-equal? (test-field-values (test-ref memory-receipt 'policies)
                                   'use-case)
                '(current-system-build-loop))
  (check-equal? (test-ref memory-receipt 'runtime-executed) #f)
  (check-equal? (test-ref compression-receipt 'strategy)
                'handoff-summary)
  (check-equal? (test-ref compression-receipt 'trigger)
                'after-human-audit)
  (check-equal? (test-ref compression-receipt 'summary-format)
                'structured-alist)
  (check-equal? (test-ref compression-receipt 'lineage-kind)
                'compressed-ci-session)
  (check-equal? (test-ref compression-receipt 'source-session-ref)
                'loop-engine/current-system-build-loop/session)
  (check-equal? (test-ref compression-receipt 'runtime-executed) #f))

;;; Handoff correlation assertions ensure the public handoff row references the
;;; exact receipt rows already exposed independently on the intent.
;; : (-> Alist Alist Alist Alist Alist Alist Alist Alist Alist Alist Alist Alist)
(def (check-custom-loop-handoff-correlation handoff
                                            result-contract
                                            agent-profiles
                                            agent-harnesses
                                            agent-sessions
                                            lineage-receipt
                                            selector-receipt
                                            resource-dispatch-receipt
                                            capability-receipt
                                            memory-receipt
                                            compression-receipt)
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
  (check-equal? (test-ref handoff 'compression-receipt)
                compression-receipt)
  (check-equal? (test-ref handoff 'result-contract) result-contract)
  (check-equal? (test-ref handoff 'runtime-executed) #f))

;;; Agent-boundary assertions coordinate the graph, receipt, and handoff
;;; checks against the same projected intent.
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
         (test-ref intent 'memory-receipt))
        (compression-receipt
         (test-ref intent 'compression-receipt)))
    (check-custom-loop-agent-graph-boundary handoff
                                            result-contract
                                            sandbox-agreement
                                            agent-profiles
                                            agent-harnesses
                                            agent-sessions)
    (check-custom-loop-policy-receipt-boundary lineage-receipt
                                               selector-receipt
                                               resource-dispatch-receipt
                                               capability-receipt
                                               memory-receipt
                                               compression-receipt)
    (check-custom-loop-handoff-correlation handoff
                                           result-contract
                                           agent-profiles
                                           agent-harnesses
                                           agent-sessions
                                           lineage-receipt
                                           selector-receipt
                                           resource-dispatch-receipt
                                           capability-receipt
                                           memory-receipt
                                           compression-receipt)))

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
                                  'loop-engine-memory-receipts))
                          'selected-use-case)
                'current-system-build-loop)
  (check-equal? (test-ref (car (.ref presentation
                                  'loop-engine-compression-receipts))
                          'trigger)
                'after-human-audit)
  (check-equal? (test-ref (car (.ref presentation
                                  'loop-engine-runtime-command-manifests))
                          'operation)
                'loop-engine-handoff)
  (check-equal? (test-ref (car (.ref presentation
                                  'loop-engine-runtime-command-manifest-summaries))
                          'contract)
                'poo-flow.loop-governor.runtime-command-manifest.v1))

;;; The concrete case is the Flue-alignment proof: one compact loop-engine row
;;; projects the full report-only object graph without runtime execution.
;; : TestCase
(def user-interface-custom-loop-engine-concrete-case
  (test-case "projects custom concrete loop-engine case"
    (let* ((context (custom-loop-concrete-context))
           (presentation (test-ref context 'presentation))
           (intent (test-ref context 'intent))
           (runtime-snapshot (test-ref context 'runtime-snapshot)))
      (check-custom-loop-concrete-declaration presentation intent)
      (check-custom-loop-agent-boundary intent)
      (check-custom-loop-operation-boundary intent)
      (check-custom-loop-presentation-boundary presentation
                                               intent
                                               runtime-snapshot))))

;; : TestSuite
(def user-interface-custom-loop-engine-test
  (test-suite "poo-flow custom user-interface loop-engine cases"
    user-interface-custom-loop-engine-concrete-case))
