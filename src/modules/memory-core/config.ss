;;; -*- Gerbil -*-
;;; Boundary: public facade for memory-core store specs and catalog receipts.
;;; Invariant: users author POO memory specs; runtime memory remains external.

(import (only-in :std/sugar filter)
        (only-in :clan/poo/object .o .ref .slot? object? object<-alist)
        :poo-flow/src/module-system/base
        :poo-flow/src/modules/memory-core/objects)

(export (import: :poo-flow/src/modules/memory-core/objects)
        memory-store-spec
        memory-catalog
        poo-flow-memory-core-poo-store-spec?
        poo-flow-memory-core-poo-catalog?
        poo-flow-memory-core-poo-store-spec->store-spec
        poo-flow-memory-core-poo-catalog->catalog
        poo-flow-memory-core-prototype-super
        poo-flow-memory-core-poo-config-flags
        poo-flow-memory-core-module-bundles)

(def memory-store-spec
  (object<-alist
   (list
    (cons 'kind +poo-flow-memory-core-store-spec-kind+)
    (cons 'store-ref #f)
    (cons 'store-kind 'custom)
    (cons 'namespace 'session)
    (cons 'scopes '())
    (cons 'recall-policies '())
    (cons 'commit-policies '())
    (cons 'runtime-owner "marlin-agent-core")
    (cons 'handoff-operation 'memory/custom)
    (cons 'durable? #f)
    (cons 'runtime-backend 'marlin-memory-adapter)
    (cons 'metadata '())
    (cons 'runtime-executed #f))))

(def memory-catalog
  (.o kind: +poo-flow-memory-core-catalog-kind+
      catalog-ref: 'memory-core/catalog
      stores: '()
      metadata: '()
      runtime-owner: "marlin-agent-core"
      runtime-executed: #f))

;; : (-> Symbol POOObject)
(def (poo-flow-memory-core-prototype-super name)
  (cond
   ((eq? name 'memory-store-spec) memory-store-spec)
   ((eq? name 'memory-catalog) memory-catalog)
   (else
    (error "unknown memory-core prototype super" name))))

;; : (-> POOObject Boolean)
(def (poo-flow-memory-core-poo-store-spec? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) +poo-flow-memory-core-store-spec-kind+)))

;; : (-> POOObject Boolean)
(def (poo-flow-memory-core-poo-catalog? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) +poo-flow-memory-core-catalog-kind+)))

;; : (-> PooMemoryStoreSpecPrototype PooMemoryStoreSpec)
(def (poo-flow-memory-core-poo-store-spec->store-spec spec)
  (poo-flow-memory-store-spec
   (.ref spec 'store-ref)
   (.ref spec 'store-kind)
   (.ref spec 'namespace)
   (.ref spec 'scopes)
   (.ref spec 'recall-policies)
   (.ref spec 'commit-policies)
   (.ref spec 'runtime-owner)
   (.ref spec 'handoff-operation)
   (.ref spec 'durable?)
   (.ref spec 'runtime-backend)
   (.ref spec 'metadata)))

;; : (-> [PooMemoryStoreSpecPrototype] [PooMemoryStoreSpec])
(def (poo-flow-memory-core-poo-store-specs->store-specs specs)
  (map poo-flow-memory-core-poo-store-spec->store-spec specs))

;; : (-> PooMemoryCatalogPrototype [PooMemoryStoreSpec] PooMemoryCatalog)
(def (poo-flow-memory-core-poo-catalog->catalog catalog specs)
  (poo-flow-memory-catalog
   (.ref catalog 'catalog-ref)
   specs
   (.ref catalog 'metadata)))

;; : (-> [POOObject] [POOObject])
(def (poo-flow-memory-core-poo-config-store-specs prototypes)
  (filter poo-flow-memory-core-poo-store-spec? prototypes))

;; : (-> [POOObject] [POOObject])
(def (poo-flow-memory-core-poo-config-catalogs prototypes)
  (filter poo-flow-memory-core-poo-catalog? prototypes))

;; : (-> PooMemoryCatalog [Alist])
(def (poo-flow-memory-core-catalog-manifests catalog)
  (map (lambda (spec)
         (poo-flow-memory-handoff-manifest->alist
          (poo-flow-memory-handoff-manifest
           (string->symbol
            (string-append
             "memory/request/"
             (symbol->string (poo-flow-memory-store-spec-ref spec))))
           spec)))
       (.ref catalog 'stores)))

;; : (-> [POOObject] Alist [UserModuleFlagEntry])
(def (poo-flow-memory-core-poo-config-flags prototypes user-config)
  (let* ((store-specs
          (poo-flow-memory-core-poo-store-specs->store-specs
           (poo-flow-memory-core-poo-config-store-specs prototypes)))
         (catalogs (poo-flow-memory-core-poo-config-catalogs prototypes))
         (catalog
          (if (null? catalogs)
            (poo-flow-memory-catalog 'memory-core/user store-specs)
            (poo-flow-memory-core-poo-catalog->catalog
             (car catalogs)
             store-specs))))
    (list '+catalog
          '+typed-receipts
          '+runtime-manifest
          (cons ':config (list catalog))
          (cons ':memory-catalog catalog)
          (cons ':memory-manifests
                (poo-flow-memory-core-catalog-manifests catalog))
          (cons ':user-config user-config))))

(def poo-flow-memory-core-module-bundles
  (list
   (poo-flow-user-module-bundle
    (session memory-core +catalog +typed-receipts +runtime-manifest))))
