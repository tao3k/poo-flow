;;; -*- Gerbil -*-
;;; Boundary: fixed session handoff receipts for runtime owners.
;;; Invariant: handoff values are data receipts, not executable Scheme handlers.

(import (only-in :clan/poo/object .o .ref object?)
        :poo-flow/src/modules/session/objects-core)

(export make-poo-flow-session-handoff-receipt
        poo-flow-session-handoff-receipt?
        poo-flow-session-handoff-receipt-kind
        poo-flow-session-handoff-receipt-schema
        poo-flow-session-handoff-receipt-source
        poo-flow-session-handoff-receipt-session-id
        poo-flow-session-handoff-receipt-chunk-count
        poo-flow-session-handoff-receipt-placement-profile-ref
        poo-flow-session-handoff-receipt-placement-resolved?
        poo-flow-session-handoff-receipt-placement-diagnostics
        poo-flow-session-handoff-receipt-runtime-owner
        poo-flow-session-handoff-receipt-handoff-required
        poo-flow-session-handoff-receipt-runtime-executed
        poo-flow-session-handoff-receipt-runtime-parses-scheme-source
        poo-flow-session-handoff-receipt-scheme-manufactures-runtime-handlers
        poo-flow-session-handoff-receipt-metadata
        poo-flow-session-handoff
        poo-flow-session-handoff?
        poo-flow-session-topology->handoff-metadata
        make-poo-flow-lean-fact-key-contract
        poo-flow-lean-fact-key-contract?
        poo-flow-lean-fact-key-contract-key
        poo-flow-lean-fact-key-contract-kind
        poo-flow-lean-fact-key-contract-lean-owner
        poo-flow-lean-fact-key-contract-lean-name
        poo-flow-lean-fact-key-contract-source-slot
        poo-flow-lean-fact-key-contract-polarity
        poo-flow-session-handoff-lean-fact-key-contracts
        poo-flow-ui-scenario-lean-fact-key-contracts
        poo-flow-lean-fact-contract-keys
        poo-flow-lean-fact-contract-complete?
        poo-flow-ui-scenario->lean-facts
        poo-flow-session-handoff->lean-facts
        poo-flow-session-handoff->alist)

;;; Fixed handoff receipts make the ABI boundary explicit: Scheme constructs
;;; typed receipt state, and only the ABI projection turns it into alist data.
;; : (-> Symbol Symbol Symbol Symbol Integer Symbol Boolean [Alist] String Boolean Boolean Boolean Boolean Alist PooSessionHandoffReceipt)
(defstruct poo-flow-session-handoff-receipt
  (kind
   schema
   source
   session-id
   chunk-count
   placement-profile-ref
   placement-resolved?
   placement-diagnostics
   runtime-owner
   handoff-required
   runtime-executed
   runtime-parses-scheme-source
   scheme-manufactures-runtime-handlers
   metadata)
  transparent: #t)

;;; Handoff receipts summarize the session for runtime owners. They keep the
;;; heavy execution boundary explicit and never claim Scheme executed work.
;; : (-> PooSession [Alist] PooSessionHandoff)
(def (poo-flow-session-handoff session . maybe-metadata)
  (poo-flow-session-require "session handoff requires a session"
                            (poo-flow-session? session)
                            session)
  (let (placement (poo-flow-session-value-placement session))
    (.o kind: 'poo-flow.session.handoff
        schema: 'poo-flow.modules.session.handoff.v1
        source: 'poo-flow-session-presentation
        session-id: (poo-flow-session-id session)
        chunk-count: (length (poo-flow-session-chunks session))
        placement-profile-ref: (poo-flow-session-placement-profile-ref
                                placement)
        placement-resolved?: (poo-flow-session-placement-resolved? placement)
        placement-diagnostics: (poo-flow-session-placement-diagnostics
                                placement)
        runtime-owner: "marlin-agent-core"
        handoff-required: #t
        runtime-executed: #f
        runtime-parses-scheme-source: #f
        scheme-manufactures-runtime-handlers: #f
        metadata: (if (null? maybe-metadata) '() (car maybe-metadata)))))

;; : (-> Value Boolean)
(def (poo-flow-session-handoff? value)
  (or (poo-flow-session-handoff-receipt? value)
      (object? value)))

;; : (forall (a) (-> PooSessionHandoff Symbol (-> PooSessionHandoff a) a))
(def (poo-flow-session-handoff-ref handoff slot struct-ref)
  (if (poo-flow-session-handoff-receipt? handoff)
    (struct-ref handoff)
    (.ref handoff slot)))

;;; The ABI projection is the only place where handoff receipt state becomes an
;;; alist. Runtime language bindings consume this shape without seeing Gerbil
;;; structs or POO internals.
;; poo-flow-session-handoff->alist
;;   : (-> PooSessionHandoff Alist)
;;   | contract: project one fixed handoff receipt into ABI alist fields
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-session-handoff->alist handoff)
;;       ;; => ((kind . poo-flow.session.handoff) ...)
;;       ```
;;     %
(def (poo-flow-session-handoff->alist handoff)
  (list
   (cons 'kind
         (poo-flow-session-handoff-ref
          handoff
          'kind
          poo-flow-session-handoff-receipt-kind))
   (cons 'schema
         (poo-flow-session-handoff-ref
          handoff
          'schema
          poo-flow-session-handoff-receipt-schema))
   (cons 'source
         (poo-flow-session-handoff-ref
          handoff
          'source
          poo-flow-session-handoff-receipt-source))
   (cons 'session-id
         (poo-flow-session-handoff-ref
          handoff
          'session-id
          poo-flow-session-handoff-receipt-session-id))
   (cons 'chunk-count
         (poo-flow-session-handoff-ref
          handoff
          'chunk-count
          poo-flow-session-handoff-receipt-chunk-count))
   (cons 'placement-profile-ref
         (poo-flow-session-handoff-ref
          handoff
          'placement-profile-ref
          poo-flow-session-handoff-receipt-placement-profile-ref))
   (cons 'placement-resolved?
         (poo-flow-session-handoff-ref
          handoff
          'placement-resolved?
          poo-flow-session-handoff-receipt-placement-resolved?))
   (cons 'placement-diagnostics
         (poo-flow-session-handoff-ref
          handoff
          'placement-diagnostics
          poo-flow-session-handoff-receipt-placement-diagnostics))
   (cons 'runtime-owner
         (poo-flow-session-handoff-ref
          handoff
          'runtime-owner
          poo-flow-session-handoff-receipt-runtime-owner))
   (cons 'handoff-required
         (poo-flow-session-handoff-ref
          handoff
          'handoff-required
          poo-flow-session-handoff-receipt-handoff-required))
   (cons 'runtime-executed
         (poo-flow-session-handoff-ref
          handoff
          'runtime-executed
          poo-flow-session-handoff-receipt-runtime-executed))
   (cons 'runtime-parses-scheme-source
         (poo-flow-session-handoff-ref
          handoff
          'runtime-parses-scheme-source
          poo-flow-session-handoff-receipt-runtime-parses-scheme-source))
   (cons 'scheme-manufactures-runtime-handlers
         (poo-flow-session-handoff-ref
          handoff
          'scheme-manufactures-runtime-handlers
          poo-flow-session-handoff-receipt-scheme-manufactures-runtime-handlers))
   (cons 'metadata
         (poo-flow-session-handoff-ref
          handoff
          'metadata
          poo-flow-session-handoff-receipt-metadata))))

(def (poo-flow-session-handoff-fact-ref facts key)
  (let ((cell (assq key facts)))
    (and cell (cdr cell))))

;; : (-> Symbol Symbol Symbol Symbol Symbol Symbol PooLeanFactKeyContract)
(defstruct poo-flow-lean-fact-key-contract
  (key
   kind
   lean-owner
   lean-name
   source-slot
   polarity)
  transparent: #t)

(def (poo-flow-lean-fact-key key kind lean-owner lean-name source-slot polarity)
  (make-poo-flow-lean-fact-key-contract
   key
   kind
   lean-owner
   lean-name
   source-slot
   polarity))

(def poo-flow-session-handoff-lean-fact-key-contracts
  (list
   (poo-flow-lean-fact-key
    'session.lifecycle/chunk-present
    'fact
    'SessionLifecycle.SessionFact
    'chunkPresent
    'chunk-count
    'positive)
   (poo-flow-lean-fact-key
    'session.lifecycle/placement-resolved
    'fact
    'SessionLifecycle.SessionFact
    'placementResolved
    'placement-resolved?
    'positive)
   (poo-flow-lean-fact-key
    'session.lifecycle/placement-missing-profile
    'fact
    'SessionLifecycle.SessionFact
    'placementMissingProfile
    'placement-diagnostics/missing-profile
    'positive)
   (poo-flow-lean-fact-key
    'session.lifecycle/runtime-summary-present
    'fact
    'SessionLifecycle.SessionFact
    'runtimeSummaryPresent
    'handoff-receipt
    'positive)
   (poo-flow-lean-fact-key
    'session.lifecycle/handoff-receipt-present
    'fact
    'SessionLifecycle.SessionFact
    'handoffReceiptPresent
    'handoff-receipt
    'positive)
   (poo-flow-lean-fact-key
    'session.lifecycle/runtime-executed-false
    'fact
    'SessionLifecycle.SessionFact
    'runtimeExecutedFalse
    'runtime-executed
    'negative)
   (poo-flow-lean-fact-key
    'session.lifecycle/handoff-required-true
    'fact
    'SessionLifecycle.SessionFact
    'handoffRequiredTrue
    'handoff-required
    'positive)
   (poo-flow-lean-fact-key
    'session.lifecycle/runtime-owner-marlin
    'fact
    'SessionLifecycle.SessionFact
    'runtimeOwnerMarlin
    'runtime-owner
    'positive)
   (poo-flow-lean-fact-key
    'session.lifecycle/runtime-parses-scheme-source-false
    'fact
    'SessionLifecycle.SessionFact
    'runtimeParsesSchemeSourceFalse
    'runtime-parses-scheme-source
    'negative)
   (poo-flow-lean-fact-key
    'session.lifecycle/scheme-manufactures-runtime-handlers-false
    'fact
    'SessionLifecycle.SessionFact
    'schemeManufacturesRuntimeHandlersFalse
    'scheme-manufactures-runtime-handlers
    'negative)
   (poo-flow-lean-fact-key
    'scenario.bridge/s3-handoff-receipt
    'fact
    'ScenarioProof.ScenarioBridgeFact
    's3HandoffReceipt
    'static-marlin-handoff
    'positive)
   (poo-flow-lean-fact-key
    'scenario.bridge/s11-agent-registered
    'fact
    'ScenarioProof.ScenarioBridgeFact
    's11AgentRegistered
    'metadata/agent-registered
    'positive)
   (poo-flow-lean-fact-key
    'scenario.bridge/s11-subagent-registered
    'fact
    'ScenarioProof.ScenarioBridgeFact
    's11SubagentRegistered
    'metadata/subagent-registered
    'positive)
   (poo-flow-lean-fact-key
    'scenario.bridge/s11-channel-authorized
    'fact
    'ScenarioProof.ScenarioBridgeFact
    's11ChannelAuthorized
    'metadata/channel-authorized
    'positive)
   (poo-flow-lean-fact-key
    'scenario.bridge/s14-placement-missing-profile
    'fact
    'ScenarioProof.ScenarioBridgeFact
    's14PlacementMissingProfile
    'placement-diagnostics/missing-profile
    'positive)))

(def poo-flow-ui-scenario-lean-fact-key-contracts
  (list
   (poo-flow-lean-fact-key
    'ui.scenario/use-case-declared
    'fact
    'UserInterface.UiScenarioFact
    'useCaseDeclared
    'use-case-declared?
    'positive)
   (poo-flow-lean-fact-key
    'ui.scenario/profile-declared
    'fact
    'UserInterface.UiScenarioFact
    'profileDeclared
    'profile-declared?
    'positive)
   (poo-flow-lean-fact-key
    'ui.scenario/governor-configured
    'fact
    'UserInterface.UiScenarioFact
    'governorConfigured
    'governor-configured?
    'positive)
   (poo-flow-lean-fact-key
    'ui.scenario/lineage-policy-done
    'fact
    'UserInterface.UiScenarioFact
    'lineagePolicyDone
    'lineage-policy-done?
    'positive)
   (poo-flow-lean-fact-key
    'ui.scenario/selector-policy-done
    'fact
    'UserInterface.UiScenarioFact
    'selectorPolicyDone
    'selector-policy-done?
    'positive)
   (poo-flow-lean-fact-key
    'ui.scenario/resource-policy-done
    'fact
    'UserInterface.UiScenarioFact
    'resourcePolicyDone
    'resource-policy-done?
    'positive)
   (poo-flow-lean-fact-key
    'ui.scenario/capability-policy-done
    'fact
    'UserInterface.UiScenarioFact
    'capabilityPolicyDone
    'capability-policy-done?
    'positive)
   (poo-flow-lean-fact-key
    'ui.scenario/memory-policy-done
    'fact
    'UserInterface.UiScenarioFact
    'memoryPolicyDone
    'memory-policy-done?
    'positive)
   (poo-flow-lean-fact-key
    'ui.scenario/compression-policy-done
    'fact
    'UserInterface.UiScenarioFact
    'compressionPolicyDone
    'compression-policy-done?
    'positive)
   (poo-flow-lean-fact-key
    'ui.scenario/strategy-plan-done
    'fact
    'UserInterface.UiScenarioFact
    'strategyPlanDone
    'strategy-plan-done?
    'positive)
   (poo-flow-lean-fact-key
    'ui.scenario/local-validation-done
    'fact
    'UserInterface.UiScenarioFact
    'localValidationDone
    'local-validation-done?
    'positive)
   (poo-flow-lean-fact-key
    'ui.scenario/runtime-manifest-done
    'fact
    'UserInterface.UiScenarioFact
    'runtimeManifestDone
    'runtime-manifest-done?
    'positive)
   (poo-flow-lean-fact-key
    'ui.scenario/marlin-handoff-done
    'fact
    'UserInterface.UiScenarioFact
    'marlinHandoffDone
    'marlin-handoff-done?
    'positive)
   (poo-flow-lean-fact-key
    'ui.scenario/l1-report-done
    'fact
    'UserInterface.UiScenarioFact
    'l1ReportDone
    'l1-report-done?
    'positive)
   (poo-flow-lean-fact-key
    'ui.scenario/scenario-matrix-done
    'fact
    'UserInterface.UiScenarioFact
    'scenarioMatrixDone
    'scenario-matrix-done?
    'positive)
   (poo-flow-lean-fact-key
    'ui.scenario/scenario-benchmark-done
    'fact
    'UserInterface.UiScenarioFact
    'scenarioBenchmarkDone
    'scenario-benchmark-done?
    'positive)
   (poo-flow-lean-fact-key
    'ui.scenario/performance-fixture-bound
    'fact
    'UserInterface.UiScenarioFact
    'performanceFixtureBound
    'performance-fixture-bound?
    'positive)
   (poo-flow-lean-fact-key
    'ui.failure/strategy-missing-selector-policy
    'failure-obligation
    'UserInterface
    'ui_projection_blocks_strategy_without_selector_policy
    'selector-policy-done?
    'missing)
   (poo-flow-lean-fact-key
    'ui.failure/strategy-missing-resource-policy
    'failure-obligation
    'UserInterface
    'ui_projection_blocks_strategy_without_resource_policy
    'resource-policy-done?
    'missing)
   (poo-flow-lean-fact-key
    'ui.failure/strategy-missing-capability-policy
    'failure-obligation
    'UserInterface
    'ui_projection_blocks_strategy_without_capability_policy
    'capability-policy-done?
    'missing)
   (poo-flow-lean-fact-key
    'ui.failure/local-validation-missing-strategy-plan
    'failure-obligation
    'UserInterface
    'ui_projection_blocks_local_validation_without_strategy_plan
    'strategy-plan-done?
    'missing)
   (poo-flow-lean-fact-key
    'ui.failure/runtime-manifest-missing-strategy-plan
    'failure-obligation
    'UserInterface
    'ui_projection_blocks_runtime_manifest_without_strategy_plan
    'strategy-plan-done?
    'missing)
   (poo-flow-lean-fact-key
    'ui.failure/runtime-manifest-missing-local-validation
    'failure-obligation
    'UserInterface
    'ui_projection_blocks_runtime_manifest_without_local_validation
    'local-validation-done?
    'missing)
   (poo-flow-lean-fact-key
    'ui.failure/runtime-manifest-missing-memory-policy
    'failure-obligation
    'UserInterface
    'ui_projection_blocks_runtime_manifest_without_memory_policy
    'memory-policy-done?
    'missing)
   (poo-flow-lean-fact-key
    'ui.failure/runtime-manifest-missing-compression-policy
    'failure-obligation
    'UserInterface
    'ui_projection_blocks_runtime_manifest_without_compression_policy
    'compression-policy-done?
    'missing)
   (poo-flow-lean-fact-key
    'ui.failure/handoff-missing-runtime-manifest
    'failure-obligation
    'UserInterface
    'ui_projection_blocks_handoff_without_runtime_manifest
    'runtime-manifest-done?
    'missing)
   (poo-flow-lean-fact-key
    'ui.failure/benchmark-missing-scenario-matrix
    'failure-obligation
    'UserInterface
    'ui_projection_blocks_benchmark_without_matrix
    'scenario-matrix-done?
    'missing)
   (poo-flow-lean-fact-key
    'ui.failure/benchmark-missing-l1-report
    'failure-obligation
    'UserInterface
    'ui_projection_blocks_benchmark_without_l1_report
    'l1-report-done?
    'missing)
   (poo-flow-lean-fact-key
    'ui.failure/benchmark-missing-performance-fixture
    'failure-obligation
    'UserInterface
    'ui_projection_blocks_benchmark_without_performance_fixture
    'performance-fixture-bound?
    'missing)))

(def (poo-flow-lean-fact-contract-keys contracts)
  (map poo-flow-lean-fact-key-contract-key contracts))

(def (poo-flow-lean-fact-key-declared? contracts key)
  (cond
   ((null? contracts) #f)
   ((eq? key (poo-flow-lean-fact-key-contract-key (car contracts))) #t)
   (else (poo-flow-lean-fact-key-declared? (cdr contracts) key))))

(def (poo-flow-lean-fact-contract-keys-present? contracts facts)
  (cond
   ((null? contracts) #t)
   ((assq (poo-flow-lean-fact-key-contract-key (car contracts)) facts)
    (poo-flow-lean-fact-contract-keys-present? (cdr contracts) facts))
   (else #f)))

(def (poo-flow-lean-fact-contract-facts-declared? facts contracts)
  (cond
   ((null? facts) #t)
   ((poo-flow-lean-fact-key-declared? contracts (caar facts))
    (poo-flow-lean-fact-contract-facts-declared? (cdr facts) contracts))
   (else #f)))

(def (poo-flow-lean-fact-contract-complete? contracts facts)
  (and (poo-flow-lean-fact-contract-keys-present? contracts facts)
       (poo-flow-lean-fact-contract-facts-declared? facts contracts)))

(def (poo-flow-session-diagnostic-present? diagnostics key)
  (and (list? diagnostics)
       (or (and (memq key diagnostics) #t)
           (and (assq key diagnostics) #t))))

(def (poo-flow-session-metadata-true? metadata key)
  (and (list? metadata)
       (let ((cell (assq key metadata)))
         (and cell (eq? (cdr cell) #t)))))

(def (poo-flow-session-topology-ref topology slot)
  (cond
   ((object? topology) (.ref topology slot))
   ((list? topology)
    (let ((cell (assq slot topology)))
      (and cell (cdr cell))))
   (else #f)))

(def (poo-flow-session-topology->handoff-metadata topology . maybe-metadata)
  (let ((metadata (if (null? maybe-metadata) '() (car maybe-metadata))))
    (append
     (list
      (cons 'agent-registered
            (eq? (poo-flow-session-topology-ref
                  topology
                  'agent-registered?)
                 #t))
      (cons 'subagent-registered
            (eq? (poo-flow-session-topology-ref
                  topology
                  'subagent-registered?)
                 #t))
      (cons 'channel-authorized
            (eq? (poo-flow-session-topology-ref
                  topology
                  'channel-authorized?)
                 #t)))
     metadata)))

(def (poo-flow-ui-scenario-ref scenario slot)
  (cond
   ((object? scenario)
    (with-catch
     (lambda (_)
       #f)
     (lambda ()
       (.ref scenario slot))))
   ((list? scenario)
    (let ((cell (assq slot scenario)))
      (and cell (cdr cell))))
   (else #f)))

(def (poo-flow-ui-scenario-flag scenario slot)
  (eq? (poo-flow-ui-scenario-ref scenario slot) #t))

(def (poo-flow-ui-scenario->lean-facts scenario)
  (let* ((use-case-declared
          (poo-flow-ui-scenario-flag scenario 'use-case-declared?))
         (profile-declared
          (poo-flow-ui-scenario-flag scenario 'profile-declared?))
         (governor-configured
          (poo-flow-ui-scenario-flag scenario 'governor-configured?))
         (lineage-policy-done
          (poo-flow-ui-scenario-flag scenario 'lineage-policy-done?))
         (selector-policy-done
          (poo-flow-ui-scenario-flag scenario 'selector-policy-done?))
         (resource-policy-done
          (poo-flow-ui-scenario-flag scenario 'resource-policy-done?))
         (capability-policy-done
          (poo-flow-ui-scenario-flag scenario 'capability-policy-done?))
         (memory-policy-done
          (poo-flow-ui-scenario-flag scenario 'memory-policy-done?))
         (compression-policy-done
          (poo-flow-ui-scenario-flag scenario 'compression-policy-done?))
         (strategy-plan-done
          (poo-flow-ui-scenario-flag scenario 'strategy-plan-done?))
         (local-validation-done
          (poo-flow-ui-scenario-flag scenario 'local-validation-done?))
         (runtime-manifest-done
          (poo-flow-ui-scenario-flag scenario 'runtime-manifest-done?))
         (marlin-handoff-done
          (poo-flow-ui-scenario-flag scenario 'marlin-handoff-done?))
         (l1-report-done
          (poo-flow-ui-scenario-flag scenario 'l1-report-done?))
         (scenario-matrix-done
          (poo-flow-ui-scenario-flag scenario 'scenario-matrix-done?))
         (scenario-benchmark-done
          (poo-flow-ui-scenario-flag scenario 'scenario-benchmark-done?))
         (performance-fixture-bound
          (poo-flow-ui-scenario-flag scenario 'performance-fixture-bound?)))
    (list
     (cons 'ui.scenario/use-case-declared use-case-declared)
     (cons 'ui.scenario/profile-declared profile-declared)
     (cons 'ui.scenario/governor-configured governor-configured)
     (cons 'ui.scenario/lineage-policy-done lineage-policy-done)
     (cons 'ui.scenario/selector-policy-done selector-policy-done)
     (cons 'ui.scenario/resource-policy-done resource-policy-done)
     (cons 'ui.scenario/capability-policy-done capability-policy-done)
     (cons 'ui.scenario/memory-policy-done memory-policy-done)
     (cons 'ui.scenario/compression-policy-done compression-policy-done)
     (cons 'ui.scenario/strategy-plan-done strategy-plan-done)
     (cons 'ui.scenario/local-validation-done local-validation-done)
     (cons 'ui.scenario/runtime-manifest-done runtime-manifest-done)
     (cons 'ui.scenario/marlin-handoff-done marlin-handoff-done)
     (cons 'ui.scenario/l1-report-done l1-report-done)
     (cons 'ui.scenario/scenario-matrix-done scenario-matrix-done)
     (cons 'ui.scenario/scenario-benchmark-done scenario-benchmark-done)
     (cons 'ui.scenario/performance-fixture-bound performance-fixture-bound)
     (cons 'ui.failure/strategy-missing-selector-policy
           (not selector-policy-done))
     (cons 'ui.failure/strategy-missing-resource-policy
           (not resource-policy-done))
     (cons 'ui.failure/strategy-missing-capability-policy
           (not capability-policy-done))
     (cons 'ui.failure/local-validation-missing-strategy-plan
           (not strategy-plan-done))
     (cons 'ui.failure/runtime-manifest-missing-strategy-plan
           (not strategy-plan-done))
     (cons 'ui.failure/runtime-manifest-missing-local-validation
           (not local-validation-done))
     (cons 'ui.failure/runtime-manifest-missing-memory-policy
           (not memory-policy-done))
     (cons 'ui.failure/runtime-manifest-missing-compression-policy
           (not compression-policy-done))
     (cons 'ui.failure/handoff-missing-runtime-manifest
           (not runtime-manifest-done))
     (cons 'ui.failure/benchmark-missing-scenario-matrix
           (not scenario-matrix-done))
     (cons 'ui.failure/benchmark-missing-l1-report
           (not l1-report-done))
     (cons 'ui.failure/benchmark-missing-performance-fixture
           (not performance-fixture-bound)))))

(def (poo-flow-session-handoff->lean-facts handoff)
  (let* ((facts (poo-flow-session-handoff->alist handoff))
         (chunk-count
          (poo-flow-session-handoff-fact-ref facts 'chunk-count))
         (placement-resolved?
          (poo-flow-session-handoff-fact-ref facts 'placement-resolved?))
         (placement-diagnostics
          (poo-flow-session-handoff-fact-ref facts 'placement-diagnostics))
         (runtime-owner
          (poo-flow-session-handoff-fact-ref facts 'runtime-owner))
         (handoff-required
          (poo-flow-session-handoff-fact-ref facts 'handoff-required))
         (runtime-executed
          (poo-flow-session-handoff-fact-ref facts 'runtime-executed))
         (runtime-parses-scheme-source
          (poo-flow-session-handoff-fact-ref
           facts
           'runtime-parses-scheme-source))
         (scheme-manufactures-runtime-handlers
          (poo-flow-session-handoff-fact-ref
           facts
           'scheme-manufactures-runtime-handlers))
         (metadata
          (poo-flow-session-handoff-fact-ref facts 'metadata))
         (placement-missing-profile
          (poo-flow-session-diagnostic-present?
           placement-diagnostics
           'missing-profile))
         (static-marlin-handoff
          (and (eq? handoff-required #t)
               (eq? runtime-executed #f)
               (eq? runtime-parses-scheme-source #f)
               (eq? scheme-manufactures-runtime-handlers #f)
               (equal? runtime-owner "marlin-agent-core"))))
    (list
     (cons 'session.lifecycle/chunk-present
           (and (number? chunk-count) (> chunk-count 0)))
     (cons 'session.lifecycle/placement-resolved
           (and placement-resolved? #t))
     (cons 'session.lifecycle/placement-missing-profile
           placement-missing-profile)
     (cons 'session.lifecycle/runtime-summary-present #t)
     (cons 'session.lifecycle/handoff-receipt-present #t)
     (cons 'session.lifecycle/runtime-executed-false
           (eq? runtime-executed #f))
     (cons 'session.lifecycle/handoff-required-true
           (eq? handoff-required #t))
     (cons 'session.lifecycle/runtime-owner-marlin
           (equal? runtime-owner "marlin-agent-core"))
     (cons 'session.lifecycle/runtime-parses-scheme-source-false
           (eq? runtime-parses-scheme-source #f))
     (cons 'session.lifecycle/scheme-manufactures-runtime-handlers-false
           (eq? scheme-manufactures-runtime-handlers #f))
     (cons 'scenario.bridge/s3-handoff-receipt
           static-marlin-handoff)
     (cons 'scenario.bridge/s11-agent-registered
           (poo-flow-session-metadata-true?
            metadata
            'agent-registered))
     (cons 'scenario.bridge/s11-subagent-registered
           (poo-flow-session-metadata-true?
            metadata
            'subagent-registered))
     (cons 'scenario.bridge/s11-channel-authorized
           (poo-flow-session-metadata-true?
            metadata
            'channel-authorized))
     (cons 'scenario.bridge/s14-placement-missing-profile
           placement-missing-profile))))
