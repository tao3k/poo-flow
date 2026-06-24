;;; -*- Gerbil -*-
;;; Boundary: tests verify concrete loop-engine runtime manifest projection.
;;; Invariant: manifest rows are inert Marlin handoff data, not execution.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/facade
        :poo-flow/src/module-system/init-syntax
        (only-in :poo-flow/src/loops/governor-marlin
                 +loop-governor-marlin-loop-engine-discovery-schema+
                 loop-governor-marlin-loop-engine-discovery)
        (only-in :poo-flow/user-interface/custom/my-module/config
                 poo-flow-custom-my-module-loop-engine-case))

(export user-interface-custom-loop-engine-runtime-manifest-test)

;;; Test lookup mirrors the public alist payload shape emitted by presentation;
;;; it intentionally avoids reaching back into POO objects or private helpers.
;; : (-> Alist Symbol MaybeValue)
(def (test-ref alist key)
  (let (entry (assoc key alist))
    (if entry (cdr entry) #f)))

;;; Field collection checks runtime request row order without coupling the test
;;; to each row's full payload.
;; : (-> [Alist] Symbol [Value])
(def (test-field-values rows key)
  (map (lambda (row) (test-ref row key)) rows))

;;; Expected manifest vocabularies pin the ABI-facing object families and agent
;;; names that Marlin can discover without guessing the entrypoint.
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
    compression-receipt
    policy-extension-receipt
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
    (compression-receipt
     . poo-flow.loop-engine.compression-receipt.v1)
    (policy-extension-receipt
     . poo-flow.loop-engine.policy-extension-receipt.v1)
    (sandbox-handoff-agreement
     . poo-flow.loop-engine.sandbox-handoff-agreement.v1)))

;; : Symbol
(def expected-loop-engine-human-audit-result-contract
  'poo-flow.loop-governor.human-audit-decision.v1)

;;; Presentation construction goes through the facade because the ABI manifest
;;; must be discoverable from normal `use-module` configuration.
;; : (-> PooUserModuleSelection POOObject)
(def (custom-loop-presentation module-bundle)
  (pooFlowUserConfigPresentation
   (pooFlowUserConfig
    (poo-flow-user-module-bundles->modules (list module-bundle))
    (poo-flow-settings))))

;;; Manifest descriptor assertions prove the adapter row is inert command data,
;;; not evidence that Scheme launched Marlin.
;; : (-> Alist Alist)
(def (check-custom-loop-runtime-manifest-descriptor runtime-manifest
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
  (check-equal? (test-ref (test-ref runtime-manifest 'metadata) 'contract)
                'poo-flow.loop-governor.runtime-command-manifest.v1)
  (check-equal? (test-ref runtime-manifest-summary 'kind)
                'runtime-command-manifest-summary)
  (check-equal? (test-ref runtime-manifest-summary 'operation)
                'loop-engine-handoff)
  (check-equal? (test-ref runtime-manifest-summary 'object-families)
                expected-loop-engine-object-families)
  (check-equal? (test-ref runtime-manifest-summary 'receipt-contracts)
                expected-loop-engine-receipt-contracts))

;;; Discovery assertions keep the legacy govern-loop ABI manifest and the newer
;;; runtime handoff manifest on one vocabulary surface for Marlin consumers.
;; : (-> Alist Alist Alist)
(def (check-custom-loop-runtime-manifest-discovery runtime-manifest
                                                   runtime-manifest-request
                                                   runtime-manifest-summary)
  (let (discovery (loop-governor-marlin-loop-engine-discovery))
    (check-equal? (test-ref discovery 'schema)
                  +loop-governor-marlin-loop-engine-discovery-schema+)
    (check-equal? (test-ref discovery 'kind)
                  'loop-engine-marlin-discovery)
    (check-equal? (test-ref discovery 'runtime-command-contract)
                  (test-ref runtime-manifest-request 'contract))
    (check-equal? (test-ref discovery 'runtime-command-executable)
                  (test-ref runtime-manifest 'executable))
    (check-equal? (test-ref discovery 'object-families)
                  expected-loop-engine-object-families)
    (check-equal? (test-ref discovery 'object-families)
                  (test-ref runtime-manifest-request 'object-families))
    (check-equal? (test-ref discovery 'object-families)
                  (test-ref runtime-manifest-summary 'object-families))
    (check-equal? (test-ref discovery 'receipt-contracts)
                  expected-loop-engine-receipt-contracts)
    (check-equal? (test-ref discovery 'receipt-contracts)
                  (test-ref runtime-manifest-request 'receipt-contracts))
    (check-equal? (test-ref discovery 'receipt-contracts)
                  (test-ref runtime-manifest-summary 'receipt-contracts))
    (check-equal? (test-ref discovery 'control-owner) 'gerbil)
    (check-equal? (test-ref discovery 'execution-owner) 'marlin-agent-core)
    (check-equal? (test-ref discovery 'runtime-executed) #f)))

;;; Manifest request contract assertions keep result and object-family schema
;;; checks separate from concrete policy receipt checks.
;; : (-> Alist)
(def (check-custom-loop-runtime-manifest-request-contracts
      runtime-manifest-request)
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
                'current-system-build-loop))

;;; Manifest receipt assertions verify policy receipts survive serialization
;;; into the runtime request without becoming runtime actions.
;; : (-> Alist)
(def (check-custom-loop-runtime-manifest-request-receipts
      runtime-manifest-request)
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
                          'state-path)
                "loop-state/current-system-build.org")
  (check-equal? (test-ref (test-ref runtime-manifest-request
                                     'memory-receipt)
                          'runtime-executed)
                #f)
  (check-equal? (test-ref (test-ref runtime-manifest-request
                                     'compression-receipt)
                          'lineage-kind)
                'compressed-ci-session)
  (check-equal? (test-ref (test-ref runtime-manifest-request
                                     'compression-receipt)
                          'runtime-executed)
                #f))

;;; Manifest graph assertions verify agent and sandbox rows keep the same
;;; public shape after entering the handoff request payload.
;; : (-> Alist)
(def (check-custom-loop-runtime-manifest-request-graph
      runtime-manifest-request)
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
                'build-verifier-agent))

;;; Runtime manifest is the ABI handoff surface that Marlin can consume without
;;; guessing the loop-engine entrypoint or request shape.
;; : TestCase
(def user-interface-custom-loop-engine-runtime-manifest-case
  (test-case "projects custom loop-engine runtime manifest"
    (let* ((presentation
            (custom-loop-presentation
             poo-flow-custom-my-module-loop-engine-case))
           (intent
            (car (.ref presentation 'loop-engine-intents)))
           (runtime-manifest
            (test-ref intent 'runtime-command-manifest))
           (runtime-manifest-request
            (test-ref runtime-manifest 'request))
           (runtime-manifest-summary
            (test-ref intent 'runtime-command-manifest-summary)))
      (check-custom-loop-runtime-manifest-descriptor
       runtime-manifest
       runtime-manifest-summary)
      (check-custom-loop-runtime-manifest-discovery
       runtime-manifest
       runtime-manifest-request
       runtime-manifest-summary)
      (check-custom-loop-runtime-manifest-request-contracts
       runtime-manifest-request)
      (check-custom-loop-runtime-manifest-request-receipts
       runtime-manifest-request)
      (check-custom-loop-runtime-manifest-request-graph
       runtime-manifest-request)
      (check-equal? (test-ref intent 'runtime-executed) #f))))

;;; The suite keeps ABI handoff assertions separate from profile projection so
;;; changes in Marlin-facing request shape are reviewed against their own case.
;; : TestSuite
(def user-interface-custom-loop-engine-runtime-manifest-test
  (test-suite "poo-flow custom loop-engine runtime manifest"
    user-interface-custom-loop-engine-runtime-manifest-case))
