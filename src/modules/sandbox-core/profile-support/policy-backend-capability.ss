;;; -*- Gerbil -*-
;;; Boundary: backend capability policy describes sandbox provider capabilities
;;; before nano, docker, cube, or native runtime adapters consume them.
;;; Invariant: capability objects must stay parser-visible and POO-native for
;;; shared sandbox profile inheritance.

(import :gerbil/gambit
        (only-in :clan/poo/object object<-alist object? .slot? .ref)
        (only-in :std/sugar filter)
        :poo-flow/src/modules/sandbox-core/profile-support/projection-syntax
        :poo-flow/src/modules/sandbox-core/profile-support/policy-core)

(export poo-flow-sandbox-backend-capability
        poo-flow-sandbox-backend-capability?
        poo-flow-sandbox-backend-capability/backend-kind
        poo-flow-sandbox-backend-capability/capabilities
        poo-flow-sandbox-backend-capability-supports?
        poo-flow-sandbox-backend-capability-registry
        poo-flow-sandbox-backend-capability-registry?
        poo-flow-sandbox-backend-capability-registry-entries
        poo-flow-sandbox-backend-capability-registry-aliases
        poo-flow-sandbox-backend-capability-registry-default
        poo-flow-sandbox-backend-capability-registry-extend
        poo-flow-sandbox-backend-capability-registry-merge
        poo-flow-sandbox-backend-capability-registry-canonical-kind
        poo-flow-sandbox-backend-capability-registry-ref
        poo-flow-sandbox-backend-capability/sandbox
        poo-flow-sandbox-backend-capability/nono
        poo-flow-sandbox-backend-capability/cube
        poo-flow-sandbox-backend-capability/docker
        poo-flow-sandbox-backend-capability-registry/sandbox-core
        poo-flow-sandbox-backend-capability-registry/default
        poo-flow-sandbox-backend-capability-registry-put-entries
        poo-flow-sandbox-backend-capability-registry-put-entries/index
        poo-flow-sandbox-backend-capability-registry-put-entries/kept
        poo-flow-sandbox-backend-capability-registry-put-entries/materialize
        poo-flow-sandbox-backend-capability-ref)

;; poo-flow-sandbox-backend-capability
;;   : (-> Symbol [Symbol] [Alist] PooSandboxBackendCapability)
;;   | contract: build a POO backend capability descriptor from normalized slots
;;   | result: backend capability policy object used by registry validation
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-backend-capability 'nono '(read) '())
;;       ;; => sandbox backend capability object
;;       ```
;;     %
;; : (-> Symbol [CapabilitySymbol] [Alist] PooSandboxBackendCapability)
;;; Backend capability objects are the sandbox policy extension boundary.
;;; - Keep registry aliases and default backend resolution explicit before profile validation consumes them.
;; : (-> Symbol List List Object)
(def (poo-flow-sandbox-backend-capability backend-kind
                                          capabilities
                                          . maybe-options)
  (let (options (if (null? maybe-options) '() (car maybe-options)))
    (object<-alist
     (poo-flow-sandbox-profile-field-rows
      (kind poo-flow-sandbox-backend-capability-kind)
      (backend-kind backend-kind)
      (isolation
       (poo-flow-sandbox-profile-policy-option options 'isolation 'process))
      (capabilities capabilities)
      (supports-command
       (poo-flow-sandbox-profile-policy-option options 'supports-command #t))
      (supports-filesystem
       (poo-flow-sandbox-profile-policy-option options 'supports-filesystem #t))
      (supports-code-interpreter
       (poo-flow-sandbox-profile-policy-option
        options
        'supports-code-interpreter
        #f))
      (supports-network
       (poo-flow-sandbox-profile-policy-option options 'supports-network #f))
      (supports-persistence
       (poo-flow-sandbox-profile-policy-option
        options
        'supports-persistence
        #f))
      (max-sandboxes
       (poo-flow-sandbox-profile-policy-option options 'max-sandboxes #f))
      (cold-start-ms-p50
       (poo-flow-sandbox-profile-policy-option options 'cold-start-ms-p50 #f))
      (availability
       (poo-flow-sandbox-profile-policy-option
        options
        'availability
        '((mode . static) (runtime-executed . #f))))
      (metadata
       (poo-flow-sandbox-profile-policy-option options 'metadata '()))))))

;; poo-flow-sandbox-backend-capability?
;;   : (-> SandboxPolicyCandidate Boolean)
;;   | contract: recognize POO backend capability policy objects
;;   | result: #t only for values carrying the backend capability kind id
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-backend-capability? '())
;;       ;; => #f
;;       ```
;;     %
;; : (-> SandboxPolicyCandidate Boolean)
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

;; : (-> [Alist] [Alist] POOObject)
(def (poo-flow-sandbox-backend-capability-registry entries . maybe-options)
  (let (options (if (null? maybe-options) '() (car maybe-options)))
    (object<-alist
     (list
      (cons 'kind poo-flow-sandbox-backend-capability-registry-kind)
      (cons 'entries entries)
      (cons 'aliases
            (poo-flow-sandbox-profile-policy-option options 'aliases '()))
      (cons 'default-capability
            (poo-flow-sandbox-profile-policy-option
             options
             'default-capability
             #f))
      (cons 'metadata
            (poo-flow-sandbox-profile-policy-option options 'metadata '()))))))

;; poo-flow-sandbox-backend-capability-registry?
;;   : (-> SandboxBackendCapabilityRegistryCandidate Boolean)
;;   | contract: recognize POO backend capability registry objects
;;   | result: #t only for registry objects with the registry kind id
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-backend-capability-registry? '())
;;       ;; => #f
;;       ```
;;     %
;; : (-> SandboxBackendCapabilityRegistryCandidate Boolean)
(def (poo-flow-sandbox-backend-capability-registry? value)
  (poo-flow-sandbox-policy-object-kind?
   value
   poo-flow-sandbox-backend-capability-registry-kind))

;; : (-> PooSandboxBackendCapabilityRegistry [Alist])
(def (poo-flow-sandbox-backend-capability-registry-entries registry)
  (if (poo-flow-sandbox-backend-capability-registry? registry)
    (.ref registry 'entries)
    '()))

;; : (-> PooSandboxBackendCapabilityRegistry [Alist])
(def (poo-flow-sandbox-backend-capability-registry-aliases registry)
  (if (poo-flow-sandbox-backend-capability-registry? registry)
    (.ref registry 'aliases)
    '()))

;; poo-flow-sandbox-backend-capability-registry-default-slot
;;   : (-> PooSandboxBackendCapabilityRegistry MaybeSandboxBackendCapability)
;;   | contract: read the default capability slot when a registry is valid
;;   | result: default capability value or #f for invalid/missing registries
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-backend-capability-registry-default-slot '())
;;       ;; => #f
;;       ```
;;     %
;; : (-> PooSandboxBackendCapabilityRegistry MaybeSandboxBackendCapability)
(def (poo-flow-sandbox-backend-capability-registry-default-slot registry)
  (if (and (poo-flow-sandbox-backend-capability-registry? registry)
           (.slot? registry 'default-capability))
    (.ref registry 'default-capability)
    #f))

;; : (-> PooSandboxBackendCapabilityRegistry PooSandboxBackendCapability)
(def (poo-flow-sandbox-backend-capability-registry-default registry)
  (let (default-capability
        (poo-flow-sandbox-backend-capability-registry-default-slot registry))
    (if default-capability
      default-capability
      poo-flow-sandbox-backend-capability/sandbox)))

;; : (-> PooSandboxBackendCapabilityRegistry [Alist])
(def (poo-flow-sandbox-backend-capability-registry-metadata registry)
  (if (and (poo-flow-sandbox-backend-capability-registry? registry)
           (.slot? registry 'metadata))
    (.ref registry 'metadata)
    '()))

;; : (-> Alist Alist Alist)
(def (poo-flow-sandbox-backend-capability-registry-put-entries entries extra)
  (if (null? extra)
    entries
    (let* ((latest (make-hash-table))
           (ordered-extra-keys
            (poo-flow-sandbox-backend-capability-registry-put-entries/index
             (reverse extra)
             latest
             (make-hash-table)
             '()))
           (kept-entries
            (poo-flow-sandbox-backend-capability-registry-put-entries/kept
             entries
             latest
             '())))
      (poo-flow-sandbox-profile-rows/tail
       kept-entries
       (poo-flow-sandbox-backend-capability-registry-put-entries/materialize
        ordered-extra-keys
        latest
	       '())))))

;; : (-> Object Boolean)
(def (poo-flow-sandbox-backend-capability-registry-entry? entry)
  (pair? entry))

;; : (-> Pair Symbol)
(def (poo-flow-sandbox-backend-capability-registry-entry-key entry)
  (car entry))

;; : (-> Alist HashTable HashTable [Symbol] [Symbol])
(def (poo-flow-sandbox-backend-capability-registry-put-entries/index reversed-extra
                                                                     latest
                                                                     seen
                                                                     ordered)
  (cond
   ((null? reversed-extra) ordered)
   ((not (poo-flow-sandbox-backend-capability-registry-entry?
          (car reversed-extra)))
    (poo-flow-sandbox-backend-capability-registry-put-entries/index
     (cdr reversed-extra)
     latest
     seen
     ordered))
   (else
    (let (entry-key (poo-flow-sandbox-backend-capability-registry-entry-key
                     (car reversed-extra)))
      (if (hash-get seen entry-key)
        (poo-flow-sandbox-backend-capability-registry-put-entries/index
         (cdr reversed-extra)
         latest
         seen
         ordered)
        (begin
          (hash-put! seen entry-key #t)
          (hash-put! latest entry-key (car reversed-extra))
          (poo-flow-sandbox-backend-capability-registry-put-entries/index
	           (cdr reversed-extra)
	           latest
	           seen
	           (cons entry-key ordered))))))))

;; : (-> Alist HashTable Alist Alist)
(def (poo-flow-sandbox-backend-capability-registry-put-entries/kept entries
                                                                  latest
                                                                  result)
  (poo-flow-sandbox-profile-rows/tail
   result
   (filter
    (lambda (entry)
      (not
       (and (poo-flow-sandbox-backend-capability-registry-entry? entry)
            (hash-get
             latest
             (poo-flow-sandbox-backend-capability-registry-entry-key entry)))))
    entries)))

;; : (-> [Symbol] HashTable Alist Alist)
(def (poo-flow-sandbox-backend-capability-registry-put-entries/materialize keys
                                                                          latest
                                                                          result)
  (poo-flow-sandbox-profile-rows/tail
   result
   (map (lambda (key) (hash-get latest key)) keys)))

;; : (-> PooSandboxBackendCapabilityRegistry [Alist] [Alist] POOObject)
(def (poo-flow-sandbox-backend-capability-registry-extend registry
                                                          entries
                                                          .
                                                          maybe-options)
  (let* ((options (if (null? maybe-options) '() (car maybe-options)))
         (aliases (poo-flow-sandbox-profile-policy-option
                   options
                   'aliases
                   '()))
         (metadata (poo-flow-sandbox-profile-policy-option
                    options
                    'metadata
                    '()))
         (default-capability
          (if (poo-flow-sandbox-profile-policy-option? options
                                                       'default-capability)
            (poo-flow-sandbox-profile-policy-option
             options
             'default-capability
             #f)
            (poo-flow-sandbox-backend-capability-registry-default-slot
             registry))))
    (poo-flow-sandbox-backend-capability-registry
     (poo-flow-sandbox-backend-capability-registry-put-entries
      (poo-flow-sandbox-backend-capability-registry-entries registry)
      entries)
     (list
      (cons 'aliases
            (poo-flow-sandbox-backend-capability-registry-put-entries
             (poo-flow-sandbox-backend-capability-registry-aliases registry)
             aliases))
      (cons 'default-capability default-capability)
      (cons 'metadata
            (poo-flow-sandbox-profile-rows/tail
             (poo-flow-sandbox-backend-capability-registry-metadata registry)
             metadata))))))

;; : (-> PooSandboxBackendCapabilityRegistry PooSandboxBackendCapabilityRegistry POOObject)
(def (poo-flow-sandbox-backend-capability-registry-merge base extension)
  (let (extension-default
        (poo-flow-sandbox-backend-capability-registry-default-slot extension))
    (poo-flow-sandbox-backend-capability-registry-extend
     base
     (poo-flow-sandbox-backend-capability-registry-entries extension)
     (poo-flow-sandbox-profile-field-rows/tail
      (if extension-default
        (poo-flow-sandbox-profile-field-rows
         (default-capability extension-default))
        '())
      (aliases
       (poo-flow-sandbox-backend-capability-registry-aliases
        extension))
      (metadata
       (poo-flow-sandbox-backend-capability-registry-metadata
        extension))))))

;; poo-flow-sandbox-backend-capability-registry-canonical-kind
;;   : (-> PooSandboxBackendCapabilityRegistry Symbol Symbol)
;;   | contract: resolve backend capability aliases to canonical registry keys
;;   | result: canonical backend kind when an alias exists, otherwise input kind
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-backend-capability-registry-canonical-kind registry 'nono)
;;       ;; => nono
;;       ```
;;     %
;; : (-> PooSandboxBackendCapabilityRegistry Symbol Symbol)
(def (poo-flow-sandbox-backend-capability-registry-canonical-kind registry
                                                                  backend-kind)
  (let (entry
        (assoc backend-kind
               (poo-flow-sandbox-backend-capability-registry-aliases
                registry)))
    (if entry (cdr entry) backend-kind)))

;; poo-flow-sandbox-backend-capability-registry-ref
;;   : (-> PooSandboxBackendCapabilityRegistry Symbol PooSandboxBackendCapability)
;;   | contract: resolve a backend capability through aliases and defaults
;;   | result: matched capability object or the registry default capability
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-backend-capability-registry-ref registry 'nono)
;;       ;; => sandbox backend capability object
;;       ```
;;     %
;; : (-> PooSandboxBackendCapabilityRegistry Symbol PooSandboxBackendCapability)
(def (poo-flow-sandbox-backend-capability-registry-ref registry backend-kind)
  (let* ((canonical-kind
          (poo-flow-sandbox-backend-capability-registry-canonical-kind
           registry
           backend-kind))
         (entry
          (assoc canonical-kind
                 (poo-flow-sandbox-backend-capability-registry-entries
                  registry))))
    (if entry
      (cdr entry)
      (poo-flow-sandbox-backend-capability-registry-default registry))))

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

;; poo-flow-sandbox-backend-capability-registry/sandbox-core
;;   : POOObject
;;   | doc m%
;;       Minimal sandbox-core registry contribution. Module-system catalogs
;;       start from this object and merge backend-module contributions from
;;       enabled modules.
(def poo-flow-sandbox-backend-capability-registry/sandbox-core
  (poo-flow-sandbox-backend-capability-registry
   (list (cons 'sandbox poo-flow-sandbox-backend-capability/sandbox))
   '((metadata . ((scope . sandbox-core)
                  (runtime-executed . #f))))))

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

;; poo-flow-sandbox-backend-capability-registry/default
;;   : POOObject
;;   | doc m%
;;       Default static backend capability registry. Backend modules can later
;;       contribute registry objects through the module-system extension path
;;       without changing capability lookup call sites.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-sandbox-backend-capability/backend-kind
;;        (poo-flow-sandbox-backend-capability-registry-ref
;;         poo-flow-sandbox-backend-capability-registry/default
;;         'cubeSandbox))
;;       ;; => cube
;;       ```
(def poo-flow-sandbox-backend-capability-registry/default
  (poo-flow-sandbox-backend-capability-registry-extend
   poo-flow-sandbox-backend-capability-registry/sandbox-core
   (list
    (cons 'nono poo-flow-sandbox-backend-capability/nono)
    (cons 'cube poo-flow-sandbox-backend-capability/cube)
    (cons 'docker poo-flow-sandbox-backend-capability/docker))
   '((aliases . ((cubeSandbox . cube)))
     (default-capability . #f)
     (metadata . ((scope . sandbox-core)
                  (runtime-executed . #f))))))

;; poo-flow-sandbox-backend-capability-ref
;;   : (-> Symbol PooSandboxBackendCapability)
;;   | contract: resolve a backend capability from the default registry
;;   | result: backend capability object for the requested backend kind
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-backend-capability-ref 'nono)
;;       ;; => sandbox backend capability object
;;       ```
;;     %
;; : (-> Symbol PooSandboxBackendCapability)
(def (poo-flow-sandbox-backend-capability-ref backend-kind)
  (poo-flow-sandbox-backend-capability-registry-ref
   poo-flow-sandbox-backend-capability-registry/default
   backend-kind))
