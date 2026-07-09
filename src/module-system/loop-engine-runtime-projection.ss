(import :poo-flow/src/modules/funflow/config
        :poo-flow/src/module-system/base
        :poo-flow/src/module-system/sandbox-profile-catalog
        :poo-flow/src/module-system/sandbox-backend-capability-catalog
        :poo-flow/src/module-system/workflow-cicd-config
        :poo-flow/src/module-system/workflow-cicd-runtime-command-config
        :poo-flow/src/module-system/loop-engine-core
        :poo-flow/src/module-system/loop-engine-runtime-base
        :poo-flow/src/module-system/loop-engine-runtime-capability
        :poo-flow/src/module-system/loop-engine-runtime-agent
        :poo-flow/src/module-system/loop-engine-runtime-intent
        :poo-flow/src/module-system/loop-engine-result-contract
        :poo-flow/src/utilities/functional)

(export poo-flow-user-loop-engine-memory-policy-for-use-case
        poo-flow-user-loop-engine-memory-policy-use-cases/rev
        poo-flow-user-loop-engine-memory-policy-use-cases
        poo-flow-user-loop-engine-intent-runtime-projections
        poo-flow-user-loop-engine-intents-field-values
        poo-flow-user-module-selection-loop-engine?
        poo-flow-user-loop-engine-context-profile-catalog
        poo-flow-user-loop-engine-context-workflow-check-maps
        poo-flow-user-loop-engine-context-backend-capability-registry
        poo-flow-user-loop-engine-base-intent
        poo-flow-user-loop-engine-enriched-intent
        poo-flow-user-module-selection-loop-engine-intent
        poo-flow-user-config-loop-engine-intents/add
        poo-flow-user-config-loop-engine-intents/project-rev
        poo-flow-user-config-loop-engine-intents/project
        poo-flow-user-config-loop-engine-intent
        poo-flow-user-config-loop-engine-intents)

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

(def (poo-flow-user-loop-engine-memory-policy-use-cases/rev
      memory-policies
      use-cases-rev)
  (poo-flow-fold-left
   (lambda (memory-policy use-cases)
     (cons (poo-flow-user-loop-engine-intent-ref
            memory-policy
            'use-case
            #f)
           use-cases))
   use-cases-rev
   memory-policies))

(def (poo-flow-user-loop-engine-memory-policy-use-cases memory-policies)
  (reverse
   (poo-flow-user-loop-engine-memory-policy-use-cases/rev
    memory-policies
    '())))

(def (poo-flow-user-loop-engine-intent-runtime-projections intent)
  (list
   (cons 'runtime-handoff-contracts
         +poo-flow-user-loop-engine-handoff-contracts+)
   (cons 'receipt-contracts
         +poo-flow-user-loop-engine-receipt-contracts+)
   (cons 'runtime-packet-contracts
         +poo-flow-user-loop-engine-runtime-packet-contracts+)
   (cons 'runtime-capability-descriptor
         (poo-flow-user-loop-engine-intent-runtime-capability-descriptor
          intent))
   (cons 'policy-profile-packet
         (poo-flow-user-loop-engine-intent-policy-profile-packet intent))
   (cons 'runtime-action-packets
         (list (poo-flow-user-loop-engine-intent-runtime-action-packet
                intent)))
   (cons 'runtime-receipt-batch-template
         (poo-flow-user-loop-engine-intent-runtime-receipt-batch-template
          intent))
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
   (cons 'session-agent-topology-trace
         (poo-flow-user-loop-engine-intent-session-agent-topology-trace
          intent))
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
   (cons 'runtime-command-manifest
         (poo-flow-user-loop-engine-intent-runtime-command-manifest intent))
   (cons 'runtime-command-manifest-summary
         (poo-flow-user-loop-engine-intent-runtime-command-manifest-summary
          intent))
   (cons 'proof-manifest
         (poo-flow-user-loop-engine-intent-proof-manifest intent))
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

(def (poo-flow-user-loop-engine-intents-field-values intents field)
  (poo-flow-fold-right
   (lambda (intent values)
     (cons (poo-flow-user-loop-engine-intent-ref intent field #f)
           values))
   '()
   intents))

(def (poo-flow-user-module-selection-loop-engine? selection)
  (equal? (poo-flow-user-module-selection-key selection)
          '(flow . loop-engine)))

(def (poo-flow-user-loop-engine-context-profile-catalog context)
  (if (null? context)
    (poo-flow-user-config-sandbox-profile-catalog '())
    (car context)))

(def (poo-flow-user-loop-engine-context-workflow-check-maps context)
  (if (or (null? context) (null? (cdr context)))
    '()
    (cadr context)))

(def (poo-flow-user-loop-engine-context-backend-capability-registry context)
  (if (or (null? context) (null? (cdr context)) (null? (cddr context)))
    (poo-flow-user-config-sandbox-backend-capability-registry '())
    (caddr context)))

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
    (let (cache (vector '()))
      ;; Engineering note: policy-sensitive helpers in this owner keep explicit
      ;; contracts adjacent to definitions so downstream reports stay actionable.
      ;; : (-> Any Any)
      (def (project-selection selection)
        (let (entry (assq selection (vector-ref cache 0)))
          (if entry
            (cdr entry)
            (let (intent
                  (poo-flow-user-config-loop-engine-intent
                   selection
                   profile-catalog
                   workflow-check-maps
                   backend-capability-registry))
              (vector-set! cache
                           0
                           (cons (cons selection intent)
                                 (vector-ref cache 0)))
              intent))))
      (poo-flow-user-config-loop-engine-intents/project
       project-selection
       selected-modules))))

(def (poo-flow-user-config-loop-engine-intents/project-rev project-selection
                                                           selected-modules
                                                           intents-rev)
  (poo-flow-fold-left
   (lambda (selection intents)
     (let (intent (project-selection selection))
       (if intent
         (cons intent intents)
         intents)))
   intents-rev
   selected-modules))

(def (poo-flow-user-config-loop-engine-intents/project project-selection
                                                       selected-modules)
  (reverse
   (poo-flow-user-config-loop-engine-intents/project-rev
    project-selection
    selected-modules
    '())))

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
