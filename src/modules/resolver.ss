;;; -*- Gerbil -*-
;;; Boundary: module catalog resolution and activation lowering.
;;; Invariant: resolver matches existing catalog values by source ref.
;;; It never evaluates, imports, or opens the source ref payload.
;;; Intent: agents can trust resolver receipts as replayable evidence of selection order.
;;; Ownership: this file owns catalog-source lookup, activation snapshots, and run-config lowering.
;;; Catalog lookup compares source refs that were built by src/modules/source.ss.
;;; Activation receives descriptors that were already constructed by descriptor owners.
;;; The resolver may report missing sources, but it must not try to load them.
;;; Run-config lowering is the only place this owner touches core config values.
;;; Parser policy should treat this file as the resolver/activation owner.

(import :core/failure
        :core/task
        :core/flow
        :core/config
        :modules/source
        :modules/descriptor
        :modules/diagnostics)

(export make-poo-module-catalog-entry
        poo-module-catalog-entry?
        poo-module-catalog-entry-source
        poo-module-catalog-entry-module
        poo-module-catalog-entry->alist
        make-poo-module-catalog
        poo-module-catalog?
        poo-module-catalog-name
        poo-module-catalog-entries
        poo-module-catalog-source-refs
        poo-module-catalog-modules
        poo-module-catalog-add
        poo-module-catalog-find-source
        resolve-poo-module-source
        resolve-poo-module-sources
        resolve-poo-module-source/default
        poo-module-catalog->alist
        poo-module-resolve-doctor
        poo-module-resolve-and-activate
        poo-module-resolve-and-activate-with-base
        make-poo-module-activation
        poo-module-activation?
        poo-module-activation-modules
        poo-module-activation-task-registry
        poo-module-activation-flow-registry
        poo-module-activation-options
        activate-poo-modules
        activate-poo-modules-with-base
        poo-module-activation->run-config)

;;; Boundary: catalog entries bind already-built descriptors to source metadata.
;; PooModuleCatalogEntry <- PooModuleSourceRef PooModuleDescriptor
(defstruct poo-module-catalog-entry
  (source
   module)
  transparent: #t)

;;; Boundary: catalog entry projection preserves source/module association.
;; Alist <- PooModuleCatalogEntry
(def (poo-module-catalog-entry->alist entry)
  (list (cons 'source
              (poo-module-source-ref->alist
               (poo-module-catalog-entry-source entry)))
        (cons 'module
              (poo-module-name (poo-module-catalog-entry-module entry)))))

;;; Boundary: catalogs are immutable resolver indexes, not loaders.
;; PooModuleCatalog <- Symbol [PooModuleCatalogEntry]
(defstruct poo-module-catalog
  (name
   entries)
  transparent: #t)

;;; Boundary: source ref listing is for inspection, not resolution side effects.
;; [PooModuleSourceRef] <- PooModuleCatalog
(def (poo-module-catalog-source-refs catalog)
  (map poo-module-catalog-entry-source
       (poo-module-catalog-entries catalog)))

;;; Boundary: module listing keeps catalog lookup separate from activation.
;; [PooModuleDescriptor] <- PooModuleCatalog
(def (poo-module-catalog-modules catalog)
  (map poo-module-catalog-entry-module
       (poo-module-catalog-entries catalog)))

;;; Boundary: catalog add returns a new catalog and preserves insertion order.
;; PooModuleCatalog <- PooModuleCatalog PooModuleCatalogEntry
(def (poo-module-catalog-add catalog entry)
  (make-poo-module-catalog
   (poo-module-catalog-name catalog)
   (append (poo-module-catalog-entries catalog)
           (list entry))))

;;; Boundary: source matching is pure first-match lookup over normalized refs.
;;; Intent: resolver evidence should be replayable and independent from filesystem state.
;; MaybePooModuleCatalogEntry <- [PooModuleCatalogEntry] PooModuleSourceRef
(def (poo-module-catalog-find-source-in entries source-ref)
  (cond
   ((null? entries) #f)
   ((poo-module-source-ref=? (poo-module-catalog-entry-source (car entries))
                             source-ref)
    (car entries))
   (else
    (poo-module-catalog-find-source-in (cdr entries) source-ref))))

;;; Boundary: public catalog find delegates to pure entry lookup.
;; MaybePooModuleCatalogEntry <- PooModuleCatalog PooModuleSourceRef
(def (poo-module-catalog-find-source catalog source-ref)
  (poo-module-catalog-find-source-in
   (poo-module-catalog-entries catalog)
   source-ref))

;;; Boundary: default resolver is the non-throwing catalog lookup surface.
;; MaybePooModuleDescriptor <- PooModuleCatalog PooModuleSourceRef DefaultDescriptor
(def (resolve-poo-module-source/default catalog source-ref default)
  (let (entry (poo-module-catalog-find-source catalog source-ref))
    (if entry
      (poo-module-catalog-entry-module entry)
      default)))

;;; Boundary: missing catalog source is a typed config failure, not a loader miss.
;; PooModuleDescriptor <- PooModuleCatalog PooModuleSourceRef
(def (resolve-poo-module-source catalog source-ref)
  (let (module (resolve-poo-module-source/default catalog source-ref #f))
    (if module
      module
      (raise-control-plane-failure
       'module-system
       'missing-module-source
       "poo module source was not found in catalog"
       (list (cons 'catalog (poo-module-catalog-name catalog))
             (cons 'source (poo-module-source-ref->alist source-ref)))))))

;;; Boundary: multi-source resolution preserves requested source order.
;; [PooModuleDescriptor] <- PooModuleCatalog [PooModuleSourceRef]
(def (resolve-poo-module-sources catalog source-refs)
  (if (null? source-refs)
    '()
    (cons (resolve-poo-module-source catalog (car source-refs))
          (resolve-poo-module-sources catalog (cdr source-refs)))))

;;; Boundary: catalog alist projection is an inspection surface only.
;; Alist <- PooModuleCatalog
(def (poo-module-catalog->alist catalog)
  (list (cons 'name (poo-module-catalog-name catalog))
        (cons 'entries
              (map poo-module-catalog-entry->alist
                   (poo-module-catalog-entries catalog)))))

;;; Boundary: resolve-doctor inspects selected sources without activation.
;;; Boundary: resolve-doctor validates source selection before activation.
;; PooModuleDoctorReport <- PooModuleCatalog [PooModuleSourceRef]
(def (poo-module-resolve-doctor catalog source-refs)
  (poo-module-doctor
   (resolve-poo-module-sources catalog source-refs)))

;;; Boundary: base activation allows callers to preserve existing registries.
;; PooModuleActivation <- PooModuleCatalog [PooModuleSourceRef] TaskFamilyRegistry FlowDeclarationRegistry ModuleOptionAlist
(def (poo-module-resolve-and-activate-with-base catalog source-refs base-task-registry base-flow-registry base-options)
  (activate-poo-modules-with-base
   (resolve-poo-module-sources catalog source-refs)
   base-task-registry
   base-flow-registry
   base-options))

;;; Boundary: source-selected activation uses the same activation path as direct modules.
;; PooModuleActivation <- PooModuleCatalog [PooModuleSourceRef]
(def (poo-module-resolve-and-activate catalog source-refs)
  (activate-poo-modules
   (resolve-poo-module-sources catalog source-refs)))

;;; Boundary: activation appends descriptor contributions without mutation.
;; PooModuleActivation <- [PooModuleDescriptor] TaskFamilyRegistry FlowDeclarationRegistry ModuleOptionAlist
(defstruct poo-module-activation
  (modules
   task-registry
   flow-registry
   options)
  transparent: #t)

;;; Boundary: activation validates closure then appends base-first registries.
;;; Intent: runtime-visible registries are deterministic snapshots of module data.
;; PooModuleActivation <- [PooModuleDescriptor] TaskFamilyRegistry FlowDeclarationRegistry ModuleOptionAlist
(def (activate-poo-modules-with-base modules base-task-registry base-flow-registry base-options)
  (let (closed-modules (poo-module-closure modules))
    ;; Import validation must see the same closure that registry aggregation uses.
    (validate-poo-module-imports closed-modules)
    (make-poo-module-activation
     closed-modules
     (make-task-family-registry
      (task-family-registry-name base-task-registry)
      ;; Base descriptors stay first so existing lookup behavior is preserved.
      (append (task-family-registry-descriptors base-task-registry)
              (poo-module-all-task-descriptors closed-modules)))
     (make-flow-declaration-registry
      (flow-declaration-registry-name base-flow-registry)
      (append (flow-declaration-registry-descriptors base-flow-registry)
              (poo-module-all-flow-descriptors closed-modules)))
     (append base-options
             (poo-module-all-options closed-modules)
             (list (cons 'poo-modules (poo-module-names closed-modules)))))))

;;; Boundary: default activation uses project default task and flow registries.
;; PooModuleActivation <- [PooModuleDescriptor]
(def (activate-poo-modules modules)
  (activate-poo-modules-with-base
   modules
   default-task-family-registry
   default-flow-declaration-registry
   '()))

;;; Boundary: run-config lowering keeps modules outside runner internals.
;; RunConfig <- Symbol Strategy RuntimeAdapter PooModuleActivation
(def (poo-module-activation->run-config name strategy adapter activation)
  (make-run-config name
                   strategy
                   adapter
                   (poo-module-activation-options activation)
                   (poo-module-activation-task-registry activation)
                   (poo-module-activation-flow-registry activation)))
