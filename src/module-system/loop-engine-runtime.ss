;;; -*- Gerbil -*-
;;; Boundary: loop-engine runtime handoff projection for module-system config.
;;; Invariant: this owner emits Marlin handoff data and never executes runtime work.

(import (only-in :std/sugar filter-map)
        (only-in :poo-flow/src/core/agent-harness
                 make-poo-flow-runtime-snapshot
                 poo-flow-runtime-snapshot->alist
                 )
        (only-in :poo-flow/src/core/runtime-adapter
                 +runtime-request-schema+
                 make-stdout-runtime-command-descriptor
                 runtime-command-descriptor->manifest)
        (only-in :poo-flow/src/modules/agent-sandbox/config
                 poo-flow-default-sandbox-profiles)
        (only-in :poo-flow/src/modules/sandbox-core/profile-support/policy
                 poo-flow-sandbox-backend-capability?
                 poo-flow-sandbox-backend-capability/backend-kind
                 poo-flow-sandbox-backend-capability/capabilities
                 poo-flow-sandbox-backend-capability-registry-entries)
        (only-in :poo-flow/src/modules/funflow/config
                 poo-flow-funflow-workflow-agreement)
        (only-in :poo-flow/src/module-system/sandbox-backend-capability-catalog
                 poo-flow-user-config-sandbox-backend-capability-registry)
        :poo-flow/src/module-system/base
        :poo-flow/src/module-system/sandbox-profile-catalog
        :poo-flow/src/module-system/workflow-cicd-config
        :poo-flow/src/module-system/loop-engine-core
        :poo-flow/src/module-system/loop-engine-runtime-base
        :poo-flow/src/module-system/runtime-projection-syntax
        :poo-flow/src/module-system/loop-engine-runtime-agent
        :poo-flow/src/module-system/loop-engine-result-contract)

(export poo-flow-user-module-selection-loop-engine-intent
        make-loop-engine-capability-receipt
        loop-engine-capability-receipt?
        loop-engine-capability-receipt-backend
        loop-engine-capability-receipt-backend-kind
        loop-engine-capability-receipt-backend-capabilities
        loop-engine-capability-receipt-supported-backends
        loop-engine-capability-receipt-valid?
        loop-engine-capability-receipt-diagnostics
        loop-engine-capability-receipt-isolation
        loop-engine-capability-receipt-required
        loop-engine-capability-receipt-optional
        loop-engine-capability-receipt-unsupported-behavior
        loop-engine-capability-receipt-sandbox-ref
        loop-engine-capability-receipt-session-ref
        loop-engine-capability-receipt->alist
        poo-flow-user-loop-engine-primary-agent
        poo-flow-user-loop-engine-intent-status
        poo-flow-user-loop-engine-intent-operation-kind
        poo-flow-user-loop-engine-intent-result-contract
        poo-flow-user-loop-engine-result-contract-valid?
        poo-flow-user-loop-engine-result-contract-diagnostics
        poo-flow-user-loop-engine-intent-role-result-contract
        poo-flow-user-loop-engine-intent-operation-result-contract
        poo-flow-user-loop-engine-intent-agent-profiles
        poo-flow-user-loop-engine-intent-agent-harnesses
        poo-flow-user-loop-engine-intent-agent-sessions
        poo-flow-user-loop-engine-intent-session-agent-graph
        poo-flow-user-loop-engine-intent-agent-operation
        poo-flow-user-loop-engine-intent-delegated-operation
        poo-flow-user-loop-engine-intent-dispatch-receipt
        poo-flow-user-loop-engine-intent-runtime-command-manifest
        poo-flow-user-loop-engine-intent-runtime-command-manifest-summary
        poo-flow-user-loop-engine-intent-workflow-agreement
        poo-flow-user-loop-engine-intent-runtime-envelope
        poo-flow-user-loop-engine-intent-runtime-handoff-facts
        poo-flow-user-loop-engine-intent-sandbox-handoff-agreement
        poo-flow-user-loop-engine-intent-runtime-snapshot
        poo-flow-user-loop-engine-capability-receipt-ref
        poo-flow-user-loop-engine-capability-receipt->alist
        poo-flow-user-loop-engine-intent-workflow-run
        poo-flow-user-loop-engine-intents-field-values
        poo-flow-user-config-loop-engine-intents
        poo-flow-user-loop-engine-intent-runtime-intent
        poo-flow-user-loop-engine-intent-policy
        poo-flow-user-loop-engine-intent-runtime-projections
        poo-flow-user-config-loop-engine-intents/add)

;;; Capability receipts are generated runtime state, not user-authored POO
;;; declarations. Keep the hot construction path as a fixed Gerbil struct and
;;; project to alists only at manifest, snapshot, test-summary, and Marlin
;;; handoff boundaries.
(defstruct loop-engine-capability-receipt
  (backend
   backend-kind
   backend-capabilities
   supported-backends
   valid?
   diagnostics
   isolation
   required
   optional
   unsupported-behavior
   sandbox-ref
   session-ref)
  transparent: #t)

;; : (-> LoopEngineCapabilityReceipt Integer)
(def (loop-engine-capability-receipt-diagnostic-count receipt)
  (length (loop-engine-capability-receipt-diagnostics receipt)))

;;; Runtime envelopes are the largest loop-engine handoff object. They carry
;;; workflow, sandbox, and operation facts as inert request data for Marlin.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-runtime-envelope intent)
  (let ((use-case-name
         (poo-flow-user-loop-engine-intent-use-case-name intent)))
    (list
     (cons 'schema +runtime-request-schema+)
     (cons 'runtime 'manifest)
     (cons 'operation 'loop-engine-handoff)
     (cons 'request-id
           (poo-flow-user-loop-engine-runtime-id use-case-name "request"))
     (cons 'artifact-handle
           (poo-flow-user-loop-engine-runtime-id use-case-name "artifact"))
     (cons 'request
           (list
            (cons 'kind 'loop-engine-runtime-handoff-request)
            (cons 'contract
                  +poo-flow-user-loop-engine-runtime-command-contract+)
            (cons 'runtime-owner "marlin-agent-core")
            (cons 'object-families
                  +poo-flow-user-loop-engine-runtime-object-families+)
            (cons 'receipt-contracts
                  +poo-flow-user-loop-engine-receipt-contracts+)
            (cons 'use-case
                  (poo-flow-user-loop-engine-intent-ref intent 'use-case '()))
            (cons 'use-cases
                  (poo-flow-user-loop-engine-intent-ref intent 'use-cases '()))
            (cons 'workflow-agreement
                  (poo-flow-user-loop-engine-intent-workflow-agreement
                   intent))
            (cons 'result-contract
                  (poo-flow-user-loop-engine-intent-result-contract intent))
            (cons 'agent-profiles
                  (poo-flow-user-loop-engine-intent-agent-profiles intent))
            (cons 'agent-harnesses
                  (poo-flow-user-loop-engine-intent-agent-harnesses intent))
            (cons 'agent-sessions
                  (poo-flow-user-loop-engine-intent-agent-sessions intent))
            (cons 'session-agent-graph
                  (poo-flow-user-loop-engine-intent-session-agent-graph
                   intent))
            (cons 'workflow-run
                  (poo-flow-user-loop-engine-intent-workflow-run intent))
            (cons 'dispatch-receipt
                  (poo-flow-user-loop-engine-intent-dispatch-receipt intent))
            (cons 'agent-operation
                  (poo-flow-user-loop-engine-intent-agent-operation intent))
            (cons 'delegated-operation
                  (poo-flow-user-loop-engine-intent-delegated-operation
                   intent))
            (cons 'lineage-receipt
                  (poo-flow-user-loop-engine-intent-lineage-receipt
                   intent))
            (cons 'selector-receipt
                  (poo-flow-user-loop-engine-intent-selector-receipt
                   intent))
            (cons 'resource-dispatch-receipt
                  (poo-flow-user-loop-engine-intent-resource-dispatch-receipt
                   intent))
            (cons 'capability-receipt
                  (poo-flow-user-loop-engine-capability-receipt->alist
                   (poo-flow-user-loop-engine-intent-capability-receipt
                    intent)))
            (cons 'memory-receipt
                  (poo-flow-user-loop-engine-intent-memory-receipt intent))
            (cons 'compression-receipt
                  (poo-flow-user-loop-engine-intent-compression-receipt
                   intent))
            (cons 'session-selector-receipts
                  (poo-flow-user-loop-engine-intent-ref
                   intent
                   'session-selector-receipts
                   '()))
            (cons 'session-materialization-receipts
                  (poo-flow-user-loop-engine-intent-ref
                   intent
                   'session-materialization-receipts
                   '()))
            (cons 'policy-extension-receipts
                  (poo-flow-user-loop-engine-intent-ref
                   intent
                   'policy-extension-receipts
                   '()))
            (cons 'runtime-snapshot
                  (poo-flow-user-loop-engine-intent-runtime-snapshot intent))
            (cons 'sandbox-profile-refs
                  (poo-flow-user-loop-engine-intent-ref
                   intent
                   'sandbox-profile-refs
                   '()))
            (cons 'sandbox-runtime-summaries
                  (poo-flow-user-loop-engine-intent-ref
                   intent
                   'sandbox-runtime-summaries
                   '()))
            (cons 'sandbox-handoff-summaries
                  (poo-flow-user-loop-engine-intent-ref
                   intent
                   'sandbox-handoff-summaries
                   '()))
            (cons 'sandbox-handoff-agreement
                  (poo-flow-user-loop-engine-intent-sandbox-handoff-agreement
                   intent))
            (cons 'sandbox-unresolved-profile-refs
                  (poo-flow-user-loop-engine-intent-ref
                   intent
                   'sandbox-unresolved-profile-refs
                   '()))
            (cons 'runtime-executed #f)))
     (cons 'policy
           (poo-flow-user-loop-engine-intent-policy intent))
     (cons 'plan-id
           (poo-flow-user-loop-engine-runtime-id use-case-name "plan"))
     (cons 'node-id
           (poo-flow-user-loop-engine-runtime-id use-case-name "node"))
     (cons 'frontier
           (poo-flow-user-loop-engine-intent-ref intent 'agent-judges '())))))

;;; The command manifest is inert stdout adapter data; it serializes the whole
;;; loop-engine envelope without launching Marlin from Scheme.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-runtime-command-manifest intent)
  (runtime-command-descriptor->manifest
   (make-stdout-runtime-command-descriptor
    +poo-flow-user-loop-engine-runtime-command-name+
    +poo-flow-user-loop-engine-runtime-command-executable+
    +poo-flow-user-loop-engine-runtime-command-arguments+
    (list
     (cons 'source 'user-config-loop-engine)
     (cons 'contract
           +poo-flow-user-loop-engine-runtime-command-contract+)
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'object-families
           +poo-flow-user-loop-engine-runtime-object-families+)
     (cons 'runtime-executed #f)))
   (poo-flow-user-loop-engine-intent-runtime-envelope intent)))

;;; Summaries keep presentation tables small while retaining the descriptor ids
;;; that let agents correlate the full manifest when needed.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-runtime-command-manifest-summary intent)
  (let ((manifest
         (poo-flow-user-loop-engine-intent-runtime-command-manifest intent)))
    (list
     (cons 'kind 'runtime-command-manifest-summary)
     (cons 'contract +poo-flow-user-loop-engine-runtime-command-contract+)
     (cons 'schema
           (poo-flow-user-loop-engine-intent-ref manifest 'schema #f))
     (cons 'request-schema
           (poo-flow-user-loop-engine-intent-ref manifest 'request-schema #f))
     (cons 'operation
           (poo-flow-user-loop-engine-intent-ref manifest 'operation #f))
     (cons 'request-id
           (poo-flow-user-loop-engine-intent-ref manifest 'request-id #f))
     (cons 'artifact-handle
           (poo-flow-user-loop-engine-intent-ref manifest 'artifact-handle #f))
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'object-families
           +poo-flow-user-loop-engine-runtime-object-families+)
     (cons 'receipt-contracts
           +poo-flow-user-loop-engine-receipt-contracts+)
     (cons 'argv
           (poo-flow-user-loop-engine-intent-ref manifest 'argv '()))
     (cons 'runtime-executed #f))))

;;; Runtime snapshots expose the sandbox agreement as the handoff readiness
;;; source of truth. This prevents a loop from looking ready when a sandbox
;;; profile is unresolved or only available as an invalid runtime summary.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-runtime-snapshot intent)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (workflow-ref
          (poo-flow-user-loop-engine-intent-workflow-ref intent))
         (workflow-agreement
          (poo-flow-user-loop-engine-intent-workflow-agreement intent))
         (lineage-receipt
          (poo-flow-user-loop-engine-intent-lineage-receipt intent))
         (selector-receipt
          (poo-flow-user-loop-engine-intent-selector-receipt intent))
         (resource-dispatch-receipt
         (poo-flow-user-loop-engine-intent-resource-dispatch-receipt
          intent))
         (capability-receipt
          (poo-flow-user-loop-engine-capability-receipt->alist
           (poo-flow-user-loop-engine-intent-capability-receipt intent)))
         (memory-receipt
         (poo-flow-user-loop-engine-intent-memory-receipt intent))
         (compression-receipt
          (poo-flow-user-loop-engine-intent-compression-receipt intent))
         (sandbox-agreement
          (poo-flow-user-loop-engine-intent-sandbox-handoff-agreement
           intent))
         (handoff-ready?
          (and
           (poo-flow-user-loop-engine-intent-ref
            sandbox-agreement
            'handoff-ready?
            #f)
           (poo-flow-user-loop-engine-intent-ref
            workflow-agreement
            'valid?
            #f)))
         (handoff-summary
          (list (cons 'workflow-ref workflow-ref)
                (cons 'handoff-ready? handoff-ready?)
                (cons 'workflow-agreement workflow-agreement)
                (cons 'lineage-receipt lineage-receipt)
                (cons 'selector-receipt selector-receipt)
                (cons 'resource-dispatch-receipt resource-dispatch-receipt)
                (cons 'capability-receipt capability-receipt)
                (cons 'memory-receipt memory-receipt)
                (cons 'compression-receipt compression-receipt)
                (cons 'sandbox-handoff-agreement sandbox-agreement)
                (cons 'runtime-executed #f))))
    (poo-flow-runtime-snapshot->alist
     (make-poo-flow-runtime-snapshot
      'loop-engine
      use-case-name
      (poo-flow-user-loop-engine-intent-status intent)
      #f
      handoff-summary
      #f
      '((stage . user-config-loop-engine-runtime-snapshot)
        (runtime-executed . #f))
      (append
       handoff-summary
       (list (cons 'contract 'poo-flow.loop-governor.v1)
             (cons 'runtime-owner "marlin-agent-core")))))))

;;; Lineage receipts are OpenRath-inspired session facts. They make parent
;;; session refs and lineage export intent visible before Marlin runs anything.
;; : (-> Alist Alist)
(defpoo-runtime-receipt-projection
  poo-flow-user-loop-engine-intent-lineage-receipt
  (intent)
  (bindings
   ((use-case-name
     (poo-flow-user-loop-engine-intent-use-case-name intent))
    (lineage-policy
     (poo-flow-user-loop-engine-intent-ref intent 'lineage-policy '()))))
  (fields
   (('kind 'lineage-receipt)
    ('contract 'poo-flow.loop-engine.lineage-receipt.v1)
    ('session-ref
     (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
    ('parent-session-refs
     (poo-flow-user-loop-engine-intent-ref
      lineage-policy
      'parent-session-refs
      '()))
    ('lineage-kind
     (poo-flow-user-loop-engine-intent-ref
      lineage-policy
      'lineage-kind
      'loop-root))
    ('lineage-operator
     (poo-flow-user-loop-engine-intent-ref
      lineage-policy
      'lineage-operator
      'loop-engine-profile))
    ('journal
     (poo-flow-user-loop-engine-intent-ref
      lineage-policy
      'journal
      'report-only))
    ('export
     (poo-flow-user-loop-engine-intent-ref lineage-policy 'export 'jsonl))
    ('policy lineage-policy)
    ('runtime-owner "marlin-agent-core")
    ('runtime-executed #f))))

;;; Selector receipts keep branch choice report-only. Candidate scoring and
;;; routing remain runtime work for Marlin or a model-backed executor.
;; : (-> Alist Alist)
(defpoo-runtime-receipt-projection
  poo-flow-user-loop-engine-intent-selector-receipt
  (intent)
  (bindings
   ((use-case-name
     (poo-flow-user-loop-engine-intent-use-case-name intent))
    (selector-policy
     (poo-flow-user-loop-engine-intent-ref intent 'selector-policy '()))
    (selected-branch
     (poo-flow-user-loop-engine-intent-ref
      selector-policy
      'selected-branch
      #f))))
  (fields
   (('kind 'selector-receipt)
    ('contract 'poo-flow.loop-engine.selector-receipt.v1)
    ('session-ref
     (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
    ('candidates
     (poo-flow-user-loop-engine-intent-ref
      selector-policy
      'candidates
      (poo-flow-user-loop-engine-use-case-names intent)))
    ('judge-inputs
     (poo-flow-user-loop-engine-intent-ref
      selector-policy
      'judge-inputs
      '()))
    ('fallback
     (poo-flow-user-loop-engine-intent-ref selector-policy 'fallback #f))
    ('selected-branch
     (if selected-branch selected-branch use-case-name))
    ('policy selector-policy)
    ('runtime-owner "marlin-agent-core")
    ('runtime-executed #f))))

;;; Resource dispatch receipts project OpenRath-style resource-key collision
;;; facts. They do not schedule or run tool calls in Scheme.
;; : (-> Alist Alist)
(defpoo-runtime-receipt-projection
  poo-flow-user-loop-engine-intent-resource-dispatch-receipt
  (intent)
  (bindings
   ((use-case-name
     (poo-flow-user-loop-engine-intent-use-case-name intent))
    (resource-policy
     (poo-flow-user-loop-engine-intent-ref intent 'resource-policy '()))))
  (fields
   (('kind 'resource-dispatch-receipt)
    ('contract 'poo-flow.loop-engine.resource-dispatch-receipt.v1)
    ('dispatch-ref
     (poo-flow-user-loop-engine-runtime-id use-case-name "dispatch"))
    ('tool-refs
     (poo-flow-user-loop-engine-intent-ref resource-policy 'tool-refs '()))
    ('resource-keys
     (poo-flow-user-loop-engine-intent-ref
      resource-policy
      'resource-keys
      '()))
    ('collision-classes
     (poo-flow-user-loop-engine-intent-ref
      resource-policy
      'collision-classes
      '()))
    ('dispatch-groups
     (poo-flow-user-loop-engine-intent-ref
      resource-policy
      'dispatch-groups
      '()))
    ('policy resource-policy)
    ('runtime-owner "marlin-agent-core")
    ('runtime-executed #f))))

;;; Capability receipts are OpenRath-inspired backend expectation facts. They
;;; read the static module-system capability registry and never probe, open, or
;;; validate a live backend.
;; : (-> Pair Symbol)
(def (poo-flow-user-loop-engine-capability-entry-backend entry)
  (if (and (pair? entry)
           (poo-flow-sandbox-backend-capability? (cdr entry)))
    (poo-flow-sandbox-backend-capability/backend-kind (cdr entry))
    (and (pair? entry) (car entry))))

;; : (-> [Pair] [Symbol] [Symbol])
(def (poo-flow-user-loop-engine-capability-supported-backends/add entries
                                                                   result)
  (cond
   ((null? entries) (reverse result))
   ((poo-flow-user-loop-engine-capability-entry-backend (car entries))
    => (lambda (backend)
         (poo-flow-user-loop-engine-capability-supported-backends/add
          (cdr entries)
          (cons backend result))))
   (else
    (poo-flow-user-loop-engine-capability-supported-backends/add
     (cdr entries)
     result))))

;; : (-> PooSandboxBackendCapabilityRegistry [Symbol])
(def (poo-flow-user-loop-engine-capability-supported-backends registry)
  (poo-flow-user-loop-engine-capability-supported-backends/add
   (poo-flow-sandbox-backend-capability-registry-entries registry)
   '()))

;; : (-> PooSandboxBackendCapabilityRegistry Symbol MaybePooSandboxBackendCapability)
(def (poo-flow-user-loop-engine-capability-registry-capability registry backend)
  (let (entry (assoc backend
                     (poo-flow-sandbox-backend-capability-registry-entries
                      registry)))
    (and entry (cdr entry))))

;;; Diagnostics are payload rows for users and ABI consumers. An empty result
;;; means the policy vocabulary is valid, not that a backend probe succeeded.
;; : (-> Symbol PooSandboxBackendCapabilityRegistry [Alist])
(def (poo-flow-user-loop-engine-capability-diagnostics backend registry)
  (if (or (not backend)
          (poo-flow-user-loop-engine-capability-registry-capability
           registry
           backend))
    '()
    (list
     (list
      (cons 'field 'backend)
      (cons 'code 'unsupported-capability-backend)
      (cons 'value backend)
      (cons 'supported
            (poo-flow-user-loop-engine-capability-supported-backends
             registry))))))

;;; Generated capability receipts use fixed struct access internally and only
;;; serialize once at manifest, snapshot, or Marlin handoff boundaries.
;; : (-> LoopEngineCapabilityReceipt Symbol Value Value)
(def (poo-flow-user-loop-engine-capability-receipt-ref receipt
                                                       slot
                                                       default-value)
  (if (loop-engine-capability-receipt? receipt)
    (case slot
      ((kind) 'capability-receipt)
      ((contract) 'poo-flow.loop-engine.capability-receipt.v1)
      ((backend)
       (loop-engine-capability-receipt-backend receipt))
      ((backend-kind)
       (loop-engine-capability-receipt-backend-kind receipt))
      ((backend-capabilities)
       (loop-engine-capability-receipt-backend-capabilities receipt))
      ((supported-backends)
       (loop-engine-capability-receipt-supported-backends receipt))
      ((valid?)
       (loop-engine-capability-receipt-valid? receipt))
      ((diagnostic-count)
       (loop-engine-capability-receipt-diagnostic-count receipt))
      ((diagnostics)
       (loop-engine-capability-receipt-diagnostics receipt))
      ((isolation)
       (loop-engine-capability-receipt-isolation receipt))
      ((required)
       (loop-engine-capability-receipt-required receipt))
      ((optional)
       (loop-engine-capability-receipt-optional receipt))
      ((unsupported-behavior)
       (loop-engine-capability-receipt-unsupported-behavior receipt))
      ((sandbox-ref)
       (loop-engine-capability-receipt-sandbox-ref receipt))
      ((session-ref)
       (loop-engine-capability-receipt-session-ref receipt))
      ((runtime-owner) "marlin-agent-core")
      ((runtime-executed) #f)
      (else default-value))
    default-value))

;; : (-> LoopEngineCapabilityReceipt Alist)
(defpoo-runtime-receipt-projection
  loop-engine-capability-receipt->alist
  (receipt)
  (bindings ())
  (fields
   (('kind 'capability-receipt)
    ('contract 'poo-flow.loop-engine.capability-receipt.v1)
    ('backend (loop-engine-capability-receipt-backend receipt))
    ('backend-kind (loop-engine-capability-receipt-backend-kind receipt))
    ('backend-capabilities
     (loop-engine-capability-receipt-backend-capabilities receipt))
    ('supported-backends
     (loop-engine-capability-receipt-supported-backends receipt))
    ('valid? (loop-engine-capability-receipt-valid? receipt))
    ('diagnostic-count
     (loop-engine-capability-receipt-diagnostic-count receipt))
    ('diagnostics (loop-engine-capability-receipt-diagnostics receipt))
    ('isolation (loop-engine-capability-receipt-isolation receipt))
    ('required (loop-engine-capability-receipt-required receipt))
    ('optional (loop-engine-capability-receipt-optional receipt))
    ('unsupported-behavior
     (loop-engine-capability-receipt-unsupported-behavior receipt))
    ('sandbox-ref (loop-engine-capability-receipt-sandbox-ref receipt))
    ('session-ref (loop-engine-capability-receipt-session-ref receipt))
    ('runtime-owner "marlin-agent-core")
    ('runtime-executed #f))))

;; : (-> Value Alist)
(def (poo-flow-user-loop-engine-capability-receipt->alist receipt)
  (if (loop-engine-capability-receipt? receipt)
    (loop-engine-capability-receipt->alist receipt)
    (error "loop-engine capability receipt must be a generated struct"
           receipt)))

;;; Capability receipt is fixed generated Scheme state inside the control
;;; plane. Runtime ABI boundaries serialize it explicitly when handing data to
;;; Marlin or writing bounded summaries.
;; : (-> Alist LoopEngineCapabilityReceipt)
(def (poo-flow-user-loop-engine-intent-capability-receipt intent
                                                          .
                                                          maybe-registry)
  (if (and (null? maybe-registry) (assoc 'capability-receipt intent))
    (cdr (assoc 'capability-receipt intent))
    (let* ((use-case-name
            (poo-flow-user-loop-engine-intent-use-case-name intent))
           (capability-policy
            (poo-flow-user-loop-engine-intent-ref intent
                                                  'capability-policy
                                                  '()))
           (registry
            (if (null? maybe-registry)
              (poo-flow-user-config-sandbox-backend-capability-registry '())
              (car maybe-registry)))
           (backend
            (poo-flow-user-loop-engine-intent-ref
             capability-policy
             'backend
             #f))
           (backend-capability
            (and backend
                 (poo-flow-user-loop-engine-capability-registry-capability
                  registry
                  backend)))
           (diagnostics
            (poo-flow-user-loop-engine-capability-diagnostics backend
                                                              registry)))
      (let* ((backend-kind
              (and backend-capability
                   (poo-flow-sandbox-backend-capability/backend-kind
                    backend-capability)))
             (backend-capabilities
              (if backend-capability
                (poo-flow-sandbox-backend-capability/capabilities
                 backend-capability)
                '()))
             (supported-backends
              (poo-flow-user-loop-engine-capability-supported-backends
               registry))
             (isolation
              (poo-flow-user-loop-engine-intent-ref capability-policy
                                                    'isolation
                                                    #f))
             (required
              (poo-flow-user-loop-engine-intent-ref capability-policy
                                                    'required
                                                    '()))
             (optional
              (poo-flow-user-loop-engine-intent-ref capability-policy
                                                    'optional
                                                    '()))
             (unsupported-behavior
              (poo-flow-user-loop-engine-intent-ref capability-policy
                                                    'unsupported-behavior
                                                    'handoff-diagnostic))
             (sandbox-ref
              (poo-flow-user-loop-engine-intent-primary-sandbox-profile
               intent))
             (session-ref
              (poo-flow-user-loop-engine-runtime-id use-case-name
                                                   "session")))
        (make-loop-engine-capability-receipt
         backend
         backend-kind
         backend-capabilities
         supported-backends
         (null? diagnostics)
         diagnostics
         isolation
         required
         optional
         unsupported-behavior
         sandbox-ref
         session-ref)))))

;;; Memory receipts declare recall and commit policy without reading, ranking,
;;; writing, or retaining memory in Scheme. Marlin owns the memory store.
;; : (-> [Alist] Symbol Alist)
(def (poo-flow-user-loop-engine-memory-policy-for-use-case
      memory-policies
      use-case-name)
  (cond
   ((null? memory-policies) '())
   ((and (pair? memory-policies)
         (equal? (poo-flow-user-loop-engine-intent-ref
                  (car memory-policies)
                  'use-case
                  #f)
                 use-case-name))
    (car memory-policies))
   ((pair? memory-policies)
    (poo-flow-user-loop-engine-memory-policy-for-use-case
     (cdr memory-policies)
     use-case-name))
   (else '())))

;;; Memory receipt binds the selected use-case to one declared policy and leaves
;;; recall, commit, retention, and store mutation to the Marlin execution layer.
;; : (-> Alist Alist)
(defpoo-runtime-receipt-projection
  poo-flow-user-loop-engine-intent-memory-receipt
  (intent)
  (bindings
   ((use-case-name
     (poo-flow-user-loop-engine-intent-use-case-name intent))
    (memory-policies
     (poo-flow-user-loop-engine-intent-ref intent 'memory-policies '()))
    (memory-policy
     (poo-flow-user-loop-engine-memory-policy-for-use-case
      memory-policies
      use-case-name))))
  (fields
   (('kind 'memory-receipt)
    ('contract 'poo-flow.loop-engine.memory-receipt.v1)
    ('selected-use-case use-case-name)
    ('policy-count (length memory-policies))
    ('available-use-cases
     (map (lambda (policy)
            (poo-flow-user-loop-engine-intent-ref policy 'use-case #f))
          memory-policies))
    ('selected-policy-found? (not (null? memory-policy)))
    ('use-case
     (poo-flow-user-loop-engine-intent-ref memory-policy 'use-case #f))
    ('store
     (poo-flow-user-loop-engine-intent-ref memory-policy 'store #f))
    ('state-path
     (poo-flow-user-loop-engine-intent-ref memory-policy 'state-path #f))
    ('scope
     (poo-flow-user-loop-engine-intent-ref memory-policy 'scope #f))
    ('recall
     (poo-flow-user-loop-engine-intent-ref memory-policy 'recall '()))
    ('commit
     (poo-flow-user-loop-engine-intent-ref memory-policy 'commit '()))
    ('ranking
     (poo-flow-user-loop-engine-intent-ref memory-policy 'ranking #f))
    ('retention
     (poo-flow-user-loop-engine-intent-ref
      memory-policy
      'retention
      'report-only))
    ('policy memory-policy)
    ('policies memory-policies)
    ('session-ref
     (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
    ('runtime-owner "marlin-agent-core")
    ('runtime-executed #f))))

;;; Compression receipts describe the handoff shape for transcript/session
;;; compaction. Scheme never summarizes, mutates, or creates sessions here.
;; : (-> Alist Alist)
(defpoo-runtime-receipt-projection
  poo-flow-user-loop-engine-intent-compression-receipt
  (intent)
  (bindings
   ((use-case-name
     (poo-flow-user-loop-engine-intent-use-case-name intent))
    (compression-policy
     (poo-flow-user-loop-engine-intent-ref
      intent
      'compression-policy
      '()))))
  (fields
   (('kind 'compression-receipt)
    ('contract 'poo-flow.loop-engine.compression-receipt.v1)
    ('strategy
     (poo-flow-user-loop-engine-intent-ref compression-policy 'strategy #f))
    ('trigger
     (poo-flow-user-loop-engine-intent-ref compression-policy 'trigger #f))
    ('summary-format
     (poo-flow-user-loop-engine-intent-ref
      compression-policy
      'summary-format
      #f))
    ('lineage-kind
     (poo-flow-user-loop-engine-intent-ref
      compression-policy
      'lineage-kind
      'compressed-session))
    ('retention
     (poo-flow-user-loop-engine-intent-ref
      compression-policy
      'retention
      'report-only))
    ('policy compression-policy)
    ('source-session-ref
     (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
    ('compressed-session-ref
     (poo-flow-user-loop-engine-runtime-id
      use-case-name
      "compressed-session"))
    ('runtime-owner "marlin-agent-core")
    ('runtime-executed #f))))

;;; Handoff facts are the single report row tying loop-engine policy,
;;; workflow-run projections, sandbox evidence, and runtime command manifests.
;; : (-> Alist Alist)
(defpoo-runtime-receipt-projection
  poo-flow-user-loop-engine-intent-runtime-handoff-facts
  (intent)
  (bindings
   ((runtime-handoff
     (poo-flow-user-loop-engine-intent-ref
      intent
      'runtime-handoff
      'loop-governor-marlin-runtime-manifest))
    (capability-receipt
     (poo-flow-user-loop-engine-capability-receipt->alist
      (poo-flow-user-loop-engine-intent-capability-receipt intent)))))
  (fields
   (('kind 'loop-engine-runtime-handoff)
    ('contract 'poo-flow.loop-governor.runtime-handoff.v1)
    ('runtime-owner "marlin-agent-core")
    ('runtime-handoff runtime-handoff)
    ('handoff-contracts +poo-flow-user-loop-engine-handoff-contracts+)
    ('runtime-command-contract
     +poo-flow-user-loop-engine-runtime-command-contract+)
    ('object-families
     +poo-flow-user-loop-engine-runtime-object-families+)
    ('receipt-contracts
     +poo-flow-user-loop-engine-receipt-contracts+)
    ('workflow-ref
     (poo-flow-user-loop-engine-intent-workflow-ref intent))
    ('workflow-agreement
     (poo-flow-user-loop-engine-intent-workflow-agreement intent))
    ('result-contract
     (poo-flow-user-loop-engine-intent-result-contract intent))
    ('agent-profiles
     (poo-flow-user-loop-engine-intent-agent-profiles intent))
    ('agent-harnesses
     (poo-flow-user-loop-engine-intent-agent-harnesses intent))
    ('agent-sessions
     (poo-flow-user-loop-engine-intent-agent-sessions intent))
    ('session-agent-graph
     (poo-flow-user-loop-engine-intent-session-agent-graph intent))
    ('lineage-receipt
     (poo-flow-user-loop-engine-intent-lineage-receipt intent))
    ('selector-receipt
     (poo-flow-user-loop-engine-intent-selector-receipt intent))
    ('resource-dispatch-receipt
     (poo-flow-user-loop-engine-intent-resource-dispatch-receipt
      intent))
    ('capability-receipt capability-receipt)
    ('memory-receipt
     (poo-flow-user-loop-engine-intent-memory-receipt intent))
    ('compression-receipt
     (poo-flow-user-loop-engine-intent-compression-receipt intent))
    ('session-selector-receipts
     (poo-flow-user-loop-engine-intent-ref
      intent
      'session-selector-receipts
      '()))
    ('session-materialization-receipts
     (poo-flow-user-loop-engine-intent-ref
      intent
      'session-materialization-receipts
      '()))
    ('policy-extension-receipts
     (poo-flow-user-loop-engine-intent-ref
      intent
      'policy-extension-receipts
      '()))
    ('runtime-command-manifest
     (poo-flow-user-loop-engine-intent-runtime-command-manifest intent))
    ('runtime-command-manifest-summary
     (poo-flow-user-loop-engine-intent-runtime-command-manifest-summary
      intent))
    ('sandbox
     (poo-flow-user-loop-engine-intent-ref intent 'sandbox '()))
    ('sandbox-profile-refs
     (poo-flow-user-loop-engine-intent-ref
      intent
      'sandbox-profile-refs
      '()))
    ('sandbox-runtime-summaries
     (poo-flow-user-loop-engine-intent-ref
      intent
      'sandbox-runtime-summaries
      '()))
    ('sandbox-handoff-summaries
     (poo-flow-user-loop-engine-intent-ref
      intent
      'sandbox-handoff-summaries
      '()))
    ('sandbox-handoff-agreement
     (poo-flow-user-loop-engine-intent-sandbox-handoff-agreement
      intent))
    ('sandbox-unresolved-profile-refs
     (poo-flow-user-loop-engine-intent-ref
      intent
      'sandbox-unresolved-profile-refs
      '()))
    ('lineage-policy
     (poo-flow-user-loop-engine-intent-ref intent 'lineage-policy '()))
    ('selector-policy
     (poo-flow-user-loop-engine-intent-ref intent 'selector-policy '()))
    ('resource-policy
     (poo-flow-user-loop-engine-intent-ref intent 'resource-policy '()))
    ('capability-policy
     (poo-flow-user-loop-engine-intent-ref
      intent
      'capability-policy
      '()))
    ('memory-policies
     (poo-flow-user-loop-engine-intent-ref
      intent
      'memory-policies
      '()))
    ('compression-policy
     (poo-flow-user-loop-engine-intent-ref
      intent
      'compression-policy
      '()))
    ('runtime
     (poo-flow-user-loop-engine-intent-ref intent 'runtime '()))
    ('descriptor-realized? #f)
    ('runtime-executed #f))))

;;; Runtime projections are the bundled receipt surface for one loop intent.
;;; Keeping these rows together prevents presentation code from recomputing
;;; workflow, dispatch, operation, manifest, and snapshot facts independently.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-runtime-projections intent)
  (list
   (cons 'runtime-handoff-contracts
         +poo-flow-user-loop-engine-handoff-contracts+)
   (cons 'receipt-contracts
         +poo-flow-user-loop-engine-receipt-contracts+)
   (cons 'runtime-handoff-facts
         (poo-flow-user-loop-engine-intent-runtime-handoff-facts intent))
   (cons 'workflow-agreement
         (poo-flow-user-loop-engine-intent-workflow-agreement intent))
   (cons 'result-contract
         (poo-flow-user-loop-engine-intent-result-contract intent))
   (cons 'agent-profiles
         (poo-flow-user-loop-engine-intent-agent-profiles intent))
   (cons 'agent-harnesses
         (poo-flow-user-loop-engine-intent-agent-harnesses intent))
   (cons 'agent-sessions
         (poo-flow-user-loop-engine-intent-agent-sessions intent))
   (cons 'session-agent-graph
         (poo-flow-user-loop-engine-intent-session-agent-graph intent))
   (cons 'workflow-run
         (poo-flow-user-loop-engine-intent-workflow-run intent))
   (cons 'dispatch-receipt
         (poo-flow-user-loop-engine-intent-dispatch-receipt intent))
   (cons 'agent-operation
         (poo-flow-user-loop-engine-intent-agent-operation intent))
   (cons 'delegated-operation
         (poo-flow-user-loop-engine-intent-delegated-operation intent))
   (cons 'lineage-receipt
         (poo-flow-user-loop-engine-intent-lineage-receipt intent))
   (cons 'selector-receipt
         (poo-flow-user-loop-engine-intent-selector-receipt intent))
   (cons 'resource-dispatch-receipt
         (poo-flow-user-loop-engine-intent-resource-dispatch-receipt
          intent))
   (cons 'capability-receipt
         (poo-flow-user-loop-engine-intent-capability-receipt intent))
   (cons 'memory-receipt
         (poo-flow-user-loop-engine-intent-memory-receipt intent))
   (cons 'compression-receipt
         (poo-flow-user-loop-engine-intent-compression-receipt intent))
   (cons 'session-selector-receipts
         (poo-flow-user-loop-engine-intent-ref
          intent
          'session-selector-receipts
          '()))
   (cons 'session-materialization-receipts
         (poo-flow-user-loop-engine-intent-ref
          intent
          'session-materialization-receipts
          '()))
   (cons 'policy-extension-receipts
         (poo-flow-user-loop-engine-intent-ref
          intent
          'policy-extension-receipts
          '()))
   (cons 'runtime-command-manifest
         (poo-flow-user-loop-engine-intent-runtime-command-manifest intent))
   (cons 'runtime-command-manifest-summary
         (poo-flow-user-loop-engine-intent-runtime-command-manifest-summary
          intent))
   (cons 'sandbox-runtime-summaries
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-runtime-summaries
          '()))
   (cons 'sandbox-handoff-summaries
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-handoff-summaries
          '()))
   (cons 'sandbox-handoff-agreement
         (poo-flow-user-loop-engine-intent-sandbox-handoff-agreement
          intent))
   (cons 'sandbox-unresolved-profile-refs
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-unresolved-profile-refs
          '()))
   (cons 'runtime-snapshot
         (poo-flow-user-loop-engine-intent-runtime-snapshot intent))))

;;; Presentation modules use this extractor to expose repeated loop-engine
;;; slots without learning the shape of each runtime projection row.
;; : (-> [Alist] Symbol [Value])
(def (poo-flow-user-loop-engine-intents-field-values intents field)
  (cond
   ((null? intents) '())
   (else
    (cons
     (poo-flow-user-loop-engine-intent-ref (car intents) field #f)
     (poo-flow-user-loop-engine-intents-field-values (cdr intents) field)))))

;;; Loop-engine intents are the workflow-facing surface for configuring the
;;; governor node graph from init.ss. The result is report-only contract data.
;; : (-> PooUserModuleSelection Boolean)
(def (poo-flow-user-module-selection-loop-engine? selection)
  (equal? (poo-flow-user-module-selection-key selection)
          '(flow . loop-engine)))

;;; Boundary: user loop engine context profile catalog is the policy-visible
;;; edge for module-system, loop behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> [Value] [PooSandboxProfile])
(def (poo-flow-user-loop-engine-context-profile-catalog context)
  (if (null? context)
    poo-flow-default-sandbox-profiles
    (car context)))

;;; Boundary: user loop engine context workflow check maps is the policy-
;;; visible edge for module-system, loop behavior, keeping validation, lookup,
;;; or projection responsibilities centralized for callers.
;; : (-> [Value] [PooFlowCicdCheckMap])
(def (poo-flow-user-loop-engine-context-workflow-check-maps context)
  (if (or (null? context) (null? (cdr context)))
    '()
    (cadr context)))

;;; Boundary: user loop engine context backend capability registry is the
;;; static OpenRath-style capability vocabulary selected by enabled modules.
;; : (-> [Value] PooSandboxBackendCapabilityRegistry)
(def (poo-flow-user-loop-engine-context-backend-capability-registry context)
  (if (or (null? context) (null? (cdr context)) (null? (cddr context)))
    (poo-flow-user-config-sandbox-backend-capability-registry '())
    (caddr context)))

;; : (-> PooUserModuleSelection Alist Alist)
(def (poo-flow-user-loop-engine-base-intent selection poo-intent-fields)
  (append
   (list (cons 'key
               (poo-flow-user-module-selection-key selection))
         (cons 'feature '+loop-engine)
         (cons 'workflow-owned? #t)
         (cons 'governor-derived? #t))
   poo-intent-fields
   (list
    (cons 'contract 'poo-flow.loop-governor.v1)
    (cons 'node-contract 'poo-flow.loop-governor.node.v1)
    (cons 'descriptor-realized? #f)
    (cons 'runtime-executed #f))))

;; : (-> Alist [PooSandboxProfile] [PooFlowCicdCheckMap] PooSandboxBackendCapabilityRegistry Alist)
(def (poo-flow-user-loop-engine-enriched-intent base-intent
                                                profile-catalog
                                                workflow-check-maps
                                                backend-capability-registry)
  (let* ((sandbox-profile-refs
          (poo-flow-user-loop-engine-sandbox-profile-refs base-intent))
         (sandbox-runtime-summaries
          (poo-flow-user-loop-engine-sandbox-runtime-summaries
           sandbox-profile-refs
           profile-catalog))
         (sandbox-handoff-summaries
          (poo-flow-user-loop-engine-sandbox-handoff-summaries
           sandbox-profile-refs
           profile-catalog))
         (sandbox-unresolved-profile-refs
          (poo-flow-user-loop-engine-sandbox-unresolved-profile-refs
           sandbox-profile-refs
           profile-catalog))
         (sandbox-handoff-agreement
          (poo-flow-user-loop-engine-sandbox-handoff-agreement
           sandbox-profile-refs
           sandbox-runtime-summaries
           sandbox-handoff-summaries
           sandbox-unresolved-profile-refs))
         (workflow-agreement
          (poo-flow-funflow-workflow-agreement
           (poo-flow-user-loop-engine-intent-workflow-ref base-intent)
           workflow-check-maps))
         (workflow-functional-dags
          (poo-flow-user-alist-ref workflow-agreement
                                   'functional-dags
                                   '()))
         (intent
          (append
           base-intent
           (list
            (cons 'workflow-agreement workflow-agreement)
            (cons 'workflow-functional-dag-count
                  (poo-flow-user-alist-ref workflow-agreement
                                           'functional-dag-count
                                           0))
            (cons 'workflow-functional-dags workflow-functional-dags)
            (cons 'sandbox-profile-refs sandbox-profile-refs)
            (cons 'sandbox-runtime-summaries sandbox-runtime-summaries)
            (cons 'sandbox-handoff-summaries sandbox-handoff-summaries)
            (cons 'sandbox-handoff-agreement sandbox-handoff-agreement)
            (cons 'sandbox-unresolved-profile-refs
                  sandbox-unresolved-profile-refs))))
         (capability-receipt
          (poo-flow-user-loop-engine-intent-capability-receipt
           intent
           backend-capability-registry))
         (intent-with-capability
          (append intent
                  (list (cons 'capability-receipt capability-receipt)))))
    (append intent-with-capability
            (poo-flow-user-loop-engine-intent-runtime-projections
             intent-with-capability))))

;; : (-> PooUserModuleSelection [PooSandboxProfile] MaybeAlist)
(def (poo-flow-user-module-selection-loop-engine-intent selection
                                                       . maybe-context)
  (and (poo-flow-user-module-selection-loop-engine? selection)
       (let (poo-intent-fields
             (poo-flow-user-loop-engine-selection-poo-intent selection))
         (and poo-intent-fields
              (poo-flow-user-loop-engine-enriched-intent
               (poo-flow-user-loop-engine-base-intent selection
                                                      poo-intent-fields)
               (poo-flow-user-loop-engine-context-profile-catalog
                maybe-context)
               (poo-flow-user-loop-engine-context-workflow-check-maps
                maybe-context)
               (poo-flow-user-loop-engine-context-backend-capability-registry
                maybe-context))))))

;;; Loop engine intents are collected with a recursive add/fold shape so module
;;; selection order becomes the handoff order for later runtime descriptors.
;; : (-> [PooUserModuleSelection] [PooSandboxProfile] [PooFlowCicdCheckMap] [Alist])
(def (poo-flow-user-config-loop-engine-intents/add selected-modules
                                                   profile-catalog
                                                   . maybe-workflow-check-maps)
  (let ((workflow-check-maps
         (if (null? maybe-workflow-check-maps)
           '()
           (car maybe-workflow-check-maps)))
        (backend-capability-registry
         (if (or (null? maybe-workflow-check-maps)
                 (null? (cdr maybe-workflow-check-maps)))
           (poo-flow-user-config-sandbox-backend-capability-registry
            selected-modules)
           (cadr maybe-workflow-check-maps))))
    (filter-map
     (lambda (selection)
       (poo-flow-user-config-loop-engine-intent
        selection
        profile-catalog
        workflow-check-maps
        backend-capability-registry))
     selected-modules)))

;; : (-> PooUserModuleSelection [PooSandboxProfile] [PooFlowCicdCheckMap] MaybeAlist)
(def (poo-flow-user-config-loop-engine-intent selection
                                              profile-catalog
                                              workflow-check-maps
                                              .
                                              maybe-backend-capability-registry)
  (poo-flow-user-module-selection-loop-engine-intent
   selection
   profile-catalog
   workflow-check-maps
   (if (null? maybe-backend-capability-registry)
     (poo-flow-user-config-sandbox-backend-capability-registry '())
     (car maybe-backend-capability-registry))))

;;; Config-level loop-engine intents let workflow docs and tests show the real
;;; governor configuration result from `:workflow` without starting a loop.
;; : (-> PooUserConfig [Alist])
(def (poo-flow-user-config-loop-engine-intents config)
  (let* ((selected-modules (poo-flow-user-config-modules config))
         (profile-catalog
          (poo-flow-user-config-sandbox-profile-catalog selected-modules))
         (workflow-check-maps
          (poo-flow-user-config-workflow-cicd-check-maps config))
         (backend-capability-registry
          (poo-flow-user-config-sandbox-backend-capability-registry
           selected-modules)))
    (poo-flow-user-config-loop-engine-intents/add
     selected-modules
     profile-catalog
     workflow-check-maps
     backend-capability-registry)))
