;;; -*- Gerbil -*-
;;; Boundary: sandbox profile resolution, config, and profile collection build.

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
        :poo-flow/src/modules/sandbox-core/profile-support/prototype
        :poo-flow/src/modules/sandbox-core/profile-support/authoring
        :poo-flow/src/modules/sandbox-core/profile-support/derivation)

(export poo-flow-sandbox-profile-object-slot
        poo-flow-sandbox-profile-object-base-node
        poo-flow-sandbox-profile-object-derived-base-node
        poo-flow-sandbox-profile-object-resolve
        poo-flow-sandbox-profile-object->profile
        poo-flow-sandbox-profile-object-profile?
        poo-flow-sandbox-profile-object-config
        poo-flow-sandbox-profile-object-derive
        poo-flow-sandbox-profile-object-profiles/build
        poo-flow-sandbox-profile-object-profiles)

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
