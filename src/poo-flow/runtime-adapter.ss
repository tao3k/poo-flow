;;; -*- Gerbil -*-
;;; Boundary: adapters normalize calls to heavy runtime implementations.
;;; Invariant: this module only defines the request-only placeholder adapter.

(import :poo-flow/task)

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
