;;; -*- Gerbil -*-
;;; Boundary: module loader backends convert source refs into descriptor values.
;;; Invariant: loader backends return data and never activate modules or run flows.
;;; Intent: source loading stays separate from catalog resolution and activation.
;;; Parser policy should treat this file as the source-loader owner.

(import :core/failure
        :modules/source
        :modules/descriptor
        :modules/resolver)

(export make-poo-module-loader-entry
        poo-module-loader-entry?
        poo-module-loader-entry-source
        poo-module-loader-entry-module
        make-poo-module-loader-backend
        poo-module-loader-backend?
        poo-module-loader-backend-name
        poo-module-loader-backend-source-kind
        poo-module-loader-backend-load
        poo-module-loader-backend-metadata
        make-poo-module-load-receipt
        poo-module-load-receipt?
        poo-module-load-receipt-source
        poo-module-load-receipt-module
        poo-module-load-receipt-backend-name
        poo-module-load-receipt-loaded?
        poo-module-load-receipt-code
        poo-module-load-receipt-messages
        poo-module-load-receipt-metadata
        poo-module-static-loader
        poo-module-loader-backend-supports?
        poo-module-load-source-receipt
        poo-module-load-source-receipts
        poo-module-load-receipt->alist
        poo-module-load-source
        poo-module-load-sources
        poo-module-load-catalog)

;;; Boundary: static loader entries bind source refs to already-built descriptors.
;; PooModuleLoaderEntry <- PooModuleSourceRef PooModuleDescriptor
(defstruct poo-module-loader-entry
  (source
   module)
  transparent: #t)

;;; Boundary: backend load procedures are pure source-ref to maybe descriptor functions.
;; PooModuleLoaderBackend <- LoaderName SourceKind LoaderProcedure Alist
(defstruct poo-module-loader-backend
  (name
   source-kind
   load
   metadata)
  transparent: #t)

;;; Boundary: load receipts are inspection data before catalog resolution.
;; PooModuleLoadReceipt <- PooModuleSourceRef MaybePooModuleDescriptor MaybeLoaderName Boolean Symbol [String] Alist
(defstruct poo-module-load-receipt
  (source
   module
   backend-name
   loaded?
   code
   messages
   metadata)
  transparent: #t)

;;; Boundary: wildcard source kind is explicit and does not inspect source values.
;; Boolean <- SourceKind PooModuleSourceRef
(def (poo-module-loader-source-kind-matches? source-kind source-ref)
  (or (eq? source-kind '*)
      (eq? source-kind (poo-module-source-ref-kind source-ref))))

;;; Boundary: static loaders use source-ref equality, never path reads.
;; MaybePooModuleLoaderEntry <- [PooModuleLoaderEntry] PooModuleSourceRef
(def (poo-module-static-loader-find-entry entries source-ref)
  (cond
   ((null? entries) #f)
   ((poo-module-source-ref=? (poo-module-loader-entry-source (car entries))
                             source-ref)
    (car entries))
   (else
    (poo-module-static-loader-find-entry (cdr entries) source-ref))))

;;; Boundary: static loader handler returns a descriptor or false.
;; MaybePooModuleDescriptor <- [PooModuleLoaderEntry] PooModuleSourceRef
(def (poo-module-static-loader-load entries source-ref)
  (let (entry (poo-module-static-loader-find-entry entries source-ref))
    (if entry
      (poo-module-loader-entry-module entry)
      #f)))

;;; Boundary: static loaders are useful for manifests and tests before IO backends exist.
;; PooModuleLoaderBackend <- LoaderName SourceKind [PooModuleLoaderEntry]
(def (poo-module-static-loader loader-name source-kind entries)
  (make-poo-module-loader-backend
   loader-name
   source-kind
   (lambda (source-ref)
     (poo-module-static-loader-load entries source-ref))
   (list (cons 'mode 'static)
         (cons 'entry-count (length entries)))))

;;; Boundary: support checks only source kind, not filesystem or registry state.
;; Boolean <- PooModuleLoaderBackend PooModuleSourceRef
(def (poo-module-loader-backend-supports? backend source-ref)
  (poo-module-loader-source-kind-matches?
   (poo-module-loader-backend-source-kind backend)
   source-ref))

;;; Boundary: successful receipt records the backend that produced the descriptor.
;; PooModuleLoadReceipt <- PooModuleLoaderBackend PooModuleSourceRef PooModuleDescriptor
(def (poo-module-loaded-receipt backend source-ref module)
  (make-poo-module-load-receipt
   source-ref
   module
   (poo-module-loader-backend-name backend)
   #t
   'loaded
   '()
   (poo-module-loader-backend-metadata backend)))

;;; Boundary: missing loader receipts remain data until callers request strict loading.
;; PooModuleLoadReceipt <- PooModuleSourceRef
(def (poo-module-missing-loader-receipt source-ref)
  (make-poo-module-load-receipt
   source-ref
   #f
   #f
   #f
   'missing-loader
   '("poo module source was not loaded by any backend")
   '()))

;;; Boundary: backend attempts are ordered and stop at the first descriptor.
;; PooModuleLoadReceipt <- [PooModuleLoaderBackend] PooModuleSourceRef
(def (poo-module-load-source-receipt backends source-ref)
  (cond
   ((null? backends)
    (poo-module-missing-loader-receipt source-ref))
   ((not (poo-module-loader-backend-supports? (car backends) source-ref))
    (poo-module-load-source-receipt (cdr backends) source-ref))
   (else
    (let (module ((poo-module-loader-backend-load (car backends)) source-ref))
      (if module
        (poo-module-loaded-receipt (car backends) source-ref module)
        (poo-module-load-source-receipt (cdr backends) source-ref))))))

;; [PooModuleLoadReceipt] <- [PooModuleLoaderBackend] [PooModuleSourceRef]
(def (poo-module-load-source-receipts backends source-refs)
  (if (null? source-refs)
    '()
    (cons (poo-module-load-source-receipt backends (car source-refs))
          (poo-module-load-source-receipts backends (cdr source-refs)))))

;;; Boundary: receipt projection is stable evidence for doctors and user tooling.
;; Alist <- PooModuleLoadReceipt
(def (poo-module-load-receipt->alist receipt)
  (list (cons 'source
              (poo-module-source-ref->alist
               (poo-module-load-receipt-source receipt)))
        (cons 'module
              (if (poo-module-load-receipt-module receipt)
                (poo-module-name (poo-module-load-receipt-module receipt))
                #f))
        (cons 'backend-name (poo-module-load-receipt-backend-name receipt))
        (cons 'loaded? (poo-module-load-receipt-loaded? receipt))
        (cons 'code (poo-module-load-receipt-code receipt))
        (cons 'messages (poo-module-load-receipt-messages receipt))
        (cons 'metadata (poo-module-load-receipt-metadata receipt))))

;;; Boundary: strict loading raises typed failures before resolver activation.
;; PooModuleDescriptor <- [PooModuleLoaderBackend] PooModuleSourceRef
(def (poo-module-load-source backends source-ref)
  (let (receipt (poo-module-load-source-receipt backends source-ref))
    (if (poo-module-load-receipt-loaded? receipt)
      (poo-module-load-receipt-module receipt)
      (raise-control-plane-failure
       'module-system
       'missing-module-loader
       "poo module source was not loaded by any backend"
       (list (cons 'source (poo-module-source-ref->alist source-ref))
             (cons 'receipt (poo-module-load-receipt->alist receipt)))))))

;;; Boundary: multi-source loading preserves requested source order.
;; [PooModuleDescriptor] <- [PooModuleLoaderBackend] [PooModuleSourceRef]
(def (poo-module-load-sources backends source-refs)
  (if (null? source-refs)
    '()
    (cons (poo-module-load-source backends (car source-refs))
          (poo-module-load-sources backends (cdr source-refs)))))

;;; Boundary: loaded catalogs hand descriptor data to the existing resolver owner.
;; PooModuleCatalog <- CatalogName [PooModuleLoaderBackend] [PooModuleSourceRef]
(def (poo-module-load-catalog catalog-name backends source-refs)
  (make-poo-module-catalog
   catalog-name
   (map make-poo-module-catalog-entry
        source-refs
        (poo-module-load-sources backends source-refs))))
