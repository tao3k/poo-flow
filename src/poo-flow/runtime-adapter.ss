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

(defstruct adapter-result
  (request-id
   status
   value
   artifact-handle
   error)
  transparent: #t)

(defstruct runtime-adapter
  (name
   capabilities
   submitter
   fetcher
   store-putter
   store-getter)
  transparent: #t)

(def (make-request-only-adapter)
  (make-runtime-adapter 'request-only
                        '(store external)
                        request-only-submit
                        request-only-fetch
                        request-only-store-put
                        request-only-store-get))

(def (adapter-supports? adapter capability)
  (and (memq capability (runtime-adapter-capabilities adapter)) #t))

(def (adapter-submit adapter request)
  ((runtime-adapter-submitter adapter) request))

(def (adapter-fetch adapter request-id)
  ((runtime-adapter-fetcher adapter) request-id))

(def (adapter-store-put adapter request)
  ((runtime-adapter-store-putter adapter) request))

(def (adapter-store-get adapter handle)
  ((runtime-adapter-store-getter adapter) handle))

(def (request-id request)
  (list 'request (execution-request-name request) (execution-request-kind request)))

(def (request-only-submit request)
  (make-adapter-result (request-id request) 'requested request #f #f))

(def (request-only-fetch request-id)
  (make-adapter-result request-id 'requested #f #f #f))

(def (request-only-store-put request)
  (make-adapter-result (request-id request) 'requested request #f #f))

(def (request-only-store-get handle)
  (make-adapter-result (list 'store-get handle) 'requested #f handle #f))
