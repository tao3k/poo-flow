;;; -*- Gerbil -*-
;;; Boundary: module loader backend descriptors and lazy receipt values.
;;; Invariant: this owner returns data and never activates modules.

(import :poo-flow/src/module-system/projection-syntax
        :poo-flow/src/module-system/source
        :poo-flow/src/module-system/descriptor)

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
        poo-flow-module-load-receipt->alist)


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

;;; Boundary: module load source receipts is the policy-visible edge for
;;; module-system behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> [PooModuleLoaderBackend] [PooModuleSourceRef] [PooModuleLoadReceipt])
(def (poo-flow-module-load-source-receipts backends source-refs)
  (if (null? source-refs)
    '()
    (cons (poo-flow-module-load-source-receipt backends (car source-refs))
          (poo-flow-module-load-source-receipts backends (cdr source-refs)))))

;;; Boundary: receipt projection is stable evidence for doctors and user tooling.
;; : (-> PooModuleLoadReceipt Alist)
(defpoo-module-final-projection
  poo-flow-module-load-receipt->alist (receipt)
  (bindings ((module
              (poo-flow-module-load-receipt-module receipt))))
  (fields ((source
            (poo-flow-module-source-ref->alist
             (poo-flow-module-load-receipt-source receipt)))
           (module
            (if module
              (poo-flow-module-name module)
              #f))
           (backend-name (poo-flow-module-load-receipt-backend-name receipt))
           (loaded? (poo-flow-module-load-receipt-loaded? receipt))
           (code (poo-flow-module-load-receipt-code receipt))
           (messages (poo-flow-module-load-receipt-messages receipt))
           (metadata (poo-flow-module-load-receipt-metadata receipt)))))
