;;; -*- Gerbil -*-
;;; Boundary: module loader tree sources, auto-imports, and catalog loading.
;;; Invariant: tree declarations remain lazy data until a backend is forced.

(import :poo-flow/src/core/failure
        :poo-flow/src/module-system/source
        :poo-flow/src/module-system/descriptor
        :poo-flow/src/module-system/resolver
        :poo-flow/src/module-system/extension
        :poo-flow/src/module-system/loader-backend)

(export poo-flow-module-tree-entrypoint
        poo-flow-module-tree-source
        poo-flow-module-tree-config-source
        poo-flow-module-tree-objects-source
        poo-flow-module-tree-source-refs
        poo-flow-module-tree-lazy-load-plans
        poo-flow-src-modules-root
        poo-flow-src-module-tree-entrypoints
        poo-flow-module-system-source
        poo-flow-module-system-source-refs
        poo-flow-module-category-names
        poo-flow-module-tree-entrypoint-module-name
        poo-flow-module-tree-entrypoint-name-conflict?
        poo-flow-module-tree-entrypoint-conflicts
        poo-flow-src-module-tree-entrypoint-conflicts
        poo-flow-src-modules-source-refs
        poo-flow-src-modules-lazy-load-plans
        poo-flow-module-auto-import-root-identity
        poo-flow-module-auto-import-entry-node
        poo-flow-module-auto-imports-node
        poo-flow-module-auto-imports-mk-merge
        poo-flow-module-auto-imports-result-source-refs
        poo-flow-user-tree-source
        poo-flow-user-tree-entrypoint-policy
        poo-flow-user-tree-source-allowed-responsibilities
        poo-flow-user-tree-source-denied-responsibilities
        poo-flow-user-tree-source-allows?
        poo-flow-user-tree-source-policy-violations
        poo-flow-user-tree-source-valid?
        poo-flow-user-tree-init-source
        poo-flow-user-tree-objects-source
        poo-flow-user-tree-config-source
        poo-flow-user-tree-modules-config-source
        poo-flow-user-tree-source-refs
        poo-flow-user-tree-lazy-load-plans
        poo-flow-module-load-source
        poo-flow-module-load-sources
        poo-flow-module-load-catalog)

;;; Boundary: auto-import plans are POO nodes over source refs, not evaluator IO.
;; : PooFlowModuleAutoImportRootIdentity
(def poo-flow-module-auto-import-root-identity 'auto-imports)

;;; Boundary: tree entrypoints are source metadata, not filesystem reads.
;; : (-> Path Symbol Path)
(def (poo-flow-module-tree-entrypoint module-root-path entrypoint-role)
  (let* ((leaf (string-append (symbol->string entrypoint-role) ".ss"))
         (path-length (string-length module-root-path)))
    (if (and (> path-length 0)
             (char=? (string-ref module-root-path (- path-length 1)) #\/))
      (string-append module-root-path leaf)
      (string-append module-root-path "/" leaf))))

;;; Boundary: a module tree contributes separate config and objects entrypoints.
;; : (-> Path Symbol PooModuleSourceRef)
(def (poo-flow-module-tree-source module-root-path entrypoint-role)
  (let (entrypoint
        (poo-flow-module-tree-entrypoint module-root-path entrypoint-role))
    (make-poo-flow-module-source-ref
     'local
     entrypoint
     (list (cons 'kind 'module-tree)
           (cons 'module-tree-root module-root-path)
           (cons 'entrypoint entrypoint)
           (cons 'entrypoint-role entrypoint-role)))))

;; : (-> Path PooModuleSourceRef)
(def (poo-flow-module-tree-config-source module-root-path)
  (poo-flow-module-tree-source module-root-path 'config))

;; : (-> Path PooModuleSourceRef)
(def (poo-flow-module-tree-objects-source module-root-path)
  (poo-flow-module-tree-source module-root-path 'objects))

;; : (-> Path [PooModuleSourceRef])
(def (poo-flow-module-tree-source-refs module-root-path)
  (list (poo-flow-module-tree-config-source module-root-path)
        (poo-flow-module-tree-objects-source module-root-path)))

;;; Boundary: tree loading remains lazy data until callers force a plan.
;; : (-> [PooModuleLoaderBackend] Path [PooFlowLazyLoadPlan])
(def (poo-flow-module-tree-lazy-load-plans backends module-root-path
                                           . maybe-metadata)
  (let (metadata
        (if (null? maybe-metadata) '() (car maybe-metadata)))
    (map (lambda (source-ref)
           (poo-flow-make-lazy-load-plan backends source-ref metadata))
         (poo-flow-module-tree-source-refs module-root-path))))

;;; Boundary: src/modules is a declared package module tree, not a filesystem scan root.
;; : Path
(def poo-flow-src-modules-root "src/modules")

;;; Boundary: each entry names module-tree entrypoints that exist under src/modules.
;; : [(Path Symbol...)]
(def poo-flow-src-module-tree-entrypoints
  '(("agent-sandbox" config)
    ("cubeSandbox" objects config)
    ("sandbox-core" objects)
    ("funflow" config)
    ("loop-governor" config)
    ("nono-sandbox" objects config)
    ("workflow" flows syntax)))

;;; Boundary: module-system source refs are internal package owners, not
;;; user-interface modules. They stay explicit so the loader never scans src.
;; : (-> Symbol Path PooModuleSourceRef)
(def (poo-flow-module-system-source entrypoint-role entrypoint-path)
  (let (entrypoint
        (string-append "src/module-system/" entrypoint-path))
    (make-poo-flow-module-source-ref
     'local
     entrypoint
     (list (cons 'kind 'module-system)
           (cons 'module-system-root "src/module-system")
           (cons 'entrypoint entrypoint)
           (cons 'entrypoint-role entrypoint-role)))))

;; : (-> Unit [PooModuleSourceRef])
(def (poo-flow-module-system-source-refs)
  (list
   (poo-flow-module-system-source 'profile-config "profile-config.ss")
   (poo-flow-module-system-source 'init-syntax "init-syntax.ss")
   (poo-flow-module-system-source 'root-profile "root-profile.ss")
   (poo-flow-module-system-source 'declaration-case "declaration-case.ss")))

;;; Boundary: category names are loader-owned because every module tree,
;;; developer object tree, and user tree eventually passes through this owner.
;; : [Symbol]
(def poo-flow-module-category-names
  '(modules flow loop sandbox custom))

;; : (-> (Path Symbol...) Symbol)
(def (poo-flow-module-tree-entrypoint-module-name entrypoint-spec)
  (string->symbol (car entrypoint-spec)))

;; : (-> (Path Symbol...) Boolean)
(def (poo-flow-module-tree-entrypoint-name-conflict? entrypoint-spec)
  (poo-flow-loader-member?
   (poo-flow-module-tree-entrypoint-module-name entrypoint-spec)
   poo-flow-module-category-names))

;;; Conflict receipts are data so doctors can report naming drift without
;;; forcing source loading or descriptor realization.
;; : (-> [(Path Symbol...)] [Alist])
(def (poo-flow-module-tree-entrypoint-conflicts entrypoint-specs)
  (cond
   ((null? entrypoint-specs) '())
   ((poo-flow-module-tree-entrypoint-name-conflict? (car entrypoint-specs))
    (cons
     (list (cons 'code 'module-category-name-conflict)
           (cons 'module-name
                 (poo-flow-module-tree-entrypoint-module-name
                  (car entrypoint-specs)))
           (cons 'module-root (car (car entrypoint-specs)))
           (cons 'categories poo-flow-module-category-names))
     (poo-flow-module-tree-entrypoint-conflicts (cdr entrypoint-specs))))
   (else
    (poo-flow-module-tree-entrypoint-conflicts (cdr entrypoint-specs)))))

;; : (-> Unit [Alist])
(def (poo-flow-src-module-tree-entrypoint-conflicts)
  (poo-flow-module-tree-entrypoint-conflicts
   poo-flow-src-module-tree-entrypoints))

;;; Internal path join stays string-only so this owner never probes the filesystem.
;; : (-> Path Path)
(def (poo-flow-src-module-tree-root module-name)
  (string-append poo-flow-src-modules-root "/" module-name))

;;; Internal expansion keeps module entrypoints ordered for stable diagnostics.
;; : (-> (Path Symbol...) [PooModuleSourceRef])
(def (poo-flow-src-module-tree-entrypoint-source-refs entrypoint-spec)
  (let ((module-root
         (poo-flow-src-module-tree-root (car entrypoint-spec)))
        (entrypoint-roles (cdr entrypoint-spec)))
    (map (lambda (entrypoint-role)
           (poo-flow-module-tree-source module-root entrypoint-role))
         entrypoint-roles)))

;;; Internal recursion flattens the declared tree without forcing source loads.
;; : (-> [(Path Symbol...)] [PooModuleSourceRef])
(def (poo-flow-src-module-tree-entrypoint-source-refs* entrypoint-specs)
  (if (null? entrypoint-specs)
    '()
    (append
     (poo-flow-src-module-tree-entrypoint-source-refs
      (car entrypoint-specs))
     (poo-flow-src-module-tree-entrypoint-source-refs*
      (cdr entrypoint-specs)))))

;;; Boundary: upstream module sources are declared and lazy by default.
;; : (-> [PooModuleSourceRef])
(def (poo-flow-src-modules-source-refs)
  (append
   (poo-flow-src-module-tree-entrypoint-source-refs*
    poo-flow-src-module-tree-entrypoints)
   (poo-flow-module-system-source-refs)))

;;; Boundary: src/modules lazy plans never call loader handlers.
;; : (-> [PooModuleLoaderBackend] [PooFlowLazyLoadPlan])
(def (poo-flow-src-modules-lazy-load-plans backends . maybe-metadata)
  (let (metadata
        (if (null? maybe-metadata) '() (car maybe-metadata)))
    (map (lambda (source-ref)
           (poo-flow-make-lazy-load-plan backends source-ref metadata))
         (poo-flow-src-modules-source-refs))))

;; : (-> PooModuleLoaderMetadata Symbol PooModuleLoaderMetadataValue PooModuleLoaderMetadataValue)
(def (poo-flow-loader-alist-ref/default entries key default-value)
  (let (entry (assoc key entries))
    (if entry (cdr entry) default-value)))

;; : (-> PooModuleLoaderValue [PooModuleLoaderValue] Boolean)
(def (poo-flow-loader-member? value values)
  (cond ((null? values) #f)
        ((equal? value (car values)) #t)
        (else (poo-flow-loader-member? value (cdr values)))))

;;; Boundary: each source ref is an importable entrypoint node.
;; : (-> PooModuleSourceRef PooModuleExtensionNode)
(def (poo-flow-module-auto-import-entry-node source-ref)
  (let* ((metadata (poo-flow-module-source-ref-metadata source-ref))
         (entrypoint-role
          (poo-flow-loader-alist-ref/default metadata 'entrypoint-role #f))
         (tree-kind
          (poo-flow-loader-alist-ref/default metadata 'kind #f)))
    (poo-flow-module-extension-node
     (poo-flow-module-source-ref-value source-ref)
     (list (cons 'source-ref source-ref)
           (cons 'entrypoint-role entrypoint-role)
           (cons 'tree-kind tree-kind)
           (cons 'allowed-responsibilities
                 (poo-flow-loader-alist-ref/default
                  metadata
                  'allowed-responsibilities
                  '()))
           (cons 'denied-responsibilities
                 (poo-flow-loader-alist-ref/default
                  metadata
                  'denied-responsibilities
                  '()))
           (cons 'enabled? #t))
     '())))

;;; Boundary: auto-import roots are POO graphs so extensions can remove entries.
;; : (-> [PooModuleSourceRef] PooModuleExtensionNode)
(def (poo-flow-module-auto-imports-node source-refs)
  (poo-flow-module-extension-node
   poo-flow-module-auto-import-root-identity
   '((namespace . auto-imports))
   (map poo-flow-module-auto-import-entry-node source-refs)))

;;; Boundary: disabling an auto import is a regular node-remove contribution.
;; : (-> [PooModuleSourceRef] [PooModuleExtensionContribution] PooModuleExtensionResult)
(def (poo-flow-module-auto-imports-mk-merge source-refs contributions)
  (poo-flow-module-extension-fixed-point
   (poo-flow-module-auto-imports-node source-refs)
   contributions))

;; : (-> PooModuleExtensionNode MaybePooModuleSourceRef)
(def (poo-flow-module-auto-import-entry-source-ref entry-node)
  (poo-flow-loader-alist-ref/default
   (poo-flow-module-extension-node-slots entry-node)
   'source-ref
   #f))

;;; Boundary: resolved source refs are read after POO removals/extensions apply.
;; : (-> PooModuleExtensionResult [PooModuleSourceRef])
(def (poo-flow-module-auto-imports-result-source-refs result)
  (let (root (poo-flow-module-extension-result-root result))
    (map poo-flow-module-auto-import-entry-source-ref
         (poo-flow-module-extension-node-children root))))

;;; Boundary: user-root trees have a different shape from upstream modules.
;; : (-> Path Symbol Path Path)
(def (poo-flow-user-tree-entrypoint user-root-path entrypoint-role entrypoint-path)
  (let (path-length (string-length user-root-path))
    (if (and (> path-length 0)
             (char=? (string-ref user-root-path (- path-length 1)) #\/))
      (string-append user-root-path entrypoint-path)
      (string-append user-root-path "/" entrypoint-path))))

;;; Boundary: entrypoint policy is data so loaders and tools can reject misuse.
;; : (-> Symbol Alist)
(def (poo-flow-user-tree-entrypoint-policy entrypoint-role)
  (cond
   ((eq? entrypoint-role 'init)
    '((policy . init-switches-only)
      (allowed-responsibilities
       . (profile-selection module-switch feature-switch
          module-category-switch custom-module-switch))
      (denied-responsibilities
       . (object-contract field-contract sandbox-profile-recipe settings
          package-sync descriptor-realization runtime-execution facade-export))))
   ((eq? entrypoint-role 'objects)
    '((policy . objects-and-contracts-only)
      (allowed-responsibilities
       . (poo-object object-contract field-contract object-inheritance
          object-extension))
      (denied-responsibilities
       . (sandbox-profile-recipe profile-selection module-switch feature-switch
          settings package-sync descriptor-realization runtime-execution
          facade-export))))
   ((eq? entrypoint-role 'config)
    '((policy . tool-facing-facade-only)
      (allowed-responsibilities
       . (facade-export inspection-helper presentation-helper))
      (denied-responsibilities
       . (module-switch feature-switch object-contract field-contract
          package-sync descriptor-realization runtime-execution))))
   ((eq? entrypoint-role 'modules-config)
    '((policy . user-module-helper-only)
      (allowed-responsibilities
       . (configuration-helper syntax-helper module-helper))
      (denied-responsibilities
       . (module-switch feature-switch object-contract package-sync
          descriptor-realization runtime-execution))))
   (else
    '((policy . unknown-entrypoint)
      (allowed-responsibilities . ())
      (denied-responsibilities . (runtime-execution package-sync))))))

;;; Boundary: user-root source refs cover init/config/objects and modules helpers.
;; : (-> Path Symbol Path PooModuleSourceRef)
(def (poo-flow-user-tree-source user-root-path entrypoint-role entrypoint-path)
  (let* ((entrypoint
          (poo-flow-user-tree-entrypoint user-root-path
                                         entrypoint-role
                                         entrypoint-path))
         (policy
          (poo-flow-user-tree-entrypoint-policy entrypoint-role)))
    (make-poo-flow-module-source-ref
     'local
     entrypoint
     (append
      (list (cons 'kind 'user-tree)
            (cons 'user-tree-root user-root-path)
            (cons 'entrypoint entrypoint)
            (cons 'entrypoint-role entrypoint-role))
      policy))))

;; : (-> PooModuleSourceRef [Symbol])
(def (poo-flow-user-tree-source-allowed-responsibilities source-ref)
  (poo-flow-loader-alist-ref/default
   (poo-flow-module-source-ref-metadata source-ref)
   'allowed-responsibilities
   '()))

;; : (-> PooModuleSourceRef [Symbol])
(def (poo-flow-user-tree-source-denied-responsibilities source-ref)
  (poo-flow-loader-alist-ref/default
   (poo-flow-module-source-ref-metadata source-ref)
   'denied-responsibilities
   '()))

;; : (-> PooModuleSourceRef Symbol Boolean)
(def (poo-flow-user-tree-source-allows? source-ref responsibility)
  (and
   (poo-flow-loader-member?
    responsibility
    (poo-flow-user-tree-source-allowed-responsibilities source-ref))
   (not
    (poo-flow-loader-member?
     responsibility
     (poo-flow-user-tree-source-denied-responsibilities source-ref)))))

;; : (-> PooModuleSourceRef [Symbol] [Symbol])
(def (poo-flow-user-tree-source-policy-violations source-ref responsibilities)
  (cond ((null? responsibilities) '())
        ((poo-flow-user-tree-source-allows? source-ref (car responsibilities))
         (poo-flow-user-tree-source-policy-violations source-ref
                                                     (cdr responsibilities)))
        (else
         (cons (car responsibilities)
               (poo-flow-user-tree-source-policy-violations
                source-ref
                (cdr responsibilities))))))

;; : (-> PooModuleSourceRef [Symbol] Boolean)
(def (poo-flow-user-tree-source-valid? source-ref responsibilities)
  (null? (poo-flow-user-tree-source-policy-violations source-ref
                                                      responsibilities)))

;; : (-> Path PooModuleSourceRef)
(def (poo-flow-user-tree-init-source user-root-path)
  (poo-flow-user-tree-source user-root-path 'init "init.ss"))

;; : (-> Path PooModuleSourceRef)
(def (poo-flow-user-tree-objects-source user-root-path)
  (poo-flow-user-tree-source user-root-path 'objects "objects.ss"))

;; : (-> Path PooModuleSourceRef)
(def (poo-flow-user-tree-config-source user-root-path)
  (poo-flow-user-tree-source user-root-path 'config "config.ss"))

;; : (-> Path PooModuleSourceRef)
(def (poo-flow-user-tree-modules-config-source user-root-path)
  (poo-flow-user-tree-source user-root-path
                             'modules-config
                             "modules/config.ss"))

;; : (-> Path [PooModuleSourceRef])
(def (poo-flow-user-tree-source-refs user-root-path)
  (list (poo-flow-user-tree-init-source user-root-path)
        (poo-flow-user-tree-objects-source user-root-path)
        (poo-flow-user-tree-config-source user-root-path)
        (poo-flow-user-tree-modules-config-source user-root-path)))

;;; Boundary: user-root tree loading is lazy and never evaluates init.ss.
;; : (-> [PooModuleLoaderBackend] Path [PooFlowLazyLoadPlan])
(def (poo-flow-user-tree-lazy-load-plans backends user-root-path
                                         . maybe-metadata)
  (let (metadata
        (if (null? maybe-metadata) '() (car maybe-metadata)))
    (map (lambda (source-ref)
           (poo-flow-make-lazy-load-plan backends source-ref metadata))
         (poo-flow-user-tree-source-refs user-root-path))))

;;; Boundary: strict loading raises typed failures before resolver activation.
;; : (-> [PooModuleLoaderBackend] PooModuleSourceRef PooModuleDescriptor)
(def (poo-flow-module-load-source backends source-ref)
  (let (receipt (poo-flow-module-load-source-receipt backends source-ref))
    (if (poo-flow-module-load-receipt-loaded? receipt)
      (poo-flow-module-load-receipt-module receipt)
      (raise-control-plane-failure
       'module-system
       'missing-module-loader
       "poo module source was not loaded by any backend"
       (list (cons 'source (poo-flow-module-source-ref->alist source-ref))
             (cons 'receipt (poo-flow-module-load-receipt->alist receipt)))))))

;;; Boundary: multi-source loading preserves requested source order.
;; : (-> [PooModuleLoaderBackend] [PooModuleSourceRef] [PooModuleDescriptor])
(def (poo-flow-module-load-sources backends source-refs)
  (if (null? source-refs)
    '()
    (cons (poo-flow-module-load-source backends (car source-refs))
          (poo-flow-module-load-sources backends (cdr source-refs)))))

;;; Boundary: loaded catalogs hand descriptor data to the existing resolver owner.
;; : (-> CatalogName [PooModuleLoaderBackend] [PooModuleSourceRef] PooModuleCatalog)
(def (poo-flow-module-load-catalog catalog-name backends source-refs)
  (make-poo-flow-module-catalog
   catalog-name
   (map make-poo-flow-module-catalog-entry
        source-refs
        (poo-flow-module-load-sources backends source-refs))))
