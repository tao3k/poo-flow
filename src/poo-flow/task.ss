;;; -*- Gerbil -*-
;;; Boundary: tasks describe work intent and adapter request shape.
;;; Invariant: only pure/scheme tasks carry an in-process executor.

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

;;; The request field is symbolic control-plane data; the executor slot is
;;; present only for local task kinds.
;; Task <- Symbol Symbol Request Contract Contract Executor
(defstruct task
  (name
   kind
   request
   input-contract
   output-contract
   executor)
  transparent: #t)

;;; Normalized requests are the adapter boundary format shared by store and
;;; external tasks.
;; ExecutionRequest <- Symbol Symbol Request Value Contract Contract
(defstruct execution-request
  (name
   kind
   request
   input
   input-contract
   output-contract)
  transparent: #t)

;; Task <- Symbol Procedure Contract Contract
(def (make-pure-task name proc input-contract output-contract)
  (make-task name 'pure (list 'pure name) input-contract output-contract proc))

;; Task <- Symbol Procedure Contract Contract
(def (make-scheme-task name proc input-contract output-contract)
  (make-task name 'scheme (list 'scheme name) input-contract output-contract proc))

;; Task <- Symbol Symbol Payload Contract Contract
(def (make-store-task name operation payload input-contract output-contract)
  (make-task name 'store (list 'store operation payload) input-contract output-contract #f))

;; Task <- Symbol Symbol Payload Contract Contract
(def (make-external-task name operation payload input-contract output-contract)
  (make-task name 'external (list 'external operation payload) input-contract output-contract #f))

;; Boolean <- Task
(def (task-local? task)
  (or (eq? (task-kind task) 'pure)
      (eq? (task-kind task) 'scheme)))

;; Boolean <- Task
(def (task-adapter-routed? task)
  (or (eq? (task-kind task) 'store)
      (eq? (task-kind task) 'external)))

;; ExecutionRequest <- Task Value
(def (task-normalized-request task input)
  (make-execution-request (task-name task)
                          (task-kind task)
                          (task-request task)
                          input
                          (task-input-contract task)
                          (task-output-contract task)))
