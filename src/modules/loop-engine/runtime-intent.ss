;;; Boundary: converts accepted loop-engine intent into runtime request and receipt objects.
;;; Invariant: intent projection preserves policy, capability, proof, and session evidence.
(import :poo-flow/src/core/runtime-protocol
        :poo-flow/src/core/runtime-command-descriptor
        "core.ss"
        "proof-abi.ss"
        "runtime-base.ss"
        "runtime-capability.ss"
        "runtime-agent.ss"
        "result-contract.ss")

(export poo-flow-user-loop-engine-intent-runtime-action-kind
        poo-flow-user-loop-engine-intent-runtime-request
        poo-flow-user-loop-engine-intent-runtime-envelope
        poo-flow-user-loop-engine-runtime-envelope/from-request
        poo-flow-user-loop-engine-intent-runtime-capability-descriptor
        poo-flow-user-loop-engine-intent-policy-profile-packet
        poo-flow-user-loop-engine-intent-runtime-action-packet
        poo-flow-user-loop-engine-intent-runtime-receipt-batch-template
        poo-flow-user-loop-engine-intent-runtime-handoff-facts
        poo-flow-user-loop-engine-runtime-handoff-facts/from-request
        poo-flow-user-loop-engine-intent-lineage-receipt
        poo-flow-user-loop-engine-intent-selector-receipt
        poo-flow-user-loop-engine-intent-resource-dispatch-receipt
        poo-flow-user-loop-engine-intent-memory-receipt
        poo-flow-user-loop-engine-intent-compression-receipt
        poo-flow-user-loop-engine-intent-runtime-command-manifest
        poo-flow-user-loop-engine-runtime-command-manifest/from-envelope
        poo-flow-user-loop-engine-intent-runtime-command-manifest-summary
        poo-flow-user-loop-engine-runtime-command-manifest-summary/from-manifest
        poo-flow-user-loop-engine-intent-proof-manifest
        poo-flow-user-loop-engine-proof-manifest/from-manifest
        poo-flow-user-loop-engine-intent-runtime-snapshot
        poo-flow-user-loop-engine-runtime-snapshot/from-components)

(def (poo-flow-user-loop-engine-intent-runtime-action-kind intent)
  (if (null? (poo-flow-user-loop-engine-intent-ref intent 'human-audit '()))
    'run
    'ask-owner))

(def (poo-flow-user-loop-engine-intent-use-case-refs intent)
  (let ((selected (poo-flow-user-loop-engine-intent-use-case-name intent)))
    (reverse
     (foldl
      (lambda (entry refs)
        (if (and (pair? entry) (not (memq (car entry) refs)))
          (cons (car entry) refs)
          refs))
      (if selected (list selected) '())
      (poo-flow-user-loop-engine-intent-ref intent 'use-cases '())))))

(def (poo-flow-user-loop-engine-intent-runtime-readiness-receipts
      intent
      sandbox-agreement)
  (list
   (list
    (cons 'kind 'loop-engine-runtime-action-readiness-receipt)
    (cons 'status 'ready)
    (cons 'action-kind
          (poo-flow-user-loop-engine-intent-runtime-action-kind intent))
    (cons 'sandbox-handoff-ready?
          (poo-flow-user-loop-engine-intent-ref
           sandbox-agreement
           'handoff-ready?
           #f))
    (cons 'runtime-owner "marlin-agent-core")
    (cons 'runtime-executed #f))))

(def (poo-flow-user-loop-engine-intent-runtime-receipt-contract kind)
  (case kind
    ((loop-engine-lineage-receipt)
     'poo-flow.loop-engine.lineage-receipt.v1)
    ((loop-engine-selector-receipt)
     'poo-flow.loop-engine.selector-receipt.v1)
    ((loop-engine-resource-dispatch-receipt)
     'poo-flow.loop-engine.resource-dispatch-receipt.v1)
    ((loop-engine-memory-receipt)
     'poo-flow.loop-engine.memory-receipt.v1)
    ((loop-engine-compression-receipt)
     'poo-flow.loop-engine.compression-receipt.v1)
    (else #f)))

(def (poo-flow-user-loop-engine-intent-runtime-receipt kind suffix intent fields)
  (let ((use-case-name
         (poo-flow-user-loop-engine-intent-use-case-name intent))
        (workflow-ref
         (poo-flow-user-loop-engine-intent-workflow-ref intent)))
    (append
     (list
      (cons 'kind kind)
      (cons 'contract
            (poo-flow-user-loop-engine-intent-runtime-receipt-contract kind))
      (cons 'receipt-id
            (poo-flow-user-loop-engine-runtime-id use-case-name suffix))
      (cons 'use-case-name use-case-name)
      (cons 'workflow-ref workflow-ref)
      (cons 'runtime-owner "marlin-agent-core")
      (cons 'runtime-executed #f))
     fields)))

(def (poo-flow-user-loop-engine-intent-runtime-capability-descriptor intent)
  (let ((capability-receipt
         (poo-flow-user-loop-engine-capability-receipt->alist
          (poo-flow-user-loop-engine-intent-capability-receipt intent))))
    (list
     (cons 'kind 'loop-engine-runtime-capability-descriptor)
     (cons 'contract
           +poo-flow-user-loop-engine-runtime-capability-descriptor-contract+)
     (cons 'runtime-language 'rust)
     (cons 'transport-class 'manifest)
     (cons 'runtime-packet-contracts
           +poo-flow-user-loop-engine-runtime-packet-contracts+)
     (cons 'supports-readiness-gates? #t)
     (cons 'capability-receipt capability-receipt)
     (cons 'sandbox-profile-refs
           (poo-flow-user-loop-engine-intent-ref
            intent
            'sandbox-profile-refs
            '()))
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'runtime-executed #f))))

(def (poo-flow-user-loop-engine-intent-policy-profile-packet intent)
  (let ((use-case-name
         (poo-flow-user-loop-engine-intent-use-case-name intent)))
    (list
     (cons 'kind 'loop-engine-policy-profile-packet)
     (cons 'contract
           +poo-flow-user-loop-engine-policy-profile-packet-contract+)
     (cons 'profile-id
           (poo-flow-user-loop-engine-runtime-id
            use-case-name
            "policy-profile"))
     (cons 'source-refs (list use-case-name))
     (cons 'policy (poo-flow-user-loop-engine-intent-policy intent))
     (cons 'queue-policy
           (poo-flow-user-loop-engine-intent-ref
            intent
            'queue-policy
            '((prioritize-steering . #t))))
     (cons 'policy-extension-receipts
           (poo-flow-user-loop-engine-intent-ref
            intent
            'policy-extension-receipts
            '()))
     (cons 'sandbox-profile-refs
           (poo-flow-user-loop-engine-intent-ref
            intent
            'sandbox-profile-refs
            '()))
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'runtime-executed #f))))

(def (poo-flow-user-loop-engine-intent-runtime-action-packet intent)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (sandbox-agreement
          (poo-flow-user-loop-engine-intent-sandbox-handoff-agreement
           intent))
         (readiness-receipts
          (poo-flow-user-loop-engine-intent-runtime-readiness-receipts
           intent
           sandbox-agreement)))
    (list
     (cons 'kind 'loop-engine-runtime-action-packet)
     (cons 'contract +poo-flow-user-loop-engine-runtime-action-packet-contract+)
     (cons 'profile-id
           (poo-flow-user-loop-engine-runtime-id
            use-case-name
            "policy-profile"))
     (cons 'candidate-refs
           (poo-flow-user-loop-engine-intent-use-case-refs intent))
     (cons 'readiness-receipts
           readiness-receipts)
     (cons 'gate-state
           (list
            (cons 'sandbox-handoff-ready?
                  (poo-flow-user-loop-engine-intent-ref
                   sandbox-agreement
                   'handoff-ready?
                   #f))
            (cons 'readiness-receipts
                  readiness-receipts)))
     (cons 'action-kind
           (poo-flow-user-loop-engine-intent-runtime-action-kind intent))
     (cons 'operation-kind
           (poo-flow-user-loop-engine-intent-operation-kind intent))
     (cons 'result-contract
           (poo-flow-user-loop-engine-intent-operation-result-contract intent))
     (cons 'workflow-ref (poo-flow-user-loop-engine-intent-workflow-ref intent))
     (cons 'status (poo-flow-user-loop-engine-intent-status intent))
     (cons 'runtime-intent
           (poo-flow-user-loop-engine-intent-runtime-intent intent))
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'runtime-executed #f))))

(def (poo-flow-user-loop-engine-intent-runtime-receipt-batch-template intent)
  (list
   (cons 'kind 'loop-engine-runtime-receipt-batch-template)
   (cons 'contract +poo-flow-user-loop-engine-runtime-receipt-batch-contract+)
   (cons 'use-case-name
         (poo-flow-user-loop-engine-intent-use-case-name intent))
   (cons 'workflow-ref (poo-flow-user-loop-engine-intent-workflow-ref intent))
   (cons 'receipt-kinds
         '(dispatch
           lineage
           selector
           resource-dispatch
           capability
           memory
           compression))
   (cons 'status 'not-executed)
   (cons 'accepted-packet-ids '())
   (cons 'runtime-owner "marlin-agent-core")
   (cons 'runtime-executed #f)))

(def (poo-flow-user-loop-engine-runtime-handoff-facts/from-request
      intent
      request)
  (let* ((workflow-agreement
          (poo-flow-user-loop-engine-intent-workflow-agreement intent))
         (sandbox-agreement
          (poo-flow-user-loop-engine-intent-sandbox-handoff-agreement
           intent))
         (workflow-valid?
          (poo-flow-user-loop-engine-intent-ref
           workflow-agreement
           'valid?
           #f))
         (sandbox-ready?
          (poo-flow-user-loop-engine-intent-ref
           sandbox-agreement
           'handoff-ready?
           #f)))
    (append
     (list
      (cons 'kind 'loop-engine-runtime-handoff)
      (cons 'contract 'poo-flow.loop-governor.runtime-handoff.v1)
      (cons 'runtime-handoff
            (poo-flow-user-loop-engine-intent-ref
             intent
             'runtime-handoff
             'loop-governor-marlin-runtime-manifest))
      (cons 'runtime-command-contract
            +poo-flow-user-loop-engine-runtime-command-contract+)
      (cons 'object-families
            +poo-flow-user-loop-engine-runtime-object-families+)
      (cons 'receipt-contracts
            +poo-flow-user-loop-engine-receipt-contracts+)
      (cons 'runtime-packet-contracts
            +poo-flow-user-loop-engine-runtime-packet-contracts+)
      (cons 'workflow-ref
            (poo-flow-user-loop-engine-intent-workflow-ref intent))
      (cons 'action-kind
            (poo-flow-user-loop-engine-intent-runtime-action-kind intent))
      (cons 'workflow-valid? workflow-valid?)
      (cons 'sandbox-handoff-ready? sandbox-ready?)
      (cons 'handoff-ready? (and workflow-valid? sandbox-ready?))
      (cons 'proof-manifest
            (poo-flow-user-loop-engine-intent-proof-manifest intent))
      (cons 'descriptor-realized? #f)
      (cons 'runtime-owner "marlin-agent-core")
      (cons 'runtime-executed #f))
     request)))

(def (poo-flow-user-loop-engine-intent-runtime-handoff-facts intent)
  (poo-flow-user-loop-engine-runtime-handoff-facts/from-request
   intent
   (poo-flow-user-loop-engine-intent-runtime-request intent)))

(def (poo-flow-user-loop-engine-intent-lineage-receipt intent)
  (let ((lineage-policy
         (poo-flow-user-loop-engine-intent-ref intent 'lineage-policy '())))
    (poo-flow-user-loop-engine-intent-runtime-receipt
     'loop-engine-lineage-receipt
     "lineage"
     intent
     (list
      (cons 'status (poo-flow-user-loop-engine-intent-status intent))
      (cons 'lineage-policy lineage-policy)
      (cons 'parent-session-refs
            (poo-flow-user-loop-engine-intent-ref
             lineage-policy
             'parent-session-refs
             '()))
      (cons 'lineage-kind
            (poo-flow-user-loop-engine-intent-ref
             lineage-policy
             'lineage-kind
             #f))
      (cons 'lineage-operator
            (poo-flow-user-loop-engine-intent-ref
             lineage-policy
             'lineage-operator
             #f))
      (cons 'use-case
            (poo-flow-user-loop-engine-intent-ref intent 'use-case '()))
      (cons 'use-cases
            (poo-flow-user-loop-engine-intent-ref intent 'use-cases '()))
      (cons 'runtime-intent
            (poo-flow-user-loop-engine-intent-runtime-intent intent))
      (cons 'policy-profile-packet
            (poo-flow-user-loop-engine-intent-policy-profile-packet intent))
      (cons 'workflow-agreement
            (poo-flow-user-loop-engine-intent-workflow-agreement intent))))))

(def (poo-flow-user-loop-engine-intent-selector-receipt intent)
  (let ((selector-policy
         (poo-flow-user-loop-engine-intent-ref intent 'selector-policy '())))
    (poo-flow-user-loop-engine-intent-runtime-receipt
     'loop-engine-selector-receipt
     "selector"
     intent
     (list
      (cons 'selector-policy selector-policy)
      (cons 'candidates
            (poo-flow-user-loop-engine-intent-ref
             selector-policy
             'candidates
             '()))
      (cons 'selected-branch
            (poo-flow-user-loop-engine-intent-ref
             selector-policy
             'selected-branch
             #f))
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
             '()))))))

(def (poo-flow-user-loop-engine-intent-resource-dispatch-receipt intent)
  (let ((resource-policy
         (poo-flow-user-loop-engine-intent-ref intent 'resource-policy '())))
    (poo-flow-user-loop-engine-intent-runtime-receipt
     'loop-engine-resource-dispatch-receipt
     "resource-dispatch"
     intent
     (list
      (cons 'resource-policy resource-policy)
      (cons 'tool-refs
            (poo-flow-user-loop-engine-intent-ref
             resource-policy
             'tool-refs
             '()))
      (cons 'dispatch-groups
            (poo-flow-user-loop-engine-intent-ref
             resource-policy
             'dispatch-groups
             '()))
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
      (cons 'sandbox-unresolved-profile-refs
            (poo-flow-user-loop-engine-intent-ref
             intent
             'sandbox-unresolved-profile-refs
             '()))
      (cons 'sandbox-handoff-agreement
            (poo-flow-user-loop-engine-intent-sandbox-handoff-agreement
             intent))))))

(def (poo-flow-user-loop-engine-intent-memory-policy-for-use-case policies
                                                                  use-case)
  (cond
   ((null? policies) '())
   ((not (pair? policies)) '())
   ((equal? (poo-flow-user-loop-engine-intent-ref
             (car policies)
             'use-case
             #f)
            use-case)
    (car policies))
   (else
    (poo-flow-user-loop-engine-intent-memory-policy-for-use-case
     (cdr policies)
     use-case))))

;;; Receipt boundary: resolve one memory policy per use case and retain unresolved selections as diagnostics.
(def (poo-flow-user-loop-engine-intent-memory-receipt intent)
  (let* ((memory-policies
          (poo-flow-user-loop-engine-intent-ref intent 'memory-policies '()))
         (available-use-cases
          (map (lambda (policy)
                 (poo-flow-user-loop-engine-intent-ref
                  policy
                  'use-case
                  #f))
               memory-policies))
         (selector-policy
          (poo-flow-user-loop-engine-intent-ref intent 'selector-policy '()))
         (selected-use-case
          (poo-flow-user-loop-engine-intent-ref
           selector-policy
           'selected-branch
           (if (null? available-use-cases)
             #f
             (car available-use-cases))))
         (selected-policy
          (poo-flow-user-loop-engine-intent-memory-policy-for-use-case
           memory-policies
           selected-use-case)))
    (poo-flow-user-loop-engine-intent-runtime-receipt
     'loop-engine-memory-receipt
     "memory"
     intent
     (list
      (cons 'memory-intents
            (poo-flow-user-loop-engine-intent-ref intent 'memory-intents '()))
      (cons 'memory-policy
            (poo-flow-user-loop-engine-intent-ref intent 'memory-policy '()))
      (cons 'memory-policies memory-policies)
      (cons 'policies memory-policies)
      (cons 'selected-use-case selected-use-case)
      (cons 'use-case selected-use-case)
      (cons 'policy-count (length memory-policies))
      (cons 'available-use-cases available-use-cases)
      (cons 'selected-policy-found? (not (null? selected-policy)))
      (cons 'store
            (poo-flow-user-loop-engine-intent-ref selected-policy 'store #f))
      (cons 'state-path
            (poo-flow-user-loop-engine-intent-ref
             selected-policy
             'state-path
             #f))
      (cons 'scope
            (poo-flow-user-loop-engine-intent-ref selected-policy 'scope #f))
      (cons 'recall
            (poo-flow-user-loop-engine-intent-ref selected-policy 'recall '()))
      (cons 'commit
            (poo-flow-user-loop-engine-intent-ref selected-policy 'commit '()))
      (cons 'ranking
            (poo-flow-user-loop-engine-intent-ref selected-policy 'ranking #f))
      (cons 'retention
            (poo-flow-user-loop-engine-intent-ref
             selected-policy
             'retention
             #f))
      (cons 'checkpoint-ref
            (poo-flow-user-loop-engine-intent-ref intent 'checkpoint-ref #f))))))

(def (poo-flow-user-loop-engine-intent-compression-receipt intent)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (compression-policy
          (poo-flow-user-loop-engine-intent-ref
           intent
           'compression-policy
           '())))
    (poo-flow-user-loop-engine-intent-runtime-receipt
     'loop-engine-compression-receipt
     "compression"
     intent
     (list
      (cons 'compression-policy compression-policy)
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
             #f))
      (cons 'source-session-ref
            (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
      (cons 'compressed-session-ref
            (poo-flow-user-loop-engine-runtime-id
             use-case-name
             "compressed-session"))
      (cons 'retention
            (poo-flow-user-loop-engine-intent-ref intent 'retention '()))
      (cons 'artifact-refs
            (poo-flow-user-loop-engine-intent-ref intent 'artifact-refs '()))))))

;;; Materialize each expensive runtime projection once. The returned request
;;; deliberately shares its component values with higher-level projections;
;;; presentation must not rebuild the whole request for every report field.
(def (poo-flow-user-loop-engine-intent-runtime-request intent)
  (let* ((runtime-capability-descriptor
          (poo-flow-user-loop-engine-intent-runtime-capability-descriptor
           intent))
         (policy-profile-packet
          (poo-flow-user-loop-engine-intent-policy-profile-packet intent))
         (runtime-action-packets
          (list
           (poo-flow-user-loop-engine-intent-runtime-action-packet intent)))
         (runtime-receipt-batch-template
          (poo-flow-user-loop-engine-intent-runtime-receipt-batch-template
           intent))
         (workflow-agreement
          (poo-flow-user-loop-engine-intent-workflow-agreement intent))
         (result-contract
          (poo-flow-user-loop-engine-intent-result-contract intent))
         (agent-profiles
          (poo-flow-user-loop-engine-intent-agent-profiles intent))
         (agent-harnesses
          (poo-flow-user-loop-engine-intent-agent-harnesses intent))
         (agent-sessions
          (poo-flow-user-loop-engine-intent-agent-sessions intent))
         (session-agent-graph
          (poo-flow-user-loop-engine-intent-session-agent-graph intent))
         (session-agent-topology-trace
          (poo-flow-user-loop-engine-intent-session-agent-topology-trace
           intent))
         (workflow-run
          (poo-flow-user-loop-engine-intent-workflow-run intent))
         (dispatch-receipt
          (poo-flow-user-loop-engine-intent-dispatch-receipt intent))
         (agent-operation
          (poo-flow-user-loop-engine-intent-agent-operation intent))
         (delegated-operation
          (poo-flow-user-loop-engine-intent-delegated-operation intent))
         (lineage-receipt
          (poo-flow-user-loop-engine-intent-lineage-receipt intent))
         (selector-receipt
          (poo-flow-user-loop-engine-intent-selector-receipt intent))
         (resource-dispatch-receipt
          (poo-flow-user-loop-engine-intent-resource-dispatch-receipt intent))
         (capability-receipt
          (poo-flow-user-loop-engine-capability-receipt->alist
           (poo-flow-user-loop-engine-intent-capability-receipt intent)))
         (memory-receipt
          (poo-flow-user-loop-engine-intent-memory-receipt intent))
         (compression-receipt
          (poo-flow-user-loop-engine-intent-compression-receipt intent))
         (sandbox-agreement
          (poo-flow-user-loop-engine-intent-sandbox-handoff-agreement intent))
         (runtime-snapshot
          (poo-flow-user-loop-engine-runtime-snapshot/from-components
           intent
           workflow-agreement
           lineage-receipt
           selector-receipt
           resource-dispatch-receipt
           capability-receipt
           memory-receipt
           compression-receipt
           sandbox-agreement)))
    (list
            (cons 'kind 'loop-engine-runtime-handoff-request)
            (cons 'contract
                  +poo-flow-user-loop-engine-runtime-command-contract+)
            (cons 'runtime-owner "marlin-agent-core")
            (cons 'object-families
                  +poo-flow-user-loop-engine-runtime-object-families+)
            (cons 'receipt-contracts
                  +poo-flow-user-loop-engine-receipt-contracts+)
            (cons 'runtime-packet-contracts
                  +poo-flow-user-loop-engine-runtime-packet-contracts+)
            (cons 'runtime-capability-descriptor
                  runtime-capability-descriptor)
            (cons 'policy-profile-packet
                  policy-profile-packet)
            (cons 'runtime-action-packets
                  runtime-action-packets)
            (cons 'runtime-receipt-batch-template
                  runtime-receipt-batch-template)
            (cons 'use-case
                  (poo-flow-user-loop-engine-intent-ref intent 'use-case '()))
            (cons 'use-cases
                  (poo-flow-user-loop-engine-intent-ref intent 'use-cases '()))
            (cons 'workflow-agreement
                  workflow-agreement)
            (cons 'result-contract
                  result-contract)
            (cons 'agent-profiles
                  agent-profiles)
            (cons 'agent-harnesses
                  agent-harnesses)
            (cons 'agent-sessions
                  agent-sessions)
            (cons 'session-agent-graph
                  session-agent-graph)
            (cons 'session-agent-topology-trace
                  session-agent-topology-trace)
            (cons 'workflow-run
                  workflow-run)
            (cons 'dispatch-receipt
                  dispatch-receipt)
            (cons 'agent-operation
                  agent-operation)
            (cons 'delegated-operation
                  delegated-operation)
            (cons 'lineage-receipt
                  lineage-receipt)
            (cons 'selector-receipt
                  selector-receipt)
            (cons 'resource-dispatch-receipt
                  resource-dispatch-receipt)
            (cons 'capability-receipt
                  capability-receipt)
            (cons 'memory-receipt
                  memory-receipt)
            (cons 'compression-receipt
                  compression-receipt)
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
            (cons 'spec-evolution-reviews
                  (poo-flow-user-loop-engine-intent-ref
                   intent
                   'spec-evolution-reviews
                   '()))
            (cons 'spec-evolution-human-audit-review-items
                  (poo-flow-user-loop-engine-intent-ref
                   intent
                   'spec-evolution-human-audit-review-items
                   '()))
            (cons 'spec-evolution-runtime-manifest-rows
                  (poo-flow-user-loop-engine-intent-ref
                   intent
                   'spec-evolution-runtime-manifest-rows
                   '()))
            (cons 'runtime-snapshot
                  runtime-snapshot)
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
                  sandbox-agreement)
            (cons 'sandbox-unresolved-profile-refs
                  (poo-flow-user-loop-engine-intent-ref
                   intent
                   'sandbox-unresolved-profile-refs
                   '()))
            (cons 'runtime-executed #f))))

(def (poo-flow-user-loop-engine-runtime-envelope/from-request intent request)
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
     (cons 'request request)
     (cons 'policy
           (poo-flow-user-loop-engine-intent-policy intent))
     (cons 'plan-id
           (poo-flow-user-loop-engine-runtime-id use-case-name "plan"))
     (cons 'node-id
           (poo-flow-user-loop-engine-runtime-id use-case-name "node"))
     (cons 'frontier
           (poo-flow-user-loop-engine-intent-ref intent 'agent-judges '())))))

;;; Handoff boundary: package stable request identities and evidence without executing the runtime operation.
(def (poo-flow-user-loop-engine-intent-runtime-envelope intent)
  (poo-flow-user-loop-engine-runtime-envelope/from-request
   intent
   (poo-flow-user-loop-engine-intent-runtime-request intent)))

(def (poo-flow-user-loop-engine-runtime-command-manifest/from-envelope envelope)
  (runtime-command-fields->manifest
   +poo-flow-user-loop-engine-runtime-command-name+
   +poo-flow-user-loop-engine-runtime-command-executable+
   +poo-flow-user-loop-engine-runtime-command-arguments+
   'stdout-s-expression
   (list
    (cons 'source 'user-config-loop-engine)
    (cons 'contract
          +poo-flow-user-loop-engine-runtime-command-contract+)
    (cons 'runtime-owner "marlin-agent-core")
    (cons 'object-families
          +poo-flow-user-loop-engine-runtime-object-families+)
    (cons 'runtime-executed #f))
   envelope))

(def (poo-flow-user-loop-engine-intent-runtime-command-manifest intent)
  (poo-flow-user-loop-engine-runtime-command-manifest/from-envelope
   (poo-flow-user-loop-engine-intent-runtime-envelope intent)))

(def (poo-flow-user-loop-engine-runtime-command-manifest-summary/from-manifest
      manifest)
  (let* ((request
          (poo-flow-user-loop-engine-intent-ref manifest 'request '()))
         (metadata
          (poo-flow-user-loop-engine-intent-ref manifest 'metadata '())))
    (list
     (cons 'kind 'runtime-command-manifest-summary)
     (cons 'name (poo-flow-user-loop-engine-intent-ref manifest 'name #f))
     (cons 'operation
           (poo-flow-user-loop-engine-intent-ref manifest 'operation #f))
     (cons 'request-id
           (poo-flow-user-loop-engine-intent-ref manifest 'request-id #f))
     (cons 'artifact-handle
           (poo-flow-user-loop-engine-intent-ref
            manifest
            'artifact-handle
            #f))
     (cons 'contract
           (poo-flow-user-loop-engine-intent-ref
            metadata
            'contract
            +poo-flow-user-loop-engine-runtime-command-contract+))
     (cons 'object-families
           (poo-flow-user-loop-engine-intent-ref
            metadata
            'object-families
            +poo-flow-user-loop-engine-runtime-object-families+))
     (cons 'receipt-contracts
           +poo-flow-user-loop-engine-receipt-contracts+)
     (cons 'runtime-packet-contracts
           +poo-flow-user-loop-engine-runtime-packet-contracts+)
     (cons 'runtime-owner
           (poo-flow-user-loop-engine-intent-ref
            request
            'runtime-owner
            "marlin-agent-core"))
     (cons 'runtime-executed #f))))

(def (poo-flow-user-loop-engine-intent-runtime-command-manifest-summary intent)
  (poo-flow-user-loop-engine-runtime-command-manifest-summary/from-manifest
   (poo-flow-user-loop-engine-intent-runtime-command-manifest intent)))

(def (poo-flow-user-loop-engine-proof-manifest/from-manifest manifest)
  (poo-flow-loop-engine-proof-manifest
     (poo-flow-user-loop-engine-intent-ref manifest 'request-id #f)
     (poo-flow-user-loop-engine-intent-ref manifest 'artifact-handle #f)
     +poo-flow-user-loop-engine-runtime-command-contract+
     +poo-flow-user-loop-engine-runtime-object-families+
     +poo-flow-user-loop-engine-receipt-contracts+
     +poo-flow-user-loop-engine-runtime-packet-contracts+))

(def (poo-flow-user-loop-engine-intent-proof-manifest intent)
  (let (use-case-name
        (poo-flow-user-loop-engine-intent-use-case-name intent))
    (poo-flow-loop-engine-proof-manifest
     (poo-flow-user-loop-engine-runtime-id use-case-name "request")
     (poo-flow-user-loop-engine-runtime-id use-case-name "artifact")
     +poo-flow-user-loop-engine-runtime-command-contract+
     +poo-flow-user-loop-engine-runtime-object-families+
     +poo-flow-user-loop-engine-receipt-contracts+
     +poo-flow-user-loop-engine-runtime-packet-contracts+)))

;;; Runtime intent snapshots are already serialized as bounded alists at this
;;; boundary; avoid depending on the heavier runtime snapshot projection owner.
(def (poo-flow-user-loop-engine-runtime-snapshot/from-components
      intent
      workflow-agreement
      lineage-receipt
      selector-receipt
      resource-dispatch-receipt
      capability-receipt
      memory-receipt
      compression-receipt
      sandbox-agreement)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (workflow-ref
          (poo-flow-user-loop-engine-intent-workflow-ref intent))
         (spec-evolution-human-audit-review-items
          (poo-flow-user-loop-engine-intent-ref
           intent
           'spec-evolution-human-audit-review-items
           '()))
         (spec-evolution-runtime-manifest-rows
          (poo-flow-user-loop-engine-intent-ref
           intent
           'spec-evolution-runtime-manifest-rows
           '()))
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
                (cons 'spec-evolution-human-audit-review-items
                      spec-evolution-human-audit-review-items)
                (cons 'spec-evolution-runtime-manifest-rows
                      spec-evolution-runtime-manifest-rows)
                (cons 'sandbox-handoff-agreement sandbox-agreement)
                (cons 'runtime-executed #f))))
    (list
     (cons 'kind 'runtime-snapshot)
     (cons 'subject-kind 'loop-engine)
     (cons 'subject-id use-case-name)
     (cons 'engine 'loop-engine)
     (cons 'use-case-name use-case-name)
     (cons 'status (poo-flow-user-loop-engine-intent-status intent))
     (cons 'result #f)
     (cons 'handoff-summary handoff-summary)
     (cons 'error #f)
     (cons 'metadata
           (list
            (cons 'stage 'user-config-loop-engine-runtime-snapshot)
            (cons 'workflow-agreement workflow-agreement)
            (cons 'handoff-ready? handoff-ready?)
            (cons 'runtime-executed #f)))
     (cons 'details
           (append
            handoff-summary
            (list (cons 'contract 'poo-flow.loop-governor.v1)
                  (cons 'runtime-owner "marlin-agent-core")))))))

(def (poo-flow-user-loop-engine-intent-runtime-snapshot intent)
  (poo-flow-user-loop-engine-runtime-snapshot/from-components
   intent
   (poo-flow-user-loop-engine-intent-workflow-agreement intent)
   (poo-flow-user-loop-engine-intent-lineage-receipt intent)
   (poo-flow-user-loop-engine-intent-selector-receipt intent)
   (poo-flow-user-loop-engine-intent-resource-dispatch-receipt intent)
   (poo-flow-user-loop-engine-capability-receipt->alist
    (poo-flow-user-loop-engine-intent-capability-receipt intent))
   (poo-flow-user-loop-engine-intent-memory-receipt intent)
   (poo-flow-user-loop-engine-intent-compression-receipt intent)
   (poo-flow-user-loop-engine-intent-sandbox-handoff-agreement intent)))
