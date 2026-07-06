;;; -*- Gerbil -*-
;;; Boundary: pure graph runtime receipts for proof-backed UI cases.
;;; Invariant: this executor records graph semantics; it never calls tools/models.

(import (only-in :clan/poo/object .o .ref object?)
        :poo-flow/src/graph/types)

(export +poo-flow-graph-branch-choice-kind+
        +poo-flow-graph-runtime-policy-kind+
        +poo-flow-graph-runtime-receipt-kind+
        poo-flow-graph-runtime-lean-fact-keys
        poo-flow-graph-branch-choice
        poo-flow-graph-branch-choice?
        poo-flow-graph-runtime-policy
        poo-flow-graph-runtime-policy?
        poo-flow-graph-runtime-receipt?
        poo-flow-graph-runtime-execute
        poo-flow-graph-runtime-receipt->lean-facts
        poo-flow-graph-runtime-receipt->lean-module
        poo-flow-graph-runtime-lean-fact-contract-complete?)

;; : Symbol
(def +poo-flow-graph-branch-choice-kind+
  'poo-flow.graph.branch-choice.v1)

;; : Symbol
(def +poo-flow-graph-runtime-policy-kind+
  'poo-flow.graph.runtime-policy.v1)

;; : Symbol
(def +poo-flow-graph-runtime-receipt-kind+
  'poo-flow.graph.runtime-receipt.v1)

;; : [Symbol]
(def poo-flow-graph-runtime-lean-fact-keys
  '(graph.runtime/executed
    graph.runtime/finished
    graph.runtime/loop-fuel-contained
    graph.runtime/handoff-reached
    graph.runtime/sandbox-scope-contained
    graph.runtime/tool-permissions-contained
    graph.runtime/checkpoint-persisted
    graph.runtime/human-approval-sound
    graph.runtime/subagents-parented
    graph.runtime/diagnostics-empty
    graph.runtime/reusable-production-case))

;; : (-> Object Object PooFlowGraphBranchChoice)
(def (poo-flow-graph-branch-choice from to)
  (let ((from-value from)
        (to-value to))
    (.o (kind +poo-flow-graph-branch-choice-kind+)
        (from from-value)
        (to to-value))))

;; : (-> Object Boolean)
(def (poo-flow-graph-branch-choice? value)
  (and (object? value)
       (eq? (.ref value 'kind)
            +poo-flow-graph-branch-choice-kind+)))

;; : (-> Symbol Object Object [PooFlowGraphBranchChoice] Nat Boolean Boolean Boolean Boolean Boolean Boolean Boolean PooFlowGraphRuntimePolicy)
(def (poo-flow-graph-runtime-policy name
                                    entry-id
                                    finish-id
                                    branch-choices
                                    fuel
                                    sandbox-scope-contained?
                                    tool-permissions-contained?
                                    checkpoint-persisted?
                                    human-approval-required?
                                    human-approved?
                                    subagents-parented?
                                    handoff-required?)
  (let ((name-value name)
        (entry-id-value entry-id)
        (finish-id-value finish-id)
        (branch-choices-value branch-choices)
        (fuel-value fuel)
        (sandbox-scope-contained-value sandbox-scope-contained?)
        (tool-permissions-contained-value tool-permissions-contained?)
        (checkpoint-persisted-value checkpoint-persisted?)
        (human-approval-required-value human-approval-required?)
        (human-approved-value human-approved?)
        (subagents-parented-value subagents-parented?)
        (handoff-required-value handoff-required?))
    (.o (kind +poo-flow-graph-runtime-policy-kind+)
        (name name-value)
        (entry-id entry-id-value)
        (finish-id finish-id-value)
        (branch-choices branch-choices-value)
        (fuel fuel-value)
        (sandbox-scope-contained sandbox-scope-contained-value)
        (tool-permissions-contained tool-permissions-contained-value)
        (checkpoint-persisted checkpoint-persisted-value)
        (human-approval-required human-approval-required-value)
        (human-approved human-approved-value)
        (subagents-parented subagents-parented-value)
        (handoff-required handoff-required-value))))

;; : (-> Object Boolean)
(def (poo-flow-graph-runtime-policy? value)
  (and (object? value)
       (eq? (.ref value 'kind)
            +poo-flow-graph-runtime-policy-kind+)))

;; : (-> Object Boolean)
(def (poo-flow-graph-runtime-receipt? value)
  (and (object? value)
       (eq? (.ref value 'kind)
            +poo-flow-graph-runtime-receipt-kind+)))

;; : (-> PooFlowGraph PooFlowGraphRuntimePolicy PooFlowGraphRuntimeReceipt)
(def (poo-flow-graph-runtime-execute graph-value policy)
  (let* ((fuel (.ref policy 'fuel))
         (max-steps (+ 1 (* (+ fuel 1)
                            (+ 1 (length (poo-flow-graph-edges graph-value)))))))
    (runtime-walk graph-value
                  policy
                  (.ref policy 'entry-id)
                  (.ref policy 'branch-choices)
                  fuel
                  (list (.ref policy 'entry-id))
                  0
                  max-steps
                  '())))

;; : (-> PooFlowGraph PooFlowGraphRuntimePolicy Object [PooFlowGraphBranchChoice] Nat [Object] Nat Nat Alist PooFlowGraphRuntimeReceipt)
(def (runtime-walk graph-value
                   policy
                   current-id
                   branch-choices
                   fuel
                   trace-rev
                   step-count
                   max-steps
                   diagnostics-rev)
  (cond
   ((> step-count max-steps)
    (runtime-receipt graph-value
                     policy
                     (reverse trace-rev)
                     fuel
                     current-id
                     #f
                     (reverse
                      (cons (cons 'max-steps-exceeded max-steps)
                            diagnostics-rev))))
   ((equal? current-id (.ref policy 'finish-id))
    (runtime-receipt graph-value
                     policy
                     (reverse trace-rev)
                     fuel
                     current-id
                     #t
                     (reverse diagnostics-rev)))
   (else
    (let* ((selection
            (runtime-select-edge current-id
                                 (poo-flow-graph-edges graph-value)
                                 branch-choices))
           (edge (car selection))
           (branch-choices* (cadr selection))
           (diagnostic (caddr selection)))
      (cond
       (diagnostic
        (runtime-receipt graph-value
                         policy
                         (reverse trace-rev)
                         fuel
                         current-id
                         #f
                         (reverse (cons diagnostic diagnostics-rev))))
       ((and (runtime-loop-edge? edge)
             (= fuel 0))
        (runtime-receipt graph-value
                         policy
                         (reverse trace-rev)
                         fuel
                         current-id
                         #f
                         (reverse
                          (cons (cons 'fuel-exhausted current-id)
                                diagnostics-rev))))
       (else
        (let* ((next-id (poo-flow-graph-edge-to edge))
               (fuel* (if (runtime-loop-edge? edge)
                        (- fuel 1)
                        fuel)))
          (runtime-walk graph-value
                        policy
                        next-id
                        branch-choices*
                        fuel*
                        (cons next-id trace-rev)
                        (+ step-count 1)
                        max-steps
                        diagnostics-rev))))))))

;; : (-> Object [PooFlowGraphEdge] [PooFlowGraphBranchChoice] [MaybeEdge [PooFlowGraphBranchChoice] MaybeDiagnostic])
(def (runtime-select-edge current-id edges branch-choices)
  (let* ((outgoing (runtime-outgoing-edges current-id edges))
         (choice-result
          (runtime-next-branch-choice current-id branch-choices))
         (choice (car choice-result))
         (branch-choices* (cadr choice-result)))
    (cond
     ((null? outgoing)
      (list #f branch-choices (cons 'dead-end current-id)))
     (choice
      (let ((edge (runtime-edge-to (poo-flow-graph-branch-choice-to choice)
                                   outgoing)))
        (if edge
          (list edge branch-choices* #f)
          (list #f branch-choices*
                (cons 'missing-branch-target
                      (poo-flow-graph-branch-choice-to choice))))))
     ((runtime-has-conditional-edge? outgoing)
      (list #f branch-choices (cons 'missing-branch-choice current-id)))
     (else
      (list (car outgoing) branch-choices #f)))))

;; : (-> PooFlowGraph PooFlowGraphRuntimePolicy [Object] Nat Object Boolean Alist PooFlowGraphRuntimeReceipt)
(def (runtime-receipt graph-value
                      policy
                      trace
                      fuel-after
                      current-id
                      finished?
                      diagnostics)
  (let* ((handoff-reached?
          (and finished?
               (or (not (.ref policy 'handoff-required))
                   (equal? current-id (.ref policy 'finish-id)))))
         (human-approval-sound?
          (or (not (.ref policy 'human-approval-required))
              (.ref policy 'human-approved)))
         (loop-fuel-contained?
          (>= fuel-after 0))
         (diagnostics*
          (runtime-final-diagnostics diagnostics
                                     policy
                                     handoff-reached?
                                     human-approval-sound?)))
    (let ((graph-id-value (poo-flow-graph-id graph-value))
          (policy-name-value (.ref policy 'name))
          (entry-id-value (.ref policy 'entry-id))
          (finish-id-value (.ref policy 'finish-id))
          (trace-value trace)
          (fuel-before-value (.ref policy 'fuel))
          (fuel-after-value fuel-after)
          (current-id-value current-id)
          (finished-value finished?)
          (loop-fuel-contained-value loop-fuel-contained?)
          (handoff-reached-value handoff-reached?)
          (sandbox-scope-contained-value
           (.ref policy 'sandbox-scope-contained))
          (tool-permissions-contained-value
           (.ref policy 'tool-permissions-contained))
          (checkpoint-persisted-value
           (.ref policy 'checkpoint-persisted))
          (human-approval-required-value
           (.ref policy 'human-approval-required))
          (human-approved-value (.ref policy 'human-approved))
          (human-approval-sound-value human-approval-sound?)
          (subagents-parented-value (.ref policy 'subagents-parented))
          (diagnostics-value diagnostics*))
      (.o (kind +poo-flow-graph-runtime-receipt-kind+)
          (schema 'poo-flow.graph.runtime-receipt.v1)
          (graph-id graph-id-value)
          (policy-name policy-name-value)
          (entry-id entry-id-value)
          (finish-id finish-id-value)
          (trace trace-value)
          (fuel-before fuel-before-value)
          (fuel-after fuel-after-value)
          (current-id current-id-value)
          (finished finished-value)
          (loop-fuel-contained loop-fuel-contained-value)
          (handoff-reached handoff-reached-value)
          (sandbox-scope-contained sandbox-scope-contained-value)
          (tool-permissions-contained tool-permissions-contained-value)
          (checkpoint-persisted checkpoint-persisted-value)
          (human-approval-required human-approval-required-value)
          (human-approved human-approved-value)
          (human-approval-sound human-approval-sound-value)
          (subagents-parented subagents-parented-value)
          (diagnostics diagnostics-value)
          (runtime-executed #t)))))

;; : (-> Alist PooFlowGraphRuntimePolicy Boolean Boolean Alist)
(def (runtime-final-diagnostics diagnostics
                                policy
                                handoff-reached?
                                human-approval-sound?)
  (let* ((diagnostics
          (if (.ref policy 'sandbox-scope-contained)
            diagnostics
            (cons (cons 'sandbox-scope-not-contained
                        (.ref policy 'name))
                  diagnostics)))
         (diagnostics
          (if (.ref policy 'tool-permissions-contained)
            diagnostics
            (cons (cons 'tool-permissions-not-contained
                        (.ref policy 'name))
                  diagnostics)))
         (diagnostics
          (if (.ref policy 'checkpoint-persisted)
            diagnostics
            (cons (cons 'checkpoint-not-persisted
                        (.ref policy 'name))
                  diagnostics)))
         (diagnostics
          (if human-approval-sound?
            diagnostics
            (cons (cons 'human-approval-missing
                        (.ref policy 'name))
                  diagnostics)))
         (diagnostics
          (if (.ref policy 'subagents-parented)
            diagnostics
            (cons (cons 'subagents-not-parented
                        (.ref policy 'name))
                  diagnostics)))
         (diagnostics
          (if handoff-reached?
            diagnostics
            (cons (cons 'handoff-not-reached
                        (.ref policy 'name))
                  diagnostics))))
    diagnostics))

;; : (-> PooFlowGraphRuntimeReceipt Alist)
(def (poo-flow-graph-runtime-receipt->lean-facts receipt)
  (let* ((diagnostics-empty? (null? (.ref receipt 'diagnostics)))
         (reusable-production-case?
          (and (.ref receipt 'runtime-executed)
               (.ref receipt 'finished)
               (.ref receipt 'loop-fuel-contained)
               (.ref receipt 'handoff-reached)
               (.ref receipt 'sandbox-scope-contained)
               (.ref receipt 'tool-permissions-contained)
               (.ref receipt 'checkpoint-persisted)
               (.ref receipt 'human-approval-sound)
               (.ref receipt 'subagents-parented)
               diagnostics-empty?)))
    (list
     (cons 'graph.runtime/executed (.ref receipt 'runtime-executed))
     (cons 'graph.runtime/finished (.ref receipt 'finished))
     (cons 'graph.runtime/loop-fuel-contained
           (.ref receipt 'loop-fuel-contained))
     (cons 'graph.runtime/handoff-reached
           (.ref receipt 'handoff-reached))
     (cons 'graph.runtime/sandbox-scope-contained
           (.ref receipt 'sandbox-scope-contained))
     (cons 'graph.runtime/tool-permissions-contained
           (.ref receipt 'tool-permissions-contained))
     (cons 'graph.runtime/checkpoint-persisted
           (.ref receipt 'checkpoint-persisted))
     (cons 'graph.runtime/human-approval-sound
           (.ref receipt 'human-approval-sound))
     (cons 'graph.runtime/subagents-parented
           (.ref receipt 'subagents-parented))
     (cons 'graph.runtime/diagnostics-empty diagnostics-empty?)
     (cons 'graph.runtime/reusable-production-case
           reusable-production-case?))))

;; : (-> Alist Boolean)
(def (poo-flow-graph-runtime-lean-fact-contract-complete? facts)
  (and (andmap (lambda (key)
                 (and (assq key facts) #t))
               poo-flow-graph-runtime-lean-fact-keys)
       (andmap (lambda (fact)
                 (and (pair? fact)
                      (memq (car fact)
                            poo-flow-graph-runtime-lean-fact-keys)
                      #t))
               facts)))

;; : (-> PooFlowGraphRuntimeReceipt [String] String)
(def (poo-flow-graph-runtime-receipt->lean-module receipt
                                                  . maybe-namespace)
  (let* ((namespace (if (null? maybe-namespace)
                     "PooFlowProof.Generated.LangChainLangGraphRuntime"
                     (car maybe-namespace)))
         (facts (poo-flow-graph-runtime-receipt->lean-facts receipt)))
    (string-append
     "import PooFlowProof.PooC3.LangChainLangGraph\n\n"
     "namespace " namespace "\n\n"
     "open PooFlowProof.PooC3.LangChainLangGraph\n\n"
     "def generatedRuntimeFactRows : List (String × Bool) :=\n"
     (runtime-lean-fact-rows-source facts)
     "\n\n"
     "def generatedProductionRuntimeFacts : ProductionRuntimeFacts where\n"
     "  runtimeExecuted := "
     (runtime-lean-prop (runtime-lean-fact facts 'graph.runtime/executed))
     "\n"
     "  finished := "
     (runtime-lean-prop (runtime-lean-fact facts 'graph.runtime/finished))
     "\n"
     "  loopFuelContained := "
     (runtime-lean-prop
      (runtime-lean-fact facts 'graph.runtime/loop-fuel-contained))
     "\n"
     "  handoffReached := "
     (runtime-lean-prop
      (runtime-lean-fact facts 'graph.runtime/handoff-reached))
     "\n"
     "  sandboxScopeContained := "
     (runtime-lean-prop
      (runtime-lean-fact facts 'graph.runtime/sandbox-scope-contained))
     "\n"
     "  toolPermissionsContained := "
     (runtime-lean-prop
      (runtime-lean-fact facts 'graph.runtime/tool-permissions-contained))
     "\n"
     "  checkpointPersisted := "
     (runtime-lean-prop
      (runtime-lean-fact facts 'graph.runtime/checkpoint-persisted))
     "\n"
     "  humanApprovalSound := "
     (runtime-lean-prop
      (runtime-lean-fact facts 'graph.runtime/human-approval-sound))
     "\n"
     "  subagentsParented := "
     (runtime-lean-prop
      (runtime-lean-fact facts 'graph.runtime/subagents-parented))
     "\n"
     "  diagnosticsEmpty := "
     (runtime-lean-prop
      (runtime-lean-fact facts 'graph.runtime/diagnostics-empty))
     "\n\n"
     "theorem generatedProductionRuntimeReusable :\n"
     "    ReusableProductionRuntime generatedProductionRuntimeFacts := by\n"
     "  repeat constructor\n\n"
     "theorem generatedProductionRuntimeCheckpointAndHumanGate :\n"
     "    generatedProductionRuntimeFacts.checkpointPersisted /\\\n"
     "      generatedProductionRuntimeFacts.humanApprovalSound :=\n"
     "  production_runtime_has_checkpoint_and_human_gate\n"
     "    generatedProductionRuntimeReusable\n\n"
     "theorem generatedProductionRuntimeScopeAndToolContainment :\n"
     "    generatedProductionRuntimeFacts.sandboxScopeContained /\\\n"
     "      generatedProductionRuntimeFacts.toolPermissionsContained :=\n"
     "  production_runtime_has_scope_and_tool_containment\n"
     "    generatedProductionRuntimeReusable\n\n"
     "end " namespace "\n")))

;; : (-> Alist Symbol Boolean)
(def (runtime-lean-fact facts key)
  (let ((cell (assq key facts)))
    (and cell (cdr cell))))

;; : (-> Boolean String)
(def (runtime-lean-prop value)
  (if value "True" "False"))

;; : (-> Boolean String)
(def (runtime-lean-bool value)
  (if value "true" "false"))

;; : (-> Alist String)
(def (runtime-lean-fact-rows-source facts)
  (runtime-lean-fact-rows-source-loop
   poo-flow-graph-runtime-lean-fact-keys
   facts
   #t))

;; : (-> [Symbol] Alist Boolean String)
(def (runtime-lean-fact-rows-source-loop keys facts first?)
  (cond
   ((null? keys) "  []")
   (else
    (string-append
     "  "
     (if first? "[" ",")
     " (\""
     (symbol->string (car keys))
     "\", "
     (runtime-lean-bool (runtime-lean-fact facts (car keys)))
     ")"
     (runtime-lean-fact-rows-source-tail (cdr keys) facts)))))

;; : (-> [Symbol] Alist String)
(def (runtime-lean-fact-rows-source-tail keys facts)
  (cond
   ((null? keys) "\n  ]")
   (else
    (string-append
     "\n"
     (runtime-lean-fact-rows-source-loop keys facts #f)))))

;; : (-> PooFlowGraphBranchChoice Object)
(def (poo-flow-graph-branch-choice-to choice)
  (.ref choice 'to))

;; : (-> Object [PooFlowGraphEdge] [PooFlowGraphEdge])
(def (runtime-outgoing-edges current-id edges)
  (cond
   ((null? edges) '())
   ((equal? current-id (poo-flow-graph-edge-from (car edges)))
    (cons (car edges)
          (runtime-outgoing-edges current-id (cdr edges))))
   (else
    (runtime-outgoing-edges current-id (cdr edges)))))

;; : (-> Object [PooFlowGraphEdge] MaybeEdge)
(def (runtime-edge-to target-id edges)
  (cond
   ((null? edges) #f)
   ((equal? target-id (poo-flow-graph-edge-to (car edges)))
    (car edges))
   (else
    (runtime-edge-to target-id (cdr edges)))))

;; : (-> PooFlowGraphEdge Boolean)
(def (runtime-loop-edge? edge)
  (memq (poo-flow-graph-edge-kind edge)
        '(loop back-edge retry self-loop)))

;; : (-> PooFlowGraphEdge Boolean)
(def (runtime-conditional-edge? edge)
  (memq (poo-flow-graph-edge-kind edge)
        '(conditional branch router)))

;; : (-> [PooFlowGraphEdge] Boolean)
(def (runtime-has-conditional-edge? edges)
  (cond
   ((null? edges) #f)
   ((runtime-conditional-edge? (car edges)) #t)
   (else
    (runtime-has-conditional-edge? (cdr edges)))))

;; : (-> Object [PooFlowGraphBranchChoice] [MaybeChoice [PooFlowGraphBranchChoice]])
(def (runtime-next-branch-choice current-id branch-choices)
  (runtime-next-branch-choice/rev current-id branch-choices '()))

;; : (-> Object [PooFlowGraphBranchChoice] [PooFlowGraphBranchChoice] [MaybeChoice [PooFlowGraphBranchChoice]])
(def (runtime-next-branch-choice/rev current-id branch-choices prefix-rev)
  (cond
   ((null? branch-choices)
    (list #f (reverse prefix-rev)))
   ((equal? current-id (.ref (car branch-choices) 'from))
    (list (car branch-choices)
          (append (reverse prefix-rev) (cdr branch-choices))))
   (else
    (runtime-next-branch-choice/rev current-id
                                    (cdr branch-choices)
                                    (cons (car branch-choices)
                                          prefix-rev)))))
