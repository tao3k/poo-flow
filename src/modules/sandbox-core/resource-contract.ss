;;; -*- Gerbil -*-
;;; Boundary: sandbox resources prototype contract and projection helpers.
;;; Invariant: resource validation does not import full sandbox profile machinery.

(import :gerbil/gambit
        (only-in :clan/poo/object .def .ref .slot? object?)
        (only-in :gslph/src/extensions/poo-object-validation
                 poo-object-contract-validation
                 poo-object-validation-valid?))

(export poo-flow-runtime-filesystem-prototype
        poo-flow-runtime-volume-filesystem-prototype
        poo-flow-snapshot-filesystem-prototype
        poo-flow-runtime-filesystem-resources-prototype
        poo-flow-runtime-volume-resources-prototype
        poo-flow-snapshot-resources-prototype
        poo-flow-runtime-volume-ports-resources-prototype
        poo-flow-sandbox-resources-prototype-contract-validation
        poo-flow-sandbox-resources-prototype-contract-validation-valid?
        poo-flow-sandbox-resources-prototype-contract-validation-diagnostics
        poo-flow-sandbox-resources-prototype-contract-validation->alist
        poo-flow-require-sandbox-resources-prototype-contract!
        poo-flow-sandbox-prototype-slot-entry
        poo-flow-sandbox-filesystem-prototype->resource-entry
        poo-flow-sandbox-filesystem-prototype->resource-policy
        poo-flow-sandbox-resources-prototype->resource-policy
        poo-flow-sandbox-resources-value->resource-policy)

;;; Runtime resources are modeled as a first-class POO object so backend
;;; profiles can extend concrete slots without reintroducing ad hoc alists.
;; : PooSandboxFilesystemPrototype
(.def poo-flow-runtime-filesystem-prototype
  scope: 'runtime
  materialized-by: 'runtime
  mounts: 'runtime)

;; : PooSandboxFilesystemPrototype
(.def poo-flow-runtime-volume-filesystem-prototype
  scope: 'volume
  materialized-by: 'runtime
  mounts: 'runtime)

;; : PooSandboxFilesystemPrototype
(.def poo-flow-snapshot-filesystem-prototype
  scope: 'snapshot
  snapshot: 'clone)

;; : PooSandboxResourcesPrototype
(.def poo-flow-runtime-filesystem-resources-prototype
  filesystem: poo-flow-runtime-filesystem-prototype
  cpu: 2
  memory: "4Gi")

;; : PooSandboxResourcesPrototype
(.def poo-flow-runtime-volume-resources-prototype
  filesystem: poo-flow-runtime-volume-filesystem-prototype
  cpu: 2
  memory: "4Gi")

;; : PooSandboxResourcesPrototype
(.def poo-flow-snapshot-resources-prototype
  filesystem: poo-flow-snapshot-filesystem-prototype
  cpu: 2
  memory: "4Gi")

;; : PooSandboxResourcesPrototype
(.def poo-flow-runtime-volume-ports-resources-prototype
  filesystem: poo-flow-runtime-volume-filesystem-prototype
  ports: '((scope . runtime)
           (published-by . runtime))
  cpu: 2
  memory: "4Gi")

;; : PooSandboxResourcesPrototypeContractValidationKind
(def poo-flow-sandbox-resources-prototype-contract-validation-kind
  "poo-flow-sandbox-resources-prototype-contract-validation")

;; : PooSandboxResourcesPrototypeContractValidationSchema
(def poo-flow-sandbox-resources-prototype-contract-validation-schema
  "poo-flow-sandbox-resources-prototype-contract-validation/v1")

;;; Boundary: sandbox contract receipt is the policy-visible edge for sandbox,
;;; core behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> Pair... HashTable)
(def (poo-flow-sandbox-contract-receipt . entries)
  (let (table (make-hash-table))
    (for-each
     (lambda (entry)
       (hash-put! table (car entry) (cdr entry)))
     entries)
    table))

;;; Boundary: sandbox resource spec has key predicate is the policy-visible
;;; edge for sandbox, core behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> AgentSandboxFilesystemResourceSpec Symbol Boolean)
(def (poo-flow-sandbox-resource-spec-has-key? spec key)
  (cond
   ((null? spec) #f)
   ((not (pair? spec)) #f)
   ((and (pair? (car spec))
         (eq? (caar spec) key))
    #t)
   (else
    (poo-flow-sandbox-resource-spec-has-key? (cdr spec) key))))

;; : (-> AgentSandboxFilesystemResourceSpec Boolean)
(def (poo-flow-sandbox-resource-spec-has-anchor? spec)
  (or (poo-flow-sandbox-resource-spec-has-key? spec 'mounts)
      (poo-flow-sandbox-resource-spec-has-key? spec 'workspace)
      (poo-flow-sandbox-resource-spec-has-key? spec 'paths)
      (poo-flow-sandbox-resource-spec-has-key? spec 'root)
      (poo-flow-sandbox-resource-spec-has-key? spec 'volume)
      (poo-flow-sandbox-resource-spec-has-key? spec 'snapshot)))

;; : (-> AgentSandboxResourcePolicyEntry Boolean)
(def (poo-flow-sandbox-structured-filesystem-entry? resource)
  (and (pair? resource)
       (eq? (car resource) 'filesystem)
       (list? (cdr resource))
       (poo-flow-sandbox-resource-spec-has-key? (cdr resource) 'scope)
       (poo-flow-sandbox-resource-spec-has-anchor? (cdr resource))))

;;; Boundary: sandbox resource policy has structured filesystem predicate is
;;; the policy-visible edge for sandbox, core behavior, keeping validation,
;;; lookup, or projection responsibilities centralized for callers.
;; : (-> ResourcePolicy Boolean)
(def (poo-flow-sandbox-resource-policy-has-structured-filesystem?
      resource-policy)
  (cond
   ((null? resource-policy) #f)
   ((not (pair? resource-policy)) #f)
   ((poo-flow-sandbox-structured-filesystem-entry? (car resource-policy))
    #t)
   (else
    (poo-flow-sandbox-resource-policy-has-structured-filesystem?
     (cdr resource-policy)))))

;; : [Symbol]
(def +poo-flow-sandbox-resources-prototype-slots+
  '(filesystem ports cpu memory timeout-ms))

;;; Boundary: sandbox resources prototype slot if present is the policy-visible
;;; edge for sandbox, core behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> PooSandboxResourcesPrototype Symbol [Symbol])
(def (poo-flow-sandbox-resources-prototype-slot-if-present resources slot)
  (if (.slot? resources slot) [slot] '()))

;;; Boundary: sandbox resources prototype present slots is the policy-visible
;;; edge for sandbox, core behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> PooSandboxResourcesPrototype [Symbol])
(def (poo-flow-sandbox-resources-prototype-present-slots resources)
  (if (object? resources)
    (apply append
           (map (lambda (slot)
                  (poo-flow-sandbox-resources-prototype-slot-if-present
                   resources
                   slot))
                +poo-flow-sandbox-resources-prototype-slots+))
    '()))

;; : (-> PooSandboxResourcesPrototype HashTable)
(def (poo-flow-sandbox-resources-prototype-source-ref resources)
  (poo-flow-sandbox-contract-receipt
   (cons 'kind "dependency")
   (cons 'manager "gerbil.pkg")
   (cons 'dependency "github.com/tao3k/gerbil-scheme-language-project-harness")
   (cons 'repository "github.com/tao3k/agent-semantic-protocols")
   (cons 'localSource "languages/gerbil-scheme-language-project-harness")
   (cons 'repositorySource "src/extensions/facade.ss")
   (cons 'indexHint "gslph-extensions-facade")
   (cons 'pathPolicy "package-dependency")
   (cons 'selectorScheme "gerbil-poo")
   (cons 'object 'PooSandboxResourcesPrototype)
   (cons 'slots
         (poo-flow-sandbox-resources-prototype-present-slots resources))))

;;; Boundary: sandbox resources prototype slot default is the policy-visible
;;; edge for sandbox, core behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> PooSandboxResourcesPrototype Symbol Value)
(def (poo-flow-sandbox-resources-prototype-slot/default resources
                                                           slot
                                                           default)
  (if (and (object? resources) (.slot? resources slot))
    (with-catch
     (lambda (_failure) default)
     (lambda ()
       (.ref resources slot)))
    default))

;; : (-> Symbol Symbol Symbol Value Alist HashTable)
(def (poo-flow-sandbox-resources-prototype-field-contract field
                                                           value-kind
                                                           merge
                                                           default
                                                           metadata)
  (poo-flow-sandbox-contract-receipt
   (cons 'field field)
   (cons 'identity field)
   (cons 'valueKind value-kind)
   (cons 'value-kind value-kind)
   (cons 'merge merge)
   (cons 'default default)
   (cons 'metadata metadata)))

;; : (-> PooSandboxResourcesPrototype [HashTable])
(def (poo-flow-sandbox-resources-prototype-field-contracts resources)
  (list
   (poo-flow-sandbox-resources-prototype-field-contract
    'filesystem
    'PooSandboxFilesystemPrototype
    'node-extend
    (poo-flow-sandbox-resources-prototype-slot/default resources
                                                        'filesystem
                                                        #f)
    '((scope . sandbox-core) (slot . filesystem)))
   (poo-flow-sandbox-resources-prototype-field-contract
    'cpu
    'Number
    'override
    (poo-flow-sandbox-resources-prototype-slot/default resources 'cpu #f)
    '((scope . sandbox-core) (slot . cpu)))
   (poo-flow-sandbox-resources-prototype-field-contract
    'ports
    'List
    'override
    (poo-flow-sandbox-resources-prototype-slot/default resources 'ports #f)
    '((scope . sandbox-core) (slot . ports) (optional . #t)))
   (poo-flow-sandbox-resources-prototype-field-contract
    'memory
    'String
    'override
    (poo-flow-sandbox-resources-prototype-slot/default resources 'memory #f)
    '((scope . sandbox-core) (slot . memory)))
   (poo-flow-sandbox-resources-prototype-field-contract
    'timeout-ms
    'Number
    'override
    (poo-flow-sandbox-resources-prototype-slot/default resources
                                                        'timeout-ms
                                                        #f)
    '((scope . sandbox-core) (slot . timeout-ms) (optional . #t)))))

;; : (-> Symbol String Dyn Alist)
(def (poo-flow-sandbox-resources-prototype-diagnostic code message value)
  (list (cons 'code code)
        (cons 'message message)
        (cons 'object 'PooSandboxResourcesPrototype)
        (cons 'value value)))

;;; Boundary: sandbox resources prototype slot readable predicate is the
;;; policy-visible edge for sandbox, core behavior, keeping validation, lookup,
;;; or projection responsibilities centralized for callers.
;; : (-> PooSandboxResourcesPrototype Symbol Boolean)
(def (poo-flow-sandbox-resources-prototype-slot-readable? resources slot)
  (and (object? resources)
       (.slot? resources slot)
       (with-catch
        (lambda (_failure) #f)
        (lambda ()
          (.ref resources slot)
          #t))))

;;; Boundary: sandbox resources prototype slot readability diagnostics is the
;;; policy-visible edge for sandbox, core behavior, keeping validation, lookup,
;;; or projection responsibilities centralized for callers.
;; : (-> Symbol Symbol PooSandboxResourcesPrototype [Alist])
(def (poo-flow-sandbox-resources-prototype-slot-readability-diagnostics code
                                                                        slot
                                                                        resources)
  (if (or (not (object? resources))
          (not (.slot? resources slot))
          (poo-flow-sandbox-resources-prototype-slot-readable? resources slot))
    '()
    (list
     (poo-flow-sandbox-resources-prototype-diagnostic
      code
      "sandbox resources prototype slot exists but cannot be read through POO slot resolution"
      resources))))

;;; Boundary: sandbox resources prototype missing slot diagnostics is the
;;; policy-visible edge for sandbox, core behavior, keeping validation, lookup,
;;; or projection responsibilities centralized for callers.
;; : (-> PooSandboxResourcesPrototype [Alist])
(def (poo-flow-sandbox-resources-prototype-missing-slot-diagnostics resources
                                                                    slot
                                                                    code
                                                                    message)
  (if (.slot? resources slot)
    '()
    (list
     (poo-flow-sandbox-resources-prototype-diagnostic
      code
      message
      resources))))

;;; Boundary: sandbox prototype slot entry is the policy-visible edge for
;;; sandbox, core behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> Object Symbol [Pair])
(def (poo-flow-sandbox-prototype-slot-entry prototype slot)
  (if (.slot? prototype slot)
    (list (cons slot (.ref prototype slot)))
    '()))

;; : (-> PooSandboxFilesystemPrototype AgentSandboxResourcePolicyEntry)
(def (poo-flow-sandbox-filesystem-prototype->resource-entry filesystem)
  (cons 'filesystem
        (append
         (poo-flow-sandbox-prototype-slot-entry filesystem 'scope)
         (poo-flow-sandbox-prototype-slot-entry filesystem 'materialized-by)
         (poo-flow-sandbox-prototype-slot-entry filesystem 'paths)
         (poo-flow-sandbox-prototype-slot-entry filesystem 'mounts)
         (poo-flow-sandbox-prototype-slot-entry filesystem 'access)
         (poo-flow-sandbox-prototype-slot-entry filesystem 'snapshot)
         (poo-flow-sandbox-prototype-slot-entry filesystem 'volume))))

;; : (-> PooSandboxFilesystemPrototype ResourcePolicy)
(def (poo-flow-sandbox-filesystem-prototype->resource-policy filesystem)
  (list (poo-flow-sandbox-filesystem-prototype->resource-entry filesystem)))

;;; Boundary: sandbox resources prototype to resource policy is the policy-
;;; visible edge for sandbox, core behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> PooSandboxResourcesPrototype ResourcePolicy)
(def (poo-flow-sandbox-resources-prototype->resource-policy resources)
  (append
   (if (.slot? resources 'filesystem)
     (list
      (poo-flow-sandbox-filesystem-prototype->resource-entry
       (.ref resources 'filesystem)))
     '())
   (poo-flow-sandbox-prototype-slot-entry resources 'mounts)
   (poo-flow-sandbox-prototype-slot-entry resources 'ports)
   (poo-flow-sandbox-prototype-slot-entry resources 'cpu)
   (poo-flow-sandbox-prototype-slot-entry resources 'memory)
   (poo-flow-sandbox-prototype-slot-entry resources 'timeout-ms)))

;;; Boundary: sandbox resources prototype structured filesystem diagnostics is
;;; the policy-visible edge for sandbox, core behavior, keeping validation,
;;; lookup, or projection responsibilities centralized for callers.
;; : (-> PooSandboxResourcesPrototype [Alist])
(def (poo-flow-sandbox-resources-prototype-structured-filesystem-diagnostics
      resources)
  (if (not (poo-flow-sandbox-resources-prototype-slot-readable?
            resources
            'filesystem))
    '()
    (let (resource-policy
          (poo-flow-sandbox-resources-prototype->resource-policy resources))
      (if (poo-flow-sandbox-resource-policy-has-structured-filesystem?
           resource-policy)
        '()
        (list
         (poo-flow-sandbox-resources-prototype-diagnostic
          'filesystem-not-structured
          "sandbox resources filesystem must project to a structured resource-policy entry"
          resource-policy))))))

;;; Boundary: sandbox resources prototype local diagnostics is the policy-
;;; visible edge for sandbox, core behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> PooSandboxResourcesPrototype [Alist])
(def (poo-flow-sandbox-resources-prototype-local-diagnostics resources)
  (if (not (object? resources))
    (list
     (poo-flow-sandbox-resources-prototype-diagnostic
      'resources-prototype-not-object
      "sandbox resources contract expects a POO object"
      resources))
    (append
     (poo-flow-sandbox-resources-prototype-missing-slot-diagnostics
      resources
      'filesystem
      'missing-filesystem-slot
      "sandbox resources prototype must define filesystem")
     (poo-flow-sandbox-resources-prototype-missing-slot-diagnostics
      resources
      'cpu
      'missing-cpu-slot
      "sandbox resources prototype must define cpu")
     (poo-flow-sandbox-resources-prototype-missing-slot-diagnostics
      resources
      'memory
      'missing-memory-slot
      "sandbox resources prototype must define memory")
     (poo-flow-sandbox-resources-prototype-slot-readability-diagnostics
      'unreadable-filesystem-slot
      'filesystem
      resources)
     (poo-flow-sandbox-resources-prototype-slot-readability-diagnostics
      'unreadable-cpu-slot
      'cpu
      resources)
     (poo-flow-sandbox-resources-prototype-slot-readability-diagnostics
      'unreadable-memory-slot
      'memory
      resources)
     (poo-flow-sandbox-resources-prototype-structured-filesystem-diagnostics
      resources))))

;; : (-> PooSandboxResourcesPrototype HashTable)
(def (poo-flow-sandbox-resources-prototype-contract-validation resources)
  (let* ((source-ref
          (poo-flow-sandbox-resources-prototype-source-ref resources))
         (harness-validation
          (poo-object-contract-validation
           'PooSandboxResourcesPrototype
           (poo-flow-sandbox-resources-prototype-field-contracts resources)
           source-ref))
         (local-diagnostics
          (poo-flow-sandbox-resources-prototype-local-diagnostics resources))
         (diagnostics
          (append local-diagnostics
                  (hash-get harness-validation 'diagnostics)))
         (valid? (and (null? diagnostics)
                      (poo-object-validation-valid? harness-validation))))
    (poo-flow-sandbox-contract-receipt
     (cons 'kind
           poo-flow-sandbox-resources-prototype-contract-validation-kind)
     (cons 'schema
           poo-flow-sandbox-resources-prototype-contract-validation-schema)
     (cons 'object 'PooSandboxResourcesPrototype)
     (cons 'valid valid?)
     (cons 'sourceRef source-ref)
     (cons 'harnessValidation harness-validation)
     (cons 'diagnostics diagnostics)
     (cons 'checkedSignals
           '(upstream-poo-object-contract-validation
             resources-prototype-object-shape
             resources-required-slots
             resources-structured-filesystem-projection)))))

;; : (-> HashTable Boolean)
(def (poo-flow-sandbox-resources-prototype-contract-validation-valid?
      validation)
  (and (hash-table? validation)
       (hash-get validation 'valid)))

;; : (-> HashTable [Alist])
(def (poo-flow-sandbox-resources-prototype-contract-validation-diagnostics
      validation)
  (hash-get validation 'diagnostics))

;; : (-> HashTable Alist)
(def (poo-flow-sandbox-resources-prototype-contract-validation->alist
      validation)
  (let ((harness-validation (hash-get validation 'harnessValidation))
        (diagnostics (hash-get validation 'diagnostics)))
    (list
     (cons 'kind (hash-get validation 'kind))
     (cons 'schema (hash-get validation 'schema))
     (cons 'object (hash-get validation 'object))
     (cons 'valid (hash-get validation 'valid))
     (cons 'diagnostics diagnostics)
     (cons 'diagnostic-count (length diagnostics))
     (cons 'harness-kind (hash-get harness-validation 'kind))
     (cons 'harness-valid (hash-get harness-validation 'valid))
     (cons 'checked-signals (hash-get validation 'checkedSignals)))))

;;; Boundary: require sandbox resources prototype contract! is the policy-
;;; visible edge for sandbox, core behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> PooSandboxResourcesPrototype PooSandboxResourcesPrototype)
(def (poo-flow-require-sandbox-resources-prototype-contract! resources)
  (let (validation
        (poo-flow-sandbox-resources-prototype-contract-validation resources))
    (if (poo-flow-sandbox-resources-prototype-contract-validation-valid?
         validation)
      resources
      (error "sandbox resources prototype failed typed contract validation"
             validation))))

;;; Boundary: sandbox resources value to resource policy is the policy-visible
;;; edge for sandbox, core behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> Value ResourcePolicy)
(def (poo-flow-sandbox-resources-value->resource-policy resources)
  (if (object? resources)
    (poo-flow-sandbox-resources-prototype->resource-policy
     (poo-flow-require-sandbox-resources-prototype-contract! resources))
    resources))
