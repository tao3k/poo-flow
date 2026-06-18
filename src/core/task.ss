;;; -*- Gerbil -*-
;;; Boundary: tasks describe work intent and adapter request shape.
;;; Invariant: only pure/scheme tasks carry an in-process executor.

(import (only-in :clan/poo/object .mix .@ object?)
        :core/roles
        :core/failure)

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
        task-family-descriptor-prototype
        make-task-family-registry
        task-family-registry?
        task-family-registry-prototype
        default-task-family-registry
        task-family-registry-name
        task-family-registry-descriptors
        task-family-registry-extend
        pure-task-family-descriptor
        scheme-task-family-descriptor
        external-task-family-descriptor
        task-family-descriptors
        task-family-name
        task-family-capability
        task-family-route
        task-family-runtime-owner
        task-family-adapter-dispatch
        task-family-for-kind-in
        task-family-for-kind
        task-descriptor-in
        task-descriptor
        task-capability-in
        task-capability
        task-route-in
        task-route
        task-runtime-owner-in
        task-runtime-owner
        task-adapter-operation-in
        task-adapter-operation
        task-request-operation
        task-request-payload
        make-pure-task
        make-scheme-task
        make-external-task
        task-local?-in
        task-local?
        task-adapter-routed?-in
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
;; TaskFamilyDescriptorPrototype <- Unit
(def task-family-descriptor-prototype
  (.mix slots: (role-constant-slots
                (list (cons 'kind 'task-family)
                      (cons 'capability #f)
                      (cons 'route 'local)
                      (cons 'runtime-owner 'gerbil)
                      (cons 'adapter-dispatch #f)
                      (cons 'extension-policy 'descriptor-prototype)))
        task-role))

;; TaskFamilyDescriptor <- Symbol Symbol Symbol Symbol AdapterDispatch
(def (make-task-family-descriptor family-name family-capability family-route family-runtime-owner family-adapter-dispatch)
  (.mix slots: (role-constant-slots
                (list (cons 'name family-name)
                      (cons 'capability family-capability)
                      (cons 'route family-route)
                      (cons 'runtime-owner family-runtime-owner)
                      (cons 'adapter-dispatch family-adapter-dispatch)
                      (cons 'responsibility
                            (list 'task-family family-route family-capability))))
        task-family-descriptor-prototype))

;; Boolean <- TaskFamilyDescriptorCandidate
(def (task-family-descriptor? descriptor)
  (and (object? descriptor)
       (eq? (.@ descriptor kind) 'task-family)))

;;; Registries are immutable POO policy bundles; extension code gets a new
;;; registry value instead of mutating the default control-plane registry.
;; TaskFamilyRegistryPrototype <- Unit
(def task-family-registry-prototype
  (.mix slots: (role-constant-slots
                (list (cons 'kind 'task-family-registry)
                      (cons 'descriptors '())
                      (cons 'extension-policy 'immutable-registry)))
        task-role))

;; TaskFamilyRegistry <- Symbol [TaskFamilyDescriptor]
(def (make-task-family-registry registry-name registry-descriptors)
  (.mix slots: (role-constant-slots
                (list (cons 'name registry-name)
                      (cons 'descriptors registry-descriptors)
                      (cons 'responsibility
                            (list 'task-family-registry registry-name))))
        task-family-registry-prototype))

;; Boolean <- TaskFamilyRegistryCandidate
(def (task-family-registry? registry)
  (and (object? registry)
       (eq? (.@ registry kind) 'task-family-registry)))

;; Symbol <- TaskFamilyRegistry
(def (task-family-registry-name registry)
  (.@ registry name))

;; [TaskFamilyDescriptor] <- TaskFamilyRegistry
(def (task-family-registry-descriptors registry)
  (.@ registry descriptors))

;; TaskFamilyRegistry <- TaskFamilyRegistry TaskFamilyDescriptor
(def (task-family-registry-extend registry descriptor)
  (make-task-family-registry
   (task-family-registry-name registry)
   (append (task-family-registry-descriptors registry)
           (list descriptor))))

;; TaskFamilyDescriptor <- Unit
(def pure-task-family-descriptor
  (make-task-family-descriptor 'pure 'pure 'local 'gerbil #f))

;; TaskFamilyDescriptor <- Unit
(def scheme-task-family-descriptor
  (make-task-family-descriptor 'scheme 'scheme 'local 'gerbil #f))

;; TaskFamilyDescriptor <- Unit
(def external-task-family-descriptor
  (make-task-family-descriptor 'external 'external 'adapter 'rust-or-external-runtime 'submit))

;; TaskFamilyRegistry <- Unit
(def default-task-family-registry
  (make-task-family-registry
   'default-task-families
   (list pure-task-family-descriptor
         scheme-task-family-descriptor
         external-task-family-descriptor)))

;; [TaskFamilyDescriptor] <- Unit
(def task-family-descriptors
  (task-family-registry-descriptors default-task-family-registry))

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
(def (task-family-for-kind-in registry kind)
  (let ((descriptor (find-task-family kind (task-family-registry-descriptors registry))))
    (if descriptor
      descriptor
      (raise-control-plane-failure
       'task-registry
       'unknown-task-family
       "unknown task family"
       (list (cons 'registry (task-family-registry-name registry))
             (cons 'kind kind))))))

;; TaskFamilyDescriptor <- Symbol
(def (task-family-for-kind kind)
  (task-family-for-kind-in default-task-family-registry kind))

;; TaskFamilyDescriptor <- TaskFamilyRegistry Task
(def (task-descriptor-in registry task)
  (task-family-for-kind-in registry (task-kind task)))

;; TaskFamilyDescriptor <- Task
(def (task-descriptor task)
  (task-descriptor-in default-task-family-registry task))

;; Symbol <- TaskFamilyRegistry Task
(def (task-capability-in registry task)
  (task-family-capability (task-descriptor-in registry task)))

;; Symbol <- Task
(def (task-capability task)
  (task-capability-in default-task-family-registry task))

;; Symbol <- TaskFamilyRegistry Task
(def (task-route-in registry task)
  (task-family-route (task-descriptor-in registry task)))

;; Symbol <- Task
(def (task-route task)
  (task-route-in default-task-family-registry task))

;; Symbol <- TaskFamilyRegistry Task
(def (task-runtime-owner-in registry task)
  (task-family-runtime-owner (task-descriptor-in registry task)))

;; Symbol <- Task
(def (task-runtime-owner task)
  (task-runtime-owner-in default-task-family-registry task))

;;; Adapter operations translate descriptor-level dispatch into runtime adapter
;;; slots. Extensions may install a procedure dispatch hook when an operation
;;; must be derived from extension-owned task request data.
;; AdapterOperation <- TaskFamilyRegistry Task
(def (task-adapter-operation-in registry task)
  (let ((dispatch (task-family-adapter-dispatch (task-descriptor-in registry task))))
    (if (procedure? dispatch)
      (dispatch task)
      dispatch)))

;; AdapterOperation <- Task
(def (task-adapter-operation task)
  (task-adapter-operation-in default-task-family-registry task))

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

;;; Request operation and payload are generic helpers for extension-owned task
;;; families that use the conventional =(family operation payload)= shape.
;; Symbol | #f <- Task
(def (task-request-operation task)
  (if (and (pair? (task-request task))
           (pair? (cdr (task-request task))))
    (cadr (task-request task))
    #f))

;; Payload | #f <- Task
(def (task-request-payload task)
  (if (and (pair? (task-request task))
           (pair? (cdr (task-request task)))
           (pair? (cddr (task-request task))))
    (caddr (task-request task))
    #f))

;; Task <- Symbol Symbol Payload Contract Contract
(def (make-external-task name operation payload input-contract output-contract)
  (make-task name 'external (list 'external operation payload) input-contract output-contract #f))

;; Boolean <- TaskFamilyRegistry Task
(def (task-local?-in registry task)
  (eq? (task-route-in registry task) 'local))

;; Boolean <- Task
(def (task-local? task)
  (task-local?-in default-task-family-registry task))

;; Boolean <- TaskFamilyRegistry Task
(def (task-adapter-routed?-in registry task)
  (eq? (task-route-in registry task) 'adapter))

;; Boolean <- Task
(def (task-adapter-routed? task)
  (task-adapter-routed?-in default-task-family-registry task))

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
