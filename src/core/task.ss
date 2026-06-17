;;; -*- Gerbil -*-
;;; Boundary: tasks describe work intent and adapter request shape.
;;; Invariant: only pure/scheme tasks carry an in-process executor.

(import (only-in :clan/poo/object .o .@ object?)
        :core/roles)

(export make-task
        task?
        task-name
        task-kind
        task-request
        task-input-contract
        task-output-contract
        task-executor
        make-task-family-descriptor
        task-family-descriptor?
        pure-task-family-descriptor
        scheme-task-family-descriptor
        store-task-family-descriptor
        external-task-family-descriptor
        task-family-descriptors
        task-family-name
        task-family-capability
        task-family-route
        task-family-runtime-owner
        task-family-adapter-dispatch
        task-family-for-kind
        task-descriptor
        task-capability
        task-route
        task-runtime-owner
        task-adapter-operation
        make-pure-task
        make-scheme-task
        make-store-task
        task-store-operation
        task-store-payload
        task-store-put?
        task-store-get?
        make-external-task
        task-local?
        task-adapter-routed?
        task-normalized-request
        task-adapter-request
        make-execution-request
        execution-request?
        execution-request-name
        execution-request-kind
        execution-request-request
        execution-request-input
        execution-request-input-contract
        execution-request-output-contract
        execution-request-plan-id
        execution-request-node-id
        execution-request-frontier
        execution-request-strategy
        execution-request-policy)

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

;;; Task-family descriptors are POO objects because extension policy should be
;;; data-driven at the task boundary, not hard-coded in the runner.
;; TaskFamilyDescriptor <- Symbol Symbol Symbol Symbol AdapterDispatch
(def (make-task-family-descriptor family-name family-capability family-route family-runtime-owner family-adapter-dispatch)
  (.o (:: @ task-role)
      (name family-name)
      (kind 'task-family)
      (capability family-capability)
      (route family-route)
      (runtime-owner family-runtime-owner)
      (adapter-dispatch family-adapter-dispatch)
      (responsibility (list 'task-family family-route family-capability))))

;; Boolean <- TaskFamilyDescriptorCandidate
(def (task-family-descriptor? descriptor)
  (and (object? descriptor)
       (eq? (.@ descriptor kind) 'task-family)))

;; TaskFamilyDescriptor <- Unit
(def pure-task-family-descriptor
  (make-task-family-descriptor 'pure 'pure 'local 'gerbil #f))

;; TaskFamilyDescriptor <- Unit
(def scheme-task-family-descriptor
  (make-task-family-descriptor 'scheme 'scheme 'local 'gerbil #f))

;; TaskFamilyDescriptor <- Unit
(def store-task-family-descriptor
  (make-task-family-descriptor 'store 'store 'adapter 'rust-or-external-runtime 'store))

;; TaskFamilyDescriptor <- Unit
(def external-task-family-descriptor
  (make-task-family-descriptor 'external 'external 'adapter 'rust-or-external-runtime 'submit))

;; [TaskFamilyDescriptor] <- Unit
(def task-family-descriptors
  (list pure-task-family-descriptor
        scheme-task-family-descriptor
        store-task-family-descriptor
        external-task-family-descriptor))

;; Symbol <- TaskFamilyDescriptor
(def (task-family-name descriptor)
  (.@ descriptor name))

;; Symbol <- TaskFamilyDescriptor
(def (task-family-capability descriptor)
  (.@ descriptor capability))

;; Symbol <- TaskFamilyDescriptor
(def (task-family-route descriptor)
  (.@ descriptor route))

;; Symbol <- TaskFamilyDescriptor
(def (task-family-runtime-owner descriptor)
  (.@ descriptor runtime-owner))

;; AdapterDispatch <- TaskFamilyDescriptor
(def (task-family-adapter-dispatch descriptor)
  (.@ descriptor adapter-dispatch))

;; MaybeTaskFamilyDescriptor <- Symbol [TaskFamilyDescriptor]
(def (find-task-family kind descriptors)
  (cond
   ((null? descriptors) #f)
   ((eq? kind (task-family-name (car descriptors))) (car descriptors))
   (else (find-task-family kind (cdr descriptors)))))

;; TaskFamilyDescriptor <- Symbol
(def (task-family-for-kind kind)
  (let ((descriptor (find-task-family kind task-family-descriptors)))
    (if descriptor
      descriptor
      (error "unknown task family" kind))))

;; TaskFamilyDescriptor <- Task
(def (task-descriptor task)
  (task-family-for-kind (task-kind task)))

;; Symbol <- Task
(def (task-capability task)
  (task-family-capability (task-descriptor task)))

;; Symbol <- Task
(def (task-route task)
  (task-family-route (task-descriptor task)))

;; Symbol <- Task
(def (task-runtime-owner task)
  (task-family-runtime-owner (task-descriptor task)))

;;; Adapter operations translate descriptor-level dispatch into runtime adapter
;;; slots while keeping store operation details inside the task owner.
;; AdapterOperation <- Task
(def (task-adapter-operation task)
  (let ((dispatch (task-family-adapter-dispatch (task-descriptor task))))
    (cond
     ((eq? dispatch 'store)
      (cond
       ((task-store-put? task) 'store-put)
       ((task-store-get? task) 'store-get)
       (else (error "unsupported store operation" (task-store-operation task)))))
     (else dispatch))))

;;; Normalized requests are the adapter boundary format shared by store and
;;; external tasks.
;;; Plan, node, frontier, and strategy fields are optional control-plane
;;; evidence so Rust adapters can correlate requests with Scheme planning.
;;; Policy carries the stable alist snapshot that adapters should persist.
;; ExecutionRequest <- Symbol Symbol Request Value Contract Contract PlanId NodeId [Id] Strategy Policy
(defstruct execution-request
  (name
   kind
   request
   input
   input-contract
   output-contract
   plan-id
   node-id
   frontier
   strategy
   policy)
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

;;; Store operation accessors keep cache semantics explicit at the task-family
;;; boundary without requiring runners to destructure arbitrary request data.
;; Symbol | #f <- Task
(def (task-store-operation task)
  (if (eq? (task-kind task) 'store)
    (cadr (task-request task))
    #f))

;; Payload | #f <- Task
(def (task-store-payload task)
  (if (eq? (task-kind task) 'store)
    (caddr (task-request task))
    #f))

;; Boolean <- Task
(def (task-store-put? task)
  (eq? (task-store-operation task) 'put))

;; Boolean <- Task
(def (task-store-get? task)
  (eq? (task-store-operation task) 'get))

;; Task <- Symbol Symbol Payload Contract Contract
(def (make-external-task name operation payload input-contract output-contract)
  (make-task name 'external (list 'external operation payload) input-contract output-contract #f))

;; Boolean <- Task
(def (task-local? task)
  (eq? (task-route task) 'local))

;; Boolean <- Task
(def (task-adapter-routed? task)
  (eq? (task-route task) 'adapter))

;; ExecutionRequest <- Task Value
(def (task-normalized-request task input)
  (task-adapter-request task input #f #f '() #f #f))

;;; Runner-owned request enrichment keeps task constructors pure while still
;;; giving runtime adapters the graph and strategy evidence they need.
;; ExecutionRequest <- Task Value PlanId NodeId [Id] Strategy Policy
(def (task-adapter-request task input plan-id node-id frontier strategy policy)
  (make-execution-request (task-name task)
                          (task-kind task)
                          (task-request task)
                          input
                          (task-input-contract task)
                          (task-output-contract task)
                          plan-id
                          node-id
                          frontier
                          strategy
                          policy))
