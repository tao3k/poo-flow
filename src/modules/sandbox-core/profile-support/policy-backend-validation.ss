;;; -*- Gerbil -*-

(import :gerbil/gambit
        (only-in :clan/poo/object object<-alist object? .slot? .ref)
        :poo-flow/src/modules/sandbox-core/profile-support/policy-core
        :poo-flow/src/modules/sandbox-core/profile-support/policy-backend-capability
        :poo-flow/src/modules/sandbox-core/profile-support/projection-syntax)

(export poo-flow-sandbox-backend-capability-registry-diagnostic
        poo-flow-sandbox-backend-capability-registry-diagnostic?
        poo-flow-sandbox-backend-capability-registry-validation
        poo-flow-sandbox-backend-capability-registries-validation
        poo-flow-sandbox-backend-capability-registry-validation?
        poo-flow-sandbox-backend-capability-registry-validation-valid?
        poo-flow-sandbox-backend-capability-registry-validation-diagnostics
        poo-flow-sandbox-backend-capability-registry-validation-diagnostic-count)

;;; Backend registry diagnostics are fixed internal structs until validation
;;; projects them to alists at the receipt boundary.
;; poo-flow-sandbox-backend-capability-registry-diagnostic-entry
;;   : PooSandboxBackendCapabilityRegistryDiagnosticStruct
;;   | contract: fixed diagnostic fields for backend capability registry checks
;;   | result: struct value consumed by the explicit diagnostic ->alist projector
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-backend-capability-registry-diagnostic?
;;        (poo-flow-sandbox-backend-capability-registry-diagnostic
;;         'missing-entry 'capabilities 'error '()))
;;       ;; => #t
;;       ```
;;     %
(defstruct poo-flow-sandbox-backend-capability-registry-diagnostic-entry
  (kind schema code phase slot severity payload))

;; poo-flow-sandbox-backend-capability-registry-diagnostic->alist
;;   : (-> PooSandboxBackendCapabilityRegistryDiagnostic Alist)
;;   | contract: project one fixed backend registry diagnostic to receipt rows
;;   | result: ordered alist preserving payload rows after fixed diagnostic keys
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-backend-capability-registry-diagnostic->alist diagnostic)
;;       ;; => ((kind . "poo-flow.sandbox.backend-capability-registry.diagnostic.v1") ...)
;;       ```
;;     %
(def (poo-flow-sandbox-backend-capability-registry-diagnostic->alist diagnostic)
  (poo-flow-sandbox-profile-field-rows/tail
   (poo-flow-sandbox-backend-capability-registry-diagnostic-entry-payload
    diagnostic)
   (kind
    (poo-flow-sandbox-backend-capability-registry-diagnostic-entry-kind
     diagnostic))
   (schema
    (poo-flow-sandbox-backend-capability-registry-diagnostic-entry-schema
     diagnostic))
   (code
    (poo-flow-sandbox-backend-capability-registry-diagnostic-entry-code
     diagnostic))
   (phase
    (poo-flow-sandbox-backend-capability-registry-diagnostic-entry-phase
     diagnostic))
   (slot
    (poo-flow-sandbox-backend-capability-registry-diagnostic-entry-slot
     diagnostic))
   (severity
    (poo-flow-sandbox-backend-capability-registry-diagnostic-entry-severity
     diagnostic))
   (payload
    (poo-flow-sandbox-backend-capability-registry-diagnostic-entry-payload
     diagnostic))))

;; poo-flow-sandbox-backend-capability-registry-diagnostic
;;   : (-> Symbol Symbol Symbol Alist PooSandboxBackendCapabilityRegistryDiagnostic)
;;   | contract: construct an inert backend registry diagnostic struct
;;   | result: fixed diagnostic value; callers project with ->alist at boundary
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-backend-capability-registry-diagnostic
;;        'missing-entry 'capabilities 'error '())
;;       ;; => backend capability registry diagnostic struct
;;       ```
;;     %
(def (poo-flow-sandbox-backend-capability-registry-diagnostic code
                                                              slot
                                                              severity
                                                              payload)
  (make-poo-flow-sandbox-backend-capability-registry-diagnostic-entry
   poo-flow-sandbox-backend-capability-registry-diagnostic-kind
   poo-flow-sandbox-backend-capability-registry-diagnostic-kind
   code
   'backend-capability-registry
   slot
   severity
   payload))

;; poo-flow-sandbox-backend-capability-registry-diagnostic?
;;   : (-> Value Boolean)
;;   | contract: recognize fixed backend capability diagnostic structs
;;   | result: #t only for backend capability registry diagnostic struct values
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-backend-capability-registry-diagnostic? '())
;;       ;; => #f
;;       ```
;;     %
(def (poo-flow-sandbox-backend-capability-registry-diagnostic? value)
  (poo-flow-sandbox-backend-capability-registry-diagnostic-entry? value))

;; poo-flow-sandbox-backend-capability-registry-invalid-diagnostics
;;   : (-> SandboxBackendCapabilityRegistryCandidate Fixnum [PooSandboxBackendCapabilityRegistryDiagnostic])
;;   | contract: emit invalid-registry diagnostics for non-registry candidates
;;   | result: empty list for valid registries, otherwise one diagnostic struct
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-backend-capability-registry-invalid-diagnostics '() 0)
;;       ;; => (backend capability registry diagnostic struct)
;;       ```
;;     %
;; : (-> SandboxBackendCapabilityRegistryCandidate Fixnum [PooSandboxBackendCapabilityRegistryDiagnostic])
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

;; poo-flow-sandbox-backend-capability-registries-invalid-diagnostics
;;   : (-> [SandboxBackendCapabilityRegistryCandidate] Fixnum [PooSandboxBackendCapabilityRegistryDiagnostic])
;;   | contract: scan registry candidates and collect invalid-registry diagnostics
;;   | result: diagnostic structs in traversal order
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-backend-capability-registries-invalid-diagnostics '() 0)
;;       ;; => ()
;;       ```
;;     %
;; : (-> [SandboxBackendCapabilityRegistryCandidate] Fixnum [PooSandboxBackendCapabilityRegistryDiagnostic])
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

;; poo-flow-sandbox-backend-capability-registry-member?
;;   : (-> SandboxPolicySlotValue [SandboxPolicySlotValue] Boolean)
;;   | contract: test value membership in a registry validation collection
;;   | result: #t when the value is present, otherwise #f
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-backend-capability-registry-member? 'read '(read))
;;       ;; => #t
;;       ```
;;     %
(def (poo-flow-sandbox-backend-capability-registry-member? value values)
  (and (member value values) #t))

;; poo-flow-sandbox-backend-capability-registry-duplicate-keys/add
;;   : (-> [Alist] SandboxPolicyIndex SandboxPolicyIndex [Symbol] [Symbol])
;;   | contract: update duplicate tracking indexes while preserving duplicate keys
;;   | result: duplicate key list accumulated in reverse traversal order
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-backend-capability-registry-duplicate-keys/add
;;        '() (make-hash-table) (make-hash-table) '())
;;       ;; => ()
;;       ```
;;     %
;; : (-> [Alist] SandboxPolicyIndex SandboxPolicyIndex [Symbol] [Symbol])
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

;; poo-flow-sandbox-backend-capability-registry-alias-diagnostics
;;   : (-> [Alist] [Symbol] [PooSandboxBackendCapabilityRegistryDiagnostic])
;;   | contract: validate alias rows against the backend capability entry index
;;   | result: backend capability registry diagnostic structs
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-backend-capability-registry-alias-diagnostics
;;        '() '())
;;       ;; => ()
;;       ```
;;     %
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
      (diagnostics
       (map poo-flow-sandbox-backend-capability-registry-diagnostic->alist
            diagnostics))
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
