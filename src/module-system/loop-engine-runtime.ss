;;; -*- Gerbil -*-
;;; Boundary: loop-engine runtime handoff projection for module-system config.
;;; Invariant: this owner emits Marlin handoff data and never executes runtime work.

(import (only-in :poo-flow/src/core/agent-harness
                 make-poo-flow-runtime-snapshot
                 poo-flow-runtime-snapshot->alist
                 )
        (only-in :poo-flow/src/core/runtime-adapter
                 +runtime-request-schema+
                 make-stdout-runtime-command-descriptor
                 runtime-command-descriptor->manifest)
        (only-in :poo-flow/src/modules/agent-sandbox/config
                 poo-flow-default-sandbox-profiles)
        (only-in :poo-flow/src/modules/funflow/config
                 poo-flow-funflow-workflow-agreement)
        :poo-flow/src/module-system/base
        :poo-flow/src/module-system/sandbox-profile-catalog
        :poo-flow/src/module-system/workflow-cicd-config
        :poo-flow/src/module-system/loop-engine-core
        :poo-flow/src/module-system/loop-engine-runtime-base
        :poo-flow/src/module-system/loop-engine-runtime-agent
        :poo-flow/src/module-system/loop-engine-result-contract)

(export poo-flow-user-module-selection-loop-engine-intent
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
        poo-flow-user-loop-engine-intent-workflow-run
        poo-flow-user-loop-engine-intents-field-values
        poo-flow-user-config-loop-engine-intents
        poo-flow-user-loop-engine-intent-runtime-intent
        poo-flow-user-loop-engine-intent-policy
        poo-flow-user-loop-engine-intent-runtime-projections
        poo-flow-user-config-loop-engine-intents/add)

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
                  (poo-flow-user-loop-engine-intent-capability-receipt
                   intent))
            (cons 'memory-receipt
                  (poo-flow-user-loop-engine-intent-memory-receipt intent))
            (cons 'compression-receipt
                  (poo-flow-user-loop-engine-intent-compression-receipt
                   intent))
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
          (poo-flow-user-loop-engine-intent-capability-receipt intent))
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
(def (poo-flow-user-loop-engine-intent-lineage-receipt intent)
  (let ((use-case-name
         (poo-flow-user-loop-engine-intent-use-case-name intent))
        (lineage-policy
         (poo-flow-user-loop-engine-intent-ref intent 'lineage-policy '())))
    (list
     (cons 'kind 'lineage-receipt)
     (cons 'contract 'poo-flow.loop-engine.lineage-receipt.v1)
     (cons 'session-ref
           (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
     (cons 'parent-session-refs
           (poo-flow-user-loop-engine-intent-ref
            lineage-policy
            'parent-session-refs
            '()))
     (cons 'lineage-kind
           (poo-flow-user-loop-engine-intent-ref
            lineage-policy
            'lineage-kind
            'loop-root))
     (cons 'lineage-operator
           (poo-flow-user-loop-engine-intent-ref
            lineage-policy
            'lineage-operator
            'loop-engine-profile))
     (cons 'journal
           (poo-flow-user-loop-engine-intent-ref
            lineage-policy
            'journal
            'report-only))
     (cons 'export
           (poo-flow-user-loop-engine-intent-ref
            lineage-policy
            'export
            'jsonl))
     (cons 'policy lineage-policy)
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'runtime-executed #f))))

;;; Selector receipts keep branch choice report-only. Candidate scoring and
;;; routing remain runtime work for Marlin or a model-backed executor.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-selector-receipt intent)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (selector-policy
          (poo-flow-user-loop-engine-intent-ref intent 'selector-policy '()))
         (selected-branch
          (poo-flow-user-loop-engine-intent-ref
           selector-policy
           'selected-branch
           #f)))
    (list
     (cons 'kind 'selector-receipt)
     (cons 'contract 'poo-flow.loop-engine.selector-receipt.v1)
     (cons 'session-ref
           (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
     (cons 'candidates
           (poo-flow-user-loop-engine-intent-ref
            selector-policy
            'candidates
            (poo-flow-user-loop-engine-use-case-names intent)))
     (cons 'judge-inputs
           (poo-flow-user-loop-engine-intent-ref
            selector-policy
            'judge-inputs
            '()))
     (cons 'fallback
           (poo-flow-user-loop-engine-intent-ref
            selector-policy
            'fallback
            #f))
     (cons 'selected-branch
           (if selected-branch selected-branch use-case-name))
     (cons 'policy selector-policy)
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'runtime-executed #f))))

;;; Resource dispatch receipts project OpenRath-style resource-key collision
;;; facts. They do not schedule or run tool calls in Scheme.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-resource-dispatch-receipt intent)
  (let ((use-case-name
         (poo-flow-user-loop-engine-intent-use-case-name intent))
        (resource-policy
         (poo-flow-user-loop-engine-intent-ref intent 'resource-policy '())))
    (list
     (cons 'kind 'resource-dispatch-receipt)
     (cons 'contract 'poo-flow.loop-engine.resource-dispatch-receipt.v1)
     (cons 'dispatch-ref
           (poo-flow-user-loop-engine-runtime-id use-case-name "dispatch"))
     (cons 'tool-refs
           (poo-flow-user-loop-engine-intent-ref
            resource-policy
            'tool-refs
            '()))
     (cons 'resource-keys
           (poo-flow-user-loop-engine-intent-ref
            resource-policy
            'resource-keys
            '()))
     (cons 'collision-classes
           (poo-flow-user-loop-engine-intent-ref
            resource-policy
            'collision-classes
            '()))
     (cons 'dispatch-groups
           (poo-flow-user-loop-engine-intent-ref
            resource-policy
            'dispatch-groups
            '()))
     (cons 'policy resource-policy)
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'runtime-executed #f))))

;;; Capability receipts are OpenRath-inspired backend expectation facts. They
;;; do not probe, open, or validate a backend; Marlin consumes them later.
;;; Supported backends are a validation vocabulary only; Scheme never creates
;;; the sandbox backend and still leaves all runtime realization to Marlin.
;; : [Symbol]
(def +poo-flow-user-loop-engine-capability-supported-backends+
  '(nono-sandbox cube-sandbox))

;;; Backend support keeps current public contracts limited to cube-sandbox and
;;; nono-sandbox while accepting the historical cubeSandbox spelling as input.
;; : (-> Symbol Boolean)
(def (poo-flow-user-loop-engine-capability-backend-supported? backend)
  (or (not backend)
      (memq backend
            +poo-flow-user-loop-engine-capability-supported-backends+)
      (eq? backend 'cubeSandbox)))

;;; Diagnostics are payload rows for users and ABI consumers. An empty result
;;; means the policy vocabulary is valid, not that a backend probe succeeded.
;; : (-> Symbol [Alist])
(def (poo-flow-user-loop-engine-capability-diagnostics backend)
  (if (poo-flow-user-loop-engine-capability-backend-supported? backend)
    '()
    (list
     (list
      (cons 'field 'backend)
      (cons 'code 'unsupported-capability-backend)
      (cons 'value backend)
      (cons 'supported
            +poo-flow-user-loop-engine-capability-supported-backends+)))))

;;; Capability receipt is self-contained so Marlin can reject unsupported
;;; backend intent without inspecting the original profile object graph.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-capability-receipt intent)
  (let ((use-case-name
         (poo-flow-user-loop-engine-intent-use-case-name intent))
        (capability-policy
         (poo-flow-user-loop-engine-intent-ref intent
                                               'capability-policy
                                               '())))
    (let* ((backend
            (poo-flow-user-loop-engine-intent-ref
             capability-policy
             'backend
             #f))
           (diagnostics
            (poo-flow-user-loop-engine-capability-diagnostics backend)))
      (list
       (cons 'kind 'capability-receipt)
       (cons 'contract 'poo-flow.loop-engine.capability-receipt.v1)
       (cons 'backend backend)
       (cons 'supported-backends
             +poo-flow-user-loop-engine-capability-supported-backends+)
       (cons 'valid? (null? diagnostics))
       (cons 'diagnostic-count (length diagnostics))
       (cons 'diagnostics diagnostics)
       (cons 'isolation
             (poo-flow-user-loop-engine-intent-ref
              capability-policy
              'isolation
              #f))
       (cons 'required
             (poo-flow-user-loop-engine-intent-ref
              capability-policy
              'required
              '()))
       (cons 'optional
             (poo-flow-user-loop-engine-intent-ref
              capability-policy
              'optional
              '()))
       (cons 'unsupported-behavior
             (poo-flow-user-loop-engine-intent-ref
              capability-policy
              'unsupported-behavior
              'handoff-diagnostic))
       (cons 'policy capability-policy)
       (cons 'sandbox-ref
             (poo-flow-user-loop-engine-intent-primary-sandbox-profile
              intent))
       (cons 'session-ref
             (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
       (cons 'runtime-owner "marlin-agent-core")
       (cons 'runtime-executed #f)))))

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
(def (poo-flow-user-loop-engine-intent-memory-receipt intent)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (memory-policies
          (poo-flow-user-loop-engine-intent-ref intent 'memory-policies '()))
         (memory-policy
          (poo-flow-user-loop-engine-memory-policy-for-use-case
           memory-policies
           use-case-name)))
    (list
     (cons 'kind 'memory-receipt)
     (cons 'contract 'poo-flow.loop-engine.memory-receipt.v1)
     (cons 'selected-use-case use-case-name)
     (cons 'use-case
           (poo-flow-user-loop-engine-intent-ref
            memory-policy
            'use-case
            #f))
     (cons 'store
           (poo-flow-user-loop-engine-intent-ref
            memory-policy
            'store
            #f))
     (cons 'state-path
           (poo-flow-user-loop-engine-intent-ref
            memory-policy
            'state-path
            #f))
     (cons 'scope
           (poo-flow-user-loop-engine-intent-ref
            memory-policy
            'scope
            #f))
     (cons 'recall
           (poo-flow-user-loop-engine-intent-ref
            memory-policy
            'recall
            '()))
     (cons 'commit
           (poo-flow-user-loop-engine-intent-ref
            memory-policy
            'commit
            '()))
     (cons 'ranking
           (poo-flow-user-loop-engine-intent-ref
            memory-policy
            'ranking
            #f))
     (cons 'retention
           (poo-flow-user-loop-engine-intent-ref
            memory-policy
            'retention
            'report-only))
     (cons 'policy memory-policy)
     (cons 'policies memory-policies)
     (cons 'session-ref
           (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'runtime-executed #f))))

;;; Compression receipts describe the handoff shape for transcript/session
;;; compaction. Scheme never summarizes, mutates, or creates sessions here.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-compression-receipt intent)
  (let ((use-case-name
         (poo-flow-user-loop-engine-intent-use-case-name intent))
        (compression-policy
         (poo-flow-user-loop-engine-intent-ref
          intent
          'compression-policy
          '())))
    (list
     (cons 'kind 'compression-receipt)
     (cons 'contract 'poo-flow.loop-engine.compression-receipt.v1)
     (cons 'strategy
           (poo-flow-user-loop-engine-intent-ref
            compression-policy
            'strategy
            #f))
     (cons 'trigger
           (poo-flow-user-loop-engine-intent-ref
            compression-policy
            'trigger
            #f))
     (cons 'summary-format
           (poo-flow-user-loop-engine-intent-ref
            compression-policy
            'summary-format
            #f))
     (cons 'lineage-kind
           (poo-flow-user-loop-engine-intent-ref
            compression-policy
            'lineage-kind
            'compressed-session))
     (cons 'retention
           (poo-flow-user-loop-engine-intent-ref
            compression-policy
            'retention
            'report-only))
     (cons 'policy compression-policy)
     (cons 'source-session-ref
           (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
     (cons 'compressed-session-ref
           (poo-flow-user-loop-engine-runtime-id
            use-case-name
            "compressed-session"))
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'runtime-executed #f))))

;;; Handoff facts are the single report row tying loop-engine policy,
;;; workflow-run projections, sandbox evidence, and runtime command manifests.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-runtime-handoff-facts intent)
  (list
   (cons 'kind 'loop-engine-runtime-handoff)
   (cons 'contract 'poo-flow.loop-governor.runtime-handoff.v1)
   (cons 'runtime-owner "marlin-agent-core")
   (cons 'runtime-handoff
         (poo-flow-user-loop-engine-intent-ref
          intent
          'runtime-handoff
          'loop-governor-marlin-runtime-manifest))
   (cons 'handoff-contracts +poo-flow-user-loop-engine-handoff-contracts+)
   (cons 'runtime-command-contract
         +poo-flow-user-loop-engine-runtime-command-contract+)
   (cons 'object-families
         +poo-flow-user-loop-engine-runtime-object-families+)
   (cons 'receipt-contracts
         +poo-flow-user-loop-engine-receipt-contracts+)
   (cons 'workflow-ref
         (poo-flow-user-loop-engine-intent-workflow-ref intent))
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
   (cons 'sandbox
         (poo-flow-user-loop-engine-intent-ref intent 'sandbox '()))
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
   (cons 'lineage-policy
         (poo-flow-user-loop-engine-intent-ref intent 'lineage-policy '()))
   (cons 'selector-policy
         (poo-flow-user-loop-engine-intent-ref intent 'selector-policy '()))
   (cons 'resource-policy
         (poo-flow-user-loop-engine-intent-ref intent 'resource-policy '()))
   (cons 'capability-policy
         (poo-flow-user-loop-engine-intent-ref
          intent
          'capability-policy
          '()))
   (cons 'memory-policies
         (poo-flow-user-loop-engine-intent-ref
          intent
          'memory-policies
          '()))
   (cons 'compression-policy
         (poo-flow-user-loop-engine-intent-ref
          intent
          'compression-policy
          '()))
   (cons 'runtime
         (poo-flow-user-loop-engine-intent-ref intent 'runtime '()))
   (cons 'descriptor-realized? #f)
   (cons 'runtime-executed #f)))

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
;; : (-> PooUserModuleSelection [PooSandboxProfile] MaybeAlist)
(def (poo-flow-user-module-selection-loop-engine-intent selection
                                                       . maybe-context)
  (if (equal? (poo-flow-user-module-selection-key selection)
              '(flow . loop-engine))
    (let (poo-intent-fields
          (poo-flow-user-loop-engine-selection-poo-intent selection))
      (if poo-intent-fields
        (let* ((profile-catalog
                (if (null? maybe-context)
                  poo-flow-default-sandbox-profiles
                  (car maybe-context)))
               (workflow-check-maps
                (if (or (null? maybe-context)
                        (null? (cdr maybe-context)))
                  '()
                  (cadr maybe-context)))
               (base-intent
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
               (sandbox-profile-refs
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
               (intent
                (append
                 base-intent
                 (list
                  (cons 'workflow-agreement workflow-agreement)
                  (cons 'sandbox-profile-refs sandbox-profile-refs)
                  (cons 'sandbox-runtime-summaries
                        sandbox-runtime-summaries)
                  (cons 'sandbox-handoff-summaries
                        sandbox-handoff-summaries)
                  (cons 'sandbox-handoff-agreement
                        sandbox-handoff-agreement)
                  (cons 'sandbox-unresolved-profile-refs
                        sandbox-unresolved-profile-refs)))))
          (append intent
                  (poo-flow-user-loop-engine-intent-runtime-projections
                   intent)))
        #f))
    #f))

;;; Loop engine intents are collected with a recursive add/fold shape so module
;;; selection order becomes the handoff order for later runtime descriptors.
;; : (-> [PooUserModuleSelection] [PooSandboxProfile] [PooFlowCicdCheckMap] [Alist])
(def (poo-flow-user-config-loop-engine-intents/add selected-modules
                                                   profile-catalog
                                                   . maybe-workflow-check-maps)
  (let ((workflow-check-maps
         (if (null? maybe-workflow-check-maps)
           '()
           (car maybe-workflow-check-maps))))
  (cond
   ((null? selected-modules) '())
   ((poo-flow-user-module-selection-loop-engine-intent (car selected-modules)
                                                       profile-catalog
                                                       workflow-check-maps)
    => (lambda (intent)
         (cons intent
               (poo-flow-user-config-loop-engine-intents/add
                (cdr selected-modules)
                profile-catalog
                workflow-check-maps))))
   (else
    (poo-flow-user-config-loop-engine-intents/add
     (cdr selected-modules)
     profile-catalog
     workflow-check-maps)))))

;;; Config-level loop-engine intents let workflow docs and tests show the real
;;; governor configuration result from `:workflow` without starting a loop.
;; : (-> PooUserConfig [Alist])
(def (poo-flow-user-config-loop-engine-intents config)
  (let* ((selected-modules (poo-flow-user-config-modules config))
         (profile-catalog
          (poo-flow-user-config-sandbox-profile-catalog selected-modules))
         (workflow-check-maps
          (poo-flow-user-config-workflow-cicd-check-maps config)))
    (poo-flow-user-config-loop-engine-intents/add
     selected-modules
     profile-catalog
     workflow-check-maps)))
