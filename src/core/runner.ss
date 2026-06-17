;;; -*- Gerbil -*-
;;; Boundary: runner interprets plans and emits receipts.
;;; Invariant: adapter calls remain behind runtime-adapter functions.

(import :core/receipt
        :core/task
        :core/flow
        :core/plan
        :core/strategy
        :core/policy
        :core/runtime-adapter
        :core/replay)

(export make-run-result
        run-result?
        run-result-value
        run-result-receipt
        make-runner
        runner?
        runner-strategy
        runner-adapter
        runner-plan
        runner-ready-frontier
        runner-ready-frontier-ids
        runner-validate
        runner-run
        runner-run-replay-report)

;; RunResult <- Value Receipt
(defstruct run-result
  (value receipt)
  transparent: #t)

;; Runner <- Strategy RuntimeAdapter
(defstruct runner
  (strategy adapter)
  transparent: #t)

;; ExecutionPlan <- Runner Flow
(def (runner-plan runner flow)
  (strategy-plan (runner-strategy runner) flow))

;;; Frontier queries follow the same runner boundary as execution: flow is
;;; lowered once, then strategy decides which graph facts are policy-visible.
;; [PlanNode] <- Runner Flow [Id]
(def (runner-ready-frontier runner flow completed-node-ids)
  (let ((strategy (runner-strategy runner)))
    (strategy-ready-frontier strategy
                             (runner-plan runner flow)
                             completed-node-ids)))

;;; Id-only frontier output is the adapter-friendly form; it avoids leaking
;;; task closures or Scheme plan-node payloads across runtime boundaries.
;; [Id] <- Runner Flow [Id]
(def (runner-ready-frontier-ids runner flow completed-node-ids)
  (let ((strategy (runner-strategy runner)))
    (strategy-ready-frontier-ids strategy
                                 (runner-plan runner flow)
                                 completed-node-ids)))

;; Boolean <- Runner Flow
(def (runner-validate runner flow)
  (runner-validate-plan runner (runner-plan runner flow)))

;;; Replay reporting runs the normal interpreter first, then validates the
;;; emitted receipt against the same plan that drove execution.
;; ReplayReport <- Runner Flow Input
(def (runner-run-replay-report runner flow input)
  (let* ((plan (runner-plan runner flow))
         (result (runner-run runner flow input)))
    (validate-replay-report plan (run-result-receipt result))))

;;; Boundary: validation is the only pre-run traversal over planned nodes.
;;; Invariant: each node is checked against both strategy and adapter support.
;; Boolean <- Runner ExecutionPlan
(def (runner-validate-plan runner plan)
  (let ((strategy (runner-strategy runner))
        (adapter (runner-adapter runner)))
    (for-each (lambda (node) (validate-plan-node strategy adapter node))
              (execution-plan-nodes plan))
    #t))

;; Boolean <- Strategy RuntimeAdapter PlanNode
(def (validate-plan-node strategy adapter node)
  (validate-step strategy adapter (plan-node-step node)))

;; Boolean <- Strategy RuntimeAdapter Step
(def (validate-step strategy adapter step)
  (when (task? step)
    (validate-task strategy adapter step)))

;; Boolean <- Strategy RuntimeAdapter Task
(def (validate-task strategy adapter task)
  (unless (memq (task-capability task) (strategy-capabilities strategy))
    (error "strategy does not support task kind" (task-kind task)))
  (when (task-adapter-routed? task)
    (unless (adapter-supports? adapter (task-capability task))
      (error "adapter does not support task kind" (task-kind task)))))

;;; Execution returns both the final value and a root receipt that contains the
;;; child receipts produced by each planned step.
;; RunResult <- Runner Flow Input
(def (runner-run runner flow input)
  (let ((strategy (runner-strategy runner)))
    (let ((plan (runner-plan runner flow)))
      (runner-validate-plan runner plan)
      (let ((result (run-plan-nodes runner plan strategy (execution-plan-nodes plan) input '() '() '())))
        (let ((value (car result))
              (children (reverse (cdr result)))
              (root-frontier (strategy-ready-frontier-ids strategy plan '())))
          (make-run-result
           value
           (make-receipt (execution-plan-flow-name plan)
                         #f
                         'flow
                         #f
                         (strategy-name strategy)
                         (execution-policy->alist
                          (strategy-execution-policy strategy root-frontier))
                         'local
                         #f
                         input
                         value
                         'no-cache
                         root-frontier
                         'ok
                         #f
                         children)))))))

;;; Boundary: this recursive driver is the topology interpreter loop.
;;; Invariant: completed ids are audit state for frontier receipts, while the
;;; values table is the dataflow state used to feed dependency outputs into
;;; later DAG nodes.
;; StepSequenceResult <- Runner ExecutionPlan Strategy [PlanNode] Input [Id] [Receipt] Alist
(def (run-plan-nodes runner plan strategy nodes input completed-node-ids receipts values)
  (if (null? nodes)
    (cons (plan-output-value plan values input) receipts)
    (let* ((node (car nodes))
           (frontier (strategy-ready-frontier-ids strategy plan completed-node-ids))
           (node-input (node-input-value node values input))
           (step-result (run-plan-node runner plan strategy node node-input frontier))
           (value (car step-result))
           (receipt (cdr step-result))
           (completed (cons (plan-node-id node) completed-node-ids))
           (next-values (cons (cons (plan-node-id node) value) values)))
      (run-plan-nodes runner plan strategy (cdr nodes) input completed (cons receipt receipts) next-values))))

;;; Node dispatch stays shape-based: task nodes execute work, flow nodes wrap
;;; nested runs, and branch nodes join dependency values.
;; StepResult <- Runner ExecutionPlan Strategy PlanNode Input [Id]
(def (run-plan-node runner plan strategy node input frontier)
  (let ((step (plan-node-step node)))
    (cond
     ((task? step)
      (run-task runner plan strategy node step input frontier))
     ((flow? step)
      (let ((nested (runner-run runner step input)))
        (cons (run-result-value nested)
              (make-flow-step-receipt plan strategy node step input frontier nested))))
     ((branch-step? step)
      (cons input
            (make-branch-receipt plan strategy node step input frontier)))
     (else
      (error "flow step is neither task nor flow" step)))))

;;; Flow nodes wrap nested receipts so top-level replay can still match each
;;; planned DAG node to one top-level child receipt.
;; Receipt <- ExecutionPlan Strategy PlanNode Flow Input [Id] RunResult
(def (make-flow-step-receipt plan strategy node flow input frontier nested)
  (make-receipt (execution-plan-flow-name plan)
                (flow-name flow)
                (plan-node-kind node)
                (plan-node-id node)
                (strategy-name strategy)
                (execution-policy->alist
                 (strategy-execution-policy strategy frontier))
                'local
                #f
                input
                (run-result-value nested)
                'no-cache
                frontier
                'ok
                #f
                (list (run-result-receipt nested))))

;;; Branch join nodes are local control-plane joins: their input is the list of
;;; dependency values produced by branch arms.
;; Receipt <- ExecutionPlan Strategy PlanNode BranchStep Value [Id]
(def (make-branch-receipt plan strategy node branch input frontier)
  (make-receipt (execution-plan-flow-name plan)
                (branch-step-name branch)
                'branch
                (plan-node-id node)
                (strategy-name strategy)
                (execution-policy->alist
                 (strategy-execution-policy strategy frontier))
                'local
                #f
                input
                input
                'no-cache
                frontier
                'ok
                #f
                '()))

;;; Terminal selection converts the dataflow table back to the public run
;;; result. Multiple terminals remain a list so future DAG plans can expose
;;; more than one sink without inventing an implicit ordering rule.
;; Value <- ExecutionPlan Alist Value
(def (plan-output-value plan values default-input)
  (let ((terminal-values (node-values (map plan-node-id
                                           (execution-plan-terminal-nodes plan))
                                      values)))
    (cond
     ((null? terminal-values) default-input)
     ((null? (cdr terminal-values)) (car terminal-values))
     (else terminal-values))))

;;; Node input selection follows dependency cardinality: roots receive the
;;; original input, one dependency passes a scalar value, and joins receive the
;;; ordered dependency value list.
;; Value <- PlanNode Alist Value
(def (node-input-value node values default-input)
  (let ((dependencies (plan-node-dependencies node)))
    (cond
     ((null? dependencies) default-input)
     ((null? (cdr dependencies)) (value-for-node-id (car dependencies) values))
     (else (node-values dependencies values)))))

;;; Dependency ids are already in plan order, so this projection preserves the
;;; branch-left and branch-right ordering expected by join receipts.
;; [Value] <- [Id] Alist
(def (node-values ids values)
  (if (null? ids)
    '()
    (cons (value-for-node-id (car ids) values)
          (node-values (cdr ids) values))))

;;; Missing dependency values indicate a malformed plan order rather than an
;;; application failure, so the runner raises a control-plane error.
;; Value <- Id Alist
(def (value-for-node-id id values)
  (let ((entry (assoc id values)))
    (if entry
      (cdr entry)
      (error "missing dependency value" id))))

;;; Adapter dispatch preserves store put/get as first-class task-family
;;; operations; external tasks still use the generic submit slot.
;; AdapterResult <- RuntimeAdapter Task ExecutionRequest
(def (adapter-result-for-task adapter task request)
  (let ((operation (task-adapter-operation task)))
    (cond
     ((eq? operation 'store-put)
      (adapter-store-put adapter request))
     ((eq? operation 'store-get)
      (adapter-store-get adapter (task-store-payload task)))
     ((eq? operation 'submit)
      (adapter-submit adapter request))
     (else
      (error "unsupported adapter operation" operation)))))

;;; Adapter cache evidence is derived after runtime handoff because only the
;;; adapter result knows whether this was a request-only handoff or a handle hit.
;; CacheDecision <- Strategy Task Input AdapterResult
(def (adapter-cache-decision strategy task input adapter-result)
  (cond
   ((eq? (task-adapter-operation task) 'store-get)
    (list 'cache-hit
          (task-name task)
          (task-store-payload task)
          (adapter-result-artifact-handle adapter-result)))
   ((eq? (adapter-result-status adapter-result) 'requested)
    (list 'cache-request-only
          (task-name task)
          (task-kind task)
          (adapter-result-request-id adapter-result)))
   (else
    (strategy-cache-decision strategy task input adapter-result))))

;;; Boundary: local tasks run in-process, while routed tasks cross the adapter.
;;; Invariant: both branches return the same value/receipt pair shape.
;; StepResult <- Runner ExecutionPlan Strategy PlanNode Task Input [Id]
(def (run-task runner plan strategy node task input frontier)
  (cond
   ((strategy-can-run-locally? strategy task)
    (let* ((policy (execution-policy->alist
                    (strategy-execution-policy strategy frontier)))
           (value ((task-executor task) input))
           (cache (strategy-cache-decision strategy task input value)))
      (cons value
            (make-receipt (execution-plan-flow-name plan)
                          (task-name task)
                          (task-kind task)
                          (plan-node-id node)
                          (strategy-name strategy)
                          policy
                          'local
                          #f
                          input
                          value
                          cache
                          frontier
                          'ok
                          #f
                          '()))))
   ((task-adapter-routed? task)
    (let* ((request (task-adapter-request task
                                           input
                                           (execution-plan-flow-name plan)
                                           (plan-node-id node)
                                           frontier
                                           (strategy-name strategy)
                                           (execution-policy->alist
                                            (strategy-execution-policy strategy frontier))))
           (adapter-result (adapter-result-for-task (runner-adapter runner) task request))
           (cache (adapter-cache-decision strategy task input adapter-result)))
      (cons adapter-result
            (make-receipt (execution-plan-flow-name plan)
                          (task-name task)
                          (task-kind task)
                          (plan-node-id node)
                          (strategy-name strategy)
                          (execution-request-policy request)
                          (runtime-adapter-name (runner-adapter runner))
                          (adapter-result-request-id adapter-result)
                          input
                          adapter-result
                          cache
                          frontier
                          (adapter-result-status adapter-result)
                          (adapter-result-error adapter-result)
                          '()))))
   (else
    (error "unsupported task kind" (task-kind task)))))
