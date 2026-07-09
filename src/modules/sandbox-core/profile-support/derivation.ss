;;; -*- Gerbil -*-
;;; Boundary: sandbox profile derivation metadata and row contributions.

(import (only-in :std/srfi/1 any fold)
        :gerbil/gambit
        (only-in :clan/poo/object .def .o .ref .slot? object?)
        :poo-flow/src/module-system/extension
        :poo-flow/src/module-system/object-core
        :poo-flow/src/module-system/objects
        :poo-flow/src/modules/agent-sandbox/config
        (only-in :poo-flow/src/modules/agent-sandbox/profile-validation
                 agent-sandbox-profile-resource-policy-filesystem-entry?
                 agent-sandbox-profile-resource-policy-filesystem-diagnostics)
        :poo-flow/src/modules/sandbox-core/resource-contract
        :poo-flow/src/modules/sandbox-core/profile-support/prototype
        :poo-flow/src/modules/sandbox-core/profile-support/projection-syntax
        :poo-flow/src/modules/sandbox-core/profile-support/authoring)

(export poo-flow-sandbox-profile-object-option
        poo-flow-sandbox-profile-object-metadata-key?
        poo-flow-sandbox-profile-object-metadata-without
        poo-flow-sandbox-profile-object-derivation-path
        poo-flow-sandbox-profile-object-derivation-step
        poo-flow-sandbox-profile-object-derived-metadata
        poo-flow-sandbox-profile-object-unsafe-filesystem-resource?
        poo-flow-sandbox-profile-object-field-value-safe?
        poo-flow-sandbox-profile-object-validate-row
        poo-flow-sandbox-profile-object-validate-rows)

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

;;; Metadata pruning is used only while deriving child profiles. It removes
;;; fields that must be recomputed for the child, while leaving unrelated
;;; policy annotations untouched.
;; : (-> Alist [Symbol] Alist Alist)
(def (poo-flow-sandbox-profile-object-metadata-without/rev metadata
                                                           keys
                                                           result-rev)
  (fold
   (lambda (entry result)
     (if (and (pair? entry)
              (poo-flow-sandbox-profile-object-metadata-key?
               (car entry)
               keys))
       result
       (cons entry result)))
   result-rev
   metadata))

;; : (-> Alist [Symbol] Alist)
(def (poo-flow-sandbox-profile-object-metadata-without metadata keys)
  (reverse
   (poo-flow-sandbox-profile-object-metadata-without/rev
    metadata
    keys
    '())))

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
  (poo-flow-sandbox-profile-field-rows/tail
   (if scope-ref
     (poo-flow-sandbox-profile-field-rows (scope-ref scope-ref))
     '())
   (profile name-value)
   (parent-profile parent-name)
   (scope scope)
   (derived-by 'poo-flow-sandbox-profile-object-derive)))

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
          (poo-flow-sandbox-profile-rows/tail
           (poo-flow-sandbox-profile-object-derivation-path parent-metadata)
           (list
            (poo-flow-sandbox-profile-object-derivation-step
             name-value
             (poo-flow-sandbox-profile-name parent-profile)
             scope
             scope-ref)))))
    (poo-flow-sandbox-profile-rows/tail
     (poo-flow-sandbox-profile-object-metadata-without
      parent-metadata
      '(derivation-path runtime-executed))
     (poo-flow-sandbox-profile-field-rows/tail
      (poo-flow-sandbox-profile-object-option options 'metadata '())
      (derivation-path lineage)
      (runtime-executed #f)))))


;;; Validation rejects malformed rows before merge planning, keeping bad user
;;; fragments from becoming partial POO contributions. The recursive scan is
;;; deliberately narrow: only filesystem resource rows can fail the extra
;;; project-workspace/path safety checks.
;; : (-> [AgentSandboxResourcePolicyEntry] Boolean)
(def (poo-flow-sandbox-profile-object-unsafe-filesystem-resource? resources)
  (and (list? resources)
       (if (any
            (lambda (resource)
              (and (agent-sandbox-profile-resource-policy-filesystem-entry?
                    resource)
                   (not (null?
                         (agent-sandbox-profile-resource-policy-filesystem-diagnostics
                          resources)))))
            resources)
         #t
         #f)))

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
               (poo-flow-sandbox-profile-field-rows
                (row row)
                (slot (and field
                           (poo-flow-module-field-contract-identity
                            field)))
                (value
                 (poo-flow-sandbox-profile-object-row-value row))
                (accepted?
                 (and field
                      (poo-flow-module-field-contract-accepts?
                       field
                       (poo-flow-sandbox-profile-object-row-value
                        row))))
                (safe?
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
