(import :poo-flow/receipt
        :poo-flow/task
        :poo-flow/flow
        :poo-flow/plan
        :poo-flow/strategy
        :poo-flow/runtime-adapter)

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

(defstruct run-result
  (value receipt)
  transparent: #t)

(defstruct runner
  (strategy adapter)
  transparent: #t)

(def (runner-plan runner flow)
  (strategy-plan (runner-strategy runner) flow))

(def (runner-validate runner flow)
  (runner-validate-plan runner (runner-plan runner flow)))

(def (runner-validate-plan runner plan)
  (let ((strategy (runner-strategy runner))
        (adapter (runner-adapter runner)))
    (for-each (lambda (node) (validate-plan-node strategy adapter node))
              (execution-plan-nodes plan))
    #t))

(def (validate-plan-node strategy adapter node)
  (validate-step strategy adapter (plan-node-step node)))

(def (validate-step strategy adapter step)
  (when (task? step)
    (validate-task strategy adapter step)))

(def (validate-task strategy adapter task)
  (unless (memq (task-kind task) (strategy-capabilities strategy))
    (error "strategy does not support task kind" (task-kind task)))
  (when (task-adapter-routed? task)
    (unless (adapter-supports? adapter (task-kind task))
      (error "adapter does not support task kind" (task-kind task)))))

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

(def (run-plan-nodes runner plan strategy nodes input receipts)
  (if (null? nodes)
    (cons input receipts)
    (let* ((node (car nodes))
           (step-result (run-plan-node runner plan strategy node input))
           (value (car step-result))
           (receipt (cdr step-result)))
      (run-plan-nodes runner plan strategy (cdr nodes) value (cons receipt receipts)))))

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
