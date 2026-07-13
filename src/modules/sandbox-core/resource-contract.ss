;;; -*- Gerbil -*-
;;; Boundary: sandbox resources prototype contract and projection helpers.
;;; Invariant: resource validation does not import full sandbox profile machinery.

(import :gerbil/gambit
        (only-in :clan/poo/object .def .ref .slot? object?)
        (only-in :gslph/src/extensions/poo-object-validation
                 poo-object-contract-validation
                 poo-object-validation-valid?)
        (only-in "../../utilities/contracts.ss"
                 poo-flow-slot-contract-slot
                 poo-flow-slot-contract-value-kind
                 poo-flow-slot-contract-metadata
                 poo-flow-object-type-contract->alist
                 poo-flow-contract-check-slot!)
        (only-in "../../utilities/contract-syntax.ss"
                 defcontract-family)
        :poo-flow/src/module-system/projection-syntax
        :poo-flow/src/type-facts/objects)

(export poo-flow-runtime-filesystem-prototype
        poo-flow-runtime-volume-filesystem-prototype
        poo-flow-snapshot-filesystem-prototype
        poo-flow-runtime-filesystem-resources-prototype
        poo-flow-runtime-volume-resources-prototype
        poo-flow-snapshot-resources-prototype
        poo-flow-runtime-volume-ports-resources-prototype
        +poo-flow-sandbox-resources-prototype-filesystem-slot-contract+
        +poo-flow-sandbox-resources-prototype-cpu-slot-contract+
        +poo-flow-sandbox-resources-prototype-ports-slot-contract+
        +poo-flow-sandbox-resources-prototype-memory-slot-contract+
        +poo-flow-sandbox-resources-prototype-timeout-slot-contract+
        +poo-flow-sandbox-resources-prototype-slot-contracts+
        +poo-flow-sandbox-resources-prototype-type-contract+
        +poo-flow-sandbox-resources-prototype-slots+
        poo-flow-sandbox-resources-prototype-type-contract->alist
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

;; : (-> ContractFamilyDeclaration ContractFamilyDefinitions)
;;   | doc m%
;;       Declare sandbox resource slot contracts as structured data while
;;       keeping sandbox resource semantics in sandbox-core.
;;
;;       # Examples
;;       ```scheme
;;       +poo-flow-sandbox-resources-prototype-slot-contracts+
;;       ;; => sandbox-resource-slot-contract-list
;;       ```
;;     %
(defcontract-family
  +poo-flow-sandbox-resources-prototype-slot-contracts+
  +poo-flow-sandbox-resources-prototype-type-contract+
  'sandbox/resources
  'sandbox-core
  'PooSandboxResourcesPrototype
  '((scope . sandbox-core) (projection . resource-contract))
  ((+poo-flow-sandbox-resources-prototype-filesystem-slot-contract+
    'sandbox.resources/filesystem
    'filesystem
    'PooSandboxFilesystemPrototype
    'object?
    object?
    #t
    '((scope . sandbox-core) (slot . filesystem) (merge . node-extend)))
   (+poo-flow-sandbox-resources-prototype-cpu-slot-contract+
    'sandbox.resources/cpu
    'cpu
    'Number
    'number?
    number?
    #t
    '((scope . sandbox-core) (slot . cpu) (merge . override)))
   (+poo-flow-sandbox-resources-prototype-ports-slot-contract+
    'sandbox.resources/ports
    'ports
    'List
    'list?
    list?
    #f
    '((scope . sandbox-core) (slot . ports) (optional . #t) (merge . override)))
   (+poo-flow-sandbox-resources-prototype-memory-slot-contract+
    'sandbox.resources/memory
    'memory
    'String
    'string?
    string?
    #t
    '((scope . sandbox-core) (slot . memory) (merge . override)))
   (+poo-flow-sandbox-resources-prototype-timeout-slot-contract+
    'sandbox.resources/timeout-ms
    'timeout-ms
    'Number
    'number?
    number?
    #f
    '((scope . sandbox-core) (slot . timeout-ms) (optional . #t) (merge . override)))))

;; : (-> List List List)
(def (poo-flow-sandbox-resource-rows/tail rows tail)
  (foldr cons tail rows))

;; : (-> [List] List List)
(def (poo-flow-sandbox-resource-segments/tail segments tail)
  (if (null? segments)
    tail
    (poo-flow-sandbox-resource-rows/tail
     (car segments)
     (poo-flow-sandbox-resource-segments/tail (cdr segments) tail))))

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
  (map poo-flow-slot-contract-slot
       +poo-flow-sandbox-resources-prototype-slot-contracts+))

;; : (-> Alist)
(def (poo-flow-sandbox-resources-prototype-type-contract->alist)
  (poo-flow-object-type-contract->alist
   +poo-flow-sandbox-resources-prototype-type-contract+))

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
    (filter (lambda (slot) (.slot? resources slot))
            +poo-flow-sandbox-resources-prototype-slots+)
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

;; : (-> PooFlowSlotContract Symbol)
(def (poo-flow-sandbox-resources-prototype-slot-merge contract)
  (let (entry (assoc 'merge (poo-flow-slot-contract-metadata contract)))
    (if entry (cdr entry) 'override)))

;; : (-> PooSandboxResourcesPrototype PooFlowSlotContract Value)
(def (poo-flow-sandbox-resources-prototype-slot-default resources contract)
  (poo-flow-sandbox-resources-prototype-slot/default
   resources
   (poo-flow-slot-contract-slot contract)
   #f))

;; : (-> PooFlowSlotContract Value HashTable)
(def (poo-flow-sandbox-resources-prototype-field-contract contract default)
  (let (field (poo-flow-slot-contract-slot contract))
    (poo-flow-sandbox-contract-receipt
     (cons 'field field)
     (cons 'identity field)
     (cons 'valueKind (poo-flow-slot-contract-value-kind contract))
     (cons 'value-kind (poo-flow-slot-contract-value-kind contract))
     (cons 'merge (poo-flow-sandbox-resources-prototype-slot-merge contract))
     (cons 'default default)
     (cons 'metadata (poo-flow-slot-contract-metadata contract)))))

;; : (-> PooSandboxResourcesPrototype [HashTable])
(def (poo-flow-sandbox-resources-prototype-field-contracts resources)
  (map
   (lambda (contract)
     (poo-flow-sandbox-resources-prototype-field-contract
      contract
      (poo-flow-sandbox-resources-prototype-slot-default resources contract)))
   +poo-flow-sandbox-resources-prototype-slot-contracts+))

;; : (-> Symbol String Dyn Alist)
(def (poo-flow-sandbox-resources-prototype-diagnostic code message value)
  (list
   (cons 'code code)
   (cons 'message message)
   (cons 'object 'PooSandboxResourcesPrototype)
   (cons 'value value)))

;; : [PooFlowTypeFactContract]
(def +poo-flow-sandbox-resources-prototype-type-facts+
  (list
   (poo-flow-type-fact
    'sandbox.resources/filesystem-prototype
    'slot-contract
    'PooSandboxResourcesPrototype
    'filesystemPrototype
    'filesystem
    'PooSandboxFilesystemPrototype
    'positive
    '((scope . sandbox-core) (required . #t)))
   (poo-flow-type-fact
    'sandbox.resources/cpu-number
    'slot-contract
    'PooSandboxResourcesPrototype
    'cpuNumber
    'cpu
    'Number
    'positive
    '((scope . sandbox-core) (required . #t)))
   (poo-flow-type-fact
    'sandbox.resources/memory-string
    'slot-contract
    'PooSandboxResourcesPrototype
    'memoryString
    'memory
    'String
    'positive
    '((scope . sandbox-core) (required . #t)))
   (poo-flow-type-fact
    'sandbox.resources/ports-list
    'slot-contract
    'PooSandboxResourcesPrototype
    'portsList
    'ports
    'List
    'optional
    '((scope . sandbox-core) (required . #f)))
   (poo-flow-type-fact
    'sandbox.resources/timeout-number
    'slot-contract
    'PooSandboxResourcesPrototype
    'timeoutNumber
    'timeout-ms
    'Number
    'optional
    '((scope . sandbox-core) (required . #f)))))

;; : [PooFlowLeanFactContract]
(def +poo-flow-sandbox-resources-prototype-lean-fact-contracts+
  (list
   (poo-flow-lean-fact
    'sandbox.resources/filesystem-structured
    'fact
    'SandboxResources.SandboxResourceFact
    'filesystemStructured
    'filesystem
    'positive
    '((scope . sandbox-core)))
   (poo-flow-lean-fact
    'sandbox.resources/cpu-present
    'fact
    'SandboxResources.SandboxResourceFact
    'cpuPresent
    'cpu
    'positive
    '((scope . sandbox-core)))
   (poo-flow-lean-fact
    'sandbox.resources/memory-present
    'fact
    'SandboxResources.SandboxResourceFact
    'memoryPresent
    'memory
    'positive
    '((scope . sandbox-core)))
   (poo-flow-lean-fact
    'sandbox.resources/runtime-executed-false
    'fact
    'SandboxResources.SandboxResourceFact
    'runtimeExecutedFalse
    'runtime-executed
    'negative
    '((scope . sandbox-core)))))

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

;; : (-> PooSandboxResourcesPrototype PooFlowSlotContract [Alist])
(def (poo-flow-sandbox-resources-prototype-slot-contract-diagnostics
      resources
      contract)
  (let (slot (poo-flow-slot-contract-slot contract))
    (if (and (object? resources)
             (.slot? resources slot)
             (poo-flow-sandbox-resources-prototype-slot-readable? resources slot))
      (with-catch
       (lambda (_failure)
         (list
          (poo-flow-sandbox-resources-prototype-diagnostic
           'slot-contract-failed
           "sandbox resources prototype slot failed structured contract"
           (list
            (cons 'slot slot)
            (cons 'value (.ref resources slot))))))
       (lambda ()
         (poo-flow-contract-check-slot! contract (.ref resources slot))
         '()))
      '())))

;; : (-> PooSandboxResourcesPrototype [Alist])
(def (poo-flow-sandbox-resources-prototype-slot-contracts-diagnostics
      resources)
  (poo-flow-sandbox-resource-segments/tail
   (map
    (lambda (contract)
      (poo-flow-sandbox-resources-prototype-slot-contract-diagnostics
       resources
       contract))
    +poo-flow-sandbox-resources-prototype-slot-contracts+)
   '()))

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
        (poo-flow-sandbox-resource-segments/tail
         (list
          (poo-flow-sandbox-prototype-slot-entry filesystem 'scope)
          (poo-flow-sandbox-prototype-slot-entry filesystem 'materialized-by)
          (poo-flow-sandbox-prototype-slot-entry filesystem 'paths)
          (poo-flow-sandbox-prototype-slot-entry filesystem 'mounts)
          (poo-flow-sandbox-prototype-slot-entry filesystem 'access)
          (poo-flow-sandbox-prototype-slot-entry filesystem 'snapshot))
         (poo-flow-sandbox-prototype-slot-entry filesystem 'volume))))

;; : (-> PooSandboxFilesystemPrototype ResourcePolicy)
(def (poo-flow-sandbox-filesystem-prototype->resource-policy filesystem)
  (list (poo-flow-sandbox-filesystem-prototype->resource-entry filesystem)))

;;; Boundary: sandbox resources prototype to resource policy is the policy-
;;; visible edge for sandbox, core behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> PooSandboxResourcesPrototype ResourcePolicy)
(def (poo-flow-sandbox-resources-prototype->resource-policy resources)
  (poo-flow-sandbox-resource-segments/tail
   (list
    (if (.slot? resources 'filesystem)
      (list
       (poo-flow-sandbox-filesystem-prototype->resource-entry
        (.ref resources 'filesystem)))
      '())
    (poo-flow-sandbox-prototype-slot-entry resources 'mounts)
    (poo-flow-sandbox-prototype-slot-entry resources 'ports)
    (poo-flow-sandbox-prototype-slot-entry resources 'cpu)
    (poo-flow-sandbox-prototype-slot-entry resources 'memory))
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
    (poo-flow-sandbox-resource-segments/tail
     (list
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
      (poo-flow-sandbox-resources-prototype-slot-contracts-diagnostics
       resources))
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
          (poo-flow-sandbox-resource-rows/tail
           local-diagnostics
           (hash-get harness-validation 'diagnostics)))
         (valid? (and (null? diagnostics)
                      (poo-object-validation-valid? harness-validation))))
    (make-poo-flow-type-validation-receipt
     poo-flow-sandbox-resources-prototype-contract-validation-kind
     poo-flow-sandbox-resources-prototype-contract-validation-schema
     'PooSandboxResourcesPrototype
     valid?
     source-ref
     harness-validation
     diagnostics
     '(upstream-poo-object-contract-validation
       resources-prototype-object-shape
       resources-required-slots
       resources-structured-filesystem-projection
       structured-type-facts
       lean-fact-contracts)
     +poo-flow-sandbox-resources-prototype-type-facts+
     +poo-flow-sandbox-resources-prototype-lean-fact-contracts+
     #f)))

;; : (-> PooFlowTypeValidationReceipt Boolean)
(def (poo-flow-sandbox-resources-prototype-contract-validation-valid?
      validation)
  (poo-flow-type-validation-receipt-valid? validation))

;; : (-> PooFlowTypeValidationReceipt [Alist])
(def (poo-flow-sandbox-resources-prototype-contract-validation-diagnostics
      validation)
  (poo-flow-type-validation-receipt-diagnostics validation))

;; : (-> PooFlowTypeValidationReceipt Alist)
(defpoo-module-final-projection
  poo-flow-sandbox-resources-prototype-contract-validation->alist
  (validation)
  (bindings ((harness-validation
              (poo-flow-type-validation-receipt-harness-validation
               validation))
             (diagnostics
              (poo-flow-type-validation-receipt-diagnostics validation))))
  (fields ((kind (poo-flow-type-validation-receipt-kind validation))
           (schema (poo-flow-type-validation-receipt-schema validation))
           (object (poo-flow-type-validation-receipt-object validation))
           (valid (poo-flow-type-validation-receipt-valid validation))
           (diagnostics diagnostics)
           (diagnostic-count (length diagnostics))
           (harness-kind (hash-get harness-validation 'kind))
           (harness-valid (hash-get harness-validation 'valid))
           (checked-signals
            (poo-flow-type-validation-receipt-checked-signals validation))
           (type-facts
            (map poo-flow-type-fact-contract->alist
                 (poo-flow-type-validation-receipt-type-facts validation)))
           (lean-fact-contracts
            (map poo-flow-lean-fact-contract->alist
                 (poo-flow-type-validation-receipt-lean-fact-contracts
                  validation)))
           (runtime-executed
            (poo-flow-type-validation-receipt-runtime-executed
             validation)))))

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
