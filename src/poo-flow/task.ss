(export make-task
        task?
        task-name
        task-kind
        task-request
        task-input-contract
        task-output-contract
        task-executor
        make-pure-task
        make-scheme-task
        make-store-task
        make-external-task
        task-local?
        task-adapter-routed?
        task-normalized-request
        make-execution-request
        execution-request?
        execution-request-name
        execution-request-kind
        execution-request-request
        execution-request-input
        execution-request-input-contract
        execution-request-output-contract)

(defstruct task
  (name
   kind
   request
   input-contract
   output-contract
   executor)
  transparent: #t)

(defstruct execution-request
  (name
   kind
   request
   input
   input-contract
   output-contract)
  transparent: #t)

(def (make-pure-task name proc input-contract output-contract)
  (make-task name 'pure (list 'pure name) input-contract output-contract proc))

(def (make-scheme-task name proc input-contract output-contract)
  (make-task name 'scheme (list 'scheme name) input-contract output-contract proc))

(def (make-store-task name operation payload input-contract output-contract)
  (make-task name 'store (list 'store operation payload) input-contract output-contract #f))

(def (make-external-task name operation payload input-contract output-contract)
  (make-task name 'external (list 'external operation payload) input-contract output-contract #f))

(def (task-local? task)
  (or (eq? (task-kind task) 'pure)
      (eq? (task-kind task) 'scheme)))

(def (task-adapter-routed? task)
  (or (eq? (task-kind task) 'store)
      (eq? (task-kind task) 'external)))

(def (task-normalized-request task input)
  (make-execution-request (task-name task)
                          (task-kind task)
                          (task-request task)
                          input
                          (task-input-contract task)
                          (task-output-contract task)))
