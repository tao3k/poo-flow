;;; -*- Gerbil -*-
;;; Owner: Store/CAS workflow alignment lives in this extension module.
;;; Boundary: core provides generic task, strategy, config, and adapter slots.
;;; Import contract: users opt in through =:extensions/store= exports.
;;; Runtime contract: this module emits artifact-store request data only.
;;; Runtime contract: CAS materialization and cache reuse stay runtime-owned.
;;; Policy evidence: receipts carry generic adapter observations from core.

(import :core/api)

(export store-task-family-descriptor
        make-store-task-family-registry
        store-enable-strategy
        make-store-enabled-strategy
        make-cached-store-enabled-strategy
        make-store-enabled-adapter
        make-store-run-config
        make-store-rust-run-config
        make-store-task
        task-store-operation
        task-store-payload
        task-store-put?
        task-store-get?
        store-flow)

;; AdapterOperation <- Task
(def (store-task-adapter-dispatch task)
  (cond
   ((task-store-put? task) 'store-put)
   ((task-store-get? task) 'store-get)
   (else
    (raise-control-plane-failure
     'store-extension
     'unsupported-store-operation
     "unsupported store operation"
     (list (cons 'task (task-name task))
           (cons 'operation (task-store-operation task)))))))

;; TaskFamilyDescriptor <- Unit
(def store-task-family-descriptor
  (make-task-family-descriptor 'store
                               'store
                               'adapter
                               'rust-or-external-runtime
                               store-task-adapter-dispatch))

;; TaskFamilyRegistry <- [TaskFamilyRegistry]
(def (make-store-task-family-registry . maybe-registry)
  (task-family-registry-extend
   (if (null? maybe-registry) default-task-family-registry (car maybe-registry))
   store-task-family-descriptor))

;; [Symbol] <- [Symbol] Symbol
(def (capabilities-with capability-set capability)
  (if (memq capability capability-set)
    capability-set
    (append capability-set (list capability))))

;; Strategy <- Strategy
(def (store-enable-strategy strategy)
  (make-strategy (strategy-name strategy)
                 (capabilities-with (strategy-capabilities strategy) 'store)
                 (strategy-cache-policy strategy)
                 (strategy-failure-policy strategy)
                 (strategy-planner strategy)))

;;; Store-aware strategies are opt-in wrappers over core strategy policy. Core
;;; stays unaware of Store/CAS while extension users get normal validation.
;; Strategy <- Unit
(def (make-store-enabled-strategy)
  (store-enable-strategy (make-local-eager-strategy)))

;; Strategy <- Unit
(def (make-cached-store-enabled-strategy)
  (store-enable-strategy (make-cached-local-eager-strategy)))

;; RuntimeAdapter <- RuntimeAdapter
(def (make-store-enabled-adapter adapter)
  (make-runtime-adapter (runtime-adapter-name adapter)
                        (capabilities-with (runtime-adapter-capabilities adapter)
                                           'store)
                        (runtime-adapter-submitter adapter)
                        (runtime-adapter-fetcher adapter)
                        (runtime-adapter-store-putter adapter)
                        (runtime-adapter-store-getter adapter)))

;; Value <- Alist Symbol Value
(def (store-option options key default)
  (let (entry (assoc key options))
    (if entry
      (cdr entry)
      default)))

;; RunConfig <- [Alist]
(def (make-store-run-config . maybe-options)
  (let (options (if (null? maybe-options) '() (car maybe-options)))
    (make-run-config 'store-request-only
                     (make-store-enabled-strategy)
                     (make-store-enabled-adapter (make-request-only-adapter))
                     (append '((runtime . request-only)
                               (extension . store))
                             options)
                     (make-store-task-family-registry)
                     default-flow-declaration-registry)))

;; RunConfig <- [Alist]
(def (make-store-rust-run-config . maybe-options)
  (let* ((options (if (null? maybe-options) '() (car maybe-options)))
         (command (store-option options 'runtime-command #f)))
    (make-run-config 'store-rust
                     (make-store-enabled-strategy)
                     (make-store-enabled-adapter (make-rust-adapter command))
                     (append '((runtime . rust)
                               (extension . store))
                             options)
                     (make-store-task-family-registry)
                     default-flow-declaration-registry)))

;; Task <- Symbol Symbol Payload Contract Contract
(def (make-store-task name operation payload input-contract output-contract)
  (make-task name 'store (list 'store operation payload) input-contract output-contract #f))

;;; Store operation accessors keep CAS semantics explicit at the extension
;;; boundary without requiring runners to destructure store request data.
;; Symbol | #f <- Task
(def (task-store-operation task)
  (if (eq? (task-kind task) 'store)
    (task-request-operation task)
    #f))

;; Payload | #f <- Task
(def (task-store-payload task)
  (if (eq? (task-kind task) 'store)
    (task-request-payload task)
    #f))

;; Boolean <- Task
(def (task-store-put? task)
  (eq? (task-store-operation task) 'put))

;; Boolean <- Task
(def (task-store-get? task)
  (eq? (task-store-operation task) 'get))

;; Flow <- Symbol Symbol Payload Contract Contract
(def (store-flow name operation payload input-contract output-contract)
  (task-flow name
             (make-store-task name operation payload input-contract output-contract)))
