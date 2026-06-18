;;; -*- Gerbil -*-
;;; Boundary: module descriptors and import closure validation.
;;; Invariant: descriptors are data bundles and never load module sources.

(import (only-in :clan/poo/object .o .mix .@ .ref object?)
        :core/roles
        :core/failure
        :core/task
        :core/flow
        :modules/interface
        :modules/source)

(export poo-module-role
        poo-module-descriptor-prototype
        make-poo-module-descriptor/full
        make-poo-module-descriptor/extended
        make-poo-module-descriptor
        make-empty-poo-module-descriptor
        poo-module
        poo-module-descriptor?
        poo-module-config?
        poo-modules
        pooModules
        defpoo-module
        poo-module-name
        poo-module-imports
        poo-module-task-registry
        poo-module-flow-registry
        poo-module-options
        poo-module-interface-object
        poo-module-schemas
        poo-module-config
        poo-module-extensions
        poo-module-scripts
        poo-module-metadata
        poo-module-descriptor-source-ref
        poo-module-group
        poo-module-flags
        poo-module-features
        poo-module-depth
        poo-module-phase-files
        poo-module-hooks
        poo-module-task-descriptors
        poo-module-flow-descriptors
        poo-module-names
        poo-module-import-profile
        poo-module-import-config
        poo-module-import-configs
        poo-module-closure
        poo-module-all-task-descriptors
        poo-module-all-flow-descriptors
        poo-module-all-options
        poo-module-missing-imports
        validate-poo-module-imports)

;;; Boundary: role data anchors module descriptors in the control-plane C3 set.
;; Role <- Unit
(def poo-module-role
  (.o (:: @ control-plane-role)
      (name 'poo-module)
      (kind 'module)
      (responsibility 'descriptor-bundle)
      (runtime-owner 'gerbil)
      (module-capability 'descriptor-activation)))

;;; Boundary: descriptor defaults make direct constructors and facade modules compatible.
;;; Intent: every module surface eventually lowers into this stable slot layout.
;; PooModuleDescriptorPrototype <- Unit
(def poo-module-descriptor-prototype
  (.mix slots: (role-constant-slots
                (list (cons 'kind 'poo-module)
                      (cons 'module-kind poo-modules-kind)
                      (cons 'group 'poo)
                      (cons 'interface #f)
                      (cons 'imports '())
                      (cons 'extensions '())
                      (cons 'scripts '())
                      (cons 'flags '())
                      (cons 'features '())
                      (cons 'depth (cons 0 0))
                      (cons 'phase-files '())
                      (cons 'hooks '())
                      (cons 'task-registry
                            (make-task-family-registry 'empty-module-task-families '()))
                      (cons 'flow-registry
                            (make-flow-declaration-registry 'empty-module-flow-declarations '()))
                      (cons 'options '())
                      (cons 'config (.o))
                      (cons 'schemas (.o))
                      (cons 'metadata '())
                      (cons 'source-ref #f)
                      (cons 'extension-policy 'module-descriptor)))
        poo-module-role))

;;; Boundary: full constructor is the single descriptor slot authority.
;;; Intent: all public constructors must pass through one slot assembly point.
;;; Doom influence stays explicit in slots instead of hidden loader context.
;; PooModuleDescriptor <- ModuleName ModuleImportList TaskFamilyRegistry FlowDeclarationRegistry ModuleOptionAlist MaybeInterface ModuleSchemas ModuleConfig [ModuleExtension] [ModuleScript] ModuleMetadata MaybeSourceRef ModuleGroup [ModuleFlag] [ModuleFeature] ModuleDepth ModulePhaseFiles ModuleHooks
(def (make-poo-module-descriptor/full
      module-name
      module-imports
      task-registry
      flow-registry
      options
      interface
      schemas
      config
      extensions
      scripts
      metadata
      source-ref
      group
      flags
      features
      depth
      phase-files
      hooks)
  (.mix slots: (role-constant-slots
                (list (cons 'name module-name)
                      (cons 'module-kind poo-modules-kind)
                      (cons 'group group)
                      (cons 'interface interface)
                      (cons 'imports module-imports)
                      (cons 'extensions extensions)
                      (cons 'scripts scripts)
                      (cons 'flags flags)
                      (cons 'features features)
                      (cons 'depth depth)
                      (cons 'phase-files phase-files)
                      (cons 'hooks hooks)
                      (cons 'task-registry task-registry)
                      (cons 'flow-registry flow-registry)
                      (cons 'options options)
                      (cons 'config config)
                      (cons 'schemas schemas)
                      (cons 'metadata metadata)
                      (cons 'source-ref source-ref)
                      (cons 'responsibility
                            (list 'poo-module module-name))))
        poo-module-descriptor-prototype))

;;; Boundary: extended constructor keeps Marlin migration call sites stable.
;; PooModuleDescriptor <- ModuleName ModuleImportList TaskFamilyRegistry FlowDeclarationRegistry ModuleOptionAlist MaybeInterface ModuleSchemas ModuleConfig [ModuleExtension] [ModuleScript] ModuleMetadata MaybeSourceRef
(def (make-poo-module-descriptor/extended
      module-name
      module-imports
      task-registry
      flow-registry
      options
      interface
      schemas
      config
      extensions
      scripts
      metadata
      source-ref)
  (make-poo-module-descriptor/full
   module-name
   module-imports
   task-registry
   flow-registry
   options
   interface
   schemas
   config
   extensions
   scripts
   metadata
   source-ref
   'poo
   '()
   '()
   (cons 0 0)
   '()
   '()))

;; PooModuleDescriptor <- ModuleName ModuleImportList TaskFamilyRegistry FlowDeclarationRegistry ModuleOptionAlist
(def (make-poo-module-descriptor module-name module-imports task-registry flow-registry options)
  (make-poo-module-descriptor/extended
   module-name
   module-imports
   task-registry
   flow-registry
   options
   #f
   (.o)
   (.o)
   '()
   '()
   '()
   #f))

;; PooModuleDescriptor <- ModuleName ModuleImportList ModuleOptionAlist
(def (make-empty-poo-module-descriptor module-name module-imports options)
  (make-poo-module-descriptor
   module-name
   module-imports
   (make-task-family-registry module-name '())
   (make-flow-declaration-registry module-name '())
   options))

;;; Boundary: Marlin-style facade lowers sparse user config into a descriptor.
;;; Intent: preserve Marlin's interface/config split without importing its runtime.
;; PooModuleDescriptor <- PooModuleInterface POOObject
(def (poo-modules interface module-config)
  (let* ((config-values
          ;; Config may be supplied under Marlin's `config` slot or as legacy options.
          (poo-module-object-ref/default
           module-config
           'config
           (poo-module-object-ref/default module-config 'options (.o))))
         (module-id-value
          ;; Missing ids inherit the interface id so sparse configs stay valid.
          (poo-module-object-ref/default
           module-config
           'id
           (poo-module-interface-id interface)))
         (module-imports
          (poo-module-object-ref/default module-config 'imports '()))
         (module-extensions
          (poo-module-object-ref/default module-config 'extensions '()))
         (module-scripts
          (poo-module-object-ref/default module-config 'scripts '()))
         (module-metadata
          (poo-module-object-ref/default
           module-config
           'metadata
           (poo-module-interface-metadata interface)))
         (module-source-ref
          (poo-module-object-ref/default module-config 'source-ref #f))
         (module-group
          (poo-module-object-ref/default module-config 'group 'poo))
         (module-flags
          (poo-module-object-ref/default module-config 'flags '()))
         (module-features
          (poo-module-object-ref/default module-config 'features '()))
         (module-depth
          (poo-module-object-ref/default module-config 'depth (cons 0 0)))
         (module-phase-files
          (poo-module-object->alist
           (poo-module-object-ref/default module-config 'phase-files '())))
         (module-hooks
          (poo-module-object->alist
           (poo-module-object-ref/default module-config 'hooks '()))))
    (make-poo-module-descriptor/full
     module-id-value
     module-imports
     (make-task-family-registry module-id-value '())
     (make-flow-declaration-registry module-id-value '())
     (poo-module-object->alist config-values)
     interface
     (poo-module-interface-schemas interface)
     config-values
     module-extensions
     module-scripts
     module-metadata
     module-source-ref
     module-group
     module-flags
     module-features
     module-depth
     module-phase-files
     module-hooks)))

;; PooModuleDescriptor <- PooModuleInterface POOObject
(def (pooModules interface module-config)
  (poo-modules interface module-config))

;; Boolean <- ModuleDescriptorCandidate
(def (poo-module-config? value)
  (poo-module-descriptor? value))

;;; Boundary: macro syntax is constructor sugar around descriptor values.
;;; No loader, source resolver, or registry lookup runs during expansion.
;;; Hygiene: the macro expands to =pooModules= with caller-provided interface/config values.
;;; Edit guard: changes must preserve the generated POO object shape used by facade tests.
;;; The macro forwards user syntax into data constructors and does not inspect source paths.
;;; Its generated object must keep id/imports/config/extensions/scripts/metadata slots.
;;; Runtime-source witnesses are the descriptor values asserted by facade tests.
;;; Editing the transformer must preserve caller hygiene and avoid phase-specific state.
;; Syntax <- DefPooModuleSyntax
(defrules defpoo-module ()
  ((_ binding
      interface
      (id module-id)
      (imports import-value ...)
      (config config-object)
      (extensions extension-value ...)
      (scripts script-value ...)
      (metadata metadata-value))
   (def binding
     (pooModules
      interface
      (.o id: module-id
          imports: (poo-imports import-value ...)
          config: config-object
          extensions: (poo-extensions extension-value ...)
          scripts: (list script-value ...)
          metadata: metadata-value))))
  ((_ binding
      interface
      (id module-id)
      (imports import-value ...)
      (config config-object)
      (extensions extension-value ...)
      (scripts script-value ...))
   (def binding
     (pooModules
      interface
      (.o id: module-id
          imports: (poo-imports import-value ...)
          config: config-object
          extensions: (poo-extensions extension-value ...)
          scripts: (list script-value ...)
          metadata: (poo-module-interface-metadata interface))))))

;;; Boundary: legacy descriptor macro remains registry-oriented and data-only.
;; PooModuleDescriptorExpansion <- PooModuleSyntax
(defrules poo-module (imports tasks flows options)
  ((_ module-name
      (imports import ...)
      (tasks task-descriptor ...)
      (flows flow-descriptor ...)
      (options option ...))
   (make-poo-module-descriptor
    'module-name
    '(import ...)
    (make-task-family-registry 'module-name (list task-descriptor ...))
    (make-flow-declaration-registry 'module-name (list flow-descriptor ...))
    (list option ...))))

;;; Boundary: descriptor predicate is slot-based to allow future C3 variants.
;; Boolean <- PooModuleDescriptorCandidate
(def (poo-module-descriptor? descriptor)
  (and (object? descriptor)
       (eq? (.@ descriptor kind) 'poo-module)))

;;; Boundary: accessors expose descriptor slots without reinterpreting values.
;; Symbol <- PooModuleDescriptor
(def (poo-module-name descriptor)
  (.@ descriptor name))

;;; Boundary: imports expose raw direct/import-spec values.
;; ModuleImportList <- PooModuleDescriptor
(def (poo-module-imports descriptor)
  (.@ descriptor imports))

;;; Boundary: task registry contribution remains descriptor-local.
;; TaskFamilyRegistry <- PooModuleDescriptor
(def (poo-module-task-registry descriptor)
  (.@ descriptor task-registry))

;;; Boundary: flow registry contribution remains descriptor-local.
;; FlowDeclarationRegistry <- PooModuleDescriptor
(def (poo-module-flow-registry descriptor)
  (.@ descriptor flow-registry))

;;; Boundary: options accessor returns activation-ready alists.
;; ModuleOptionAlist <- PooModuleDescriptor
(def (poo-module-options descriptor)
  (.@ descriptor options))

;;; Boundary: interface object is optional for direct descriptor constructors.
;; MaybePooModuleInterface <- PooModuleDescriptor
(def (poo-module-interface-object descriptor)
  (.@ descriptor interface))

;;; Boundary: schemas are carried from interfaces for projection only.
;; POOObject <- PooModuleDescriptor
(def (poo-module-schemas descriptor)
  (.@ descriptor schemas))

;;; Boundary: config keeps original POO shape for schema validation.
;; POOObject <- PooModuleDescriptor
(def (poo-module-config descriptor)
  (.@ descriptor config))

;;; Boundary: extensions remain uninterpreted module payloads.
;; [Value] <- PooModuleDescriptor
(def (poo-module-extensions descriptor)
  (.@ descriptor extensions))

;;; Boundary: scripts remain uninterpreted module payloads.
;; [Value] <- PooModuleDescriptor
(def (poo-module-scripts descriptor)
  (.@ descriptor scripts))

;;; Boundary: metadata is inspection data and never activation logic.
;; Alist <- PooModuleDescriptor
(def (poo-module-metadata descriptor)
  (.@ descriptor metadata))

;;; Boundary: descriptor source refs are provenance only.
;; MaybePooModuleSourceRef <- PooModuleDescriptor
(def (poo-module-descriptor-source-ref descriptor)
  (.@ descriptor source-ref))

;;; Boundary: group is the stable category part of a Doom-style module key.
;; ModuleGroup <- PooModuleDescriptor
(def (poo-module-group descriptor)
  (.@ descriptor group))

;;; Boundary: flags are user-facing feature switches and never loader commands.
;; [ModuleFlag] <- PooModuleDescriptor
(def (poo-module-flags descriptor)
  (.@ descriptor flags))

;;; Boundary: features are descriptive capabilities for doctor projections.
;; [ModuleFeature] <- PooModuleDescriptor
(def (poo-module-features descriptor)
  (.@ descriptor features))

;;; Boundary: depth is explicit ordering data for phase projections.
;; ModuleDepth <- PooModuleDescriptor
(def (poo-module-depth descriptor)
  (.@ descriptor depth))

;;; Boundary: phase files record Doom-like entry names without loading them.
;; ModulePhaseFiles <- PooModuleDescriptor
(def (poo-module-phase-files descriptor)
  (.@ descriptor phase-files))

;;; Boundary: hooks are data slots that runtime owners may interpret later.
;; ModuleHooks <- PooModuleDescriptor
(def (poo-module-hooks descriptor)
  (.@ descriptor hooks))

;;; Boundary: task descriptors are already normalized inside registries.
;; [TaskFamilyDescriptor] <- PooModuleDescriptor
(def (poo-module-task-descriptors descriptor)
  (task-family-registry-descriptors (poo-module-task-registry descriptor)))

;;; Boundary: flow descriptors are already normalized inside registries.
;; [FlowDeclarationDescriptor] <- PooModuleDescriptor
(def (poo-module-flow-descriptors descriptor)
  (flow-declaration-registry-descriptors (poo-module-flow-registry descriptor)))

;;; Boundary: module name projection preserves activation order.
;; [Symbol] <- [PooModuleDescriptor]
(def (poo-module-names modules)
  (if (null? modules)
    '()
    (cons (poo-module-name (car modules))
          (poo-module-names (cdr modules)))))

;; Boolean <- ModuleName [ModuleName]
(def (poo-module-member-name? value names)
  (cond
   ((null? names) #f)
   ((equal? value (car names)) #t)
   (else
    (poo-module-member-name? value (cdr names)))))

;;; Boundary: import profiles can be descriptor values or closed-world names.
;; ModuleImportProfile <- ModuleImportValue
(def (poo-module-import-profile import-value)
  (if (poo-import? import-value)
    (.ref import-value 'profile)
    import-value))

;; MaybePooModuleDescriptor <- ModuleImportValue
(def (poo-module-import-config import-value)
  (let (profile (poo-module-import-profile import-value))
    (if (poo-module-config? profile)
      profile
      #f)))

;; Boolean <- ModuleImportValue
(def (poo-module-named-import? import-value)
  (let (profile (poo-module-import-profile import-value))
    (or (symbol? profile)
        (string? profile))))

;; ModuleName <- ModuleImportValue
(def (poo-module-import-name import-value)
  (let (profile (poo-module-import-profile import-value))
    (if (poo-module-config? profile)
      (poo-module-name profile)
      profile)))

;;; Boundary: import-configs is a filter-map over import profiles.
;;; Invariant: only descriptor profiles enter the closure list.
;;; Runtime imports remain payloads for the later resolver stage.
;;; The lambda sees the result of =poo-module-import-config=, never raw source refs.
;;; Names, paths, and runtime payloads are intentionally dropped from the closure list.
;;; A hand-written loop here could accidentally activate a source-only import.
;;; The higher-order shape makes the keep/drop decision local to one candidate profile.
;; [PooModuleDescriptor] <- [Value]
(def (poo-module-import-configs imports)
  (cond
   ((null? imports) '())
   ((poo-module-import-config (car imports))
    => (lambda (module)
         (cons module
               (poo-module-import-configs (cdr imports)))))
   (else
    (poo-module-import-configs (cdr imports)))))

;;; Boundary: only direct names are missing imports; inline profiles are closure members.
;; [MissingModuleImport] <- Symbol ModuleImportList [Symbol]
(def (poo-module-missing-imports-for-name module-name imports available-names)
  (cond
   ((null? imports) '())
   ((not (poo-module-named-import? (car imports)))
    (poo-module-missing-imports-for-name module-name (cdr imports) available-names))
   ((poo-module-member-name? (poo-module-import-name (car imports)) available-names)
    (poo-module-missing-imports-for-name module-name (cdr imports) available-names))
   (else
    (cons (list (cons 'module module-name)
                (cons 'import (poo-module-import-name (car imports))))
          (poo-module-missing-imports-for-name module-name (cdr imports) available-names)))))

;;; Boundary: inline profiles join activation closure before name validation.
;;; Intent: prefab-style imports behave like concrete module values, not missing names.
;; [PooModuleDescriptor] <- [PooModuleDescriptor] [Value]
(def (poo-module-closure/add modules seen-names)
  (cond
   ((null? modules) '())
   ;; Repeated module names are skipped to keep inline imports finite.
   ((poo-module-member-name? (poo-module-name (car modules)) seen-names)
    (poo-module-closure/add (cdr modules) seen-names))
   (else
    (let* ((module (car modules))
           (next-seen (cons (poo-module-name module) seen-names))
           (inline-modules
            ;; Only import specs carrying descriptor profiles expand the closure.
            (poo-module-import-configs (poo-module-imports module))))
      (cons module
            (append (poo-module-closure/add inline-modules next-seen)
                    (poo-module-closure/add (cdr modules) next-seen)))))))

;;; Boundary: public closure starts with an empty seen set.
;; [PooModuleDescriptor] <- [PooModuleDescriptor]
(def (poo-module-closure modules)
  (poo-module-closure/add modules '()))

;;; Boundary: per-module missing import details preserve module/import pairs.
;; [MissingModuleImport] <- PooModuleDescriptor [Symbol]
(def (poo-module-missing-imports-for descriptor available-names)
  (poo-module-missing-imports-for-name
   (poo-module-name descriptor)
   (poo-module-imports descriptor)
   available-names))

;; [MissingModuleImport] <- [PooModuleDescriptor] [Symbol]
(def (poo-module-missing-imports-from modules available-names)
  (if (null? modules)
    '()
    (append (poo-module-missing-imports-for (car modules) available-names)
            (poo-module-missing-imports-from (cdr modules) available-names))))

;;; Boundary: missing import checks run over the same closure activation uses.
;; [MissingModuleImport] <- [PooModuleDescriptor]
(def (poo-module-missing-imports modules)
  (let (closed-modules (poo-module-closure modules))
    (poo-module-missing-imports-from
     closed-modules
     (poo-module-names closed-modules))))

;;; Boundary: activation may only proceed after closed-world imports validate.
;; Boolean <- [PooModuleDescriptor]
(def (validate-poo-module-imports modules)
  (let ((missing (poo-module-missing-imports modules)))
    (if (null? missing)
      #t
      (raise-control-plane-failure
       'module-system
       'missing-module-imports
       "poo module activation has missing imports"
       (list (cons 'missing missing))))))

;;; Boundary: aggregation is append-only; conflict policy belongs to diagnostics.
;; [TaskFamilyDescriptor] <- [PooModuleDescriptor]
(def (poo-module-all-task-descriptors modules)
  (if (null? modules)
    '()
    (append (poo-module-task-descriptors (car modules))
            (poo-module-all-task-descriptors (cdr modules)))))

;;; Boundary: flow aggregation mirrors task aggregation order.
;; [FlowDeclarationDescriptor] <- [PooModuleDescriptor]
(def (poo-module-all-flow-descriptors modules)
  (if (null? modules)
    '()
    (append (poo-module-flow-descriptors (car modules))
            (poo-module-all-flow-descriptors (cdr modules)))))

;;; Boundary: options stay alists until config/run-config projection.
;; ModuleOptionAlist <- [PooModuleDescriptor]
(def (poo-module-all-options modules)
  (if (null? modules)
    '()
    (append (poo-module-options (car modules))
            (poo-module-all-options (cdr modules)))))
