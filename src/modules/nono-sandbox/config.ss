;;; -*- Gerbil -*-
;;; Boundary: nono sandbox kernel module selection.
;;; Invariant: this module owns nono-specific user profile projection.

(import (only-in :clan/poo/object .o)
        :modules/agent-sandbox/config
        :modules/extension
        :modules/nono-sandbox/objects
        :modules/user-config-base)

(export poo-flow-nono-sandbox-module-bundles
        poo-flow-nono-sandbox-profile-config
        poo-flow-nono-sandbox-profile
        poo-flow-nono-sandbox-profiles)

;;; Nono is a sandbox module row; Marlin remains the runtime owner, not the row.
;; : (-> Unit [[PooUserModuleSelection]])
(def poo-flow-nono-sandbox-module-bundles
  (list
   (poo-flow-user-module-bundle
    (sandbox nono-sandbox +nono +doctor))))

;;; User profile row names are Doom-like surface syntax. This mapping is the
;;; bridge back to the nono profile object prototype in objects.ss.
;; : (-> Symbol MaybeSymbol)
(def (poo-flow-nono-sandbox-profile-row-slot row-key)
  (cond
   ((eq? row-key 'network) 'network-policy)
   ((eq? row-key 'capabilities) 'capabilities)
   ((eq? row-key 'resources) 'resource-policy)
   ((eq? row-key 'metadata) 'metadata)
   (else #f)))

;;; Backend rows are intentionally rejected in nono-specific user config:
;;; `(use-module nono-sandbox ...)` already fixes backend kind and ref policy.
;; : (-> SandboxProfileForm Boolean)
(def (poo-flow-nono-sandbox-profile-backend-row? row)
  (and (pair? row)
       (eq? (car row) 'backend)))

;;; Row lookup must go through the object prototype so user config cannot invent
;;; arbitrary profile slots that the module object never declared.
;; : (-> SandboxProfileForm MaybePooModuleFieldContract)
(def (poo-flow-nono-sandbox-profile-row-field row)
  (if (and (pair? row) (symbol? (car row)))
    (let (slot (poo-flow-nono-sandbox-profile-row-slot (car row)))
      (and slot
           (poo-flow-module-object-field
            poo-flow-nono-sandbox-profile-object
            slot)))
    #f))

;;; Profile row operators are the user-facing projection of POO slot merge
;;; behavior. The row key still selects a validated object field; the operator
;;; only overrides the merge policy for this one contribution.
;; : (-> Value Boolean)
(def (poo-flow-nono-sandbox-profile-row-operator? value)
  (or (eq? value ':override)
      (eq? value ':append)
      (eq? value ':prepend)
      (eq? value ':remove)))

;; : (-> SandboxProfileForm MaybeSymbol)
(def (poo-flow-nono-sandbox-profile-row-operator row)
  (let (tail (if (and row (pair? row)) (cdr row) '()))
    (if (and (pair? tail)
             (poo-flow-nono-sandbox-profile-row-operator? (car tail)))
      (car tail)
      #f)))

;; : (-> SandboxProfileForm [Value])
(def (poo-flow-nono-sandbox-profile-row-value row)
  (let* ((tail (cdr row))
         (operator (poo-flow-nono-sandbox-profile-row-operator row)))
    (if operator (cdr tail) tail)))

;; : (-> MaybeSymbol PooModuleFieldContract Symbol)
(def (poo-flow-nono-sandbox-profile-row-merge operator field)
  (cond
   ((eq? operator ':override) 'override)
   ((eq? operator ':append) 'append)
   ((eq? operator ':prepend) 'prepend)
   ((eq? operator ':remove) 'remove)
   (else
    (poo-flow-module-field-contract-merge field))))

;; : (-> PooModuleFieldContract Symbol PooModuleFieldContract)
(def (poo-flow-nono-sandbox-profile-field-with-merge field merge)
  (poo-flow-module-field-contract
   (poo-flow-module-field-contract-identity field)
   (poo-flow-module-field-contract-value-kind field)
   merge
   (poo-flow-module-field-contract-default field)
   (poo-flow-module-field-contract-metadata field)))

;; : (-> SandboxProfileForm PooModuleFieldContribution)
(def (poo-flow-nono-sandbox-profile-row-contribution row)
  (let* ((field (poo-flow-nono-sandbox-profile-row-field row))
         (operator (poo-flow-nono-sandbox-profile-row-operator row))
         (merge (poo-flow-nono-sandbox-profile-row-merge operator field))
         (contribution-field
          (if operator
            (poo-flow-nono-sandbox-profile-field-with-merge field merge)
            field)))
    (poo-flow-module-field-contribution
     'objects.nono-sandbox.profile
     contribution-field
     (poo-flow-nono-sandbox-profile-row-value row))))

;;; Shallow field checks catch DSL drift at config time. Runtime-level checks
;;; still happen later when the sandbox descriptor is realized.
;; : (-> SandboxProfileForm SandboxProfileForm)
(def (poo-flow-nono-sandbox-profile-validate-row row)
  (cond
   ((not (pair? row))
    (error "nono-sandbox profile config rows must be lists"))
   ((poo-flow-nono-sandbox-profile-backend-row? row)
    (error "nono-sandbox profile config inherits backend from use-module"))
   (else
    (let (field (poo-flow-nono-sandbox-profile-row-field row))
      (if (and field
               (poo-flow-module-field-contract-accepts?
                field
                (poo-flow-nono-sandbox-profile-row-value row)))
        row
        (error "nono-sandbox profile config row is not in objects.nono-sandbox.profile"))))))

;;; Validation preserves row order and returns the original forms for projection.
;; : (-> [SandboxProfileForm] [SandboxProfileForm])
(def (poo-flow-nono-sandbox-profile-validate-rows forms)
  (for-each poo-flow-nono-sandbox-profile-validate-row forms)
  forms)

;; : (-> Symbol PooModuleExtensionNode)
(def (poo-flow-nono-sandbox-profile-base-node name-value)
  (let (base-profile
        (poo-flow-sandbox-profile-config
         name-value
         (list (list 'backend 'nono name-value))))
    (poo-flow-module-extension-node
     'objects.nono-sandbox.profile
     (list (cons 'profile-name name-value)
           (cons 'backend-kind
                 (poo-flow-sandbox-profile-backend-kind base-profile))
           (cons 'backend-ref
                 (poo-flow-sandbox-profile-backend-ref base-profile))
           (cons 'network-policy
                 (poo-flow-sandbox-profile-network-policy base-profile))
           (cons 'capabilities
                 (poo-flow-sandbox-profile-capabilities base-profile))
           (cons 'resource-policy
                 (poo-flow-sandbox-profile-resource-policy base-profile))
           (cons 'metadata
                 (poo-flow-sandbox-profile-metadata base-profile)))
     '())))

;; : (-> Alist Symbol Value)
(def (poo-flow-nono-sandbox-profile-slot slots key)
  (let (entry (assoc key slots))
    (if entry
      (cdr entry)
      (error "nono-sandbox profile merge lost required slot" key))))

;; : (-> Symbol Alist PooSandboxProfile)
(def (poo-flow-nono-sandbox-profile-from-slots name-value slots)
  (.o kind: poo-flow-sandbox-profile-kind
      name: name-value
      backend-kind: (poo-flow-nono-sandbox-profile-slot slots 'backend-kind)
      backend-ref: (poo-flow-nono-sandbox-profile-slot slots 'backend-ref)
      network-policy: (poo-flow-nono-sandbox-profile-slot
                       slots
                       'network-policy)
      capabilities: (poo-flow-nono-sandbox-profile-slot
                     slots
                     'capabilities)
      resource-policy: (poo-flow-nono-sandbox-profile-slot
                        slots
                        'resource-policy)
      metadata: (poo-flow-nono-sandbox-profile-slot slots 'metadata)))

;; : (-> Symbol [SandboxProfileForm] PooSandboxProfile)
(def (poo-flow-nono-sandbox-profile-merge-rows name-value forms)
  (let* ((validated-rows (poo-flow-nono-sandbox-profile-validate-rows forms))
         (result
          (poo-flow-module-config-mk-merge
           (poo-flow-nono-sandbox-profile-base-node name-value)
           (map poo-flow-nono-sandbox-profile-row-contribution
                validated-rows)))
         (resolved-node
          (poo-flow-module-config-merge-result-root result)))
    (poo-flow-nono-sandbox-profile-from-slots
     name-value
     (poo-flow-module-extension-node-slots resolved-node))))

;;; The module owns backend projection. User rows are validated against the
;;; nono profile object first, then backend is inserted exactly once.
;; : (-> Symbol [SandboxProfileForm] PooSandboxProfile)
(def (poo-flow-nono-sandbox-profile-config name-value forms)
  (if (symbol? name-value)
    (poo-flow-nono-sandbox-profile-merge-rows name-value forms)
    (error "nono-sandbox profile name must be a symbol")))

;; poo-flow-nono-sandbox-profile
;;   : (-> Symbol SandboxProfileForm... PooSandboxProfile)
;;   | contract: validates nono profile rows against objects.nono-sandbox.profile
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-nono-sandbox-profile agent/session
;;         (network deny-by-default)
;;         (capabilities :append cache-mount)
;;         (capabilities :remove filesystem-write))
;;       ;; => nono backend profile, with backend inferred from the module
;;       ```
;;     %
;; : (-> Symbol SandboxProfileForm... PooSandboxProfile)
(defrules poo-flow-nono-sandbox-profile ()
  ((_ name form ...)
   (poo-flow-nono-sandbox-profile-config 'name '(form ...))))

;;; Nono profile rows inherit backend kind from the selected module. Users name
;;; profile refs and policy rows; the module config owns backend projection.
;; poo-flow-nono-sandbox-profiles
;;   : (-> NonoSandboxProfileRow... [PooSandboxProfile])
;;   | contract: expands nono profile rows into typed sandbox profile data
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-nono-sandbox-profiles
;;         (agent/session
;;          (network deny-by-default)))
;;       ;; => nono backend sandbox profile recipes
;;       ```
;;     %
(defrules poo-flow-nono-sandbox-profiles ()
  ((_)
   '())
  ((_ (name form ...) profile-clause ...)
   (cons (poo-flow-nono-sandbox-profile name form ...)
         (poo-flow-nono-sandbox-profiles profile-clause ...))))
