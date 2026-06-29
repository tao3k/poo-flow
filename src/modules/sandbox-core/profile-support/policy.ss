;;; -*- Gerbil -*-
;;; Boundary: sandbox profile policy and backend capability POO objects.
;;; Invariant: this layer validates and projects; it never executes a backend.

(import :gerbil/gambit
        (only-in :clan/poo/object .ref .slot? object? object<-alist)
        (only-in :std/srfi/1 filter-map))

(export poo-flow-sandbox-backend-capability-kind
        poo-flow-sandbox-profile-policy-kind
        poo-flow-sandbox-profile-policy-validation-kind
        poo-flow-sandbox-profile-policy-projection-kind
        poo-flow-sandbox-backend-capability
        poo-flow-sandbox-backend-capability?
        poo-flow-sandbox-backend-capability/backend-kind
        poo-flow-sandbox-backend-capability/capabilities
        poo-flow-sandbox-backend-capability-supports?
        poo-flow-sandbox-backend-capability/sandbox
        poo-flow-sandbox-backend-capability/nono
        poo-flow-sandbox-backend-capability/cube
        poo-flow-sandbox-backend-capability/docker
        poo-flow-sandbox-backend-capability-ref
        poo-flow-sandbox-profile-policy
        poo-flow-sandbox-profile-policy?
        poo-flow-sandbox-profile-policy-required-capabilities
        poo-flow-sandbox-profile-policy/default
        poo-flow-sandbox-profile-policy-diagnostic
        poo-flow-sandbox-profile-policy-diagnostics
        poo-flow-sandbox-profile-policy-validation
        poo-flow-sandbox-profile-policy-validation-valid?
        poo-flow-sandbox-profile-policy-projection)

;; poo-flow-sandbox-backend-capability-kind
;;   : PooFlowSandboxBackendCapabilityKindId
;;   | type PooFlowSandboxBackendCapabilityKindId = String
;;   | doc m%
;;       Stable schema kind for backend capability POO objects.
;;
;;       # Examples
;;       ```scheme
;;       poo-flow-sandbox-backend-capability-kind
;;       ;; => "poo-flow.sandbox.backend-capability.v1"
;;       ```
(defconst poo-flow-sandbox-backend-capability-kind
  "poo-flow.sandbox.backend-capability.v1")

;; poo-flow-sandbox-profile-policy-kind
;;   : PooFlowSandboxProfilePolicyKindId
;;   | type PooFlowSandboxProfilePolicyKindId = String
;;   | doc m%
;;       Stable schema kind for profile policy POO objects.
;;
;;       # Examples
;;       ```scheme
;;       poo-flow-sandbox-profile-policy-kind
;;       ;; => "poo-flow.sandbox.profile-policy.v1"
;;       ```
(defconst poo-flow-sandbox-profile-policy-kind
  "poo-flow.sandbox.profile-policy.v1")

;; poo-flow-sandbox-profile-policy-validation-kind
;;   : PooFlowSandboxProfilePolicyValidationKindId
;;   | type PooFlowSandboxProfilePolicyValidationKindId = String
;;   | doc m%
;;       Stable schema kind for profile policy validation receipts.
;;
;;       # Examples
;;       ```scheme
;;       poo-flow-sandbox-profile-policy-validation-kind
;;       ;; => "poo-flow.sandbox.profile-policy.validation.v1"
;;       ```
(defconst poo-flow-sandbox-profile-policy-validation-kind
  "poo-flow.sandbox.profile-policy.validation.v1")

;; poo-flow-sandbox-profile-policy-projection-kind
;;   : PooFlowSandboxProfilePolicyProjectionKindId
;;   | type PooFlowSandboxProfilePolicyProjectionKindId = String
;;   | doc m%
;;       Stable schema kind for non-executing profile policy projections.
;;
;;       # Examples
;;       ```scheme
;;       poo-flow-sandbox-profile-policy-projection-kind
;;       ;; => "poo-flow.sandbox.profile-policy.projection.v1"
;;       ```
(defconst poo-flow-sandbox-profile-policy-projection-kind
  "poo-flow.sandbox.profile-policy.projection.v1")

;; : (-> Alist Symbol Value Value)
(def (poo-flow-sandbox-profile-policy-option options key default-value)
  (let (entry (assoc key options))
    (if entry (cdr entry) default-value)))

;; : (-> SandboxPolicyCandidate SandboxPolicyKindId Boolean)
;; | type SandboxPolicyCandidate = Any
;; | type SandboxPolicyKindId = String
(def (poo-flow-sandbox-policy-object-kind? value kind)
  (and (object? value)
       (.slot? value 'kind)
       (equal? (.ref value 'kind) kind)))

;; : (-> Symbol [Symbol] [Alist] POOObject)
(def (poo-flow-sandbox-backend-capability backend-kind
                                          capabilities
                                          . maybe-options)
  (let (options (if (null? maybe-options) '() (car maybe-options)))
    (object<-alist
     (list
      (cons 'kind poo-flow-sandbox-backend-capability-kind)
      (cons 'backend-kind backend-kind)
      (cons 'isolation
            (poo-flow-sandbox-profile-policy-option options 'isolation 'process))
      (cons 'capabilities capabilities)
      (cons 'supports-command
            (poo-flow-sandbox-profile-policy-option options 'supports-command #t))
      (cons 'supports-filesystem
            (poo-flow-sandbox-profile-policy-option options 'supports-filesystem #t))
      (cons 'supports-code-interpreter
            (poo-flow-sandbox-profile-policy-option
             options
             'supports-code-interpreter
             #f))
      (cons 'supports-network
            (poo-flow-sandbox-profile-policy-option options 'supports-network #f))
      (cons 'supports-persistence
            (poo-flow-sandbox-profile-policy-option
             options
             'supports-persistence
             #f))
      (cons 'max-sandboxes
            (poo-flow-sandbox-profile-policy-option options 'max-sandboxes #f))
      (cons 'cold-start-ms-p50
            (poo-flow-sandbox-profile-policy-option options 'cold-start-ms-p50 #f))
      (cons 'availability
            (poo-flow-sandbox-profile-policy-option
             options
             'availability
             '((mode . static) (runtime-executed . #f))))
      (cons 'metadata
            (poo-flow-sandbox-profile-policy-option options 'metadata '()))))))

;; : (-> SandboxPolicyCandidate Boolean)
;; | type SandboxPolicyCandidate = Any
(def (poo-flow-sandbox-backend-capability? value)
  (poo-flow-sandbox-policy-object-kind?
   value
   poo-flow-sandbox-backend-capability-kind))

;; : (-> PooSandboxBackendCapability Symbol)
(def (poo-flow-sandbox-backend-capability/backend-kind capability)
  (.ref capability 'backend-kind))

;; : (-> PooSandboxBackendCapability [Symbol])
(def (poo-flow-sandbox-backend-capability/capabilities capability)
  (.ref capability 'capabilities))

;; : (-> PooSandboxBackendCapability Symbol Boolean)
(def (poo-flow-sandbox-backend-capability-supports? capability required)
  (and (member required
               (poo-flow-sandbox-backend-capability/capabilities capability))
       #t))

;; poo-flow-sandbox-backend-capability/sandbox
;;   : POOObject
;;   | doc m%
;;       Static POO capability object for the neutral sandbox backend.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-sandbox-backend-capability/backend-kind
;;        poo-flow-sandbox-backend-capability/sandbox)
;;       ;; => sandbox
;;       ```
(def poo-flow-sandbox-backend-capability/sandbox
  (poo-flow-sandbox-backend-capability
   'sandbox
   '(process process-run filesystem filesystem-read filesystem-write tmpdir
             cache-mount)
   '((isolation . process)
     (supports-command . #t)
     (supports-filesystem . #t)
     (metadata . ((scope . sandbox-core))))))

;; poo-flow-sandbox-backend-capability/nono
;;   : POOObject
;;   | doc m%
;;       Static POO capability object for the native nono sandbox backend.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-sandbox-backend-capability/backend-kind
;;        poo-flow-sandbox-backend-capability/nono)
;;       ;; => nono
;;       ```
(def poo-flow-sandbox-backend-capability/nono
  (poo-flow-sandbox-backend-capability
   'nono
   '(process process-run filesystem filesystem-read filesystem-write tmpdir
             cache-mount)
   '((isolation . user-process)
     (supports-command . #t)
     (supports-filesystem . #t)
     (cold-start-ms-p50 . 10)
     (metadata . ((scope . nono-sandbox) (binding . native-ffi))))))

;; poo-flow-sandbox-backend-capability/cube
;;   : POOObject
;;   | doc m%
;;       Static POO capability object for the Cube sandbox backend.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-sandbox-backend-capability/backend-kind
;;        poo-flow-sandbox-backend-capability/cube)
;;       ;; => cube
;;       ```
(def poo-flow-sandbox-backend-capability/cube
  (poo-flow-sandbox-backend-capability
   'cube
   '(process-run filesystem-read cache-mount snapshot kvm-isolation)
   '((isolation . kvm)
     (supports-command . #t)
     (supports-filesystem . #t)
     (supports-network . #t)
     (cold-start-ms-p50 . 500)
     (metadata . ((scope . cubeSandbox))))))

;; poo-flow-sandbox-backend-capability/docker
;;   : POOObject
;;   | doc m%
;;       Static POO capability object for the Docker sandbox backend.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-sandbox-backend-capability/backend-kind
;;        poo-flow-sandbox-backend-capability/docker)
;;       ;; => docker
;;       ```
(def poo-flow-sandbox-backend-capability/docker
  (poo-flow-sandbox-backend-capability
   'docker
   '(process-run filesystem-read filesystem-write tmpdir image-runtime
                 cache-mount)
   '((isolation . container)
     (supports-command . #t)
     (supports-filesystem . #t)
     (supports-network . #t)
     (supports-persistence . #t)
     (cold-start-ms-p50 . 1000)
     (metadata . ((scope . docker-sandbox))))))

;; : (-> Symbol PooSandboxBackendCapability)
(def (poo-flow-sandbox-backend-capability-ref backend-kind)
  (cond
   ((eq? backend-kind 'nono) poo-flow-sandbox-backend-capability/nono)
   ((or (eq? backend-kind 'cube) (eq? backend-kind 'cubeSandbox))
    poo-flow-sandbox-backend-capability/cube)
   ((eq? backend-kind 'docker) poo-flow-sandbox-backend-capability/docker)
   (else poo-flow-sandbox-backend-capability/sandbox)))

;; : (-> [Symbol] [Alist] POOObject)
(def (poo-flow-sandbox-profile-policy required-capabilities . maybe-options)
  (let (options (if (null? maybe-options) '() (car maybe-options)))
    (object<-alist
     (list
      (cons 'kind poo-flow-sandbox-profile-policy-kind)
      (cons 'required-capabilities required-capabilities)
      (cons 'backend-intent
            (poo-flow-sandbox-profile-policy-option options 'backend-intent '()))
      (cons 'resource-policy
            (poo-flow-sandbox-profile-policy-option options 'resource-policy '()))
      (cons 'safety-policy
            (poo-flow-sandbox-profile-policy-option
             options
             'safety-policy
             '((deny . ()) (human-gates . ()))))
      (cons 'failure-policy
            (poo-flow-sandbox-profile-policy-option
             options
             'failure-policy
             '((structured . #t) (recoverable . #t))))
      (cons 'projection-policy
            (poo-flow-sandbox-profile-policy-option
             options
             'projection-policy
             '((runtime-executed . #f) (target . marlin-agent-core))))
      (cons 'metadata
            (poo-flow-sandbox-profile-policy-option options 'metadata '()))))))

;; : (-> SandboxPolicyCandidate Boolean)
;; | type SandboxPolicyCandidate = Any
(def (poo-flow-sandbox-profile-policy? value)
  (poo-flow-sandbox-policy-object-kind?
   value
   poo-flow-sandbox-profile-policy-kind))

;; : (-> PooSandboxProfilePolicy [Symbol])
(def (poo-flow-sandbox-profile-policy-required-capabilities policy)
  (if (poo-flow-sandbox-profile-policy? policy)
    (.ref policy 'required-capabilities)
    '()))

;; : PooSandboxProfilePolicy
(def poo-flow-sandbox-profile-policy/default
  (poo-flow-sandbox-profile-policy '()))

;; : (-> CapabilityList CapabilityList CapabilityList)
;; | type CapabilityList = (List Symbol)
(def (poo-flow-sandbox-profile-policy-append-distinct base extra)
  (cond
   ((null? extra) base)
   ((member (car extra) base)
    (poo-flow-sandbox-profile-policy-append-distinct base (cdr extra)))
   (else
    (poo-flow-sandbox-profile-policy-append-distinct
     (append base (list (car extra)))
     (cdr extra)))))

;; : (-> PooSandboxProfilePolicy [Symbol] [Symbol])
(def (poo-flow-sandbox-profile-policy-effective-required policy
                                                         profile-capabilities)
  (poo-flow-sandbox-profile-policy-append-distinct
   (poo-flow-sandbox-profile-policy-required-capabilities policy)
   profile-capabilities))

;; : (-> Symbol Symbol Symbol Alist)
(def (poo-flow-sandbox-profile-policy-diagnostic code
                                                 phase
                                                 severity
                                                 payload)
  (append
   (list (cons 'kind 'profile-policy-diagnostic)
         (cons 'code code)
         (cons 'phase phase)
         (cons 'severity severity))
   payload))

;; poo-flow-sandbox-profile-policy-diagnostics
;;   : (-> Symbol Symbol PooSandboxBackendCapability PooSandboxProfilePolicy [Symbol] [Alist])
;;   | doc m%
;;       `poo-flow-sandbox-profile-policy-diagnostics` compares effective
;;       profile capabilities with the selected backend's static POO capability
;;       object and returns one structured diagnostic per unsupported
;;       capability.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-diagnostics
;;        'agent/gpu 'nono poo-flow-sandbox-backend-capability/nono
;;        (poo-flow-sandbox-profile-policy '(gpu-device)) '())
;;       ;; => ((kind . profile-policy-diagnostic) ...)
;;       ```
(def (poo-flow-sandbox-profile-policy-diagnostics profile-name
                                                  backend-kind
                                                  backend-capability
                                                  profile-policy
                                                  profile-capabilities)
  (let (required
        (poo-flow-sandbox-profile-policy-effective-required
         profile-policy
         profile-capabilities))
    (filter-map
     (lambda (required-capability)
       (if (poo-flow-sandbox-backend-capability-supports?
            backend-capability
            required-capability)
         #f
         (poo-flow-sandbox-profile-policy-diagnostic
          'missing-backend-capability
          'capability
          'error
          (list
           (cons 'profile profile-name)
           (cons 'backend-kind backend-kind)
           (cons 'slot 'capabilities)
           (cons 'required required-capability)
           (cons 'supported
                 (poo-flow-sandbox-backend-capability/capabilities
                  backend-capability))
           (cons 'recoverable? #t)))))
     required)))

;; : (-> Symbol Symbol Symbol PooSandboxBackendCapability PooSandboxProfilePolicy [Symbol] Alist)
(def (poo-flow-sandbox-profile-policy-validation profile-name
                                                 backend-kind
                                                 backend-ref
                                                 backend-capability
                                                 profile-policy
                                                 profile-capabilities)
  (let* ((diagnostics
          (poo-flow-sandbox-profile-policy-diagnostics
           profile-name
           backend-kind
           backend-capability
           profile-policy
           profile-capabilities))
         (valid? (null? diagnostics)))
    (list
     (cons 'kind poo-flow-sandbox-profile-policy-validation-kind)
     (cons 'schema poo-flow-sandbox-profile-policy-validation-kind)
     (cons 'valid? valid?)
     (cons 'profile profile-name)
     (cons 'backend-kind backend-kind)
     (cons 'backend-ref backend-ref)
     (cons 'required-capabilities
           (poo-flow-sandbox-profile-policy-effective-required
            profile-policy
            profile-capabilities))
     (cons 'backend-capabilities
           (poo-flow-sandbox-backend-capability/capabilities
            backend-capability))
     (cons 'diagnostics diagnostics)
     (cons 'diagnostic-count (length diagnostics))
     (cons 'runtime-executed #f))))

;; : (-> Alist Boolean)
(def (poo-flow-sandbox-profile-policy-validation-valid? validation)
  (let (entry (assoc 'valid? validation))
    (and entry (cdr entry))))

;; : (-> Symbol Symbol Symbol PooSandboxBackendCapability PooSandboxProfilePolicy [Symbol] Alist)
(def (poo-flow-sandbox-profile-policy-projection profile-name
                                                 backend-kind
                                                 backend-ref
                                                 backend-capability
                                                 profile-policy
                                                 profile-capabilities)
  (let (validation
        (poo-flow-sandbox-profile-policy-validation
         profile-name
         backend-kind
         backend-ref
         backend-capability
         profile-policy
         profile-capabilities))
    (list
     (cons 'kind poo-flow-sandbox-profile-policy-projection-kind)
     (cons 'schema poo-flow-sandbox-profile-policy-projection-kind)
     (cons 'profile profile-name)
     (cons 'backend-kind backend-kind)
     (cons 'backend-ref backend-ref)
     (cons 'validation validation)
     (cons 'valid?
           (poo-flow-sandbox-profile-policy-validation-valid? validation))
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'runtime-executed #f))))
