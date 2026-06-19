;;; -*- Gerbil -*-
;;; Boundary: module loader backends convert source refs into descriptor values.
;;; Invariant: loader backends return data and never activate modules or run flows.
;;; Intent: source loading stays separate from catalog resolution and activation.
;;; Parser policy should treat this file as the source-loader owner.

(import :core/failure
        :modules/source
        :modules/descriptor
        :modules/resolver
        :modules/extension)

(export make-poo-flow-module-loader-entry
        poo-flow-module-loader-entry?
        poo-flow-module-loader-entry-source
        poo-flow-module-loader-entry-module
        make-poo-flow-module-loader-backend
        poo-flow-module-loader-backend?
        poo-flow-module-loader-backend-name
        poo-flow-module-loader-backend-source-kind
        poo-flow-module-loader-backend-load
        poo-flow-module-loader-backend-metadata
        make-poo-flow-lazy-load-plan
        poo-flow-lazy-load-plan?
        poo-flow-lazy-load-plan-source
        poo-flow-lazy-load-plan-backends
        poo-flow-lazy-load-plan-forced?
        poo-flow-lazy-load-plan-receipt
        poo-flow-lazy-load-plan-metadata
        make-poo-flow-module-load-receipt
        poo-flow-module-load-receipt?
        poo-flow-module-load-receipt-source
        poo-flow-module-load-receipt-module
        poo-flow-module-load-receipt-backend-name
        poo-flow-module-load-receipt-loaded?
        poo-flow-module-load-receipt-code
        poo-flow-module-load-receipt-messages
        poo-flow-module-load-receipt-metadata
        poo-flow-module-static-loader
        poo-flow-module-loader-backend-supports?
        poo-flow-lazy-load-source-receipt
        poo-flow-make-lazy-load-plan
        poo-flow-force-lazy-load-source-receipt
        poo-flow-force-lazy-load-plan
        poo-flow-module-load-source-receipt
        poo-flow-module-load-source-receipts
        poo-flow-module-load-receipt->alist
        poo-flow-module-tree-entrypoint
        poo-flow-module-tree-source
        poo-flow-module-tree-config-source
        poo-flow-module-tree-objects-source
        poo-flow-module-tree-source-refs
        poo-flow-module-tree-lazy-load-plans
        poo-flow-src-modules-root
        poo-flow-src-module-tree-entrypoints
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

;;; Boundary: static loader entries bind source refs to already-built descriptors.
;; : (-> PooModuleSourceRef PooModuleDescriptor PooModuleLoaderEntry)
(defstruct poo-flow-module-loader-entry
  (source
   module)
  transparent: #t)

;;; Boundary: backend load procedures are pure source-ref to maybe descriptor functions.
;; : (-> LoaderName SourceKind LoaderProcedure Alist PooModuleLoaderBackend)
(defstruct poo-flow-module-loader-backend
  (name
   source-kind
   load
   metadata)
  transparent: #t)

;;; Boundary: lazy load plans hold source/backend data without invoking loaders.
;; : (-> PooModuleSourceRef [PooModuleLoaderBackend] Boolean PooModuleLoadReceipt Alist PooFlowLazyLoadPlan)
(defstruct poo-flow-lazy-load-plan
  (source
   backends
   forced?
   receipt
   metadata)
  transparent: #t)

;;; Boundary: load receipts are inspection data before catalog resolution.
;; : (-> PooModuleSourceRef MaybePooModuleDescriptor MaybeLoaderName Boolean Symbol [String] Alist PooModuleLoadReceipt)
(defstruct poo-flow-module-load-receipt
  (source
   module
   backend-name
   loaded?
   code
   messages
   metadata)
  transparent: #t)

;;; Boundary: auto-import plans are POO nodes over source refs, not evaluator IO.
;; : PooFlowModuleAutoImportRootIdentity
(def poo-flow-module-auto-import-root-identity 'auto-imports)

;;; Boundary: wildcard source kind is explicit and does not inspect source values.
;; : (-> SourceKind PooModuleSourceRef Boolean)
(def (poo-flow-module-loader-source-kind-matches? source-kind source-ref)
  (or (eq? source-kind '*)
      (eq? source-kind (poo-flow-module-source-ref-kind source-ref))))

;;; Boundary: static loaders use source-ref equality, never path reads.
;; : (-> [PooModuleLoaderEntry] PooModuleSourceRef MaybePooModuleLoaderEntry)
(def (poo-flow-module-static-loader-find-entry entries source-ref)
  (cond
   ((null? entries) #f)
   ((poo-flow-module-source-ref=? (poo-flow-module-loader-entry-source (car entries))
                                  source-ref)
    (car entries))
   (else
    (poo-flow-module-static-loader-find-entry (cdr entries) source-ref))))

;;; Boundary: static loader handler returns a descriptor or false.
;; : (-> [PooModuleLoaderEntry] PooModuleSourceRef MaybePooModuleDescriptor)
(def (poo-flow-module-static-loader-load entries source-ref)
  (let (entry (poo-flow-module-static-loader-find-entry entries source-ref))
    (if entry
      (poo-flow-module-loader-entry-module entry)
      #f)))

;;; Boundary: static loaders are useful for manifests and tests before IO backends exist.
;; : (-> LoaderName SourceKind [PooModuleLoaderEntry] PooModuleLoaderBackend)
(def (poo-flow-module-static-loader loader-name source-kind entries)
  (make-poo-flow-module-loader-backend
   loader-name
   source-kind
   (lambda (source-ref)
     (poo-flow-module-static-loader-load entries source-ref))
   (list (cons 'mode 'static)
         (cons 'entry-count (length entries)))))

;;; Boundary: support checks only source kind, not filesystem or registry state.
;; : (-> PooModuleLoaderBackend PooModuleSourceRef Boolean)
(def (poo-flow-module-loader-backend-supports? backend source-ref)
  (poo-flow-module-loader-source-kind-matches?
   (poo-flow-module-loader-backend-source-kind backend)
   source-ref))

;;; Boundary: successful receipt records the backend that produced the descriptor.
;; : (-> PooModuleLoaderBackend PooModuleSourceRef PooModuleDescriptor PooModuleLoadReceipt)
(def (poo-flow-module-loaded-receipt backend source-ref module)
  (make-poo-flow-module-load-receipt
   source-ref
   module
   (poo-flow-module-loader-backend-name backend)
   #t
   'loaded
   '()
   (poo-flow-module-loader-backend-metadata backend)))

;;; Boundary: missing loader receipts remain data until callers request strict loading.
;; : (-> PooModuleSourceRef PooModuleLoadReceipt)
(def (poo-flow-module-missing-loader-receipt source-ref)
  (make-poo-flow-module-load-receipt
   source-ref
   #f
   #f
   #f
   'missing-loader
   '("poo module source was not loaded by any backend")
   '()))

;;; Boundary: lazy metadata marks the deferred state as disabled-by-default.
;; : (-> [PooModuleLoaderBackend] Alist Alist)
(def (poo-flow-lazy-loader-metadata backends metadata)
  (append
   (list (cons 'mode 'lazy)
         (cons 'enabled? #f)
         (cons 'forced? #f)
         (cons 'backend-count (length backends)))
   metadata))

;;; Boundary: lazy receipts are explicit non-load evidence, not failures.
;; : (-> [PooModuleLoaderBackend] PooModuleSourceRef Alist PooModuleLoadReceipt)
(def (poo-flow-lazy-load-source-receipt backends source-ref . maybe-metadata)
  (let (metadata
        (if (null? maybe-metadata) '() (car maybe-metadata)))
    (make-poo-flow-module-load-receipt
     source-ref
     #f
     #f
     #f
     'deferred
     '("poo module source loading is deferred until forced")
     (poo-flow-lazy-loader-metadata backends metadata))))

;;; Boundary: lazy plans preserve loader order but do not call loader handlers.
;; : (-> [PooModuleLoaderBackend] PooModuleSourceRef Alist PooFlowLazyLoadPlan)
(def (poo-flow-make-lazy-load-plan backends source-ref . maybe-metadata)
  (let* ((metadata
          (if (null? maybe-metadata) '() (car maybe-metadata)))
         (receipt
          (poo-flow-lazy-load-source-receipt backends
                                             source-ref
                                             metadata)))
    (make-poo-flow-lazy-load-plan
     source-ref
     backends
     #f
     receipt
     metadata)))

;;; Boundary: forcing a lazy source delegates to the existing strict receipt path.
;; : (-> [PooModuleLoaderBackend] PooModuleSourceRef PooModuleLoadReceipt)
(def (poo-flow-force-lazy-load-source-receipt backends source-ref)
  (poo-flow-module-load-source-receipt backends source-ref))

;;; Boundary: forcing returns a new plan value and leaves the deferred plan intact.
;; : (-> PooFlowLazyLoadPlan PooFlowLazyLoadPlan)
(def (poo-flow-force-lazy-load-plan lazy-plan)
  (let (receipt
        (poo-flow-force-lazy-load-source-receipt
         (poo-flow-lazy-load-plan-backends lazy-plan)
         (poo-flow-lazy-load-plan-source lazy-plan)))
    (make-poo-flow-lazy-load-plan
     (poo-flow-lazy-load-plan-source lazy-plan)
     (poo-flow-lazy-load-plan-backends lazy-plan)
     #t
     receipt
     (poo-flow-lazy-load-plan-metadata lazy-plan))))

;;; Boundary: backend attempts are ordered and stop at the first descriptor.
;; : (-> [PooModuleLoaderBackend] PooModuleSourceRef PooModuleLoadReceipt)
(def (poo-flow-module-load-source-receipt backends source-ref)
  (cond
   ((null? backends)
    (poo-flow-module-missing-loader-receipt source-ref))
   ((not (poo-flow-module-loader-backend-supports? (car backends) source-ref))
    (poo-flow-module-load-source-receipt (cdr backends) source-ref))
   (else
    (let (module ((poo-flow-module-loader-backend-load (car backends)) source-ref))
      (if module
        (poo-flow-module-loaded-receipt (car backends) source-ref module)
        (poo-flow-module-load-source-receipt (cdr backends) source-ref))))))

;; : (-> [PooModuleLoaderBackend] [PooModuleSourceRef] [PooModuleLoadReceipt])
(def (poo-flow-module-load-source-receipts backends source-refs)
  (if (null? source-refs)
    '()
    (cons (poo-flow-module-load-source-receipt backends (car source-refs))
          (poo-flow-module-load-source-receipts backends (cdr source-refs)))))

;;; Boundary: receipt projection is stable evidence for doctors and user tooling.
;; : (-> PooModuleLoadReceipt Alist)
(def (poo-flow-module-load-receipt->alist receipt)
  (list (cons 'source
              (poo-flow-module-source-ref->alist
               (poo-flow-module-load-receipt-source receipt)))
        (cons 'module
              (if (poo-flow-module-load-receipt-module receipt)
                (poo-flow-module-name (poo-flow-module-load-receipt-module receipt))
                #f))
        (cons 'backend-name (poo-flow-module-load-receipt-backend-name receipt))
        (cons 'loaded? (poo-flow-module-load-receipt-loaded? receipt))
        (cons 'code (poo-flow-module-load-receipt-code receipt))
        (cons 'messages (poo-flow-module-load-receipt-messages receipt))
        (cons 'metadata (poo-flow-module-load-receipt-metadata receipt))))

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

;;; Boundary: src/modules is a declared module tree, not a filesystem scan root.
;; : Path
(def poo-flow-src-modules-root "src/modules")

;;; Boundary: each entry names module-tree entrypoints that exist under src/modules.
;; : [(Path Symbol...)]
(def poo-flow-src-module-tree-entrypoints
  '(("agent-sandbox" config)
    ("cubeSandbox" objects config)
    ("funflow" config)
    ("loop-governor" config)
    ("nono-sandbox" objects config)
    ("user-interface" objects config)
    ("workflow" flows syntax)))

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
  (poo-flow-src-module-tree-entrypoint-source-refs*
   poo-flow-src-module-tree-entrypoints))

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
