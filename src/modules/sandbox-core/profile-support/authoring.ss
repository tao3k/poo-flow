;;; -*- Gerbil -*-
;;; Boundary: sandbox profile object row authoring diagnostics.

(import :gerbil/gambit
        (only-in :clan/poo/object .def .o .ref .slot? object?)
        :poo-flow/src/module-system/extension
        :poo-flow/src/module-system/object-core
        :poo-flow/src/module-system/objects
        :poo-flow/src/modules/agent-sandbox/config
        (only-in :poo-flow/src/modules/agent-sandbox/profile-validation
                 agent-sandbox-profile-resource-policy-filesystem-entry?
                 agent-sandbox-profile-resource-policy-filesystem-diagnostics)
        :poo-flow/src/modules/sandbox-core/resource-contract
        :poo-flow/src/modules/sandbox-core/profile-support/prototype)

(export poo-flow-sandbox-profile-object-row-slot
        poo-flow-sandbox-profile-object-row-operator?
        poo-flow-sandbox-profile-object-row-operator
        poo-flow-sandbox-profile-object-row-value
        poo-flow-sandbox-profile-object-authoring-diagnostic
        poo-flow-sandbox-profile-object-row-contains-symbol?
        poo-flow-sandbox-profile-object-runtime-executed-true?
        poo-flow-sandbox-profile-object-row-value/default
        poo-flow-sandbox-profile-object-row-authoring-diagnostics
        poo-flow-sandbox-profile-object-authoring-diagnostics
        poo-flow-sandbox-profile-object-backend-row?
        poo-flow-sandbox-profile-object-row-field
        poo-flow-sandbox-profile-object-row-merge
        poo-flow-sandbox-profile-object-field-with-merge
        poo-flow-sandbox-profile-object-row-contribution)

;;; Profile row aliases keep the authoring surface small while the backend
;;; object uses canonical sandbox-core field names.
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

;;; Boundary: sandbox profile object row contains symbol predicate is the
;;; policy-visible edge for sandbox, core behavior, keeping validation, lookup,
;;; or projection responsibilities centralized for callers.
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

;;; Boundary: sandbox profile object row authoring diagnostics is the policy-
;;; visible edge for sandbox, core behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
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

;;; Boundary: sandbox profile object authoring diagnostics is the policy-
;;; visible edge for sandbox, core behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
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
