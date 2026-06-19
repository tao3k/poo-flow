;;; -*- Gerbil -*-
;;; Boundary: module catalog resolution and activation lowering.
;;; Invariant: resolver matches existing catalog values by source ref.
;;; It never evaluates, imports, or opens the source ref payload.
;;; Intent: agents can trust resolver receipts as replayable evidence of selection order.
;;; Ownership: this file owns catalog-source lookup, activation snapshots, and run-config lowering.
;;; Catalog lookup compares source refs that were built by modules/source.ss.
;;; Activation receives descriptors that were already constructed by descriptor owners.
;;; The resolver may report missing sources, but it must not try to load them.
;;; Run-config lowering is the only place this owner touches core config values.
;;; Parser policy should treat this file as the resolver/activation owner.

(import :poo-flow/src/core/failure
        :poo-flow/src/core/task
        :poo-flow/src/core/flow
        :poo-flow/src/core/config
        :poo-flow/src/modules/source
        :poo-flow/src/modules/descriptor
        :poo-flow/src/modules/diagnostics)

(export make-poo-flow-module-catalog-entry
        poo-flow-module-catalog-entry?
        poo-flow-module-catalog-entry-source
        poo-flow-module-catalog-entry-module
        poo-flow-module-catalog-entry->alist
        make-poo-flow-module-catalog
        poo-flow-module-catalog?
        poo-flow-module-catalog-name
        poo-flow-module-catalog-entries
        poo-flow-module-catalog-source-refs
        poo-flow-module-catalog-modules
        poo-flow-module-catalog-add
        poo-flow-module-catalog-find-source
        resolve-poo-flow-module-source
        resolve-poo-flow-module-sources
        resolve-poo-flow-module-source/default
        poo-flow-module-catalog->alist
        poo-flow-module-resolve-doctor
        poo-flow-module-resolve-and-activate
        poo-flow-module-resolve-and-activate-with-base
        make-poo-flow-module-activation
        poo-flow-module-activation?
        poo-flow-module-activation-modules
        poo-flow-module-activation-task-registry
        poo-flow-module-activation-flow-registry
        poo-flow-module-activation-options
        activate-poo-flow-modules
        activate-poo-flow-modules-with-base
        poo-flow-module-activation->run-config)

;;; Boundary: catalog entries bind already-built descriptors to source metadata.
;; : (-> PooModuleSourceRef PooModuleDescriptor PooModuleCatalogEntry)
(defstruct poo-flow-module-catalog-entry
  (source
   module)
  transparent: #t)

;;; Boundary: catalog entry projection preserves source/module association.
;; : (-> PooModuleCatalogEntry Alist)
(def (poo-flow-module-catalog-entry->alist entry)
  (list (cons 'source
              (poo-flow-module-source-ref->alist
               (poo-flow-module-catalog-entry-source entry)))
        (cons 'module
              (poo-flow-module-name
               (poo-flow-module-catalog-entry-module entry)))))

;;; Boundary: catalogs are immutable resolver indexes, not loaders.
;; : (-> Symbol [PooModuleCatalogEntry] PooModuleCatalog)
(defstruct poo-flow-module-catalog
  (name
   entries)
  transparent: #t)

;;; Boundary: source ref listing is for inspection, not resolution side effects.
;; : (-> PooModuleCatalog [PooModuleSourceRef])
(def (poo-flow-module-catalog-source-refs catalog)
  (map poo-flow-module-catalog-entry-source
       (poo-flow-module-catalog-entries catalog)))

;;; Boundary: module listing keeps catalog lookup separate from activation.
;; : (-> PooModuleCatalog [PooModuleDescriptor])
(def (poo-flow-module-catalog-modules catalog)
  (map poo-flow-module-catalog-entry-module
       (poo-flow-module-catalog-entries catalog)))

;;; Boundary: catalog add returns a new catalog and preserves insertion order.
;; : (-> PooModuleCatalog PooModuleCatalogEntry PooModuleCatalog)
(def (poo-flow-module-catalog-add catalog entry)
  (make-poo-flow-module-catalog
   (poo-flow-module-catalog-name catalog)
   (append (poo-flow-module-catalog-entries catalog)
           (list entry))))

;;; Boundary: source matching is pure first-match lookup over normalized refs.
;;; Intent: resolver evidence should be replayable and independent from filesystem state.
;; : (-> [PooModuleCatalogEntry] PooModuleSourceRef MaybePooModuleCatalogEntry)
(def (poo-flow-module-catalog-find-source-in entries source-ref)
  (cond
   ((null? entries) #f)
   ((poo-flow-module-source-ref=?
     (poo-flow-module-catalog-entry-source (car entries))
     source-ref)
    (car entries))
   (else
    (poo-flow-module-catalog-find-source-in (cdr entries) source-ref))))

;;; Boundary: public catalog find delegates to pure entry lookup.
;; : (-> PooModuleCatalog PooModuleSourceRef MaybePooModuleCatalogEntry)
(def (poo-flow-module-catalog-find-source catalog source-ref)
  (poo-flow-module-catalog-find-source-in
   (poo-flow-module-catalog-entries catalog)
   source-ref))

;;; Boundary: default resolver is the non-throwing catalog lookup surface.
;; : (-> PooModuleCatalog PooModuleSourceRef DefaultDescriptor MaybePooModuleDescriptor)
(def (resolve-poo-flow-module-source/default catalog source-ref default)
  (let (entry (poo-flow-module-catalog-find-source catalog source-ref))
    (if entry
      (poo-flow-module-catalog-entry-module entry)
      default)))

;;; Boundary: missing catalog source is a typed config failure, not a loader miss.
;; : (-> PooModuleCatalog PooModuleSourceRef PooModuleDescriptor)
(def (resolve-poo-flow-module-source catalog source-ref)
  (let (module (resolve-poo-flow-module-source/default catalog source-ref #f))
    (if module
      module
      (raise-control-plane-failure
       'module-system
       'missing-module-source
       "poo-flow module source was not found in catalog"
       (list (cons 'catalog (poo-flow-module-catalog-name catalog))
             (cons 'source (poo-flow-module-source-ref->alist source-ref)))))))

;;; Boundary: multi-source resolution preserves requested source order.
;; : (-> PooModuleCatalog [PooModuleSourceRef] [PooModuleDescriptor])
(def (resolve-poo-flow-module-sources catalog source-refs)
  (if (null? source-refs)
    '()
    (cons (resolve-poo-flow-module-source catalog (car source-refs))
          (resolve-poo-flow-module-sources catalog (cdr source-refs)))))

;;; Boundary: catalog alist projection is an inspection surface only.
;; : (-> PooModuleCatalog Alist)
(def (poo-flow-module-catalog->alist catalog)
  (list (cons 'name (poo-flow-module-catalog-name catalog))
        (cons 'entries
              (map poo-flow-module-catalog-entry->alist
                   (poo-flow-module-catalog-entries catalog)))))

;;; Boundary: resolve-doctor validates source selection before activation.
;; : (-> PooModuleCatalog [PooModuleSourceRef] PooModuleDoctorReport)
(def (poo-flow-module-resolve-doctor catalog source-refs)
  (poo-flow-module-doctor
   (resolve-poo-flow-module-sources catalog source-refs)))

;;; Boundary: base activation allows callers to preserve existing registries.
;; : (-> PooModuleCatalog [PooModuleSourceRef] TaskFamilyRegistry FlowDeclarationRegistry ModuleOptionAlist PooModuleActivation)
(def (poo-flow-module-resolve-and-activate-with-base catalog source-refs base-task-registry base-flow-registry base-options)
  (activate-poo-flow-modules-with-base
   (resolve-poo-flow-module-sources catalog source-refs)
   base-task-registry
   base-flow-registry
   base-options))

;;; Boundary: source-selected activation uses the same activation path as direct modules.
;; : (-> PooModuleCatalog [PooModuleSourceRef] PooModuleActivation)
(def (poo-flow-module-resolve-and-activate catalog source-refs)
  (activate-poo-flow-modules
   (resolve-poo-flow-module-sources catalog source-refs)))

;;; Boundary: activation appends descriptor contributions without mutation.
;; : (-> [PooModuleDescriptor] TaskFamilyRegistry FlowDeclarationRegistry ModuleOptionAlist PooModuleActivation)
(defstruct poo-flow-module-activation
  (modules
   task-registry
   flow-registry
   options)
  transparent: #t)

;;; Boundary: activation validates closure then appends base-first registries.
;;; Intent: runtime-visible registries are deterministic snapshots of module data.
;; : (-> [PooModuleDescriptor] TaskFamilyRegistry FlowDeclarationRegistry ModuleOptionAlist PooModuleActivation)
(def (activate-poo-flow-modules-with-base modules base-task-registry base-flow-registry base-options)
  (let (closed-modules (poo-flow-module-closure modules))
    ;; Import validation must see the same closure that registry aggregation uses.
    (validate-poo-flow-module-imports closed-modules)
    (make-poo-flow-module-activation
     closed-modules
     (make-task-family-registry
      (task-family-registry-name base-task-registry)
      ;; Base descriptors stay first so existing lookup behavior is preserved.
      (append (task-family-registry-descriptors base-task-registry)
              (poo-flow-module-all-task-descriptors closed-modules)))
     (make-flow-declaration-registry
      (flow-declaration-registry-name base-flow-registry)
      (append (flow-declaration-registry-descriptors base-flow-registry)
             (poo-flow-module-all-flow-descriptors closed-modules)))
     (append base-options
             (poo-flow-module-all-options closed-modules)
             (list (cons 'poo-flow-modules
                         (poo-flow-module-names closed-modules)))))))

;;; Boundary: default activation uses project default task and flow registries.
;; : (-> [PooModuleDescriptor] PooModuleActivation)
(def (activate-poo-flow-modules modules)
  (activate-poo-flow-modules-with-base
   modules
   default-task-family-registry
   default-flow-declaration-registry
   '()))

;;; Boundary: run-config lowering keeps modules outside runner internals.
;; : (-> Symbol Strategy RuntimeAdapter PooModuleActivation RunConfig)
(def (poo-flow-module-activation->run-config name strategy adapter activation)
  (make-run-config name
                   strategy
                   adapter
                   (poo-flow-module-activation-options activation)
                   (poo-flow-module-activation-task-registry activation)
                   (poo-flow-module-activation-flow-registry activation)))
