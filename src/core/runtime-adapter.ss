;;; -*- Gerbil -*-
;;; Boundary: adapters normalize calls to heavy runtime implementations.
;;; Invariant: this module only defines the request-only placeholder adapter.

(import :core/task)

(export make-adapter-result
        adapter-result?
        adapter-result-request-id
        adapter-result-status
        adapter-result-value
        adapter-result-artifact-handle
        adapter-result-error
        make-runtime-adapter
        runtime-adapter?
        runtime-adapter-name
        runtime-adapter-capabilities
        runtime-adapter-submitter
        runtime-adapter-fetcher
        runtime-adapter-store-putter
        runtime-adapter-store-getter
        make-request-only-adapter
        make-rust-adapter
        rust-request-envelope
        adapter-supports?
        adapter-submit
        adapter-fetch
        adapter-store-put
        adapter-store-get)

;; AdapterResult <- RequestId Symbol Value ArtifactHandle Error
(defstruct adapter-result
  (request-id
   status
   value
   artifact-handle
   error)
  transparent: #t)

;;; Function slots are the runtime boundary; Scheme policy calls these slots
;;; without owning the heavy implementation behind them.
;; RuntimeAdapter <- Symbol [Symbol] Submitter Fetcher StorePutter StoreGetter
(defstruct runtime-adapter
  (name
   capabilities
   submitter
   fetcher
   store-putter
   store-getter)
  transparent: #t)

;;; The request-only adapter is deterministic evidence plumbing for tests and
;;; early control-plane validation.
;; RuntimeAdapter <- Unit
(def (make-request-only-adapter)
  (make-runtime-adapter 'request-only
                        '(store external)
                        request-only-submit
                        request-only-fetch
                        request-only-store-put
                        request-only-store-get))

;;; The Rust adapter is a Scheme-side handoff stub. It proves the request shape
;;; can cross the boundary without embedding the heavy runtime implementation.
;; RuntimeAdapter <- Unit
(def (make-rust-adapter)
  (make-runtime-adapter 'rust
                        '(store external)
                        rust-submit
                        rust-fetch
                        rust-store-put
                        rust-store-get))

;; Boolean <- RuntimeAdapter Symbol
(def (adapter-supports? adapter capability)
  (and (memq capability (runtime-adapter-capabilities adapter)) #t))

;; AdapterResult <- RuntimeAdapter ExecutionRequest
(def (adapter-submit adapter request)
  ((runtime-adapter-submitter adapter) request))

;; AdapterResult <- RuntimeAdapter RequestId
(def (adapter-fetch adapter request-id)
  ((runtime-adapter-fetcher adapter) request-id))

;; AdapterResult <- RuntimeAdapter ExecutionRequest
(def (adapter-store-put adapter request)
  ((runtime-adapter-store-putter adapter) request))

;; AdapterResult <- RuntimeAdapter ArtifactHandle
(def (adapter-store-get adapter handle)
  ((runtime-adapter-store-getter adapter) handle))

;; RequestId <- ExecutionRequest
(def (request-id request)
  (list 'request (execution-request-name request) (execution-request-kind request)))

;; RequestId <- ExecutionRequest
(def (rust-request-id request)
  (list 'rust-request (execution-request-name request) (execution-request-kind request)))

;; ArtifactHandle <- ExecutionRequest
(def (rust-artifact-handle request)
  (list 'rust-artifact
        (execution-request-plan-id request)
        (execution-request-node-id request)))

;;; The envelope is intentionally alist-shaped so Rust can deserialize the same
;;; data without understanding Gerbil structs.
;; Alist <- ExecutionRequest
(def (rust-request-envelope request)
  (list (cons 'runtime 'rust)
        (cons 'request request)
        (cons 'policy (execution-request-policy request))
        (cons 'plan-id (execution-request-plan-id request))
        (cons 'node-id (execution-request-node-id request))
        (cons 'frontier (execution-request-frontier request))))

;; AdapterResult <- ExecutionRequest
(def (request-only-submit request)
  (make-adapter-result (request-id request) 'requested request #f #f))

;; AdapterResult <- RequestId
(def (request-only-fetch request-id)
  (make-adapter-result request-id 'requested #f #f #f))

;; AdapterResult <- ExecutionRequest
(def (request-only-store-put request)
  (make-adapter-result (request-id request) 'requested request #f #f))

;; AdapterResult <- ArtifactHandle
(def (request-only-store-get handle)
  (make-adapter-result (list 'store-get handle) 'requested #f handle #f))

;; AdapterResult <- ExecutionRequest
(def (rust-submit request)
  (make-adapter-result (rust-request-id request)
                       'submitted
                       (rust-request-envelope request)
                       (rust-artifact-handle request)
                       #f))

;; AdapterResult <- RequestId
(def (rust-fetch request-id)
  (make-adapter-result request-id 'submitted #f #f #f))

;; AdapterResult <- ExecutionRequest
(def (rust-store-put request)
  (rust-submit request))

;; AdapterResult <- ArtifactHandle
(def (rust-store-get handle)
  (make-adapter-result (list 'rust-store-get handle) 'submitted #f handle #f))
