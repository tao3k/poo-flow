;;; -*- Gerbil -*-
;;; Boundary: sandbox profile policy and backend capability POO objects.
;;; Invariant: this layer validates and projects; it never executes a backend.

(import :gerbil/gambit
        (only-in :clan/poo/object .ref .slot? object? object<-alist)
        (only-in :poo-flow/src/module-system/durable-policy
                 poo-flow-durable-policy/default
                 poo-flow-durable-policy?
                 poo-flow-durable-policy-name
                 poo-flow-durable-policy-diagnostic->alist
                 poo-flow-durable-policy-diagnostics
                 poo-flow-durable-policy->receipt
                 poo-flow-durable-policy-receipt->alist)
        (only-in :poo-flow/src/modules/agent-sandbox/profile-validation
                 agent-sandbox-profile-resource-policy-filesystem-entry?
                 agent-sandbox-profile-resource-policy-filesystem-diagnostics)
        :poo-flow/src/modules/sandbox-core/profile-support/projection-syntax)

(export poo-flow-sandbox-backend-capability-kind
        poo-flow-sandbox-backend-capability-registry-kind
        poo-flow-sandbox-backend-capability-registry-diagnostic-kind
        poo-flow-sandbox-backend-capability-registry-validation-kind
        poo-flow-sandbox-profile-policy-kind
        poo-flow-sandbox-profile-policy-diagnostic-kind
        poo-flow-sandbox-profile-policy-validation-kind
        poo-flow-sandbox-profile-policy-projection-kind
        poo-flow-sandbox-backend-capability
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
        poo-flow-sandbox-backend-capability-registry-diagnostic
        poo-flow-sandbox-backend-capability-registry-diagnostic?
        poo-flow-sandbox-backend-capability-registry-validation
        poo-flow-sandbox-backend-capability-registries-validation
        poo-flow-sandbox-backend-capability-registry-validation?
        poo-flow-sandbox-backend-capability-registry-validation-valid?
        poo-flow-sandbox-backend-capability-registry-validation-diagnostics
        poo-flow-sandbox-backend-capability-registry-validation-diagnostic-count
        poo-flow-sandbox-backend-capability-registry-ref
        poo-flow-sandbox-backend-capability/sandbox
        poo-flow-sandbox-backend-capability/nono
        poo-flow-sandbox-backend-capability/cube
        poo-flow-sandbox-backend-capability/docker
        poo-flow-sandbox-backend-capability-registry/sandbox-core
        poo-flow-sandbox-backend-capability-registry/default
        poo-flow-sandbox-backend-capability-ref
        poo-flow-sandbox-profile-policy
        poo-flow-sandbox-profile-policy?
        poo-flow-sandbox-profile-policy-required-capabilities
        poo-flow-sandbox-profile-policy-resource-policy
        poo-flow-sandbox-profile-policy-durable-policy
        poo-flow-sandbox-profile-policy-durable-policy-ref
        poo-flow-sandbox-profile-policy-sandbox-handle-class
        poo-flow-sandbox-profile-policy/default
        poo-flow-sandbox-profile-policy-diagnostic
        poo-flow-sandbox-profile-policy-diagnostic?
        poo-flow-sandbox-profile-policy-diagnostics
        poo-flow-sandbox-profile-policy-validation
        poo-flow-sandbox-profile-policy-validation-valid?
        poo-flow-sandbox-profile-policy-validation-diagnostics
        poo-flow-sandbox-profile-policy-validation-diagnostic-count
        poo-flow-sandbox-profile-policy-projection-validation
        poo-flow-sandbox-profile-policy-projection-valid?
        poo-flow-sandbox-profile-policy-projection-diagnostics
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

;; poo-flow-sandbox-backend-capability-registry-kind
;;   : PooFlowSandboxBackendCapabilityRegistryKindId
;;   | type PooFlowSandboxBackendCapabilityRegistryKindId = String
;;   | doc m%
;;       Stable schema kind for backend capability registry POO objects.
;;
;;       # Examples
;;       ```scheme
;;       poo-flow-sandbox-backend-capability-registry-kind
;;       ;; => "poo-flow.sandbox.backend-capability-registry.v1"
;;       ```
(defconst poo-flow-sandbox-backend-capability-registry-kind
  "poo-flow.sandbox.backend-capability-registry.v1")

;; poo-flow-sandbox-backend-capability-registry-diagnostic-kind
;;   : PooFlowSandboxBackendCapabilityRegistryDiagnosticKindId
;;   | type PooFlowSandboxBackendCapabilityRegistryDiagnosticKindId = String
(defconst poo-flow-sandbox-backend-capability-registry-diagnostic-kind
  "poo-flow.sandbox.backend-capability-registry.diagnostic.v1")

;; poo-flow-sandbox-backend-capability-registry-validation-kind
;;   : PooFlowSandboxBackendCapabilityRegistryValidationKindId
;;   | type PooFlowSandboxBackendCapabilityRegistryValidationKindId = String
(defconst poo-flow-sandbox-backend-capability-registry-validation-kind
  "poo-flow.sandbox.backend-capability-registry.validation.v1")

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

;; poo-flow-sandbox-profile-policy-diagnostic-kind
;;   : PooFlowSandboxProfilePolicyDiagnosticKindId
;;   | type PooFlowSandboxProfilePolicyDiagnosticKindId = String
;;   | doc m%
;;       Stable schema kind for profile policy diagnostic POO objects.
;;
;;       # Examples
;;       ```scheme
;;       poo-flow-sandbox-profile-policy-diagnostic-kind
;;       ;; => "poo-flow.sandbox.profile-policy.diagnostic.v1"
;;       ```
(defconst poo-flow-sandbox-profile-policy-diagnostic-kind
  "poo-flow.sandbox.profile-policy.diagnostic.v1")

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

;; : (-> Alist Symbol Boolean)
(def (poo-flow-sandbox-profile-policy-option? options key)
  (and (assoc key options) #t))

;; : (-> [Value] HashTable)
(def (poo-flow-sandbox-policy-value-index values)
  (let (index (make-hash-table))
    (for-each
     (lambda (value)
       (hash-put! index value #t))
     values)
    index))

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

;; : (-> Value Boolean)
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

;; : (-> PooSandboxBackendCapabilityRegistry Value)
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

;; : (-> Alist HashTable HashTable [Symbol] [Symbol])
(def (poo-flow-sandbox-backend-capability-registry-put-entries/index reversed-extra
                                                                     latest
                                                                     seen
                                                                     ordered)
  (cond
   ((null? reversed-extra) ordered)
   ((not (pair? (car reversed-extra)))
    (poo-flow-sandbox-backend-capability-registry-put-entries/index
     (cdr reversed-extra)
     latest
     seen
     ordered))
   ((hash-get seen (caar reversed-extra))
    (poo-flow-sandbox-backend-capability-registry-put-entries/index
     (cdr reversed-extra)
     latest
     seen
     ordered))
   (else
    (hash-put! seen (caar reversed-extra) #t)
    (hash-put! latest (caar reversed-extra) (car reversed-extra))
    (poo-flow-sandbox-backend-capability-registry-put-entries/index
     (cdr reversed-extra)
     latest
     seen
     (cons (caar reversed-extra) ordered)))))

;; : (-> Alist HashTable Alist Alist)
(def (poo-flow-sandbox-backend-capability-registry-put-entries/kept entries
                                                                  latest
                                                                  result)
  (cond
   ((null? entries) (reverse result))
   ((and (pair? (car entries)) (hash-get latest (caar entries)))
    (poo-flow-sandbox-backend-capability-registry-put-entries/kept
     (cdr entries)
     latest
     result))
   (else
    (poo-flow-sandbox-backend-capability-registry-put-entries/kept
     (cdr entries)
     latest
     (cons (car entries) result)))))

;; : (-> [Symbol] HashTable Alist Alist)
(def (poo-flow-sandbox-backend-capability-registry-put-entries/materialize keys
                                                                          latest
                                                                          result)
  (cond
   ((null? keys) (reverse result))
   (else
    (poo-flow-sandbox-backend-capability-registry-put-entries/materialize
     (cdr keys)
     latest
     (cons (hash-get latest (car keys)) result)))))

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

;; : (-> Symbol Symbol Symbol Alist POOObject)
(def (poo-flow-sandbox-backend-capability-registry-diagnostic code
                                                              slot
                                                              severity
                                                              payload)
  (object<-alist
   (poo-flow-sandbox-profile-field-rows/tail
    payload
    (kind poo-flow-sandbox-backend-capability-registry-diagnostic-kind)
    (schema poo-flow-sandbox-backend-capability-registry-diagnostic-kind)
    (code code)
    (phase 'backend-capability-registry)
    (slot slot)
    (severity severity)
    (payload payload))))

;; : (-> Value Boolean)
(def (poo-flow-sandbox-backend-capability-registry-diagnostic? value)
  (poo-flow-sandbox-policy-object-kind?
   value
   poo-flow-sandbox-backend-capability-registry-diagnostic-kind))

;; : (-> Value [POOObject])
(def (poo-flow-sandbox-backend-capability-registry-invalid-diagnostics registry
                                                                       index)
  (if (poo-flow-sandbox-backend-capability-registry? registry)
    '()
    (list
     (poo-flow-sandbox-backend-capability-registry-diagnostic
      'invalid-backend-capability-registry
      'registry
      'error
      (poo-flow-sandbox-profile-field-rows
       (registry-index index)
       (recoverable? #t))))))

;; : (-> [Value] Fixnum [POOObject])
(def (poo-flow-sandbox-backend-capability-registries-invalid-diagnostics
      registries
      index)
  (cond
   ((null? registries) '())
   (else
    (poo-flow-sandbox-profile-rows/tail
     (poo-flow-sandbox-backend-capability-registry-invalid-diagnostics
      (car registries)
      index)
     (poo-flow-sandbox-backend-capability-registries-invalid-diagnostics
      (cdr registries)
      (+ index 1))))))

;; : (-> [PooSandboxBackendCapabilityRegistry] [Alist])
(def (poo-flow-sandbox-backend-capability-registries-entries registries)
  (poo-flow-sandbox-backend-capability-registries-entries/add
   registries
   '()))

;; : (-> [PooSandboxBackendCapabilityRegistry] [Alist] [Alist])
(def (poo-flow-sandbox-backend-capability-registries-entries/add registries
                                                                 entries)
  (cond
   ((null? registries) (reverse entries))
   ((poo-flow-sandbox-backend-capability-registry? (car registries))
    (poo-flow-sandbox-backend-capability-registries-entries/add
     (cdr registries)
     (poo-flow-sandbox-backend-capability-registry-prepend
      (poo-flow-sandbox-backend-capability-registry-entries (car registries))
      entries)))
   (else
    (poo-flow-sandbox-backend-capability-registries-entries/add
     (cdr registries)
     entries))))

;; : (-> [Alist] [Alist] [Alist])
(def (poo-flow-sandbox-backend-capability-registry-prepend values result)
  (cond
   ((null? values) result)
   (else
    (poo-flow-sandbox-backend-capability-registry-prepend
     (cdr values)
     (cons (car values) result)))))

;; : (-> [PooSandboxBackendCapabilityRegistry] [Alist])
(def (poo-flow-sandbox-backend-capability-registries-aliases registries)
  (poo-flow-sandbox-backend-capability-registries-aliases/add
   registries
   '()))

;; : (-> [PooSandboxBackendCapabilityRegistry] [Alist] [Alist])
(def (poo-flow-sandbox-backend-capability-registries-aliases/add registries
                                                                 aliases)
  (cond
   ((null? registries) (reverse aliases))
   ((poo-flow-sandbox-backend-capability-registry? (car registries))
    (poo-flow-sandbox-backend-capability-registries-aliases/add
     (cdr registries)
     (poo-flow-sandbox-backend-capability-registry-prepend
      (poo-flow-sandbox-backend-capability-registry-aliases (car registries))
      aliases)))
   (else
    (poo-flow-sandbox-backend-capability-registries-aliases/add
     (cdr registries)
     aliases))))

;; : (-> Value [Value] Boolean)
(def (poo-flow-sandbox-backend-capability-registry-member? value values)
  (and (member value values) #t))

;; : (-> [Alist] HashTable HashTable [Symbol] [Symbol])
(def (poo-flow-sandbox-backend-capability-registry-duplicate-keys/add entries
                                                                       seen
                                                                       duplicate-index
                                                                       result)
  (cond
   ((null? entries) result)
   ((not (pair? (car entries)))
    (poo-flow-sandbox-backend-capability-registry-duplicate-keys/add
     (cdr entries)
     seen
     duplicate-index
     result))
   ((hash-get seen (caar entries))
    (poo-flow-sandbox-backend-capability-registry-duplicate-keys/add
     (cdr entries)
     seen
     duplicate-index
     (if (hash-get duplicate-index (caar entries))
       result
       (begin
         (hash-put! duplicate-index (caar entries) #t)
         (cons (caar entries) result)))))
   (else
    (hash-put! seen (caar entries) #t)
    (poo-flow-sandbox-backend-capability-registry-duplicate-keys/add
     (cdr entries)
     seen
     duplicate-index
     result))))

;; : (-> [Alist] [Symbol])
(def (poo-flow-sandbox-backend-capability-registry-duplicate-keys entries)
  (reverse
   (poo-flow-sandbox-backend-capability-registry-duplicate-keys/add
    entries
    (make-hash-table)
    (make-hash-table)
    '())))

;; : (-> Symbol Symbol [Symbol] [POOObject])
(def (poo-flow-sandbox-backend-capability-registry-duplicate-diagnostics code
                                                                         slot
                                                                         keys)
  (cond
   ((null? keys) '())
   (else
    (cons
     (poo-flow-sandbox-backend-capability-registry-diagnostic
      code
      slot
      'error
      (poo-flow-sandbox-profile-field-rows
       (key (car keys))
       (recoverable? #t)))
     (poo-flow-sandbox-backend-capability-registry-duplicate-diagnostics
      code
      slot
      (cdr keys))))))

;; : (-> [Alist] [POOObject])
(def (poo-flow-sandbox-backend-capability-registry-entry-diagnostics entries)
  (cond
   ((null? entries) '())
   ((not (pair? (car entries)))
    (cons
     (poo-flow-sandbox-backend-capability-registry-diagnostic
      'invalid-backend-capability-entry
      'entries
      'error
      (poo-flow-sandbox-profile-field-rows
       (entry (car entries))
       (recoverable? #t)))
     (poo-flow-sandbox-backend-capability-registry-entry-diagnostics
      (cdr entries))))
   ((not (poo-flow-sandbox-backend-capability? (cdar entries)))
    (cons
     (poo-flow-sandbox-backend-capability-registry-diagnostic
      'invalid-backend-capability-entry
      'entries
      'error
      (poo-flow-sandbox-profile-field-rows
       (backend-kind (caar entries))
       (recoverable? #t)))
     (poo-flow-sandbox-backend-capability-registry-entry-diagnostics
      (cdr entries))))
   ((not (equal? (caar entries)
                 (poo-flow-sandbox-backend-capability/backend-kind
                  (cdar entries))))
    (cons
     (poo-flow-sandbox-backend-capability-registry-diagnostic
      'backend-capability-entry-key-mismatch
      'entries
      'error
      (list
       (cons 'entry-key (caar entries))
       (cons 'backend-kind
             (poo-flow-sandbox-backend-capability/backend-kind
              (cdar entries)))
       (cons 'recoverable? #t)))
     (poo-flow-sandbox-backend-capability-registry-entry-diagnostics
      (cdr entries))))
   (else
    (poo-flow-sandbox-backend-capability-registry-entry-diagnostics
     (cdr entries)))))

;; : (-> [Alist] [Symbol] [Symbol])
(def (poo-flow-sandbox-backend-capability-registry-entry-keys/rev entries
                                                                 keys-rev)
  (cond
   ((null? entries) keys-rev)
   ((pair? (car entries))
    (poo-flow-sandbox-backend-capability-registry-entry-keys/rev
     (cdr entries)
     (cons (caar entries) keys-rev)))
   (else
    (poo-flow-sandbox-backend-capability-registry-entry-keys/rev
     (cdr entries)
     keys-rev))))

;; : (-> [Alist] [Symbol])
(def (poo-flow-sandbox-backend-capability-registry-entry-keys entries)
  (reverse
   (poo-flow-sandbox-backend-capability-registry-entry-keys/rev
    entries
    '())))

;; : (-> [Alist] [Symbol] [POOObject])
(def (poo-flow-sandbox-backend-capability-registry-alias-diagnostics aliases
                                                                      entry-index)
  (cond
   ((null? aliases) '())
   ((not (and (pair? (car aliases))
              (symbol? (caar aliases))
              (symbol? (cdar aliases))))
    (cons
     (poo-flow-sandbox-backend-capability-registry-diagnostic
      'invalid-backend-capability-alias
      'aliases
      'error
      (poo-flow-sandbox-profile-field-rows
       (alias (car aliases))
       (recoverable? #t)))
     (poo-flow-sandbox-backend-capability-registry-alias-diagnostics
      (cdr aliases)
      entry-index)))
   ((not (hash-get entry-index (cdar aliases)))
    (cons
     (poo-flow-sandbox-backend-capability-registry-diagnostic
      'backend-capability-alias-target-missing
      'aliases
      'error
       (poo-flow-sandbox-profile-field-rows
        (alias (caar aliases))
        (target (cdar aliases))
        (recoverable? #t)))
     (poo-flow-sandbox-backend-capability-registry-alias-diagnostics
      (cdr aliases)
      entry-index)))
   (else
    (poo-flow-sandbox-backend-capability-registry-alias-diagnostics
     (cdr aliases)
     entry-index))))

;; : (-> PooSandboxBackendCapabilityRegistry PooSandboxBackendCapabilityRegistryValidation)
(def (poo-flow-sandbox-backend-capability-registry-validation registry)
  (poo-flow-sandbox-backend-capability-registries-validation (list registry)))

;; : (-> [PooSandboxBackendCapabilityRegistry] PooSandboxBackendCapabilityRegistryValidation)
(def (poo-flow-sandbox-backend-capability-registries-validation registries)
  (let* ((entries
          (poo-flow-sandbox-backend-capability-registries-entries registries))
         (aliases
          (poo-flow-sandbox-backend-capability-registries-aliases registries))
         (entry-keys
          (poo-flow-sandbox-backend-capability-registry-entry-keys entries))
         (entry-index
          (poo-flow-sandbox-policy-value-index entry-keys))
         (diagnostics
          (poo-flow-sandbox-profile-rows/tail
           (poo-flow-sandbox-backend-capability-registries-invalid-diagnostics
            registries
            0)
           (poo-flow-sandbox-profile-rows/tail
            (poo-flow-sandbox-backend-capability-registry-entry-diagnostics
             entries)
            (poo-flow-sandbox-profile-rows/tail
             (poo-flow-sandbox-backend-capability-registry-duplicate-diagnostics
              'duplicate-backend-capability-id
              'entries
              (poo-flow-sandbox-backend-capability-registry-duplicate-keys
               entries))
             (poo-flow-sandbox-profile-rows/tail
              (poo-flow-sandbox-backend-capability-registry-duplicate-diagnostics
               'duplicate-backend-capability-alias
               'aliases
               (poo-flow-sandbox-backend-capability-registry-duplicate-keys
                aliases))
              (poo-flow-sandbox-backend-capability-registry-alias-diagnostics
               aliases
               entry-index)))))))
    (object<-alist
     (poo-flow-sandbox-profile-field-rows
      (kind poo-flow-sandbox-backend-capability-registry-validation-kind)
      (schema poo-flow-sandbox-backend-capability-registry-validation-kind)
      (valid? (null? diagnostics))
      (registry-count (length registries))
      (entry-count (length entries))
      (alias-count (length aliases))
      (diagnostics diagnostics)
      (diagnostic-count (length diagnostics))
      (runtime-executed #f)))))

;; : (-> Value Boolean)
(def (poo-flow-sandbox-backend-capability-registry-validation? value)
  (poo-flow-sandbox-policy-object-kind?
   value
   poo-flow-sandbox-backend-capability-registry-validation-kind))

;; : (-> PooSandboxBackendCapabilityRegistryValidation Boolean)
(def (poo-flow-sandbox-backend-capability-registry-validation-valid? validation)
  (and (object? validation)
       (.slot? validation 'valid?)
       (.ref validation 'valid?)))

;; : (-> PooSandboxBackendCapabilityRegistryValidation [PooSandboxBackendCapabilityRegistryDiagnostic])
(def (poo-flow-sandbox-backend-capability-registry-validation-diagnostics
      validation)
  (poo-flow-sandbox-profile-policy-object-slot/default
   validation
   'diagnostics
   '()))

;; : (-> PooSandboxBackendCapabilityRegistryValidation Fixnum)
(def (poo-flow-sandbox-backend-capability-registry-validation-diagnostic-count
      validation)
  (poo-flow-sandbox-profile-policy-object-slot/default
   validation
   'diagnostic-count
   0))

;; : (-> PooSandboxBackendCapabilityRegistry Symbol Symbol)
(def (poo-flow-sandbox-backend-capability-registry-canonical-kind registry
                                                                  backend-kind)
  (let (entry
        (assoc backend-kind
               (poo-flow-sandbox-backend-capability-registry-aliases
                registry)))
    (if entry (cdr entry) backend-kind)))

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

;; : (-> Symbol PooSandboxBackendCapability)
(def (poo-flow-sandbox-backend-capability-ref backend-kind)
  (poo-flow-sandbox-backend-capability-registry-ref
   poo-flow-sandbox-backend-capability-registry/default
   backend-kind))

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
      (cons 'durable-policy
            (poo-flow-sandbox-profile-policy-option
             options
             'durable-policy
             poo-flow-durable-policy/default))
      (cons 'sandbox-handle-class
            (poo-flow-sandbox-profile-policy-option
             options
             'sandbox-handle-class
             'sandbox/profile-handle))
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

;; : (-> PooSandboxProfilePolicy ResourcePolicy)
(def (poo-flow-sandbox-profile-policy-resource-policy policy)
  (if (poo-flow-sandbox-profile-policy? policy)
    (.ref policy 'resource-policy)
    '()))

;; : (-> PooSandboxProfilePolicy PooDurablePolicy)
(def (poo-flow-sandbox-profile-policy-durable-policy policy)
  (if (and (poo-flow-sandbox-profile-policy? policy)
           (.slot? policy 'durable-policy))
    (.ref policy 'durable-policy)
    poo-flow-durable-policy/default))

;; : (-> PooSandboxProfilePolicy MaybeSymbol)
(def (poo-flow-sandbox-profile-policy-durable-policy-ref policy)
  (let (durable-policy
        (poo-flow-sandbox-profile-policy-durable-policy policy))
    (if (poo-flow-durable-policy? durable-policy)
      (poo-flow-durable-policy-name durable-policy)
      #f)))

;; : (-> PooSandboxProfilePolicy Symbol)
(def (poo-flow-sandbox-profile-policy-sandbox-handle-class policy)
  (if (and (poo-flow-sandbox-profile-policy? policy)
           (.slot? policy 'sandbox-handle-class))
    (.ref policy 'sandbox-handle-class)
    'sandbox/profile-handle))

;; : PooSandboxProfilePolicy
(def poo-flow-sandbox-profile-policy/default
  (poo-flow-sandbox-profile-policy '()))

;; : (-> CapabilityList CapabilityList CapabilityList)
;; | type CapabilityList = (List Symbol)
(def (poo-flow-sandbox-profile-policy-append-distinct base extra)
  (if (null? extra)
    base
    (poo-flow-sandbox-profile-policy-append-distinct/indexed
     base
     extra
     (poo-flow-sandbox-policy-value-index base)
     '())))

;; : (-> CapabilityList CapabilityList HashTable CapabilityList CapabilityList)
(def (poo-flow-sandbox-profile-policy-append-distinct/indexed base
                                                              extra
                                                              seen
                                                              added)
  (cond
   ((null? extra)
    (if (null? added)
      base
      (append base (reverse added))))
   ((hash-get seen (car extra))
    (poo-flow-sandbox-profile-policy-append-distinct/indexed
     base
     (cdr extra)
     seen
     added))
   (else
    (hash-put! seen (car extra) #t)
    (poo-flow-sandbox-profile-policy-append-distinct/indexed
     base
     (cdr extra)
     seen
     (cons (car extra) added)))))

;; : (-> PooSandboxProfilePolicy [Symbol] [Symbol])
(def (poo-flow-sandbox-profile-policy-effective-required policy
                                                         profile-capabilities)
  (poo-flow-sandbox-profile-policy-append-distinct
   (poo-flow-sandbox-profile-policy-required-capabilities policy)
   profile-capabilities))

;; : (-> Symbol Symbol Symbol Alist POOObject)
(def (poo-flow-sandbox-profile-policy-diagnostic code
                                                 phase
                                                 severity
                                                 payload)
  (object<-alist
   (append
    (list (cons 'kind poo-flow-sandbox-profile-policy-diagnostic-kind)
          (cons 'schema poo-flow-sandbox-profile-policy-diagnostic-kind)
          (cons 'code code)
          (cons 'phase phase)
          (cons 'severity severity)
          (cons 'payload payload))
    payload)))

;; : (-> Value Boolean)
(def (poo-flow-sandbox-profile-policy-diagnostic? value)
  (poo-flow-sandbox-policy-object-kind?
   value
   poo-flow-sandbox-profile-policy-diagnostic-kind))

;; : (-> Capability Boolean)
(def (poo-flow-sandbox-profile-policy-filesystem-capability? capability)
  (cond
   ((symbol? capability)
    (or (eq? capability 'filesystem)
        (eq? capability 'filesystem-read)
        (eq? capability 'filesystem-write)))
   ((pair? capability)
    (poo-flow-sandbox-profile-policy-filesystem-capability? (car capability)))
   (else #f)))

;; : (-> [Capability] Boolean)
(def (poo-flow-sandbox-profile-policy-capabilities-have-filesystem?
      capabilities)
  (cond
   ((null? capabilities) #f)
   ((not (pair? capabilities)) #f)
   ((poo-flow-sandbox-profile-policy-filesystem-capability?
     (car capabilities))
    #t)
   (else
    (poo-flow-sandbox-profile-policy-capabilities-have-filesystem?
     (cdr capabilities)))))

;; : (-> ResourcePolicy Boolean)
(def (poo-flow-sandbox-profile-policy-resource-policy-has-filesystem?
      resource-policy)
  (cond
   ((null? resource-policy) #f)
   ((not (pair? resource-policy)) #f)
   ((agent-sandbox-profile-resource-policy-filesystem-entry?
     (car resource-policy))
    #t)
   (else
    (poo-flow-sandbox-profile-policy-resource-policy-has-filesystem?
     (cdr resource-policy)))))

;; : (-> Alist Symbol Value Value)
(def (poo-flow-sandbox-profile-policy-alist-ref entries key default-value)
  (let (entry (assoc key entries))
    (if entry (cdr entry) default-value)))

;; : (-> Symbol Symbol Alist POOObject)
(def (poo-flow-sandbox-profile-policy-resource-diagnostic profile-name
                                                          backend-kind
                                                          diagnostic)
  (poo-flow-sandbox-profile-policy-diagnostic
   (poo-flow-sandbox-profile-policy-alist-ref
    diagnostic
    'code
    'invalid-resource-policy)
   'resource
   'error
   (poo-flow-sandbox-profile-field-rows
    (profile profile-name)
    (backend-kind backend-kind)
    (slot
     (poo-flow-sandbox-profile-policy-alist-ref
      diagnostic
      'field
      'resource-policy))
    (detail diagnostic)
    (recoverable? #t))))

;; : (-> Symbol Symbol [Symbol] ResourcePolicy [POOObject])
(def (poo-flow-sandbox-profile-policy-resource-diagnostics profile-name
                                                           backend-kind
                                                           capabilities
                                                           resource-policy)
  (let ((has-filesystem-capability?
         (poo-flow-sandbox-profile-policy-capabilities-have-filesystem?
          capabilities))
        (has-filesystem-resource?
         (poo-flow-sandbox-profile-policy-resource-policy-has-filesystem?
          resource-policy)))
    (poo-flow-sandbox-profile-rows/tail
     (if (and (not (null? resource-policy))
              (not has-filesystem-capability?))
       (list
        (poo-flow-sandbox-profile-policy-diagnostic
         'missing-filesystem-sandbox-capability
         'resource
         'error
         (poo-flow-sandbox-profile-field-rows
          (profile profile-name)
          (backend-kind backend-kind)
          (slot 'capabilities)
          (requires 'resource-policy)
          (resource-policy resource-policy)
          (recoverable? #t))))
       '())
     (poo-flow-sandbox-profile-rows/tail
      (if (and has-filesystem-capability?
               (not has-filesystem-resource?))
        (list
         (poo-flow-sandbox-profile-policy-diagnostic
          'missing-filesystem-sandbox-resource
          'resource
          'error
          (poo-flow-sandbox-profile-field-rows
           (profile profile-name)
           (backend-kind backend-kind)
           (slot 'resource-policy)
           (requires 'filesystem)
           (resource-policy resource-policy)
           (recoverable? #t))))
        '())
      (poo-flow-sandbox-profile-policy-resource-diagnostic-rows
       profile-name
       backend-kind
       (agent-sandbox-profile-resource-policy-filesystem-diagnostics
        resource-policy))))))

;; : (-> Symbol Symbol [Alist] [Alist] [Alist])
(def (poo-flow-sandbox-profile-policy-resource-diagnostic-rows/rev profile-name
                                                                    backend-kind
                                                                    diagnostics
                                                                    rows-rev)
  (if (null? diagnostics)
    rows-rev
    (poo-flow-sandbox-profile-policy-resource-diagnostic-rows/rev
     profile-name
     backend-kind
     (cdr diagnostics)
     (cons (poo-flow-sandbox-profile-policy-resource-diagnostic
            profile-name
            backend-kind
            (car diagnostics))
           rows-rev))))

;; : (-> Symbol Symbol [Alist] [Alist])
(def (poo-flow-sandbox-profile-policy-resource-diagnostic-rows profile-name
                                                               backend-kind
                                                               diagnostics)
  (reverse
   (poo-flow-sandbox-profile-policy-resource-diagnostic-rows/rev
    profile-name
    backend-kind
    diagnostics
    '())))

;; : (-> PooSandboxProfilePolicy Alist)
(def (poo-flow-sandbox-profile-policy-durable-summary profile-policy
                                                      profile-name
                                                      backend-kind
                                                      backend-ref)
  (let (durable-policy
        (poo-flow-sandbox-profile-policy-durable-policy profile-policy))
    (if (poo-flow-durable-policy? durable-policy)
      (let (receipt
            (poo-flow-durable-policy->receipt
             durable-policy
             (list (cons 'session-id profile-name)
                   (cons 'loop-run-id backend-ref))))
        (let (receipt-alist
              (poo-flow-durable-policy-receipt->alist receipt))
          (list
           (cons 'policy-id
                 (poo-flow-sandbox-profile-policy-alist-ref
                  receipt-alist
                  'policy-id
                  #f))
           (cons 'backend-kind backend-kind)
           (cons 'backend-ref backend-ref)
           (cons 'sandbox-handle-class
                 (poo-flow-sandbox-profile-policy-sandbox-handle-class
                  profile-policy))
           (cons 'journal-owner
                 (poo-flow-sandbox-profile-policy-alist-ref
                  receipt-alist
                  'journal-owner
                  #f))
           (cons 'checkpoint-store
                 (poo-flow-sandbox-profile-policy-alist-ref
                  receipt-alist
                  'checkpoint-store
                  #f))
           (cons 'repair-mode
                 (poo-flow-sandbox-profile-policy-alist-ref
                  receipt-alist
                  'repair-mode
                  #f))
           (cons 'action-classes
                 (poo-flow-sandbox-profile-policy-alist-ref
                  receipt-alist
                  'action-classes
                  '()))
           (cons 'runtime-owner
                 (poo-flow-sandbox-profile-policy-alist-ref
                  receipt-alist
                  'runtime-owner
                  #f))
           (cons 'valid?
                 (poo-flow-sandbox-profile-policy-alist-ref
                  receipt-alist
                  'valid?
                  #f))
           (cons 'diagnostic-count
                 (poo-flow-sandbox-profile-policy-alist-ref
                  receipt-alist
                  'diagnostic-count
                  0))
           (cons 'runtime-executed #f))))
      (list
       (cons 'policy-id #f)
       (cons 'backend-kind backend-kind)
       (cons 'backend-ref backend-ref)
       (cons 'sandbox-handle-class
             (poo-flow-sandbox-profile-policy-sandbox-handle-class
              profile-policy))
       (cons 'valid? #f)
       (cons 'diagnostic-count 1)
       (cons 'runtime-executed #f)))))

;; : (-> Symbol Symbol PooSandboxProfilePolicy [POOObject])
(def (poo-flow-sandbox-profile-policy-durable-diagnostics profile-name
                                                          backend-kind
                                                          profile-policy)
  (let (durable-policy
        (poo-flow-sandbox-profile-policy-durable-policy profile-policy))
    (cond
     ((not durable-policy)
      (list
       (poo-flow-sandbox-profile-policy-diagnostic
        'missing-durable-placement-policy
        'durable
        'error
        (list
         (cons 'profile profile-name)
         (cons 'backend-kind backend-kind)
         (cons 'slot 'durable-policy)
         (cons 'requires 'sandbox-durable-placement)
         (cons 'recoverable? #t)))))
     ((not (poo-flow-durable-policy? durable-policy))
      (list
       (poo-flow-sandbox-profile-policy-diagnostic
        'invalid-durable-placement-policy
        'durable
        'error
        (list
         (cons 'profile profile-name)
         (cons 'backend-kind backend-kind)
         (cons 'slot 'durable-policy)
         (cons 'value durable-policy)
         (cons 'expected 'poo-flow-durable-policy)
         (cons 'recoverable? #t)))))
     (else
      (let (durable-diagnostics
            (poo-flow-durable-policy-diagnostics durable-policy))
        (if (null? durable-diagnostics)
          '()
          (list
           (poo-flow-sandbox-profile-policy-diagnostic
            'invalid-durable-placement-policy
            'durable
            'error
            (list
             (cons 'profile profile-name)
             (cons 'backend-kind backend-kind)
             (cons 'slot 'durable-policy)
             (cons 'policy
                   (poo-flow-durable-policy-name durable-policy))
             (cons 'diagnostics
                   (map poo-flow-durable-policy-diagnostic->alist
                        durable-diagnostics))
             (cons 'recoverable? #t))))))))))

;; poo-flow-sandbox-profile-policy-diagnostics
;;   : (-> Symbol Symbol PooSandboxBackendCapability PooSandboxProfilePolicy [Symbol] [POOObject])
;;   | doc m%
;;       `poo-flow-sandbox-profile-policy-diagnostics` compares effective
;;       profile capabilities with the selected backend's static POO capability
;;       object and returns POO diagnostic objects for unsupported capabilities
;;       and invalid resource policy.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-diagnostics
;;        'agent/gpu 'nono poo-flow-sandbox-backend-capability/nono
;;        (poo-flow-sandbox-profile-policy '(gpu-device)) '())
;;       ;; => POO diagnostic objects
;;       ```
(def (poo-flow-sandbox-profile-policy-diagnostics profile-name
                                                  backend-kind
                                                  backend-capability
                                                  profile-policy
                                                  profile-capabilities
                                                  .
                                                  maybe-resource-policy)
  (let* ((required
          (poo-flow-sandbox-profile-policy-effective-required
           profile-policy
           profile-capabilities))
         (resource-policy
          (if (null? maybe-resource-policy)
            (poo-flow-sandbox-profile-policy-resource-policy profile-policy)
            (car maybe-resource-policy))))
    (poo-flow-sandbox-profile-rows/tail
     (poo-flow-sandbox-profile-policy-required-capability-diagnostics
      profile-name
      backend-kind
      backend-capability
      required)
     (poo-flow-sandbox-profile-rows/tail
      (poo-flow-sandbox-profile-policy-resource-diagnostics
       profile-name
       backend-kind
       profile-capabilities
       resource-policy)
      (poo-flow-sandbox-profile-policy-durable-diagnostics
       profile-name
       backend-kind
       profile-policy)))))

;; : (-> Symbol Symbol PooSandboxBackendCapability [Symbol] [Alist] [Alist])
(def (poo-flow-sandbox-profile-policy-required-capability-diagnostics/rev
      profile-name
      backend-kind
      backend-capability
      required
      diagnostics-rev)
  (cond
   ((null? required) diagnostics-rev)
   ((poo-flow-sandbox-backend-capability-supports?
     backend-capability
     (car required))
    (poo-flow-sandbox-profile-policy-required-capability-diagnostics/rev
     profile-name
     backend-kind
     backend-capability
     (cdr required)
     diagnostics-rev))
   (else
    (poo-flow-sandbox-profile-policy-required-capability-diagnostics/rev
     profile-name
     backend-kind
     backend-capability
     (cdr required)
     (cons
      (poo-flow-sandbox-profile-policy-diagnostic
       'missing-backend-capability
       'capability
       'error
       (poo-flow-sandbox-profile-field-rows
        (profile profile-name)
        (backend-kind backend-kind)
        (slot 'capabilities)
        (required (car required))
        (supported
         (poo-flow-sandbox-backend-capability/capabilities
          backend-capability))
        (recoverable? #t)))
      diagnostics-rev)))))

;; : (-> Symbol Symbol PooSandboxBackendCapability [Symbol] [Alist])
(def (poo-flow-sandbox-profile-policy-required-capability-diagnostics
      profile-name
      backend-kind
      backend-capability
      required)
  (reverse
   (poo-flow-sandbox-profile-policy-required-capability-diagnostics/rev
    profile-name
    backend-kind
    backend-capability
    required
    '())))

;; : (-> Symbol Symbol Symbol PooSandboxBackendCapability PooSandboxProfilePolicy [Symbol] POOObject)
(def (poo-flow-sandbox-profile-policy-validation profile-name
                                                 backend-kind
                                                 backend-ref
                                                 backend-capability
                                                 profile-policy
                                                 profile-capabilities
                                                 .
                                                 maybe-resource-policy)
  (let* ((resource-policy
          (if (null? maybe-resource-policy)
            (poo-flow-sandbox-profile-policy-resource-policy profile-policy)
            (car maybe-resource-policy)))
         (diagnostics
          (poo-flow-sandbox-profile-policy-diagnostics
           profile-name
           backend-kind
           backend-capability
           profile-policy
           profile-capabilities
           resource-policy))
         (valid? (null? diagnostics)))
    (object<-alist
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
      (cons 'resource-policy resource-policy)
      (cons 'durable-policy-ref
            (poo-flow-sandbox-profile-policy-durable-policy-ref
             profile-policy))
      (cons 'durable-policy-summary
            (poo-flow-sandbox-profile-policy-durable-summary
             profile-policy
             profile-name
             backend-kind
             backend-ref))
      (cons 'durable-valid?
            (and (poo-flow-sandbox-profile-policy-durable-policy-ref
                  profile-policy)
                 (null? (poo-flow-sandbox-profile-policy-durable-diagnostics
                         profile-name
                         backend-kind
                         profile-policy))))
      (cons 'sandbox-handle-class
            (poo-flow-sandbox-profile-policy-sandbox-handle-class
             profile-policy))
      (cons 'diagnostics diagnostics)
      (cons 'diagnostic-count (length diagnostics))
      (cons 'runtime-executed #f)))))

;; : (-> POOObject Boolean)
(def (poo-flow-sandbox-profile-policy-validation-valid? validation)
  (and (object? validation)
       (.slot? validation 'valid?)
       (.ref validation 'valid?)))

;; : (-> POOObject Symbol Value Value)
(def (poo-flow-sandbox-profile-policy-object-slot/default object
                                                           key
                                                           default-value)
  (if (and (object? object) (.slot? object key))
    (.ref object key)
    default-value))

;; : (-> PooSandboxProfilePolicyValidation [PooSandboxProfilePolicyDiagnostic])
(def (poo-flow-sandbox-profile-policy-validation-diagnostics validation)
  (poo-flow-sandbox-profile-policy-object-slot/default
   validation
   'diagnostics
   '()))

;; : (-> PooSandboxProfilePolicyValidation Fixnum)
(def (poo-flow-sandbox-profile-policy-validation-diagnostic-count validation)
  (poo-flow-sandbox-profile-policy-object-slot/default
   validation
   'diagnostic-count
   0))

;; : (-> PooSandboxProfilePolicyProjection PooSandboxProfilePolicyValidation)
(def (poo-flow-sandbox-profile-policy-projection-validation projection)
  (poo-flow-sandbox-profile-policy-object-slot/default
   projection
   'validation
   #f))

;; : (-> PooSandboxProfilePolicyProjection Boolean)
(def (poo-flow-sandbox-profile-policy-projection-valid? projection)
  (and (object? projection)
       (.slot? projection 'valid?)
       (.ref projection 'valid?)))

;; : (-> PooSandboxProfilePolicyProjection [PooSandboxProfilePolicyDiagnostic])
(def (poo-flow-sandbox-profile-policy-projection-diagnostics projection)
  (let (validation
        (poo-flow-sandbox-profile-policy-projection-validation projection))
    (if validation
      (poo-flow-sandbox-profile-policy-validation-diagnostics validation)
      '())))

;; : (-> Symbol Symbol Symbol PooSandboxBackendCapability PooSandboxProfilePolicy [Symbol] POOObject)
(def (poo-flow-sandbox-profile-policy-projection profile-name
                                                 backend-kind
                                                 backend-ref
                                                 backend-capability
                                                 profile-policy
                                                 profile-capabilities
                                                 .
                                                 maybe-resource-policy)
  (let (validation
        (poo-flow-sandbox-profile-policy-validation
         profile-name
         backend-kind
         backend-ref
         backend-capability
         profile-policy
         profile-capabilities
         (if (null? maybe-resource-policy)
           (poo-flow-sandbox-profile-policy-resource-policy profile-policy)
           (car maybe-resource-policy))))
    (object<-alist
     (list
      (cons 'kind poo-flow-sandbox-profile-policy-projection-kind)
      (cons 'schema poo-flow-sandbox-profile-policy-projection-kind)
      (cons 'profile profile-name)
      (cons 'backend-kind backend-kind)
      (cons 'backend-ref backend-ref)
      (cons 'validation validation)
      (cons 'valid?
            (poo-flow-sandbox-profile-policy-validation-valid? validation))
      (cons 'durable-policy-ref
            (poo-flow-sandbox-profile-policy-durable-policy-ref
             profile-policy))
      (cons 'durable-policy-summary
            (poo-flow-sandbox-profile-policy-durable-summary
             profile-policy
             profile-name
             backend-kind
             backend-ref))
      (cons 'durable-valid?
            (poo-flow-sandbox-profile-policy-object-slot/default
             validation
             'durable-valid?
             #f))
      (cons 'sandbox-handle-class
            (poo-flow-sandbox-profile-policy-sandbox-handle-class
             profile-policy))
      (cons 'runtime-owner "marlin-agent-core")
      (cons 'runtime-executed #f)))))
