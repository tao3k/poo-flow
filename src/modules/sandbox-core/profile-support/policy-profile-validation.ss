;;; -*- Gerbil -*-

(import :gerbil/gambit
        (only-in :clan/poo/object object? .slot? .ref object<-alist)
        :poo-flow/src/modules/sandbox-core/profile-support/policy-core
        :poo-flow/src/modules/sandbox-core/profile-support/policy-backend-capability
        :poo-flow/src/modules/sandbox-core/profile-support/policy-backend-validation
        :poo-flow/src/modules/sandbox-core/profile-support/policy-profile-core
        :poo-flow/src/modules/sandbox-core/profile-support/projection-syntax
        (only-in :poo-flow/src/module-system/durable-policy
                 poo-flow-durable-policy?
                 poo-flow-durable-policy-diagnostic->alist
                 poo-flow-durable-policy-diagnostics
                 poo-flow-durable-policy->receipt
                 poo-flow-durable-policy-name
                 poo-flow-durable-policy-receipt->alist)
        (only-in :poo-flow/src/modules/agent-sandbox/profile-validation
                 agent-sandbox-profile-resource-policy-filesystem-entry?
                 agent-sandbox-profile-resource-policy-filesystem-diagnostics))

(export poo-flow-sandbox-profile-policy-diagnostic
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

;; poo-flow-sandbox-profile-policy-diagnostic-entry
;;   : PooSandboxProfilePolicyDiagnosticStruct
;;   | contract: fixed diagnostic fields for sandbox profile policy checks
;;   | result: struct value consumed by the explicit diagnostic ->alist projector
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-diagnostic?
;;        (poo-flow-sandbox-profile-policy-diagnostic
;;         'missing-resource 'resource-policy 'error '()))
;;       ;; => #t
;;       ```
;;     %
(defstruct poo-flow-sandbox-profile-policy-diagnostic-entry
  (kind schema code phase severity payload))

;; poo-flow-sandbox-profile-policy-diagnostic->alist
;;   : (-> PooSandboxProfilePolicyDiagnostic Alist)
;;   | contract: project one fixed profile policy diagnostic to receipt rows
;;   | result: ordered alist preserving payload rows after fixed diagnostic keys
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-diagnostic->alist diagnostic)
;;       ;; => ((kind . "poo-flow.sandbox.profile-policy.diagnostic.v1") ...)
;;       ```
;;     %
(def (poo-flow-sandbox-profile-policy-diagnostic->alist diagnostic)
  (poo-flow-sandbox-profile-field-rows/tail
   (poo-flow-sandbox-profile-policy-diagnostic-entry-payload diagnostic)
   (kind
    (poo-flow-sandbox-profile-policy-diagnostic-entry-kind diagnostic))
   (schema
    (poo-flow-sandbox-profile-policy-diagnostic-entry-schema diagnostic))
   (code
    (poo-flow-sandbox-profile-policy-diagnostic-entry-code diagnostic))
   (phase
    (poo-flow-sandbox-profile-policy-diagnostic-entry-phase diagnostic))
   (severity
    (poo-flow-sandbox-profile-policy-diagnostic-entry-severity diagnostic))
   (payload
    (poo-flow-sandbox-profile-policy-diagnostic-entry-payload diagnostic))))

;; poo-flow-sandbox-profile-policy-diagnostic
;;   : (-> Symbol Symbol Symbol Alist PooSandboxProfilePolicyDiagnostic)
;;   | contract: construct an inert sandbox profile diagnostic struct
;;   | result: fixed diagnostic value; callers project with ->alist at boundary
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-diagnostic
;;        'missing-resource 'resource-policy 'error '())
;;       ;; => sandbox profile policy diagnostic struct
;;       ```
;;     %
(def (poo-flow-sandbox-profile-policy-diagnostic code
                                                 phase
                                                 severity
                                                 payload)
  (make-poo-flow-sandbox-profile-policy-diagnostic-entry
   poo-flow-sandbox-profile-policy-diagnostic-kind
   poo-flow-sandbox-profile-policy-diagnostic-kind
   code
   phase
   severity
   payload))

;; poo-flow-sandbox-profile-policy-diagnostic?
;;   : (-> Value Boolean)
;;   | contract: recognize fixed sandbox profile diagnostic structs
;;   | result: #t only for sandbox profile policy diagnostic struct values
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-diagnostic? '())
;;       ;; => #f
;;       ```
;;     %
(def (poo-flow-sandbox-profile-policy-diagnostic? value)
  (poo-flow-sandbox-profile-policy-diagnostic-entry? value))

;; : (-> Symbol Symbol Alist Alist)
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

;; poo-flow-sandbox-profile-policy-alist-ref
;;   : (-> Alist Symbol Value Value)
;;   | contract: read one profile row with a default value
;;   | result: row value when present, otherwise default value
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-alist-ref
;;        '((network-policy . deny)) 'network-policy 'allow)
;;       ;; => deny
;;       ```
;;     %
(def (poo-flow-sandbox-profile-policy-alist-ref entries key default-value)
  (let (entry (assoc key entries))
    (if entry (cdr entry) default-value)))

;; poo-flow-sandbox-profile-policy-resource-diagnostic
;;   : (-> Symbol Symbol Alist PooSandboxProfilePolicyDiagnostic)
;;   | contract: construct one resource-policy diagnostic for a profile/backend pair
;;   | result: fixed profile policy diagnostic struct
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-resource-diagnostic
;;        'profile 'backend '())
;;       ;; => sandbox profile policy diagnostic struct
;;       ```
;;     %
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

;; poo-flow-sandbox-profile-policy-resource-diagnostics
;;   : (-> Symbol Symbol [Symbol] ResourcePolicy [PooSandboxProfilePolicyDiagnostic])
;;   | contract: validate resource policy rows for required capabilities
;;   | result: profile policy diagnostic structs for invalid resource coverage
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-resource-diagnostics
;;        'profile 'backend '() '())
;;       ;; => ()
;;       ```
;;     %
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

;; poo-flow-sandbox-profile-policy-resource-diagnostic-rows/rev
;;   : (-> Symbol Symbol [Alist] [Alist] [Alist])
;;   | contract: accumulate resource diagnostic rows for a profile/backend pair
;;   | result: diagnostic rows prepended to the reversed row accumulator
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-resource-diagnostic-rows/rev
;;        'profile 'backend '() '())
;;       ;; => ()
;;       ```
;;     %
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

;; poo-flow-sandbox-profile-policy-resource-diagnostic-rows
;;   : (-> Symbol Symbol [Alist] [Alist])
;;   | contract: project resource policy diagnostic payloads into ordered rows
;;   | result: ordered resource diagnostic rows for validation receipts
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-resource-diagnostic-rows
;;        'profile 'backend '())
;;       ;; => ()
;;       ```
;;     %
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

;; poo-flow-sandbox-profile-policy-durable-summary
;;   : (-> PooSandboxProfilePolicy Symbol Symbol Symbol Alist)
;;   | contract: project durable policy slots into a report-only summary row
;;   | result: alist summary used by profile policy validation receipts
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-durable-summary
;;        policy 'profile 'backend 'ref)
;;       ;; => ((profile . profile) ...)
;;       ```
;;     %
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

;; poo-flow-sandbox-profile-policy-durable-diagnostics
;;   : (-> Symbol Symbol PooSandboxProfilePolicy [PooSandboxProfilePolicyDiagnostic])
;;   | contract: validate durable policy ownership and handoff rows
;;   | result: profile policy diagnostic structs for durable-policy failures
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-durable-diagnostics
;;        'profile 'backend policy)
;;       ;; => ()
;;       ```
;;     %
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
      (cons 'diagnostics
            (map poo-flow-sandbox-profile-policy-diagnostic->alist
                 diagnostics))
      (cons 'diagnostic-count (length diagnostics))
      (cons 'runtime-executed #f)))))

;; poo-flow-sandbox-profile-policy-validation-valid?
;;   : (-> PooSandboxProfilePolicyValidation Boolean)
;;   | contract: inspect a validation receipt object's valid? slot
;;   | result: #t only when the validation object explicitly records valid? #t
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-sandbox-profile-policy-validation-valid? '())
;;       ;; => #f
;;       ```
;;     %
(def (poo-flow-sandbox-profile-policy-validation-valid? validation)
  (and (object? validation)
       (.slot? validation 'valid?)
       (.ref validation 'valid?)))

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

;; : (-> PooSandboxProfilePolicyProjection BOOLEAN)
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
