;;; -*- Gerbil -*-
;;; Boundary: adapters normalize calls to heavy runtime implementations.
;;; Invariant: this module only defines the request-only placeholder adapter.

(import :poo-flow/src/core/task
        (only-in :std/misc/process run-process))

(export make-adapter-result
        adapter-result?
        adapter-result-request-id
        adapter-result-status
        adapter-result-value
        adapter-result-artifact-handle
        adapter-result-error
        +runtime-request-schema+
        +runtime-response-schema+
        +runtime-command-descriptor-schema+
        make-runtime-response
        runtime-response?
        runtime-response-request-id
        runtime-response-status
        runtime-response-value
        runtime-response-artifact-handle
        runtime-response-error
        runtime-response-metadata
        runtime-response->alist
        runtime-response->adapter-result
        normalize-runtime-response
        adapter-result->runtime-response
        adapter-result->alist
        make-runtime-adapter
        runtime-adapter?
        runtime-adapter-name
        runtime-adapter-capabilities
        runtime-adapter-submitter
        runtime-adapter-fetcher
        runtime-adapter-store-putter
        runtime-adapter-store-getter
        make-runtime-command
        runtime-command?
        runtime-command-name
        runtime-command-kind
        runtime-command-invoker
        runtime-command-metadata
        make-runtime-command-descriptor
        runtime-command-descriptor?
        runtime-command-descriptor-name
        runtime-command-descriptor-executable
        runtime-command-descriptor-arguments
        runtime-command-descriptor-protocol
        runtime-command-descriptor-metadata
        make-stdout-runtime-command-descriptor
        runtime-command-descriptor-arguments-for
        runtime-command-descriptor->manifest
        runtime-command-manifest?
        runtime-command-manifest-ref
        runtime-command-manifest-argv
        runtime-command-manifest-envelope
        run-runtime-command-manifest
        runtime-command-manifest->command
        runtime-command-descriptor->command
        make-procedure-runtime-command
        make-process-runtime-command
        runtime-command-read-response
        make-stdout-runtime-command
        runtime-command-call
        make-request-only-adapter
        make-rust-adapter
        rust-request-envelope
        adapter-supports?
        adapter-submit
        adapter-fetch
        adapter-store-put
        adapter-store-get)

;; : (-> RequestId Symbol Value ArtifactHandle Error AdapterResult)
(defstruct adapter-result
  (request-id
   status
   value
   artifact-handle
   error)
  transparent: #t)

;; : (-> Unit Symbol)
(def +runtime-request-schema+ 'poo-flow.runtime-request.v1)

;; : (-> Unit Symbol)
(def +runtime-response-schema+ 'poo-flow.runtime-response.v1)

;; : (-> Unit Symbol)
(def +runtime-command-descriptor-schema+ 'poo-flow.runtime-command-descriptor.v1)

;;; Runtime responses are the durable schema projection for adapter results.
;;; The runner may still consume =adapter-result= directly, while Rust bridges
;;; and receipt stores can persist this stable alist-shaped response.
;; : (-> RequestId Symbol Value ArtifactHandle Error Alist RuntimeResponse)
(defstruct runtime-response
  (request-id
   status
   value
   artifact-handle
   error
   metadata)
  transparent: #t)

;; : (-> RuntimeResponse Alist)
(def (runtime-response->alist response)
  (list (cons 'schema +runtime-response-schema+)
        (cons 'request-id (runtime-response-request-id response))
        (cons 'status (runtime-response-status response))
        (cons 'value (runtime-response-value response))
        (cons 'artifact-handle (runtime-response-artifact-handle response))
        (cons 'error (runtime-response-error response))
        (cons 'metadata (runtime-response-metadata response))))

;; : (-> AdapterResult [Alist] RuntimeResponse)
(def (adapter-result->runtime-response result . maybe-metadata)
  (make-runtime-response
   (adapter-result-request-id result)
   (adapter-result-status result)
   (adapter-result-value result)
   (adapter-result-artifact-handle result)
   (adapter-result-error result)
   (if (null? maybe-metadata) '() (car maybe-metadata))))

;; : (-> AdapterResult Alist)
(def (adapter-result->alist result)
  (runtime-response->alist (adapter-result->runtime-response result)))

;;; Boundary: runtime alist ref is the policy-visible edge for core behavior,
;;; keeping validation, lookup, or projection responsibilities centralized for
;;; callers.
;; : (-> Alist Symbol Value Value)
(def (runtime-alist-ref alist key default)
  (let (entry (assoc key alist))
    (if entry
      (cdr entry)
      default)))

;; : (-> RuntimeResponse AdapterResult)
(def (runtime-response->adapter-result response)
  (make-adapter-result
   (runtime-response-request-id response)
   (runtime-response-status response)
   (runtime-response-value response)
   (runtime-response-artifact-handle response)
   (runtime-response-error response)))

;; : (-> RuntimeResponseAlistCandidate Boolean)
(def (runtime-response-alist? value)
  (and (list? value)
       (let (schema (assoc 'schema value))
         (and schema (eq? (cdr schema) +runtime-response-schema+)))))

;; : (-> Alist Value AdapterResult)
(def (invalid-runtime-response envelope response)
  (make-adapter-result
   (runtime-alist-ref envelope 'request-id #f)
   'failed
   #f
   (runtime-alist-ref envelope 'artifact-handle #f)
   (list (cons 'code 'invalid-runtime-response)
         (cons 'response response))))

;;; Runtime command responses are normalized before the runner sees them, so
;;; callers can return either the durable schema or the internal adapter shape.
;; : (-> Alist Value AdapterResult)
(def (normalize-runtime-response envelope response)
  (cond
   ((adapter-result? response)
    response)
   ((runtime-response? response)
    (runtime-response->adapter-result response))
   ((runtime-response-alist? response)
    (make-adapter-result
     (runtime-alist-ref response
                        'request-id
                        (runtime-alist-ref envelope 'request-id #f))
     (runtime-alist-ref response 'status 'submitted)
     (runtime-alist-ref response 'value #f)
     (runtime-alist-ref response
                        'artifact-handle
                        (runtime-alist-ref envelope 'artifact-handle #f))
     (runtime-alist-ref response 'error #f)))
   (else
    (invalid-runtime-response envelope response))))

;;; Function slots are the runtime boundary; Scheme policy calls these slots
;;; without owning the heavy implementation behind them.
;; : (-> Symbol [Symbol] Submitter Fetcher StorePutter StoreGetter RuntimeAdapter)
(defstruct runtime-adapter
  (name
   capabilities
   submitter
   fetcher
   store-putter
   store-getter)
  transparent: #t)

;;; Runtime commands describe the replaceable command/IPC boundary behind the
;;; Rust adapter.  The current Scheme tests can install a procedure command;
;;; later Rust or process-backed commands should keep this call shape stable.
;; : (-> Symbol Symbol Invoker Alist RuntimeCommand)
(defstruct runtime-command
  (name
   kind
   invoker
   metadata)
  transparent: #t)

;;; Runtime command descriptors are inert CLI contracts. They make the future
;;; Rust executable boundary inspectable before the command is materialized.
;; : (-> Symbol Path ArgumentsBuilder Protocol Alist RuntimeCommandDescriptor)
(defstruct runtime-command-descriptor
  (name
   executable
   arguments
   protocol
   metadata)
  transparent: #t)

;; : (-> Symbol Invoker [Alist] RuntimeCommand)
(def (make-procedure-runtime-command name invoker . maybe-metadata)
  (make-runtime-command name
                        'procedure
                        invoker
                        (if (null? maybe-metadata) '() (car maybe-metadata))))

;; : (-> Alist Symbol Value Alist RuntimeResponseLike)
(def (runtime-command-failure-response envelope code detail metadata)
  (list (cons 'schema +runtime-response-schema+)
        (cons 'request-id (runtime-alist-ref envelope 'request-id #f))
        (cons 'status 'failed)
        (cons 'value #f)
        (cons 'artifact-handle (runtime-alist-ref envelope 'artifact-handle #f))
        (cons 'error (list (cons 'code code)
                           (cons 'detail detail)))
        (cons 'metadata metadata)))

;; : (-> Symbol Path ArgumentsBuilder ResponseDecoder [Alist] RuntimeCommand)
(def (make-process-runtime-command name executable arguments response-decoder . maybe-metadata)
  (let (metadata (append (list (cons 'executable executable))
                         (if (null? maybe-metadata) '() (car maybe-metadata))))
    (make-runtime-command
     name
     'process
     (lambda (envelope)
       (let* ((argv (cons executable
                          (if (procedure? arguments)
                            (arguments envelope)
                            arguments)))
              (stdout (run-process argv)))
         (response-decoder envelope stdout)))
     metadata)))

;;; Stdout protocol commands print one runtime-response s-expression. This keeps
;;; process-backed tests close to the future Rust CLI contract without forcing
;;; each caller to install a custom decoder.
;; : (-> Alist String RuntimeResponseLike)
(def (runtime-command-read-response envelope stdout)
  (with-catch
   (lambda (failure)
     (runtime-command-failure-response envelope
                                       'invalid-runtime-command-stdout
                                       failure
                                       '()))
   (lambda ()
     (call-with-input-string stdout read))))

;; : (-> Symbol Path ArgumentsBuilder [Alist] RuntimeCommand)
(def (make-stdout-runtime-command name executable arguments . maybe-metadata)
  (apply make-process-runtime-command
         name
         executable
         arguments
         runtime-command-read-response
         maybe-metadata))

;; : (-> Symbol Path ArgumentsBuilder [Alist] RuntimeCommandDescriptor)
(def (make-stdout-runtime-command-descriptor name executable arguments . maybe-metadata)
  (make-runtime-command-descriptor
   name
   executable
   arguments
   'stdout-s-expression
   (if (null? maybe-metadata) '() (car maybe-metadata))))

;; : (-> RuntimeCommandDescriptor Alist [String])
(def (runtime-command-descriptor-arguments-for descriptor envelope)
  (let (arguments (runtime-command-descriptor-arguments descriptor))
    (if (procedure? arguments)
      (arguments envelope)
      arguments)))

;;; Descriptor manifests are the concrete CLI handoff for a request envelope:
;;; Rust can consume this data without knowing Scheme constructor details.
;; : (-> RuntimeCommandDescriptor Alist Alist)
(def (runtime-command-descriptor->manifest descriptor envelope)
  (let ((arguments (runtime-command-descriptor-arguments-for descriptor envelope)))
    (list (cons 'schema +runtime-command-descriptor-schema+)
          (cons 'request-schema (runtime-alist-ref envelope 'schema #f))
          (cons 'operation (runtime-alist-ref envelope 'operation #f))
          (cons 'request-id (runtime-alist-ref envelope 'request-id #f))
          (cons 'artifact-handle (runtime-alist-ref envelope 'artifact-handle #f))
          (cons 'request (runtime-alist-ref envelope 'request #f))
          (cons 'policy (runtime-alist-ref envelope 'policy '()))
          (cons 'plan-id (runtime-alist-ref envelope 'plan-id #f))
          (cons 'node-id (runtime-alist-ref envelope 'node-id #f))
          (cons 'frontier (runtime-alist-ref envelope 'frontier '()))
          (cons 'name (runtime-command-descriptor-name descriptor))
          (cons 'protocol (runtime-command-descriptor-protocol descriptor))
          (cons 'executable (runtime-command-descriptor-executable descriptor))
          (cons 'arguments arguments)
          (cons 'argv (cons (runtime-command-descriptor-executable descriptor)
                            arguments))
          (cons 'metadata (runtime-command-descriptor-metadata descriptor)))))

;; : (-> RuntimeCommandManifestCandidate Boolean)
(def (runtime-command-manifest? value)
  (and (list? value)
       (let (schema (assoc 'schema value))
         (and schema
              (eq? (cdr schema) +runtime-command-descriptor-schema+)))))

;; : (-> RuntimeCommandManifest Symbol Value Value)
(def (runtime-command-manifest-ref manifest key default)
  (runtime-alist-ref manifest key default))

;;; Manifest argv is the concrete Rust/process command line.  If older
;;; manifests omit =argv=, it is reconstructed from executable and arguments.
;; : (-> RuntimeCommandManifest [String])
(def (runtime-command-manifest-argv manifest)
  (runtime-command-manifest-ref
   manifest
   'argv
   (cons (runtime-command-manifest-ref manifest 'executable #f)
         (runtime-command-manifest-ref manifest 'arguments '()))))

;;; A manifest is request-bound, so its envelope is reconstructed from the
;;; durable request fields captured when descriptor code exported the manifest.
;; : (-> RuntimeCommandManifest Alist)
(def (runtime-command-manifest-envelope manifest)
  (list (cons 'schema
              (runtime-command-manifest-ref manifest
                                            'request-schema
                                            +runtime-request-schema+))
        (cons 'runtime 'manifest)
        (cons 'operation
              (runtime-command-manifest-ref manifest 'operation 'submit))
        (cons 'request-id
              (runtime-command-manifest-ref manifest 'request-id #f))
        (cons 'artifact-handle
              (runtime-command-manifest-ref manifest 'artifact-handle #f))
        (cons 'request
              (runtime-command-manifest-ref manifest 'request #f))
        (cons 'policy
              (runtime-command-manifest-ref manifest 'policy '()))
        (cons 'plan-id
              (runtime-command-manifest-ref manifest 'plan-id #f))
        (cons 'node-id
              (runtime-command-manifest-ref manifest 'node-id #f))
        (cons 'frontier
              (runtime-command-manifest-ref manifest 'frontier '()))))

;; : (-> RuntimeCommandManifest Symbol Value AdapterResult)
(def (runtime-command-manifest-failure manifest code detail)
  (make-adapter-result
   (runtime-command-manifest-ref manifest 'request-id #f)
   'failed
   #f
   (runtime-command-manifest-ref manifest 'artifact-handle #f)
   (list (cons 'code code)
         (cons 'detail detail))))

;;; Manifest execution is the first local consumer for Rust CLI handoff data:
;;; it runs the stored argv and normalizes stdout through the declared protocol.
;; : (-> RuntimeCommandManifest AdapterResult)
(def (run-runtime-command-manifest manifest)
  (cond
   ((not (runtime-command-manifest? manifest))
    (runtime-command-manifest-failure
     '()
     'invalid-runtime-command-manifest
     manifest))
   ((eq? (runtime-command-manifest-ref manifest 'protocol #f)
         'stdout-s-expression)
    (with-catch
     (lambda (failure)
       (runtime-command-manifest-failure
        manifest
        'runtime-command-manifest-error
        failure))
     (lambda ()
       (let* ((envelope (runtime-command-manifest-envelope manifest))
              (stdout (run-process (runtime-command-manifest-argv manifest))))
         (normalize-runtime-response
          envelope
          (runtime-command-read-response envelope stdout))))))
   (else
    (runtime-command-manifest-failure
     manifest
     'unsupported-runtime-command-manifest-protocol
     (runtime-command-manifest-ref manifest 'protocol #f)))))

;;; Materializing a manifest as a command lets existing adapter tests consume a
;;; request-bound CLI manifest through the same RuntimeCommand slot.
;; : (-> RuntimeCommandManifest RuntimeCommand)
(def (runtime-command-manifest->command manifest)
  (make-procedure-runtime-command
   (runtime-command-manifest-ref manifest 'name 'runtime-command-manifest)
   (lambda (_envelope)
     (run-runtime-command-manifest manifest))
   (append (list (cons 'source 'manifest))
           (runtime-command-manifest-ref manifest 'metadata '()))))

;;; Descriptor materialization is the narrow replacement seam for Rust-backed
;;; commands: workflow code depends on protocol data, not constructor details.
;; : (-> RuntimeCommandDescriptor RuntimeCommand)
(def (runtime-command-descriptor->command descriptor)
  (let ((metadata (append (list (cons 'protocol
                                      (runtime-command-descriptor-protocol descriptor)))
                          (runtime-command-descriptor-metadata descriptor))))
    (if (eq? (runtime-command-descriptor-protocol descriptor) 'stdout-s-expression)
      (make-stdout-runtime-command
       (runtime-command-descriptor-name descriptor)
       (runtime-command-descriptor-executable descriptor)
       (runtime-command-descriptor-arguments descriptor)
       metadata)
      (make-procedure-runtime-command
       (runtime-command-descriptor-name descriptor)
       (lambda (envelope)
         (runtime-command-failure-response
          envelope
          'unsupported-runtime-command-protocol
          (runtime-command-descriptor-protocol descriptor)
          metadata))
       metadata))))

;; : (-> RuntimeCommandCandidate Alist RuntimeResponseLike)
(def (runtime-command-call command envelope)
  (cond
   ((runtime-command? command)
    ((runtime-command-invoker command) envelope))
   ((procedure? command)
    (command envelope))
   (else
    (runtime-command-failure-response envelope
                                      'invalid-runtime-command
                                      command
                                      '()))))

;;; The request-only adapter is deterministic evidence plumbing for tests and
;;; early control-plane validation.
;; : (-> Unit RuntimeAdapter)
(def (make-request-only-adapter)
  (make-runtime-adapter 'request-only
                        '(external)
                        request-only-submit
                        request-only-fetch
                        request-only-store-put
                        request-only-store-get))

;;; The Rust adapter is a Scheme-side handoff stub. It proves the request shape
;;; can cross the boundary without embedding the heavy runtime implementation.
;; : (-> [RuntimeCommand] RuntimeAdapter)
(def (make-rust-adapter . maybe-command)
  (if (or (null? maybe-command) (not (car maybe-command)))
    (make-runtime-adapter 'rust
                          '(external)
                          rust-submit
                          rust-fetch
                          rust-store-put
                          rust-store-get)
    (let (command (car maybe-command))
      (make-runtime-adapter 'rust
                            '(external)
                            (lambda (request)
                              (rust-command-submit command request))
                            rust-fetch
                            (lambda (request)
                              (rust-command-store-put command request))
                            rust-store-get))))

;; : (-> RuntimeAdapter Symbol Boolean)
(def (adapter-supports? adapter capability)
  (and (memq capability (runtime-adapter-capabilities adapter)) #t))

;; : (-> RuntimeAdapter ExecutionRequest AdapterResult)
(def (adapter-submit adapter request)
  ((runtime-adapter-submitter adapter) request))

;; : (-> RuntimeAdapter RequestId AdapterResult)
(def (adapter-fetch adapter request-id)
  ((runtime-adapter-fetcher adapter) request-id))

;; : (-> RuntimeAdapter ExecutionRequest AdapterResult)
(def (adapter-store-put adapter request)
  ((runtime-adapter-store-putter adapter) request))

;; : (-> RuntimeAdapter ArtifactHandle AdapterResult)
(def (adapter-store-get adapter handle)
  ((runtime-adapter-store-getter adapter) handle))

;; : (-> ExecutionRequest RequestId)
(def (request-id request)
  (list 'request (execution-request-name request) (execution-request-kind request)))

;; : (-> ExecutionRequest RequestId)
(def (rust-request-id request)
  (list 'rust-request (execution-request-name request) (execution-request-kind request)))

;; : (-> ExecutionRequest ArtifactHandle)
(def (rust-artifact-handle request)
  (list 'rust-artifact
        (execution-request-plan-id request)
        (execution-request-node-id request)))

;;; The envelope is intentionally alist-shaped so Rust can deserialize the same
;;; data without understanding Gerbil structs.
;; : (-> ExecutionRequest [Symbol] Alist)
(def (rust-request-envelope request . maybe-operation)
  (let ((operation (if (null? maybe-operation) 'submit (car maybe-operation))))
    (list (cons 'schema +runtime-request-schema+)
          (cons 'runtime 'rust)
          (cons 'operation operation)
          (cons 'request-id (rust-request-id request))
          (cons 'artifact-handle (rust-artifact-handle request))
          (cons 'request request)
          (cons 'policy (execution-request-policy request))
          (cons 'plan-id (execution-request-plan-id request))
          (cons 'node-id (execution-request-node-id request))
          (cons 'frontier (execution-request-frontier request)))))

;; : (-> ExecutionRequest AdapterResult)
(def (request-only-submit request)
  (make-adapter-result (request-id request) 'requested request #f #f))

;; : (-> RequestId AdapterResult)
(def (request-only-fetch request-id)
  (make-adapter-result request-id 'requested #f #f #f))

;; : (-> ExecutionRequest AdapterResult)
(def (request-only-store-put request)
  (make-adapter-result (request-id request) 'requested request #f #f))

;; : (-> ArtifactHandle AdapterResult)
(def (request-only-store-get handle)
  (make-adapter-result (list 'store-get handle) 'requested #f handle #f))

;; : (-> ExecutionRequest AdapterResult)
(def (rust-submit request)
  (make-adapter-result (rust-request-id request)
                       'submitted
                       (rust-request-envelope request)
                       (rust-artifact-handle request)
                       #f))

;; : (-> RequestId AdapterResult)
(def (rust-fetch request-id)
  (make-adapter-result request-id 'submitted #f #f #f))

;; : (-> ExecutionRequest AdapterResult)
(def (rust-store-put request)
  (make-adapter-result (rust-request-id request)
                       'submitted
                       (rust-request-envelope request 'store-put)
                       (rust-artifact-handle request)
                       #f))

;; : (-> ArtifactHandle AdapterResult)
(def (rust-store-get handle)
  (make-adapter-result (list 'rust-store-get handle) 'submitted #f handle #f))

;;; Runtime command invocation is the narrow process/IPC boundary: the command sees
;;; one stable request envelope and must return a normalizable response.
;; : (-> RuntimeCommand Alist AdapterResult)
(def (runtime-command-result command envelope)
  (with-catch
   (lambda (failure)
     (make-adapter-result
      (runtime-alist-ref envelope 'request-id #f)
      'failed
      #f
      (runtime-alist-ref envelope 'artifact-handle #f)
      (list (cons 'code 'runtime-command-error)
            (cons 'error failure))))
   (lambda ()
     (normalize-runtime-response envelope (runtime-command-call command envelope)))))

;; : (-> RuntimeCommand ExecutionRequest AdapterResult)
(def (rust-command-submit command request)
  (runtime-command-result command (rust-request-envelope request)))

;; : (-> RuntimeCommand ExecutionRequest AdapterResult)
(def (rust-command-store-put command request)
  (runtime-command-result command (rust-request-envelope request 'store-put)))
