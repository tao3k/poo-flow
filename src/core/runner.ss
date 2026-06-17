;;; -*- Gerbil -*-
;;; Boundary: runner interprets plans and emits receipts.
;;; Invariant: adapter calls remain behind runtime-adapter functions.

(import :core/receipt
        :core/task
        :core/flow
        :core/plan
        :core/strategy
        :core/runtime-adapter)

(export make-run-result
        run-result?
        run-result-value
        run-result-receipt
        make-runner
        runner?
        runner-strategy
        runner-adapter
        runner-plan
        runner-validate
        runner-run)

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

;; Boolean <- Runner Flow
(def (runner-validate runner flow)
  (runner-validate-plan runner (runner-plan runner flow)))

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
  (unless (memq (task-kind task) (strategy-capabilities strategy))
    (error "strategy does not support task kind" (task-kind task)))
  (when (task-adapter-routed? task)
    (unless (adapter-supports? adapter (task-kind task))
      (error "adapter does not support task kind" (task-kind task)))))

;;; Execution returns both the final value and a root receipt that contains the
;;; child receipts produced by each planned step.
;; RunResult <- Runner Flow Input
(def (runner-run runner flow input)
  (let ((strategy (runner-strategy runner)))
    (let ((plan (runner-plan runner flow)))
      (runner-validate-plan runner plan)
      (let ((result (run-plan-nodes runner plan strategy (execution-plan-nodes plan) input '())))
        (let ((value (car result))
              (children (reverse (cdr result))))
          (make-run-result
           value
           (make-receipt (execution-plan-flow-name plan)
                         #f
                         'flow
                         (strategy-name strategy)
                         'local
                         #f
                         input
                         value
                         'no-cache
                         'ok
                         #f
                         children)))))))

;;; Boundary: this recursive driver is the sequential interpreter loop.
;;; Invariant: it preserves execution order while accumulating receipt evidence.
;; StepSequenceResult <- Runner ExecutionPlan Strategy [PlanNode] Input [Receipt]
(def (run-plan-nodes runner plan strategy nodes input receipts)
  (if (null? nodes)
    (cons input receipts)
    (let* ((node (car nodes))
           (step-result (run-plan-node runner plan strategy node input))
           (value (car step-result))
           (receipt (cdr step-result)))
      (run-plan-nodes runner plan strategy (cdr nodes) value (cons receipt receipts)))))

;; StepResult <- Runner ExecutionPlan Strategy PlanNode Input
(def (run-plan-node runner plan strategy node input)
  (let ((step (plan-node-step node)))
    (cond
     ((task? step)
      (run-task runner plan strategy step input))
     ((flow? step)
      (let ((nested (runner-run runner step input)))
        (cons (run-result-value nested) (run-result-receipt nested))))
     (else
      (error "flow step is neither task nor flow" step)))))

;;; Boundary: local tasks run in-process, while routed tasks cross the adapter.
;;; Invariant: both branches return the same value/receipt pair shape.
;; StepResult <- Runner ExecutionPlan Strategy Task Input
(def (run-task runner plan strategy task input)
  (cond
   ((strategy-can-run-locally? strategy task)
    (let ((value ((task-executor task) input)))
      (cons value
            (make-receipt (execution-plan-flow-name plan)
                          (task-name task)
                          (task-kind task)
                          (strategy-name strategy)
                          'local
                          #f
                          input
                          value
                          (strategy-cache-policy strategy)
                          'ok
                          #f
                          '()))))
   ((task-adapter-routed? task)
    (let* ((request (task-normalized-request task input))
           (adapter-result (adapter-submit (runner-adapter runner) request)))
      (cons adapter-result
            (make-receipt (execution-plan-flow-name plan)
                          (task-name task)
                          (task-kind task)
                          (strategy-name strategy)
                          (runtime-adapter-name (runner-adapter runner))
                          (adapter-result-request-id adapter-result)
                          input
                          adapter-result
                          (strategy-cache-policy strategy)
                          (adapter-result-status adapter-result)
                          (adapter-result-error adapter-result)
                          '()))))
   (else
    (error "unsupported task kind" (task-kind task)))))
