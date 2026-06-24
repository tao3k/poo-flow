;;; -*- Gerbil -*-
;;; Boundary: lazy plans, auto-import graphs, and catalog loading for module trees.
;;; Invariant: static entrypoint metadata lives in module-registry and stays loader-free.

(import :poo-flow/src/core/failure
        :poo-flow/src/module-system/source
        :poo-flow/src/module-system/resolver
        :poo-flow/src/module-system/extension
        :poo-flow/src/module-system/loader-backend
        :poo-flow/src/module-system/module-registry)

(export (import: :poo-flow/src/module-system/module-registry)
        poo-flow-module-tree-lazy-load-plans
        poo-flow-src-modules-lazy-load-plans
        poo-flow-module-auto-import-root-identity
        poo-flow-module-auto-import-entry-node
        poo-flow-module-auto-imports-node
        poo-flow-module-auto-imports-mk-merge
        poo-flow-module-auto-imports-result-source-refs
        poo-flow-user-tree-lazy-load-plans
        poo-flow-module-load-source
        poo-flow-module-load-sources
        poo-flow-module-load-catalog)

;;; Boundary: tree loading remains lazy data until callers force a plan.
;; : (-> [PooModuleLoaderBackend] Path [PooFlowLazyLoadPlan])
(def (poo-flow-module-tree-lazy-load-plans backends module-root-path
                                           . maybe-metadata)
  (let (metadata
        (if (null? maybe-metadata) '() (car maybe-metadata)))
    (map (lambda (source-ref)
           (poo-flow-make-lazy-load-plan backends source-ref metadata))
         (poo-flow-module-tree-source-refs module-root-path))))

;;; Boundary: src/modules lazy plans never call loader handlers.
;; : (-> [PooModuleLoaderBackend] [PooFlowLazyLoadPlan])
(def (poo-flow-src-modules-lazy-load-plans backends . maybe-metadata)
  (let (metadata
        (if (null? maybe-metadata) '() (car maybe-metadata)))
    (map (lambda (source-ref)
           (poo-flow-make-lazy-load-plan backends source-ref metadata))
         (poo-flow-src-modules-source-refs))))

;;; Boundary: user-root tree loading is lazy and never evaluates init.ss.
;; : (-> [PooModuleLoaderBackend] Path [PooFlowLazyLoadPlan])
(def (poo-flow-user-tree-lazy-load-plans backends user-root-path
                                         . maybe-metadata)
  (let (metadata
        (if (null? maybe-metadata) '() (car maybe-metadata)))
    (map (lambda (source-ref)
           (poo-flow-make-lazy-load-plan backends source-ref metadata))
         (poo-flow-user-tree-source-refs user-root-path))))

;;; Boundary: auto-import plans are POO nodes over source refs, not evaluator IO.
;; : PooFlowModuleAutoImportRootIdentity
(def poo-flow-module-auto-import-root-identity 'auto-imports)

;; : (-> PooModuleLoaderMetadata Symbol PooModuleLoaderMetadataValue PooModuleLoaderMetadataValue)
(def (poo-flow-loader-alist-ref/default entries key default-value)
  (let (entry (assoc key entries))
    (if entry (cdr entry) default-value)))

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
