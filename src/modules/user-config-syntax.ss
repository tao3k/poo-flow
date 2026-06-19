;;; -*- Gerbil -*-
;;; Boundary: user profile/module declaration syntax lives outside core profile data.
;;; Invariant: macros expand to user-config data and never realize descriptors.

(import :modules/user-config)

(export poo-flow-module-bundles
        poo-flow-custom-module-bundles
        poo-flow-init-module-bundles
        use-module
        poo-flow!
        poo-flow-profile-set
        poo-flow-profile-extend
        poo-flow-profile)

;;; Concrete module loading is the primary user-facing surface. The macro stays
;;; thin: it only quotes the module name and payload, while group routing lives
;;; in `poo-flow-use-module` upstream data helpers.
;; use-module
;;   : (-> Symbol UserModuleFlagEntry... [PooUserModuleSelection])
;;   | contract: maps a concrete module row into one inspectable bundle
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (use-module nono-sandbox +nono +doctor)
;;       ;; => sandbox module selection bundle
;;       ```
;;     %
(defrules use-module ()
  ((_ module flag ...)
   (poo-flow-use-module 'module (list 'flag ...))))

;;; Module bundle lists are the direct analogue of Doom's module rows: each row
;;; stays a separate bundle so diagnostics can preserve declaration order.
;; | PooFlowModuleRow = (Group Module Flag...)
;; poo-flow-module-bundles
;;   : (-> PooFlowModuleRow... [[PooUserModuleSelection]])
;;   | contract: expands module rows into inspectable bundle data only
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-module-bundles
;;         (flow funflow +functional)
;;         (loop governor +policy))
;;       ;; => bundles
;;       ```
;;     %
(defrules poo-flow-module-bundles ()
  ((_)
   '())
  ((_ module-clause module-clause-rest ...)
   (cons (poo-flow-user-module-bundle module-clause)
         (poo-flow-module-bundles module-clause-rest ...))))

;;; Private/custom module rows keep the init surface pure: users name the
;;; module and entrypoint root, while the macro supplies the custom group.
;; | PooFlowCustomModuleRow = (Module RootPath Flag...)
;; poo-flow-custom-module-bundles
;;   : (-> PooFlowCustomModuleRow... [[PooUserModuleSelection]])
;;   | contract: expands private rows into custom module selections only
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-custom-module-bundles
;;         (my-module "./custom/my-module" +private +doctor))
;;       ;; => bundles
;;       ```
;;     %
(defrules poo-flow-custom-module-bundles ()
  ((_)
   '())
  ((_ (module module-root-path flag ...) custom-clause ...)
   (cons (poo-flow-user-module-bundle
          (custom module module-root-path flag ...))
         (poo-flow-custom-module-bundles custom-clause ...))))

;;; Doom-style init rows use category markers. `+flags` remain feature
;;; modifiers, while `:workflow`, `:loop`, `:sandbox`, and `:custom` own grouping.
;;; `use-module` is intentionally not accepted here; it belongs to config/helper
;;; surfaces that already know they are constructing module selections directly.
;; | PooFlowInitRow = :Category ModuleRow...
;; poo-flow-init-module-bundles
;;   : (-> PooFlowInitRow... [[PooUserModuleSelection]])
;;   | contract: parses flat Doom-style category rows into POO module bundles
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-init-module-bundles
;;         :workflow
;;         (funflow +functional)
;;         :sandbox
;;         (nono-sandbox +doctor))
;;       ;; => bundles
;;       ```
;;     %
(defrules poo-flow-init-module-bundles
  (modules custom :workflow :loop :sandbox :custom)
  ((_)
   '())
  ((_ (modules module-clause ...) init-clause ...)
   (append (poo-flow-module-bundles module-clause ...)
           (poo-flow-init-module-bundles init-clause ...)))
  ((_ (custom custom-clause ...) init-clause ...)
   (append (poo-flow-custom-module-bundles custom-clause ...)
           (poo-flow-init-module-bundles init-clause ...)))
  ((_ :workflow init-clause ...)
   (poo-flow-init-flow-bundles init-clause ...))
  ((_ :loop init-clause ...)
   (poo-flow-init-loop-bundles init-clause ...))
  ((_ :sandbox init-clause ...)
   (poo-flow-init-sandbox-bundles init-clause ...))
  ((_ :custom init-clause ...)
   (poo-flow-init-custom-bundles init-clause ...)))

;;; Workflow category walking is a macro-time cursor over init rows: it emits
;;; flow selections until another category marker transfers control.
;; poo-flow-init-flow-bundles
;;   : (-> PooFlowInitRow... [[PooUserModuleSelection]])
;;   | contract: parses rows after :workflow until the next category marker
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-init-flow-bundles
;;         (funflow +dag)
;;         :sandbox
;;         (cubeSandbox +doctor))
;;       ;; => bundles
;;       ```
;;     %
(defrules poo-flow-init-flow-bundles (:workflow :loop :sandbox :custom)
  ((_)
   '())
  ((_ :workflow init-clause ...)
   (poo-flow-init-flow-bundles init-clause ...))
  ((_ :loop init-clause ...)
   (poo-flow-init-loop-bundles init-clause ...))
  ((_ :sandbox init-clause ...)
   (poo-flow-init-sandbox-bundles init-clause ...))
  ((_ :custom init-clause ...)
   (poo-flow-init-custom-bundles init-clause ...))
  ((_ (module flag ...) init-clause ...)
   (cons (poo-flow-user-module-bundle
          (flow module flag ...))
         (poo-flow-init-flow-bundles init-clause ...))))

;;; Loop category walking mirrors workflow parsing but tags plain rows as loop
;;; selections; marker clauses remain tail calls into sibling walkers.
;; poo-flow-init-loop-bundles
;;   : (-> PooFlowInitRow... [[PooUserModuleSelection]])
;;   | contract: parses rows after :loop until the next category marker
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-init-loop-bundles
;;         (governor +policy)
;;         :custom
;;         (my-module "./custom/my-module"))
;;       ;; => bundles
;;       ```
;;     %
(defrules poo-flow-init-loop-bundles (:workflow :loop :sandbox :custom)
  ((_)
   '())
  ((_ :workflow init-clause ...)
   (poo-flow-init-flow-bundles init-clause ...))
  ((_ :loop init-clause ...)
   (poo-flow-init-loop-bundles init-clause ...))
  ((_ :sandbox init-clause ...)
   (poo-flow-init-sandbox-bundles init-clause ...))
  ((_ :custom init-clause ...)
   (poo-flow-init-custom-bundles init-clause ...))
  ((_ (module flag ...) init-clause ...)
   (cons (poo-flow-user-module-bundle
          (loop module flag ...))
         (poo-flow-init-loop-bundles init-clause ...))))

;;; Sandbox category walking keeps backend choices declarative: rows become
;;; user selections, not sandbox descriptors or runtime requests.
;; poo-flow-init-sandbox-bundles
;;   : (-> PooFlowInitRow... [[PooUserModuleSelection]])
;;   | contract: parses rows after :sandbox until the next category marker
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-init-sandbox-bundles
;;         (nono-sandbox +doctor)
;;         (cubeSandbox +doctor))
;;       ;; => bundles
;;       ```
;;     %
(defrules poo-flow-init-sandbox-bundles (:workflow :loop :sandbox :custom)
  ((_)
   '())
  ((_ :workflow init-clause ...)
   (poo-flow-init-flow-bundles init-clause ...))
  ((_ :loop init-clause ...)
   (poo-flow-init-loop-bundles init-clause ...))
  ((_ :sandbox init-clause ...)
   (poo-flow-init-sandbox-bundles init-clause ...))
  ((_ :custom init-clause ...)
   (poo-flow-init-custom-bundles init-clause ...))
  ((_ (module flag ...) init-clause ...)
   (cons (poo-flow-user-module-bundle
          (sandbox module flag ...))
         (poo-flow-init-sandbox-bundles init-clause ...))))

;;; Custom category walking is the only init walker that accepts a module root
;;; path; it records source metadata while loaders decide execution later.
;; poo-flow-init-custom-bundles
;;   : (-> PooFlowInitRow... [[PooUserModuleSelection]])
;;   | contract: parses rows after :custom until the next category marker
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-init-custom-bundles
;;         (my-module "./custom/my-module" +private))
;;       ;; => bundles
;;       ```
;;     %
(defrules poo-flow-init-custom-bundles (:workflow :loop :sandbox :custom)
  ((_)
   '())
  ((_ :workflow init-clause ...)
   (poo-flow-init-flow-bundles init-clause ...))
  ((_ :loop init-clause ...)
   (poo-flow-init-loop-bundles init-clause ...))
  ((_ :sandbox init-clause ...)
   (poo-flow-init-sandbox-bundles init-clause ...))
  ((_ :custom init-clause ...)
   (poo-flow-init-custom-bundles init-clause ...))
  ((_ (module module-root-path flag ...) init-clause ...)
   (cons (poo-flow-user-module-bundle
          (custom module module-root-path flag ...))
         (poo-flow-init-custom-bundles init-clause ...))))

;;; Root user init macro. This is intentionally closer to Doom's `doom!` block
;;; than to constructor-oriented profile code: users list category/module/feature
;;; Low-level profile init macro. Root init files declare module rows; the
;;; facade creates the canonical `users` profile.
;; | PooFlowProfileInit = (poo-flow! ProfileBinding ProfileSetBinding (profile Name [(extends BaseProfile)]) :Category Row...)
;; poo-flow!
;;   : (-> ModuleRows CustomRows PooUserProfileSet)
;;   | contract: defines call-site profile and profile-set bindings
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow! poo-flow-user-profile poo-flow-user-profile-set
;;         (profile users (extends poo-flow-kernel-profile))
;;         :workflow
;;         (funflow (+cicd (checks +parallel)))
;;         :custom
;;         (my-module "./custom/my-module" +private))
;;       ;; => profile-bindings
;;       ```
;;     %
(defsyntax (poo-flow! stx)
  (syntax-case stx (profile extends)
    ((_ profile-binding
        profile-set-binding
        (profile profile-name (extends base-profile))
        init-clause ...)
     (syntax
      (begin
        (def profile-binding
          (pooFlowUserProfileExtend
           'profile-name
           base-profile
           (poo-flow-init-module-bundles init-clause ...)))
        (def profile-set-binding
          (pooFlowUserProfileSet
           'user
           'profile-name
           (list profile-binding))))))
    ((_ profile-binding
        profile-set-binding
        (profile profile-name)
        init-clause ...)
     (syntax
      (begin
        (def profile-binding
          (pooFlowUserProfile
           'profile-name
           (poo-flow-init-module-bundles init-clause ...)
           (pooFlowDefaultUserSettings 'profile-name)
           poo-flow-default-user-setting-keys))
        (def profile-set-binding
          (pooFlowUserProfileSet
           'user
           'profile-name
           (list profile-binding))))))
    ((ctx init-clause ...)
     (with-syntax ((module-bundles-binding
                    (datum->syntax (syntax ctx)
                                   'poo-flow-user-module-bundles)))
       (syntax
        (def module-bundles-binding
          (poo-flow-init-module-bundles init-clause ...)))))))

;;; Compact profile-set syntax borrows Doom's profiles.el shape but restricts
;;; the surface to profile registry data.
;; | PooFlowProfileSetName = Symbol
;; | PooFlowProfileName = Symbol
;; poo-flow-profile-set
;;   : (-> PooFlowProfileSetName PooFlowProfileName PooUserProfile... PooUserProfileSet)
;;   | contract: selects a default profile by name; no file loading or sync
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-profile-set user
;;         (default kernel)
;;         (profiles poo-flow-kernel-profile))
;;       ;; => profile-set
;;       ```
;;     %
(defrules poo-flow-profile-set ()
  ((_ binding-name
      set-name
      (_ default-profile-name)
      (_ profile ...))
   (def binding-name
     (pooFlowUserProfileSet 'set-name
                            'default-profile-name
                            (list profile ...))))
  ((_ set-name
      (_ default-profile-name)
      (_ profile ...))
   (pooFlowUserProfileSet 'set-name
                          'default-profile-name
                          (list profile ...))))

;;; Profile extension declaration keeps root init files close to Doom's init.el:
;;; one user-visible form appends custom modules to a base POO profile object.
;; | PooFlowProfileBinding = Identifier
;; | PooFlowProfileName = Symbol
;; | PooFlowBaseProfile = PooUserProfile
;; | PooFlowProfileModuleBundle = [PooUserModuleSelection]
;; poo-flow-profile-extend
;;   : (-> PooFlowProfileBinding PooFlowProfileName PooFlowBaseProfile PooFlowProfileModuleBundle... PooUserProfile)
;;   | contract: defines an extended profile object; no descriptor realization
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-profile-extend user-profile developer base-profile
;;         (modules custom-bundle))
;;       ;; => user-profile
;;       ```
;;     %
(defrules poo-flow-profile-extend (modules bundles)
  ((_ binding-name
      profile-name
      base-profile
      (bundles module-bundles ...))
   (def binding-name
     (pooFlowUserProfileExtend 'profile-name
                               base-profile
                               (append module-bundles ...))))
  ((_ binding-name
      profile-name
      base-profile
      (modules module-bundle ...))
   (def binding-name
     (pooFlowUserProfileExtend 'profile-name
                               base-profile
                               (list module-bundle ...)))))

;;; Canonical profile syntax keeps user-facing declarations aligned with the
;;; product name without changing the underlying profile object contract.
;; | PooFlowUserProfileName = Symbol
;; | PooFlowUserProfileModuleBundle = [PooUserModuleSelection]
;; poo-flow-profile
;;   : (-> PooFlowUserProfileName PooFlowUserProfileModuleBundle... UserSettingSyntax... [Symbol] PooUserProfile)
;;   | contract: expands directly to the branded profile constructor
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-profile developer
;;         (modules
;;          (poo-flow-user-module-bundle (flow funflow +functional)))
;;         (settings surface: "poo-flow")
;;         (setting-keys surface))
;;       ;; => profile
;;       ```
;;     %
(defrules poo-flow-profile (modules settings setting-keys)
  ((_ binding-name
      profile-name
      (modules module-bundle ...)
      (settings setting ...)
      (setting-keys setting-key ...))
   (def binding-name
     (pooFlowUserProfile 'profile-name
                         (list module-bundle ...)
                         (poo-flow-settings setting ...)
                         (list 'setting-key ...))))
  ((_ profile-name
      (modules module-bundle ...)
      (settings setting ...)
      (setting-keys setting-key ...))
   (pooFlowUserProfile 'profile-name
                       (list module-bundle ...)
                       (poo-flow-settings setting ...)
                       (list 'setting-key ...))))
