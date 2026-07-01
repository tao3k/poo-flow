;;; -*- Gerbil -*-
;;; Boundary: public facade for memory-core store specs and catalog receipts.
;;; Invariant: users author POO memory specs; runtime memory remains external.

(import (only-in :std/sugar filter)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/base
        :poo-flow/src/module-system/config-prototype-syntax
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

(defpoo-module-config-prototype
  memory-store-spec
  (slots ((kind +poo-flow-memory-core-store-spec-kind+)
          (store-ref #f)
          (store-kind 'custom)
          (namespace 'session)
          (scopes '())
          (recall-policies '())
          (commit-policies '())
          (runtime-owner "marlin-agent-core")
          (handoff-operation 'memory/custom)
          (durable? #f)
          (runtime-backend 'marlin-memory-adapter)
          (metadata '())
          (runtime-executed #f))))

(defpoo-module-config-prototype
  memory-catalog
  (slots ((kind +poo-flow-memory-core-catalog-kind+)
          (catalog-ref 'memory-core/catalog)
          (stores '())
          (metadata '())
          (runtime-owner "marlin-agent-core")
          (runtime-executed #f))))

;; : (-> Symbol POOObject)
(def (poo-flow-memory-core-prototype-super name)
  (cond
   ((eq? name 'memory-store-spec) memory-store-spec)
   ((eq? name 'memory-catalog) memory-catalog)
   (else
    (error "unknown memory-core prototype super" name))))

;; : (-> POOObject Boolean)
(defpoo-module-config-kind-predicate
  poo-flow-memory-core-poo-store-spec?
  +poo-flow-memory-core-store-spec-kind+)

;; : (-> POOObject Boolean)
(defpoo-module-config-kind-predicate
  poo-flow-memory-core-poo-catalog?
  +poo-flow-memory-core-catalog-kind+)

;; : (-> PooMemoryStoreSpecPrototype PooMemoryStoreSpec)
(defpoo-module-config-converter
  poo-flow-memory-core-poo-store-spec->store-spec (spec)
  (constructor poo-flow-memory-store-spec)
  (arguments (slot store-ref)
             (slot store-kind)
             (slot namespace)
             (slot scopes)
             (slot recall-policies)
             (slot commit-policies)
             (slot runtime-owner)
             (slot handoff-operation)
             (slot durable?)
             (slot runtime-backend)
             (slot metadata)))

;; : (-> [PooMemoryStoreSpecPrototype] [PooMemoryStoreSpec])
(def (poo-flow-memory-core-poo-store-specs->store-specs specs)
  (cond
   ((null? specs) '())
   ((pair? specs)
    (cons (poo-flow-memory-core-poo-store-spec->store-spec (car specs))
          (poo-flow-memory-core-poo-store-specs->store-specs
           (cdr specs))))
   (else
    (error "memory-core POO store specs must be a list" specs))))

;; : (-> PooMemoryCatalogPrototype [PooMemoryStoreSpec] PooMemoryCatalog)
(defpoo-module-config-converter
  poo-flow-memory-core-poo-catalog->catalog (catalog specs)
  (constructor poo-flow-memory-catalog)
  (arguments (slot catalog-ref)
             (value specs)
             (slot metadata)))

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
