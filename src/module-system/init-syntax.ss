;;; -*- Gerbil -*-
;;; Boundary: init/profile declaration syntax lives outside core profile data.
;;; Invariant: macros expand to profile-config data and never realize descriptors.

(import (only-in :clan/poo/object .o object<-alist)
        :poo-flow/src/module-system/load-syntax
        (only-in :poo-flow/src/module-system/base
                 poo-flow-user-module-selection-flag-entry
                 poo-flow-user-module-selection->alist)
        :poo-flow/src/module-system/observability
        :poo-flow/src/module-system/durable-policy
        :poo-flow/src/module-system/durable-runtime-store
        :poo-flow/src/module-system/durable-runtime-store-backend
        :poo-flow/src/module-system/durable-runtime-store-operation
        :poo-flow/src/module-system/durable-runtime-store-operation-bridge
        :poo-flow/src/module-system/durable-recovery-scenario
        :poo-flow/src/modules/cubeSandbox/config
        :poo-flow/src/modules/cubeSandbox/profile-interface
        :poo-flow/src/modules/docker-sandbox/config
        :poo-flow/src/modules/docker-sandbox/profile-interface
        :poo-flow/src/modules/funflow/config
        :poo-flow/src/modules/memory-core/config
        :poo-flow/src/modules/session/config
        :poo-flow/src/modules/tool-core/config
        :poo-flow/src/modules/nono-sandbox/config
        :poo-flow/src/modules/nono-sandbox/profile-interface
        :poo-flow/src/module-system/loop-engine-config
        :poo-flow/src/module-system/loop-engine-policy-extension
        :poo-flow/src/modules/sandbox-core/profile
        :poo-flow/src/modules/sandbox-core/profile-interface
        :poo-flow/src/module-system/profile-config
        :poo-flow/src/module-system/use-module-contract)

(export poo-flow-module-bundles
        poo-flow-custom-module-bundles
        poo-flow-init-module-bundles
        use-module
        (import: :poo-flow/src/module-system/load-syntax)
        poo-flow!
        poo-flow-profile-set
        poo-flow-profile-extend
        poo-flow-profile
        poo-flow-user-module-selection-flag-entry
        poo-flow-user-module-selection->alist
        (import: :poo-flow/src/modules/cubeSandbox/profile-interface)
        (import: :poo-flow/src/modules/docker-sandbox/profile-interface)
        (import: :poo-flow/src/modules/funflow/config)
        (import: :poo-flow/src/modules/memory-core/config)
        (import: :poo-flow/src/modules/session/config)
        (import: :poo-flow/src/modules/tool-core/config)
        (import: :poo-flow/src/module-system/loop-engine-config)
        (import: :poo-flow/src/module-system/loop-engine-policy-extension)
        (import: :poo-flow/src/modules/nono-sandbox/profile-interface)
        (import: :poo-flow/src/module-system/observability)
        (import: :poo-flow/src/module-system/durable-policy)
        (import: :poo-flow/src/module-system/durable-runtime-store)
        (import: :poo-flow/src/module-system/durable-runtime-store-backend)
        (import: :poo-flow/src/module-system/durable-runtime-store-operation)
        (import: :poo-flow/src/module-system/durable-runtime-store-operation-bridge)
        (import: :poo-flow/src/module-system/durable-recovery-scenario)
        (import: :poo-flow/src/modules/sandbox-core/profile-interface))

;; : (forall (a) (-> [a] [a] [a]))
(def (poo-flow-session-case-rows/tail rows tail)
  (let loop ((remaining-rows rows)
             (rows-rev '()))
    (if (null? remaining-rows)
      (let restore ((remaining-rev rows-rev)
                    (result tail))
        (if (null? remaining-rev)
          result
          (restore (cdr remaining-rev)
                   (cons (car remaining-rev) result))))
      (loop (cdr remaining-rows)
            (cons (car remaining-rows) rows-rev)))))

;; : (-> [[Alist]] [Alist] [Alist])
(def (poo-flow-session-case-row-groups/tail row-groups tail)
  (if (null? row-groups)
    tail
    (poo-flow-session-case-rows/tail
     (car row-groups)
     (poo-flow-session-case-row-groups/tail (cdr row-groups) tail))))

;; : (-> [Alist] [[Alist]] [Alist])
(def (poo-flow-session-case-row-groups->rows rows row-groups)
  (poo-flow-session-case-rows/tail
   rows
   (poo-flow-session-case-row-groups/tail row-groups '())))

;;; Concrete module loading is the primary user-facing surface. The macro stays
;;; thin: it only quotes the module name and payload, while group routing lives
;;; in `poo-flow-modules-system-use-module` upstream data helpers.
(begin-syntax
  (def (poo-flow-syntax-list->list stx)
    (syntax->list stx))

  (def (poo-flow-simple-keyword-slot-specs/elements ctx elements)
    (match elements
      ([] '())
      ([slot-key slot-value . more]
       (let (key (syntax->datum slot-key))
         (and (keyword? key)
              (let (rest
                    (poo-flow-simple-keyword-slot-specs/elements ctx more))
                (and rest
                     (cons (list (datum->syntax
                                  ctx
                                  (string->symbol (keyword->string key)))
                                 slot-value)
                           rest))))))
      (else #f)))

  (def (poo-flow-simple-keyword-slot-specs ctx slot-specs)
    (let (elements (poo-flow-syntax-list->list slot-specs))
      (and elements
           (poo-flow-simple-keyword-slot-specs/elements ctx elements))))

  (def (poo-flow-simple-keyword-slot-groups/elements ctx elements)
    (match elements
      ([] '())
      ([slot-specs . more]
       (cons (poo-flow-simple-keyword-slot-specs ctx slot-specs)
             (poo-flow-simple-keyword-slot-groups/elements ctx more)))))

  (def (poo-flow-simple-keyword-slot-groups ctx slot-def-groups)
    (poo-flow-simple-keyword-slot-groups/elements
     ctx
     (poo-flow-syntax-list->list slot-def-groups)))

  (def (poo-flow-all? values)
    (not (member #f values))))

;; poo-flow-use-module-poo-config
;;   : (-> Syntax Syntax)
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (use-module memory-core :config (.def (store @ spec field) field: x))
;;       ;; => module selection
;;       ```
;;     %
(defsyntax (poo-flow-use-module-poo-config stx)
  (syntax-case stx (quoted .def)
    ((ctx module-key config-flags
          (quoted quoted-form ...)
          (.def (prototype-name prototype-self prototype-super prototype-slot ...)
                slot-def ...)
          ...)
     (let* ((slot-groups
             (poo-flow-simple-keyword-slot-groups
              (syntax ctx)
              (syntax ((slot-def ...) ...)))))
       (if (poo-flow-all? slot-groups)
         (with-syntax (((((slot-name slot-value) ...) ...) slot-groups))
           (syntax
            (let* ((prototype-name
                    (object<-alist
                     (list (cons 'slot-name slot-value) ...)
                     supers: prototype-super))
                   ...)
              (poo-flow-modules-system-use-module/contract
               'module-key
               (config-flags
                (list prototype-name ...)
                '(quoted-form ...))))))
         (syntax
          (let* ((prototype-name
                  (.o (:: prototype-self prototype-super prototype-slot ...)
                      slot-def ...))
                 ...)
            (poo-flow-modules-system-use-module/contract
             'module-key
             (config-flags
              (list prototype-name ...)
              '(quoted-form ...))))))))))

;; poo-flow-use-module-sandbox-profile-config
;;   : (-> Syntax Syntax)
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (use-module nono-sandbox :inherits ci/build)
;;       ;; => sandbox selection
;;       ```
;;     %
(defsyntax (poo-flow-use-module-sandbox-profile-config stx)
  (syntax-case stx (profile-arguments quoted .def)
    ((ctx module-key config-flags
          (profile-arguments config-arg ...)
          (quoted quoted-form ...)
          (.def (profile-name profile-self profile-super profile-slot ...)
                slot-def ...)
          ...)
     (let* ((slot-groups
             (poo-flow-simple-keyword-slot-groups
              (syntax ctx)
              (syntax ((slot-def ...) ...)))))
       (if (poo-flow-all? slot-groups)
         (with-syntax (((((slot-name slot-value) ...) ...) slot-groups))
           (syntax
            (let* ((profile-name
                    (object<-alist
                     (list (cons 'slot-name slot-value) ...)
                     supers: profile-super))
                   ...)
              (poo-flow-modules-system-use-module/contract
               'module-key
               (config-flags
                config-arg ...
                (poo-flow-sandbox-profile-prototypes
                 (profile-name profile-name) ...)
                '(quoted-form ...))))))
         (syntax
          (let* ((profile-name
                  (.o (:: profile-self profile-super profile-slot ...)
                      slot-def ...))
                 ...)
            (poo-flow-modules-system-use-module/contract
             'module-key
             (config-flags
              config-arg ...
              (poo-flow-sandbox-profile-prototypes
               (profile-name profile-name) ...)
              '(quoted-form ...))))))))))

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
(defsyntax (use-module stx)
  (syntax-case stx (:config :rows :metadata profiles binding workflow funflow session-core tool-core memory-core loop-engine nono-sandbox cubeSandbox docker-sandbox
                    session-case metadata objects rows row-groups
                    .def
                    :inherits :isolation :environment :command :nono)
    ((_ funflow
        (.def (prototype-name prototype-self prototype-super prototype-slot ...)
              slot-def ...)
        ...)
     (let* ((slot-groups
             (poo-flow-simple-keyword-slot-groups
              (syntax ctx)
              (syntax ((slot-def ...) ...)))))
       (if (poo-flow-all? slot-groups)
         (with-syntax (((((slot-name slot-value) ...) ...) slot-groups))
           (syntax
            (let* ((prototype-name
                    (object<-alist
                     (list (cons 'slot-name slot-value) ...)
                     supers: (poo-flow-memory-core-prototype-super
                              'prototype-super)))
                   ...)
              (poo-flow-modules-system-use-module/contract
               'funflow
               (poo-flow-funflow-poo-config-flags
                (list prototype-name ...)
                '((.def (prototype-name prototype-self prototype-super prototype-slot ...)
                        slot-def ...)
                  ...))))))
         (syntax
          (let* ((prototype-name
                  (.o (:: prototype-self
                          (poo-flow-memory-core-prototype-super
                           'prototype-super)
                          prototype-slot ...)
                      slot-def ...))
                 ...)
            (poo-flow-modules-system-use-module/contract
             'funflow
             (poo-flow-funflow-poo-config-flags
              (list prototype-name ...)
              '((.def (prototype-name prototype-self prototype-super prototype-slot ...)
                      slot-def ...)
                ...))))))))
    ((_ funflow
        :config
        (.def (prototype-name prototype-self prototype-super prototype-slot ...)
              slot-def ...)
        ...)
     (syntax
      (poo-flow-use-module-poo-config
       funflow
       poo-flow-funflow-poo-config-flags
       (quoted :config
               (.def (prototype-name prototype-self prototype-super prototype-slot ...)
                     slot-def ...)
               ...)
       (.def (prototype-name prototype-self prototype-super prototype-slot ...)
             slot-def ...)
       ...)))
    ((_ workflow :config bad-clause ...)
     (syntax
      (poo-flow-modules-system-use-module/contract
       'workflow
       '())))
    ((_ session-core
        :config
        (session-case case-name
          (metadata metadata-entry ...)
          (objects (object-name object-expr) ...)
          (rows row-expr ...)
          (row-groups row-group-expr ...))
        ...)
     (syntax
      (let* ((case-name
              (let* ((object-name object-expr) ...)
                (object<-alist
                 (list
                  (cons 'rows
                        (poo-flow-session-case-row-groups->rows
                         (list row-expr ...)
                         (list row-group-expr ...)))
                  (cons 'metadata '(metadata-entry ...)))
                 supers: session-config)))
             ...)
        (poo-flow-modules-system-use-module/contract
         'session-core
         (poo-flow-session-core-poo-config-flags
          (list case-name ...)
          '(:config
            (session-case case-name
              (metadata metadata-entry ...)
              (objects (object-name object-expr) ...)
              (rows row-expr ...)
              (row-groups row-group-expr ...))
            ...))))))
    ((_ session-core
        :config
        (session-case case-name
          (metadata metadata-entry ...)
          (objects (object-name object-expr) ...)
          (rows row-expr ...))
        ...)
     (syntax
      (let* ((case-name
              (let* ((object-name object-expr) ...)
                (object<-alist
                 (list
                  (cons 'rows (list row-expr ...))
                  (cons 'metadata '(metadata-entry ...)))
                 supers: session-config)))
             ...)
        (poo-flow-modules-system-use-module/contract
         'session-core
         (poo-flow-session-core-poo-config-flags
          (list case-name ...)
          '(:config
            (session-case case-name
              (metadata metadata-entry ...)
              (objects (object-name object-expr) ...)
              (rows row-expr ...))
            ...))))))
    ((_ session-core
        :config
        (.def (prototype-name prototype-self prototype-super prototype-slot ...)
              slot-def ...)
        ...)
     (error "session-core :config .def has been removed; use (use-module session-core :config (session-case ...))"))
    ((_ session-core
        :rows bad-clause ...)
     (error "session-core :rows has been removed; use (use-module session-core :config (session-case ...))"))
    ((_ tool-core
        :config
        (.def (prototype-name prototype-self prototype-super prototype-slot ...)
              slot-def ...)
        ...)
     (syntax
      (poo-flow-use-module-poo-config
       tool-core
       poo-flow-tool-core-poo-config-flags
       (quoted :config
               (.def (prototype-name prototype-self prototype-super prototype-slot ...)
                     slot-def ...)
               ...)
       (.def (prototype-name prototype-self prototype-super prototype-slot ...)
             slot-def ...)
       ...)))
    ((_ memory-core
        :config
        (.def (prototype-name prototype-self prototype-super prototype-slot ...)
              slot-def ...)
        ...)
     (syntax
      (poo-flow-use-module-poo-config
       memory-core
       poo-flow-memory-core-poo-config-flags
       (quoted :config
               (.def (prototype-name prototype-self prototype-super prototype-slot ...)
                     slot-def ...)
               ...)
       (.def (prototype-name prototype-self prototype-super prototype-slot ...)
             slot-def ...)
       ...)))
    ((_ loop-engine
        :config
        (.def (prototype-name prototype-self prototype-super prototype-slot ...)
              slot-def ...)
        ...)
     (syntax
      (poo-flow-use-module-poo-config
       loop-engine
       poo-flow-user-loop-engine-poo-config-flags
       (quoted :config
               (.def (prototype-name prototype-self prototype-super prototype-slot ...)
                     slot-def ...)
               ...)
       (.def (prototype-name prototype-self prototype-super prototype-slot ...)
             slot-def ...)
       ...)))
    ((_ loop-engine bad-clause ...)
     (error "loop-engine config DSL has been removed; use (use-module loop-engine :config (.def ...))"))
    ((_ nono-sandbox
        (binding binding-kind)
        (.def (profile-name profile-self profile-super profile-slot ...)
              slot-def ...)
        ...)
     (syntax
      (poo-flow-use-module-sandbox-profile-config
       nono-sandbox
       poo-flow-nono-sandbox-config-flags
       (profile-arguments 'binding-kind)
       (quoted (binding binding-kind)
               (.def (profile-name profile-self profile-super profile-slot ...)
                     slot-def ...)
               ...)
       (.def (profile-name profile-self profile-super profile-slot ...)
             slot-def ...)
       ...)))
    ((_ nono-sandbox
        (.def (profile-name profile-self profile-super profile-slot ...)
              slot-def ...)
        ...)
     (syntax
      (poo-flow-use-module-sandbox-profile-config
       nono-sandbox
       poo-flow-nono-sandbox-config-flags
       (profile-arguments +poo-flow-nono-sandbox-default-binding+)
       (quoted (.def (profile-name profile-self profile-super profile-slot ...)
                     slot-def ...)
               ...)
       (.def (profile-name profile-self profile-super profile-slot ...)
             slot-def ...)
       ...)))
    ((_ cubeSandbox
        (.def (profile-name profile-self profile-super profile-slot ...)
              slot-def ...)
        ...)
     (syntax
      (poo-flow-use-module-sandbox-profile-config
       cubeSandbox
       poo-flow-cubeSandbox-config-flags
       (profile-arguments)
       (quoted (.def (profile-name profile-self profile-super profile-slot ...)
                     slot-def ...)
               ...)
       (.def (profile-name profile-self profile-super profile-slot ...)
             slot-def ...)
       ...)))
    ((_ docker-sandbox
        (.def (profile-name profile-self profile-super profile-slot ...)
              slot-def ...)
        ...)
     (syntax
      (poo-flow-use-module-sandbox-profile-config
       docker-sandbox
       poo-flow-docker-sandbox-config-flags
       (profile-arguments)
       (quoted (.def (profile-name profile-self profile-super profile-slot ...)
                     slot-def ...)
               ...)
       (.def (profile-name profile-self profile-super profile-slot ...)
             slot-def ...)
       ...)))
    ((_ module
        :inherits inherited-profile
        :isolation isolation-clause
        :environment environment-clause
        :command command-clause
        :nono nono-clause)
     (syntax
      (poo-flow-modules-system-use-module/contract
       'module
       (list
        (cons ':inherits 'inherited-profile)
        (cons ':isolation 'isolation-clause)
        (cons ':environment 'environment-clause)
        (cons ':command 'command-clause)
        (cons ':nono 'nono-clause)))))
    ((_ module :config bad-clause ...)
     (error "use-module :config DSL has been removed; module configs use native POO .def forms"))
    ((_ module flag ...)
     (syntax
      (poo-flow-modules-system-use-module/contract 'module (list 'flag ...))))))

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

;;; Plain category walkers share the same marker transfer and row wrapping
;;; frame. Flow and custom stay explicit because they carry special row shapes.
;; defpoo-init-category-bundles
;;   : (-> Identifier Identifier Syntax)
;;   | contract: generates a private init category walker for plain rows
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (defpoo-init-category-bundles poo-flow-init-loop-bundles loop)
;;       ;; => marker-aware walker over (module flag ...) rows
;;       ```
;;     %
(defsyntax (defpoo-init-category-bundles stx)
  (syntax-case stx ()
    ((_ walker category)
     (let ((walker-name (syntax->datum (syntax walker)))
           (category-name (syntax->datum (syntax category))))
       (datum->syntax
        (syntax walker)
        `(defrules ,walker-name (:workflow :loop :sandbox :custom)
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
                   (,category-name module flag ...))
                  (,walker-name init-clause ...)))))))))

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
(defrules poo-flow-init-flow-bundles (:workflow :loop :sandbox :custom loop-engine)
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
  ((_ (loop-engine flag flag-rest ...) init-clause ...)
   (error "loop-engine init row config DSL has been removed; use use-module loop-engine :config with native POO .def forms"))
  ((_ (loop-engine) init-clause ...)
   (cons (poo-flow-user-module-bundle
          (flow loop-engine))
         (poo-flow-init-flow-bundles init-clause ...)))
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
(defpoo-init-category-bundles poo-flow-init-loop-bundles loop)

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
(defpoo-init-category-bundles poo-flow-init-sandbox-bundles sandbox)

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
        (begin
          (def module-bundles-binding
            (poo-flow-init-module-bundles init-clause ...))
          (export module-bundles-binding)))))))

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
