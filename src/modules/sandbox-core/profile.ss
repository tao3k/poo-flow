;;; -*- Gerbil -*-
;;; Boundary: sandbox category core profile object and projection helpers.
;;; Invariant: this is developer-owned object machinery, not a user module row.

(import :gerbil/gambit
        (only-in :clan/poo/object .def .o .ref .slot? object?)
        :poo-flow/src/module-system/extension
        :poo-flow/src/module-system/object-core
        :poo-flow/src/module-system/objects
        :poo-flow/src/modules/agent-sandbox/config
        (only-in :poo-flow/src/modules/agent-sandbox/profile-validation
                 agent-sandbox-profile-resource-policy-filesystem-entry?
                 agent-sandbox-profile-resource-policy-filesystem-diagnostics)
        :poo-flow/src/modules/sandbox-core/resource-contract)

(export (import: :poo-flow/src/modules/sandbox-core/resource-contract)
        poo-flow-sandbox-core-profile-object
        poo-flow-sandbox-profile-object-row-slot
        poo-flow-sandbox-profile-object-row-operator?
        poo-flow-sandbox-profile-object-row-operator
        poo-flow-sandbox-profile-object-row-value
        poo-flow-sandbox-profile-object-authoring-diagnostic
        poo-flow-sandbox-profile-object-row-contains-symbol?
        poo-flow-sandbox-profile-object-runtime-executed-true?
        poo-flow-sandbox-profile-object-row-authoring-diagnostics
        poo-flow-sandbox-profile-object-authoring-diagnostics
        poo-flow-sandbox-profile-prototype
        poo-flow-sandbox-profile-prototype->profile
        poo-flow-sandbox-profile-prototypes
        poo-flow-sandbox-profile-object-profiles
        poo-flow-sandbox-profile-object-profiles/build
        poo-flow-sandbox-profile-object-derive
        poo-flow-sandbox-profile-object-config)

;;; The core profile object supplies the shared prototype for sandbox backends.
;;; Backend modules extend it; users only see the resulting profile rows.
;; : PooModuleObject
;; | PooSandboxCoreProfileObject = PooModuleObject
(def poo-flow-sandbox-core-profile-object
  (poo-flow-module-object
   'objects.sandbox-core.profile
   (list poo-flow-shared-sandbox-object)
   (list
    (poo-flow-module-field-contract
     'profile-name 'Symbol 'override 'default
     '((scope . sandbox-core) (dsl-row . profile-name)))
    (poo-flow-module-field-contract
     'backend-kind 'Symbol 'override 'sandbox
     '((scope . sandbox-core) (owned-by . module-config)))
    (poo-flow-module-field-contract
     'backend-ref 'Symbol 'override 'sandbox-profile
     '((scope . sandbox-core) (owned-by . module-config)))
    (poo-flow-module-field-contract
     'network-policy 'List 'override '(deny-by-default)
     '((scope . sandbox-core) (dsl-row . network)))
    (poo-flow-module-field-contract
     'capabilities 'List 'override '(process-run filesystem-read tmpdir)
     '((scope . sandbox-core) (dsl-row . capabilities)))
    (poo-flow-module-field-contract
     'resource-policy 'List 'override
     '((filesystem
        (scope . runtime)
        (materialized-by . runtime)
        (mounts . runtime)))
     '((scope . sandbox-core) (dsl-row . resources)))
    (poo-flow-module-field-contract
     'metadata 'List 'append '()
     '((scope . sandbox-core) (dsl-row . metadata))))
   '((namespace . objects.sandbox-core)
     (domain . profile)
     (collection . sandbox.profile)
     (developer-owned . #t)
     (inherits . objects.shared.sandbox))))

;;; The neutral sandbox profile prototype is backend-agnostic. Backend modules
;;; extend it rather than rewriting a resource-policy alist from scratch.
;; : PooSandboxProfilePrototype
(.def poo-flow-sandbox-profile-prototype
  backend-kind: 'sandbox
  backend-ref: 'sandbox-profile
  network-policy: '(deny-by-default)
  capabilities: '(process-run filesystem-read tmpdir)
  resources: poo-flow-runtime-volume-resources-prototype
  metadata: '((declared-by . poo-flow-poo-prototype)
              (runtime-executed . #f)))

;;; Profile projection is report-only control-plane data. It materializes the
;;; POO profile prototype as the existing public sandbox profile object without
;;; executing Docker, nono, Cube, or Marlin runtime work.
;; : (-> PooSandboxProfilePrototype Symbol Value)
(def (poo-flow-sandbox-profile-prototype-slot/default prototype slot default)
  (if (.slot? prototype slot)
    (.ref prototype slot)
    default))

;;; Public user profiles use `network` and `resources`; older internal
;;; projections may still carry `network-policy` and `resource-policy`.
;; : (-> PooSandboxProfilePrototype Symbol Symbol Value)
(def (poo-flow-sandbox-profile-prototype-slot/either prototype
                                                     public-slot
                                                     internal-slot
                                                     default)
  (cond
   ((.slot? prototype public-slot) (.ref prototype public-slot))
   ((.slot? prototype internal-slot) (.ref prototype internal-slot))
   (else default)))

;; : (-> Symbol PooSandboxProfilePrototype PooSandboxProfile)
(def (poo-flow-sandbox-profile-prototype->profile name-value prototype)
  (let* ((backend-ref-value
          (poo-flow-sandbox-profile-prototype-slot/default
           prototype
           'backend-ref
           #f))
         (resources
          (poo-flow-sandbox-profile-prototype-slot/either
           prototype
           'resources
           'resource-policy
           '())))
    (.o kind: poo-flow-sandbox-profile-kind
        name: name-value
        backend-kind: (poo-flow-sandbox-profile-prototype-slot/default
                       prototype
                       'backend-kind
                       'sandbox)
        backend-ref: (if backend-ref-value backend-ref-value name-value)
        network-policy: (poo-flow-sandbox-profile-prototype-slot/either
                         prototype
                         'network
                         'network-policy
                         '(deny-by-default))
        capabilities: (poo-flow-sandbox-profile-prototype-slot/default
                       prototype
                       'capabilities
                       '(process-run filesystem-read tmpdir))
        resource-policy: (poo-flow-sandbox-resources-value->resource-policy
                          resources)
        metadata: (poo-flow-sandbox-profile-prototype-slot/default
                   prototype
                   'metadata
                   '()))))

;; poo-flow-sandbox-profile-prototypes
;;   : (-> (ProfileName PooSandboxProfilePrototype)... [PooSandboxProfile])
;;   | doc m%
;;       `poo-flow-sandbox-profile-prototypes` keeps native POO profile names
;;       visible in user files while returning sandbox profile objects consumed
;;       by runtime manifests and presentation projections.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-sandbox-profile-prototypes (agent/nono nono-prototype))
;;       ;; => (nono-profile)
;;       ```
;;     %
(defrules poo-flow-sandbox-profile-prototypes ()
  ((_)
   '())
  ((_ (name prototype) ...)
   (list (poo-flow-sandbox-profile-prototype->profile 'name prototype) ...)))

;;; Row keys are the user syntax vocabulary; slots are the POO object contract
;;; vocabulary. Keeping this table here prevents backend wrappers from drifting.
;; : (-> Symbol MaybeSymbol)
(def (poo-flow-sandbox-profile-object-row-slot row-key)
  (cond
   ((eq? row-key 'network) 'network-policy)
   ((eq? row-key 'capabilities) 'capabilities)
   ((eq? row-key 'resources) 'resource-policy)
   ((eq? row-key 'metadata) 'metadata)
   (else #f)))

;;; Merge operators are explicit row modifiers, not field names. They are
;;; parsed before slot lookup so remove/append can reuse the same field object.
;; : (-> SandboxProfileRowOperatorCandidate Boolean)
;; | SandboxProfileRowOperatorCandidate = Symbol
(def (poo-flow-sandbox-profile-object-row-operator? value)
  (or (eq? value ':override)
      (eq? value ':append)
      (eq? value ':prepend)
      (eq? value ':remove)))

;;; Operator lookup is intentionally shallow: it reads only the second cell of
;;; a user row and leaves field validity to object-contract validation.
;; : (-> SandboxProfileForm MaybeSandboxProfileRowOperator)
(def (poo-flow-sandbox-profile-object-row-operator row)
  (let (tail (if (and row (pair? row)) (cdr row) '()))
    (if (and (pair? tail)
             (poo-flow-sandbox-profile-object-row-operator? (car tail)))
      (car tail)
      #f)))

;;; Row payload extraction strips the optional merge operator but preserves
;;; declaration order for append/prepend/remove semantics.
;; : (-> SandboxProfileForm [Value])
(def (poo-flow-sandbox-profile-object-row-value row)
  (let* ((tail (cdr row))
         (operator (poo-flow-sandbox-profile-object-row-operator row)))
    (if operator (cdr tail) tail)))

;;; Authoring diagnostics are report-only facts for enforcing the POO-native
;;; programming contract. They do not reject rows; structural validation below
;;; remains the hard gate before merge planning.
;; : (-> Symbol SandboxProfileForm Alist ValidationError)
(def (poo-flow-sandbox-profile-object-authoring-diagnostic code row payload)
  (append
   (list (cons 'field 'profile-row)
         (cons 'code code)
         (cons 'row row))
   payload))

;; : (-> Value Symbol Boolean)
(def (poo-flow-sandbox-profile-object-row-contains-symbol? value target)
  (cond
   ((eq? value target) #t)
   ((pair? value)
    (or (poo-flow-sandbox-profile-object-row-contains-symbol? (car value)
                                                              target)
        (poo-flow-sandbox-profile-object-row-contains-symbol? (cdr value)
                                                              target)))
   (else #f)))

;; : (-> SandboxProfileDatum Boolean)
;; | type SandboxProfileDatum = (U Pair Symbol Boolean String Integer)
(def (poo-flow-sandbox-profile-object-runtime-executed-true? value)
  (cond
   ((not (pair? value)) #f)
   ((and (pair? (car value))
         (eq? (caar value) 'runtime-executed)
         (eq? (cdar value) #t))
    #t)
   (else
    (or (poo-flow-sandbox-profile-object-runtime-executed-true? (car value))
        (poo-flow-sandbox-profile-object-runtime-executed-true? (cdr value))))))

;;; Row authoring diagnostics turn gerbil-poo best practices into inspectable
;;; facts: row operators are advanced escape hatches, raw compute hooks are not
;;; a user interface, and runtime-executed markers must remain report-only.
;; : (-> SandboxProfileForm Value)
(def (poo-flow-sandbox-profile-object-row-value/default row)
  (if (and row (pair? row))
    (poo-flow-sandbox-profile-object-row-value row)
    row))

;; : (-> PooModuleObject SandboxProfileForm [ValidationError])
(def (poo-flow-sandbox-profile-object-row-authoring-diagnostics
      profile-object
      row)
  (let* ((field (poo-flow-sandbox-profile-object-row-field profile-object row))
         (slot (and field (poo-flow-module-field-contract-identity field)))
         (operator (and (pair? row)
                        (poo-flow-sandbox-profile-object-row-operator row)))
         (value (poo-flow-sandbox-profile-object-row-value/default row)))
    (append
     (if operator
       (list
        (poo-flow-sandbox-profile-object-authoring-diagnostic
         'advanced-row-operator
         row
         (list (cons 'slot slot)
               (cons 'operator operator)
               (cons 'recommendation 'named-prototype-extension))))
       '())
     (if (or (poo-flow-sandbox-profile-object-row-contains-symbol? row
                                                                   ':compute)
             (poo-flow-sandbox-profile-object-row-contains-symbol? row
                                                                   '$computed-slot-spec)
             (poo-flow-sandbox-profile-object-row-contains-symbol? row
                                                                   'lambda))
       (list
        (poo-flow-sandbox-profile-object-authoring-diagnostic
         'raw-compute-hook
         row
         (list (cons 'slot slot)
               (cons 'recommendation 'poo-slot-operator-or-helper))))
       '())
     (if (poo-flow-sandbox-profile-object-runtime-executed-true? value)
       (list
        (poo-flow-sandbox-profile-object-authoring-diagnostic
         'runtime-executed-marker
         row
         (list (cons 'slot slot)
               (cons 'expected '#f))))
       '()))))

;; : (-> PooModuleObject [SandboxProfileForm] [ValidationError])
(def (poo-flow-sandbox-profile-object-authoring-diagnostics profile-object
                                                            forms)
  (cond
   ((null? forms) '())
   ((not (pair? forms)) '())
   (else
    (append
     (poo-flow-sandbox-profile-object-row-authoring-diagnostics
      profile-object
      (car forms))
     (poo-flow-sandbox-profile-object-authoring-diagnostics
      profile-object
      (cdr forms))))))

;;; Option lookup is scoped to derivation/config helper options. User profile
;;; rows still pass through field-contract validation before merge planning.
;; : (-> Alist Symbol Value Value)
(def (poo-flow-sandbox-profile-object-option options key default-value)
  (let (entry (assoc key options))
    (if entry (cdr entry) default-value)))

;;; Metadata removal is deliberately key based so derivations can replace
;;; lineage/runtime facts without dropping backend-provided metadata rows.
;; : (-> Symbol [Symbol] Boolean)
(def (poo-flow-sandbox-profile-object-metadata-key? key keys)
  (and (member key keys) #t))

;;; Derived profile metadata is still ordinary profile metadata, but lineage
;;; gets one canonical key so nested project/session/task derivations do not
;;; accumulate ambiguous repeated parent-profile pairs.
;; : (-> Alist [Symbol] Alist)
;;; Metadata pruning is used only while deriving child profiles. It removes
;;; fields that must be recomputed for the child, while leaving unrelated
;;; policy annotations untouched.
;; : (-> Alist [Symbol] Alist)
(def (poo-flow-sandbox-profile-object-metadata-without metadata keys)
  (filter (lambda (entry)
            (not (and (pair? entry)
                      (poo-flow-sandbox-profile-object-metadata-key?
                       (car entry)
                       keys))))
          metadata))

;;; Parent profiles that do not carry lineage remain valid roots; they simply
;;; start the derivation path at the first child profile.
;; : (-> Alist [Alist])
(def (poo-flow-sandbox-profile-object-derivation-path metadata)
  (let (entry (assoc 'derivation-path metadata))
    (if (and entry (list? (cdr entry))) (cdr entry) '())))

;;; Each derivation step is an audit row, not runtime metadata. The child
;;; profile name is recorded separately from the parent so fixed-point merges
;;; can be inspected after multiple project/session/task hops.
;; : (-> Symbol Symbol Symbol Value Alist)
(def (poo-flow-sandbox-profile-object-derivation-step name-value
                                                      parent-name
                                                      scope
                                                      scope-ref)
  (append
   (list (cons 'profile name-value)
         (cons 'parent-profile parent-name)
         (cons 'scope scope)
         (cons 'derived-by 'poo-flow-sandbox-profile-object-derive))
   (if scope-ref
     (list (cons 'scope-ref scope-ref))
     '())))

;;; Derived metadata replaces lineage/runtime facts while preserving ordinary
;;; parent metadata. This keeps inheritance visible without letting stale
;;; `runtime-executed` state leak into child profiles.
;; : (-> PooSandboxProfile Symbol Alist Alist)
(def (poo-flow-sandbox-profile-object-derived-metadata parent-profile
                                                       name-value
                                                       options)
  (let* ((parent-metadata (poo-flow-sandbox-profile-metadata parent-profile))
         (scope
          (poo-flow-sandbox-profile-object-option options 'scope 'profile))
         (scope-ref
          (poo-flow-sandbox-profile-object-option options 'scope-ref #f))
         (lineage
          (append
           (poo-flow-sandbox-profile-object-derivation-path parent-metadata)
           (list
            (poo-flow-sandbox-profile-object-derivation-step
             name-value
             (poo-flow-sandbox-profile-name parent-profile)
             scope
             scope-ref)))))
    (append
     (poo-flow-sandbox-profile-object-metadata-without
      parent-metadata
      '(derivation-path runtime-executed))
     (list (cons 'derivation-path lineage)
           (cons 'runtime-executed #f))
     (poo-flow-sandbox-profile-object-option options 'metadata '()))))

;;; Backend rows are rejected here because backend kind/ref come from the
;;; selected module object, not from user profile rows.
;; : (-> SandboxProfileForm Boolean)
(def (poo-flow-sandbox-profile-object-backend-row? row)
  (and (pair? row)
       (eq? (car row) 'backend)))

;;; Row-field resolution is the contract gate: unknown row names never become
;;; extension contributions, even if their payload shape looks list-like.
;; : (-> PooModuleObject SandboxProfileForm MaybePooModuleFieldContract)
(def (poo-flow-sandbox-profile-object-row-field profile-object row)
  (if (and (pair? row) (symbol? (car row)))
    (let (slot (poo-flow-sandbox-profile-object-row-slot (car row)))
      (and slot
           (poo-flow-module-object-field profile-object slot)))
    #f))

;;; User-supplied merge operators override the field default only for this row;
;;; backend objects keep their declared merge strategy for later rows.
;; : (-> MaybeSymbol PooModuleFieldContract Symbol)
(def (poo-flow-sandbox-profile-object-row-merge operator field)
  (cond
   ((eq? operator ':override) 'override)
   ((eq? operator ':append) 'append)
   ((eq? operator ':prepend) 'prepend)
   ((eq? operator ':remove) 'remove)
   (else
    (poo-flow-module-field-contract-merge field))))

;;; A per-row field copy lets `:remove` and `:append` share the backend field
;;; contract without mutating the inherited object.
;; : (-> PooModuleFieldContract Symbol PooModuleFieldContract)
(def (poo-flow-sandbox-profile-object-field-with-merge field merge)
  (poo-flow-module-field-contract
   (poo-flow-module-field-contract-identity field)
   (poo-flow-module-field-contract-value-kind field)
   merge
    (poo-flow-module-field-contract-default field)
   (poo-flow-module-field-contract-metadata field)))

;;; A user row becomes one field contribution against the inherited backend
;;; profile object, so merge/remove remains ordinary POO extension behavior.
;; : (-> PooModuleObject SandboxProfileForm PooModuleFieldContribution)
(def (poo-flow-sandbox-profile-object-row-contribution profile-object row)
  (let* ((field (poo-flow-sandbox-profile-object-row-field profile-object row))
         (operator (poo-flow-sandbox-profile-object-row-operator row))
         (merge (poo-flow-sandbox-profile-object-row-merge operator field))
         (contribution-field
          (if operator
            (poo-flow-sandbox-profile-object-field-with-merge field merge)
            field)))
    (poo-flow-module-field-contribution
     (poo-flow-module-object-identity profile-object)
     contribution-field
     (poo-flow-sandbox-profile-object-row-value row))))

;;; Validation rejects malformed rows before merge planning, keeping bad user
;;; fragments from becoming partial POO contributions. The recursive scan is
;;; deliberately narrow: only filesystem resource rows can fail the extra
;;; project-workspace/path safety checks.
;; : (-> [AgentSandboxResourcePolicyEntry] Boolean)
(def (poo-flow-sandbox-profile-object-unsafe-filesystem-resource? resources)
  (cond
   ((null? resources) #f)
   ((not (pair? resources)) #f)
   ((and (agent-sandbox-profile-resource-policy-filesystem-entry?
          (car resources))
         (not (null?
               (agent-sandbox-profile-resource-policy-filesystem-diagnostics
                resources))))
    #t)
   (else
     (poo-flow-sandbox-profile-object-unsafe-filesystem-resource?
      (cdr resources)))))

;;; Resource-policy rows get an extra semantic safety check after the structural
;;; field contract accepts the list shape. Other fields are already fully
;;; covered by their POO field contract.
;; : (-> PooModuleFieldContract [Value] Boolean)
(def (poo-flow-sandbox-profile-object-field-value-safe? field value)
  (if (eq? (poo-flow-module-field-contract-identity field) 'resource-policy)
    (not (poo-flow-sandbox-profile-object-unsafe-filesystem-resource? value))
    #t))

;;; Row validation is the last user-interface gate before profile rows become
;;; object contributions, so backend inheritance and unsafe filesystem policy
;;; are rejected here with the original row preserved in the diagnostic.
;; : (-> PooModuleObject SandboxProfileForm SandboxProfileForm)
(def (poo-flow-sandbox-profile-object-validate-row profile-object row)
  (cond
   ((not (pair? row))
    (error "sandbox profile config rows must be lists"))
   ((poo-flow-sandbox-profile-object-backend-row? row)
    (error "sandbox profile config inherits backend from use-module"))
   (else
    (let (field (poo-flow-sandbox-profile-object-row-field
                 profile-object
                 row))
      (if (and field
               (poo-flow-module-field-contract-accepts?
                field
                (poo-flow-sandbox-profile-object-row-value row))
               (poo-flow-sandbox-profile-object-field-value-safe?
                field
                (poo-flow-sandbox-profile-object-row-value row)))
        row
        (error "sandbox profile config row is not in backend profile object"
               (list (cons 'row row)
                     (cons 'slot (and field
                                      (poo-flow-module-field-contract-identity
                                       field)))
                     (cons 'value
                           (poo-flow-sandbox-profile-object-row-value row))
                     (cons 'accepted?
                           (and field
                                (poo-flow-module-field-contract-accepts?
                                 field
                                 (poo-flow-sandbox-profile-object-row-value
                                  row))))
                     (cons 'safe?
                           (and field
                                (poo-flow-sandbox-profile-object-field-value-safe?
                                 field
                                 (poo-flow-sandbox-profile-object-row-value
                                  row)))))))))))

;;; Batch validation preserves the original row list so merge planning can keep
;;; user declaration order after all rows have passed the contract gate.
;; : (-> PooModuleObject [SandboxProfileForm] [SandboxProfileForm])
(def (poo-flow-sandbox-profile-object-validate-rows profile-object forms)
  (for-each (lambda (row)
              (poo-flow-sandbox-profile-object-validate-row
               profile-object
               row))
            forms)
  forms)

;;; Slot reads are strict after merge because missing slots indicate a broken
;;; backend object contract, not optional user configuration.
;; : (-> PooModuleExtensionNode Symbol Value)
(def (poo-flow-sandbox-profile-object-slot node key)
  (let (entry (assoc key (poo-flow-module-extension-node-slots node)))
    (if entry
      (cdr entry)
      (error "sandbox profile merge lost required slot" key))))

;;; The base node supplies backend-owned defaults before user row contributions
;;; run through the extension fixed point.
;; : (-> PooModuleObject Symbol Symbol PooModuleExtensionNode)
(def (poo-flow-sandbox-profile-object-base-node profile-object
                                                backend-kind
                                                name-value)
  (poo-flow-module-object-node
   profile-object
   (list (cons 'profile-name name-value)
         (cons 'backend-kind backend-kind)
         (cons 'backend-ref name-value)
         (cons 'metadata
               '((declared-by . poo-flow-user-interface)
                 (runtime-executed . #f))))
   '()))

;;; A derived profile starts from an already-resolved parent profile, then
;;; accepts ordinary sandbox rows as POO contributions. The child profile is a
;;; new backend ref by default; callers may pass `(backend-ref . <ref>)` when
;;; they intentionally want to keep an existing runtime profile ref.
;; : (-> PooModuleObject PooSandboxProfile Symbol Alist PooModuleExtensionNode)
(def (poo-flow-sandbox-profile-object-derived-base-node profile-object
                                                        parent-profile
                                                        name-value
                                                        options)
  (poo-flow-module-object-node
   profile-object
   (list
    (cons 'profile-name name-value)
    (cons 'backend-kind (poo-flow-sandbox-profile-backend-kind parent-profile))
    (cons 'backend-ref
          (poo-flow-sandbox-profile-object-option options
                                                  'backend-ref
                                                  name-value))
    (cons 'network-policy
          (poo-flow-sandbox-profile-network-policy parent-profile))
    (cons 'capabilities
          (poo-flow-sandbox-profile-capabilities parent-profile))
    (cons 'resource-policy
          (poo-flow-sandbox-profile-resource-policy parent-profile))
    (cons 'metadata
          (poo-flow-sandbox-profile-object-derived-metadata
           parent-profile
           name-value
           options)))
   '()))

;;; Shared resolver for fresh backend profiles and parent-derived child
;;; profiles. Keeping this factored prevents derivation from bypassing row
;;; validation, unsafe filesystem checks, or object-contract merge behavior.
;; : (-> PooModuleObject Symbol PooModuleExtensionNode [SandboxProfileForm] PooSandboxProfile)
(def (poo-flow-sandbox-profile-object-resolve profile-object
                                              name-value
                                              base-node
                                              forms)
  (let* ((validated-rows
          (poo-flow-sandbox-profile-object-validate-rows
           profile-object
           forms))
         (result
          (poo-flow-module-config-mk-merge
           base-node
           (map (lambda (row)
                  (poo-flow-sandbox-profile-object-row-contribution
                   profile-object
                   row))
                validated-rows)))
         (resolved-node
          (poo-flow-module-config-merge-result-root result)))
    (poo-flow-sandbox-profile-object->profile name-value resolved-node)))

;;; Final projection rewraps the resolved POO node as the public sandbox profile
;;; recipe consumed by presentation and runtime handoff code.
;; : (-> Symbol PooModuleExtensionNode PooSandboxProfile)
(def (poo-flow-sandbox-profile-object->profile name-value node)
  (.o kind: poo-flow-sandbox-profile-kind
      name: name-value
      backend-kind: (poo-flow-sandbox-profile-object-slot node 'backend-kind)
      backend-ref: (poo-flow-sandbox-profile-object-slot node 'backend-ref)
      network-policy: (poo-flow-sandbox-profile-object-slot
                       node
                       'network-policy)
      capabilities: (poo-flow-sandbox-profile-object-slot node 'capabilities)
      resource-policy: (poo-flow-sandbox-profile-object-slot
                        node
                        'resource-policy)
      metadata: (poo-flow-sandbox-profile-object-slot node 'metadata)))

;; : (-> POOObject Boolean)
(def (poo-flow-sandbox-profile-object-profile? value)
  (and (object? value)
       (.slot? value 'kind)
       (equal? (.ref value 'kind) poo-flow-sandbox-profile-kind)))

;;; Backend config modules call this with their inherited POO profile object.
;;; This is the only constructor that turns profile rows into merged profiles.
;; : (-> PooModuleObject Symbol Symbol [SandboxProfileForm] PooSandboxProfile)
(def (poo-flow-sandbox-profile-object-config profile-object
                                             backend-kind
                                             name-value
                                             forms)
  (if (symbol? name-value)
    (poo-flow-sandbox-profile-object-resolve
     profile-object
     name-value
     (poo-flow-sandbox-profile-object-base-node profile-object
                                               backend-kind
                                               name-value)
     forms)
    (error "sandbox profile name must be a symbol")))

;;; Project/session/task/branch profiles should split by deriving from a parent
;;; profile, not by re-parsing backend rows. This keeps profile extension and
;;; override behavior on the module-system POO fixed-point path.
;; : (-> PooModuleObject PooSandboxProfile Symbol [SandboxProfileForm] [Alist] PooSandboxProfile)
(def (poo-flow-sandbox-profile-object-derive profile-object
                                             parent-profile
                                             name-value
                                             forms
                                             . maybe-options)
  (let (options (if (null? maybe-options) '() (car maybe-options)))
    (cond
     ((not (symbol? name-value))
      (error "derived sandbox profile name must be a symbol"))
     ((not (poo-flow-sandbox-profile-object-profile? parent-profile))
      (error "derived sandbox profile parent must be a POO sandbox profile"))
     (else
      (poo-flow-sandbox-profile-object-resolve
       profile-object
       name-value
       (poo-flow-sandbox-profile-object-derived-base-node
        profile-object
        parent-profile
        name-value
        options)
       forms)))))

;; poo-flow-sandbox-profile-object-profiles/build
;;   : (-> ProfileConfigFn ProfileDeriveFn ProfileRow... [PooSandboxProfile])
;;   | doc m%
;;       `poo-flow-sandbox-profile-object-profiles/build` owns ordered parent
;;       binding and `:derive` expansion while backend modules supply concrete
;;       profile constructors.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-sandbox-profile-object-profiles/build
;;        profile-config derive-config () profile-clauses)
;;       ;; => sandbox-profiles
;;       ```
;;     %
(defrules poo-flow-sandbox-profile-object-profiles/build (:derive)
  ((_ profile-config profile-derive-config (profile-name ...) ())
   (list profile-name ...))
  ((_ profile-config
      profile-derive-config
      (profile-name ...)
      ((name (:derive parent option ...) form ...) profile-clause ...))
   (let (name (profile-derive-config
               parent
               'name
               '(form ...)
               '(option ...)))
     (poo-flow-sandbox-profile-object-profiles/build
      profile-config
      profile-derive-config
      (profile-name ... name)
      (profile-clause ...))))
  ((_ profile-config
      profile-derive-config
      (profile-name ...)
      ((name form ...) profile-clause ...))
   (let (name (profile-config 'name '(form ...)))
     (poo-flow-sandbox-profile-object-profiles/build
      profile-config
      profile-derive-config
      (profile-name ... name)
      (profile-clause ...)))))

;; poo-flow-sandbox-profile-object-profiles
;;   : (-> ProfileConfigFn ProfileDeriveFn ProfileRow... [PooSandboxProfile])
;;   | doc m%
;;       `poo-flow-sandbox-profile-object-profiles` is the public profile
;;       collection syntax; `:derive` ordering stays fixed-point and POO-owned
;;       through the build macro.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-sandbox-profile-object-profiles profile-config derive-config)
;;       ;; => sandbox-profiles
;;       ```
;;     %
(defrules poo-flow-sandbox-profile-object-profiles ()
  ((_ profile-config profile-derive-config)
   '())
  ((_ profile-config profile-derive-config profile-clause ...)
   (poo-flow-sandbox-profile-object-profiles/build
    profile-config
    profile-derive-config
    ()
    (profile-clause ...))))
