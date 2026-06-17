(import :poo-flow/receipt
        :poo-flow/task
        :poo-flow/flow
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
  (let ((strategy (runner-strategy runner))
        (adapter (runner-adapter runner)))
    (for-each (lambda (step) (validate-step strategy adapter step))
              (flow-steps flow))
    #t))

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
  (runner-validate runner flow)
  (let ((strategy (runner-strategy runner)))
    (let ((result (run-steps runner flow strategy (runner-plan runner flow) input '())))
      (let ((value (car result))
            (children (reverse (cdr result))))
        (make-run-result
         value
         (make-receipt (flow-name flow)
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
                       children))))))

(def (run-steps runner flow strategy steps input receipts)
  (if (null? steps)
    (cons input receipts)
    (let* ((step (car steps))
           (step-result (run-step runner flow strategy step input))
           (value (car step-result))
           (receipt (cdr step-result)))
      (run-steps runner flow strategy (cdr steps) value (cons receipt receipts)))))

(def (run-step runner flow strategy step input)
  (cond
   ((task? step)
    (run-task runner flow strategy step input))
   ((flow? step)
    (let ((nested (runner-run runner step input)))
      (cons (run-result-value nested) (run-result-receipt nested))))
   (else
    (error "flow step is neither task nor flow" step))))

(def (run-task runner flow strategy task input)
  (cond
   ((strategy-can-run-locally? strategy task)
    (let ((value ((task-executor task) input)))
      (cons value
            (make-receipt (flow-name flow)
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
            (make-receipt (flow-name flow)
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
