;;; -*- Gerbil -*-
;;; Boundary: module descriptors and import closure validation.
;;; Invariant: descriptors are POO values and never load module sources.

(import (only-in :clan/poo/object .o .@ .ref object?)
        :poo-flow/src/core/roles
        :poo-flow/src/core/failure
        :poo-flow/src/core/object-syntax
        :poo-flow/src/core/task
        :poo-flow/src/core/flow
        :poo-flow/src/module-system/interface
        :poo-flow/src/module-system/source)

(export poo-flow-module-role
        poo-flow-module-descriptor-prototype
        make-poo-flow-module-descriptor/full
        make-poo-flow-module-descriptor/extended
        make-poo-flow-module-descriptor
        make-empty-poo-flow-module-descriptor
        poo-flow-module
        poo-flow-module-descriptor?
        poo-flow-module-config?
        poo-flow-modules
        pooFlowModules
        defpoo-flow-module
        poo-flow-module-name
        poo-flow-module-imports
        poo-flow-module-task-registry
        poo-flow-module-flow-registry
        poo-flow-module-options
        poo-flow-module-interface-object
        poo-flow-module-schemas
        poo-flow-module-config
        poo-flow-module-extensions
        poo-flow-module-scripts
        poo-flow-module-metadata
        poo-flow-module-descriptor-source-ref
        poo-flow-module-group
        poo-flow-module-flags
        poo-flow-module-features
        poo-flow-module-depth
        poo-flow-module-phase-files
        poo-flow-module-hooks
        poo-flow-module-task-descriptors
        poo-flow-module-flow-descriptors
        poo-flow-module-names
        poo-flow-module-import-profile
        poo-flow-module-import-config
        poo-flow-module-import-configs
        poo-flow-module-closure
        poo-flow-module-all-task-descriptors
        poo-flow-module-all-flow-descriptors
        poo-flow-module-all-options
        poo-flow-module-missing-imports
        validate-poo-flow-module-imports)

;;; Boundary: role data anchors module descriptors in the control-plane C3 set.
;; : (-> Unit Role)
(def poo-flow-module-role
  (.o (:: @ control-plane-role)
      (name 'poo-flow-module)
      (kind 'module)
      (brand-name poo-flow-brand-name)
      (responsibility 'descriptor-bundle)
      (scheme-owner 'gerbil)
      (runtime-owner 'marlin-agent-core)
      (module-capability 'poo-flow-descriptor-activation)))

;;; Boundary: descriptor defaults make direct constructors and facade modules compatible.
;;; Intent: every module surface eventually lowers into this stable slot layout.
;; : (-> Unit PooModuleDescriptorPrototype)
(def poo-flow-module-descriptor-prototype
  (poo-core-role-object
   (slots ((kind 'poo-flow-module)
           (module-kind poo-flow-modules-kind)
           (brand-name poo-flow-brand-name)
           (group poo-flow-brand-group)
           (interface #f)
           (imports '())
           (extensions '())
           (scripts '())
           (flags '())
           (features '())
           (depth (cons 0 0))
           (phase-files '())
           (hooks '())
           (task-registry
            (make-task-family-registry 'empty-module-task-families '()))
           (flow-registry
            (make-flow-declaration-registry 'empty-module-flow-declarations '()))
           (options '())
           (config (.o))
           (schemas (.o))
           (metadata '())
           (source-ref #f)
           (extension-policy 'poo-flow-module-descriptor)))
   (supers poo-flow-module-role)))

;;; Boundary: full constructor is the single descriptor slot authority.
;;; Intent: all public constructors must pass through one slot assembly point.
;;; Doom influence stays explicit in slots instead of hidden loader context.
;; : (-> ModuleName ModuleImportList TaskFamilyRegistry FlowDeclarationRegistry ModuleOptionAlist MaybeInterface ModuleSchemas ModuleConfig [ModuleExtension] [ModuleScript] ModuleMetadata MaybeSourceRef ModuleGroup [ModuleFlag] [ModuleFeature] ModuleDepth ModulePhaseFiles ModuleHooks PooModuleDescriptor)
(def (make-poo-flow-module-descriptor/full
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
  (poo-core-role-object
   (slots ((name module-name)
           (module-kind poo-flow-modules-kind)
           (group group)
           (interface interface)
           (imports module-imports)
           (extensions extensions)
           (scripts scripts)
           (flags flags)
           (features features)
           (depth depth)
           (phase-files phase-files)
           (hooks hooks)
           (task-registry task-registry)
           (flow-registry flow-registry)
           (options options)
           (config config)
           (schemas schemas)
           (metadata metadata)
           (source-ref source-ref)
           (responsibility
            (list 'poo-flow-module module-name))))
   (supers poo-flow-module-descriptor-prototype)))

;;; Boundary: extended constructor keeps Marlin migration call sites stable.
;; : (-> ModuleName ModuleImportList TaskFamilyRegistry FlowDeclarationRegistry ModuleOptionAlist MaybeInterface ModuleSchemas ModuleConfig [ModuleExtension] [ModuleScript] ModuleMetadata MaybeSourceRef PooModuleDescriptor)
(def (make-poo-flow-module-descriptor/extended
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
  (make-poo-flow-module-descriptor/full
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
   poo-flow-brand-group
   '()
   '()
   (cons 0 0)
   '()
   '()))

;;; Sparse constructors keep older tests and module rows from repeating the
;;; empty interface/schema/script defaults owned by the extended constructor.
;; : (-> ModuleName ModuleImportList TaskFamilyRegistry FlowDeclarationRegistry ModuleOptionAlist PooModuleDescriptor)
(def (make-poo-flow-module-descriptor module-name module-imports task-registry flow-registry options)
  (make-poo-flow-module-descriptor/extended
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

;; : (-> ModuleName ModuleImportList ModuleOptionAlist PooModuleDescriptor)
(def (make-empty-poo-flow-module-descriptor module-name module-imports options)
  (make-poo-flow-module-descriptor
   module-name
   module-imports
   (make-task-family-registry module-name '())
   (make-flow-declaration-registry module-name '())
   options))

;;; Boundary: Marlin-style facade lowers sparse user config into a POO descriptor.
;;; Intent: preserve Marlin's interface/config split without importing its runtime.
;; : (-> PooModuleInterface POOObject PooModuleDescriptor)
(def (poo-flow-modules interface module-config)
  (let* ((config-values
          ;; Config may be supplied under Marlin's `config` slot or as option data.
          (poo-flow-module-object-ref/default
           module-config
           'config
           (poo-flow-module-object-ref/default module-config 'options (.o))))
         (module-id-value
          ;; Missing ids inherit the interface id so sparse configs stay valid.
          (poo-flow-module-object-ref/default
           module-config
           'id
           (poo-flow-module-interface-id interface)))
         (module-imports
          (poo-flow-module-object-ref/default module-config 'imports '()))
         (module-extensions
          (poo-flow-module-object-ref/default module-config 'extensions '()))
         (module-scripts
          (poo-flow-module-object-ref/default module-config 'scripts '()))
         (module-metadata
          (poo-flow-module-object-ref/default
           module-config
           'metadata
           (poo-flow-module-interface-metadata interface)))
         (module-source-ref
          (poo-flow-module-object-ref/default module-config 'source-ref #f))
         (module-group
          (poo-flow-module-object-ref/default
           module-config
           'group
           poo-flow-brand-group))
         (module-flags
          (poo-flow-module-object-ref/default module-config 'flags '()))
         (module-features
          (poo-flow-module-object-ref/default module-config 'features '()))
         (module-depth
          (poo-flow-module-object-ref/default module-config 'depth (cons 0 0)))
         (module-phase-files
          (poo-flow-module-object->alist
           (poo-flow-module-object-ref/default module-config 'phase-files '())))
         (module-hooks
          (poo-flow-module-object->alist
           (poo-flow-module-object-ref/default module-config 'hooks '()))))
    (make-poo-flow-module-descriptor/full
     module-id-value
     module-imports
     (make-task-family-registry module-id-value '())
     (make-flow-declaration-registry module-id-value '())
     (poo-flow-module-object->alist config-values)
     interface
     (poo-flow-module-interface-schemas interface)
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

;; : (-> PooModuleInterface POOObject PooModuleDescriptor)
(def (pooFlowModules interface module-config)
  (poo-flow-modules interface module-config))

;; : (-> ModuleDescriptorCandidate Boolean)
(def (poo-flow-module-config? value)
  (poo-flow-module-descriptor? value))

;;; Boundary:
;;; - defpoo-flow-module is constructor sugar around POO descriptor values.
;;; - Expansion must not load files, query registries, or capture phase state.
;;; - The generated descriptor slots remain the facade-test source witnesses.
;; | type DefPooModuleBinding = Symbol
;; | type DefPooModuleClause = MacroClause
;; defpoo-flow-module
;;   : (-> DefPooModuleBinding PooModuleInterface DefPooModuleClause... PooModuleDescriptor)
;;   | contract: expands a named interface/config declaration to a POO descriptor
;;   | warning: expansion forwards syntax into constructors and stays activation-free
;;   | doc m%
;;       `defpoo-flow-module` defines `binding` as the descriptor built from an
;;       interface and a literal module configuration shape.
;;       # Examples
;;       ```scheme
;;       (defpoo-flow-module demo iface (id 'demo) (imports) (config (.o)) (extensions) (scripts))
;;       ;; => demo
;;       ```
;;     %
(defrules defpoo-flow-module ()
  ((_ binding
      interface
      (id module-id)
      (imports import-value ...)
      (config config-object)
      (extensions extension-value ...)
      (scripts script-value ...)
      (metadata metadata-value))
   (def binding
     (pooFlowModules
      interface
      (.o id: module-id
          imports: (poo-flow-imports import-value ...)
          config: config-object
          extensions: (poo-flow-extensions extension-value ...)
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
     (pooFlowModules
      interface
      (.o id: module-id
          imports: (poo-flow-imports import-value ...)
          config: config-object
          extensions: (poo-flow-extensions extension-value ...)
          scripts: (list script-value ...)
          metadata: (poo-flow-module-interface-metadata interface))))))

;;; Boundary:
;;; - poo-flow-module preserves the registry-oriented descriptor constructor surface.
;;; - The macro lowers clauses to one descriptor and never activates a module.
;;; - Registry inputs stay data so the loader/resolver boundary remains outside.
;; | type PooModuleImportClause = (Tuple 'imports ModuleImportValue...)
;; | type PooModuleTaskClause = (Tuple 'tasks TaskFamilyDescriptor...)
;; | type PooModuleFlowClause = (Tuple 'flows FlowDeclarationDescriptor...)
;; | type PooModuleOptionClause = (Tuple 'options ModuleOption...)
;; poo-flow-module
;;   : (-> ModuleName PooModuleImportClause PooModuleTaskClause PooModuleFlowClause PooModuleOptionClause PooModuleDescriptor)
;;   | contract: expands task and flow registry clauses to one descriptor value
;;   | warning: expansion is constructor sugar only and must stay activation-free
;;   | doc m%
;;       `poo-flow-module` returns a descriptor for `module-name` from explicit
;;       import, task, flow, and option clauses.
;;       # Examples
;;       ```scheme
;;       (poo-flow-module demo (imports) (tasks task-descriptor) (flows flow-descriptor) (options))
;;       ;; => PooModuleDescriptor
;;       ```
;;     %
(defrules poo-flow-module (imports tasks flows options)
  ((_ module-name
      (imports import ...)
      (tasks task-descriptor ...)
      (flows flow-descriptor ...)
      (options option ...))
   (make-poo-flow-module-descriptor
    'module-name
    '(import ...)
    (make-task-family-registry 'module-name (list task-descriptor ...))
    (make-flow-declaration-registry 'module-name (list flow-descriptor ...))
    (list option ...))))

;;; Boundary: descriptor predicate is slot-based to allow future C3 variants.
;; : (-> PooModuleDescriptorCandidate Boolean)
(def (poo-flow-module-descriptor? descriptor)
  (and (object? descriptor)
       (eq? (.@ descriptor kind) 'poo-flow-module)))

;;; Boundary: accessors expose descriptor slots without reinterpreting values.
;; : (-> PooModuleDescriptor Symbol)
(def (poo-flow-module-name descriptor)
  (.@ descriptor name))

;;; Boundary: imports expose raw direct/import-spec values.
;; : (-> PooModuleDescriptor ModuleImportList)
(def (poo-flow-module-imports descriptor)
  (.@ descriptor imports))

;;; Boundary: task registry contribution remains descriptor-local.
;; : (-> PooModuleDescriptor TaskFamilyRegistry)
(def (poo-flow-module-task-registry descriptor)
  (.@ descriptor task-registry))

;;; Boundary: flow registry contribution remains descriptor-local.
;; : (-> PooModuleDescriptor FlowDeclarationRegistry)
(def (poo-flow-module-flow-registry descriptor)
  (.@ descriptor flow-registry))

;;; Boundary: options accessor returns the activation-edge option projection.
;; : (-> PooModuleDescriptor ModuleOptionAlist)
(def (poo-flow-module-options descriptor)
  (.@ descriptor options))

;;; Boundary: interface object is optional for direct descriptor constructors.
;; : (-> PooModuleDescriptor MaybePooModuleInterface)
(def (poo-flow-module-interface-object descriptor)
  (.@ descriptor interface))

;;; Boundary: schemas are carried from interfaces for projection only.
;; : (-> PooModuleDescriptor POOObject)
(def (poo-flow-module-schemas descriptor)
  (.@ descriptor schemas))

;;; Boundary: config keeps original POO shape for schema validation.
;; : (-> PooModuleDescriptor POOObject)
(def (poo-flow-module-config descriptor)
  (.@ descriptor config))

;;; Boundary: extensions remain uninterpreted module payloads.
;; : (-> PooModuleDescriptor [Value])
(def (poo-flow-module-extensions descriptor)
  (.@ descriptor extensions))

;;; Boundary: scripts remain uninterpreted module payloads.
;; : (-> PooModuleDescriptor [Value])
(def (poo-flow-module-scripts descriptor)
  (.@ descriptor scripts))

;;; Boundary: metadata is inspection data and never activation logic.
;; : (-> PooModuleDescriptor Alist)
(def (poo-flow-module-metadata descriptor)
  (.@ descriptor metadata))

;;; Boundary: descriptor source refs are provenance only.
;; : (-> PooModuleDescriptor MaybePooModuleSourceRef)
(def (poo-flow-module-descriptor-source-ref descriptor)
  (.@ descriptor source-ref))

;;; Boundary: group is the stable category part of a Doom-style module key.
;; : (-> PooModuleDescriptor ModuleGroup)
(def (poo-flow-module-group descriptor)
  (.@ descriptor group))

;;; Boundary: flags are user-facing feature switches and never loader commands.
;; : (-> PooModuleDescriptor [ModuleFlag])
(def (poo-flow-module-flags descriptor)
  (.@ descriptor flags))

;;; Boundary: features are descriptive capabilities for doctor projections.
;; : (-> PooModuleDescriptor [ModuleFeature])
(def (poo-flow-module-features descriptor)
  (.@ descriptor features))

;;; Boundary: depth is explicit ordering data for phase projections.
;; : (-> PooModuleDescriptor ModuleDepth)
(def (poo-flow-module-depth descriptor)
  (.@ descriptor depth))

;;; Boundary: phase files record Doom-like entry names without loading them.
;; : (-> PooModuleDescriptor ModulePhaseFiles)
(def (poo-flow-module-phase-files descriptor)
  (.@ descriptor phase-files))

;;; Boundary: hooks are projected POO slot contributions for runtime owners.
;; : (-> PooModuleDescriptor ModuleHooks)
(def (poo-flow-module-hooks descriptor)
  (.@ descriptor hooks))

;;; Boundary: task descriptors are already normalized inside registries.
;; : (-> PooModuleDescriptor [TaskFamilyDescriptor])
(def (poo-flow-module-task-descriptors descriptor)
  (task-family-registry-descriptors (poo-flow-module-task-registry descriptor)))

;;; Boundary: flow descriptors are already normalized inside registries.
;; : (-> PooModuleDescriptor [FlowDeclarationDescriptor])
(def (poo-flow-module-flow-descriptors descriptor)
  (flow-declaration-registry-descriptors (poo-flow-module-flow-registry descriptor)))

;;; Boundary: module name projection preserves activation order.
;; : (-> [PooModuleDescriptor] [Symbol])
(def (poo-flow-module-names modules)
  (if (null? modules)
    '()
    (cons (poo-flow-module-name (car modules))
          (poo-flow-module-names (cdr modules)))))

;;; Boundary: module member name predicate is the policy-visible edge for
;;; module-system behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> ModuleName [ModuleName] Boolean)
(def (poo-flow-module-member-name? value names)
  (cond
   ((null? names) #f)
   ((equal? value (car names)) #t)
   (else
    (poo-flow-module-member-name? value (cdr names)))))

;;; Boundary: import profiles can be descriptor values or closed-world names.
;; : (-> ModuleImportValue ModuleImportProfile)
(def (poo-flow-module-import-profile import-value)
  (if (poo-flow-import? import-value)
    (.ref import-value 'profile)
    import-value))

;;; Boundary: module import config is the policy-visible edge for module-system
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> ModuleImportValue MaybePooModuleDescriptor)
(def (poo-flow-module-import-config import-value)
  (let (profile (poo-flow-module-import-profile import-value))
    (if (poo-flow-module-config? profile)
      profile
      #f)))

;; : (-> ModuleImportValue Boolean)
(def (poo-flow-module-named-import? import-value)
  (let (profile (poo-flow-module-import-profile import-value))
    (or (symbol? profile)
        (string? profile))))

;;; Boundary: module import name is the policy-visible edge for module-system
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> ModuleImportValue ModuleName)
(def (poo-flow-module-import-name import-value)
  (let (profile (poo-flow-module-import-profile import-value))
    (if (poo-flow-module-config? profile)
      (poo-flow-module-name profile)
      profile)))

;;; Boundary: import-configs keeps only descriptor profiles from import rows.
;;; Invariant: only descriptor profiles enter the closure list.
;;; Runtime imports remain payloads for the later resolver stage.
;;; Names, paths, and runtime payloads are intentionally dropped from the closure list.
;; : (-> [Value] [PooModuleDescriptor] [PooModuleDescriptor])
(def (poo-flow-module-import-configs/rev imports configs-rev)
  (cond
   ((null? imports) configs-rev)
   ((poo-flow-module-import-config (car imports))
    => (lambda (module)
         (poo-flow-module-import-configs/rev
          (cdr imports)
          (cons module configs-rev))))
   (else
    (poo-flow-module-import-configs/rev (cdr imports) configs-rev))))

;; : (-> [Value] [PooModuleDescriptor])
(def (poo-flow-module-import-configs imports)
  (reverse (poo-flow-module-import-configs/rev imports '())))

;;; Boundary: only direct names are missing imports; inline profiles are closure members.
;;; Boundary: module missing imports for name is the policy-visible edge for
;;; module-system behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> Symbol ModuleImportList [Symbol] [MissingModuleImport])
(def (poo-flow-module-missing-imports-for-name module-name imports available-names)
  (cond
   ((null? imports) '())
   ((not (poo-flow-module-named-import? (car imports)))
    (poo-flow-module-missing-imports-for-name module-name (cdr imports) available-names))
   ((poo-flow-module-member-name? (poo-flow-module-import-name (car imports)) available-names)
    (poo-flow-module-missing-imports-for-name module-name (cdr imports) available-names))
   (else
    (cons (list (cons 'module module-name)
                (cons 'import (poo-flow-module-import-name (car imports))))
          (poo-flow-module-missing-imports-for-name module-name (cdr imports) available-names)))))

;;; Boundary: inline profiles join activation closure before name validation.
;;; Intent: prefab-style imports behave like concrete module values, not missing names.
;; : (-> [PooModuleDescriptor] [Value] [PooModuleDescriptor])
(def (poo-flow-module-closure/add modules seen-names)
  (cond
   ((null? modules) '())
   ;; Repeated module names are skipped to keep inline imports finite.
   ((poo-flow-module-member-name? (poo-flow-module-name (car modules)) seen-names)
    (poo-flow-module-closure/add (cdr modules) seen-names))
   (else
    (let* ((module (car modules))
           (next-seen (cons (poo-flow-module-name module) seen-names))
           (inline-modules
            ;; Only import specs carrying descriptor profiles expand the closure.
            (poo-flow-module-import-configs (poo-flow-module-imports module))))
      (cons module
            (append (poo-flow-module-closure/add inline-modules next-seen)
                    (poo-flow-module-closure/add (cdr modules) next-seen)))))))

;;; Boundary: public closure starts with an empty seen set.
;; : (-> [PooModuleDescriptor] [PooModuleDescriptor])
(def (poo-flow-module-closure modules)
  (poo-flow-module-closure/add modules '()))

;;; Boundary: per-module missing import details preserve module/import pairs.
;; : (-> PooModuleDescriptor [Symbol] [MissingModuleImport])
(def (poo-flow-module-missing-imports-for descriptor available-names)
  (poo-flow-module-missing-imports-for-name
   (poo-flow-module-name descriptor)
   (poo-flow-module-imports descriptor)
   available-names))

;;; Boundary: module missing imports from is the policy-visible edge for
;;; module-system behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> [PooModuleDescriptor] [Symbol] [MissingModuleImport])
(def (poo-flow-module-missing-imports-from modules available-names)
  (if (null? modules)
    '()
    (append (poo-flow-module-missing-imports-for (car modules) available-names)
            (poo-flow-module-missing-imports-from (cdr modules) available-names))))

;;; Boundary: missing import checks run over the same closure activation uses.
;; : (-> [PooModuleDescriptor] [MissingModuleImport])
(def (poo-flow-module-missing-imports modules)
  (let (closed-modules (poo-flow-module-closure modules))
    (poo-flow-module-missing-imports-from
     closed-modules
     (poo-flow-module-names closed-modules))))

;;; Boundary: activation may only proceed after closed-world imports validate.
;; : (-> [PooModuleDescriptor] Boolean)
(def (validate-poo-flow-module-imports modules)
  (let ((missing (poo-flow-module-missing-imports modules)))
    (if (null? missing)
      #t
      (raise-control-plane-failure
       'module-system
       'missing-module-imports
       "poo-flow module activation has missing imports"
       (list (cons 'missing missing))))))

;;; Boundary: aggregation is append-only; conflict policy belongs to diagnostics.
;;; Boundary: module all task descriptors is the policy-visible edge for
;;; module-system behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> [PooModuleDescriptor] [TaskFamilyDescriptor])
(def (poo-flow-module-all-task-descriptors modules)
  (if (null? modules)
    '()
    (append (poo-flow-module-task-descriptors (car modules))
            (poo-flow-module-all-task-descriptors (cdr modules)))))

;;; Boundary: flow aggregation mirrors task aggregation order.
;; : (-> [PooModuleDescriptor] [FlowDeclarationDescriptor])
(def (poo-flow-module-all-flow-descriptors modules)
  (if (null? modules)
    '()
    (append (poo-flow-module-flow-descriptors (car modules))
            (poo-flow-module-all-flow-descriptors (cdr modules)))))

;;; Boundary: option projections stay at the config/run-config edge.
;; : (-> [PooModuleDescriptor] ModuleOptionAlist)
(def (poo-flow-module-all-options modules)
  (if (null? modules)
    '()
    (append (poo-flow-module-options (car modules))
            (poo-flow-module-all-options (cdr modules)))))
