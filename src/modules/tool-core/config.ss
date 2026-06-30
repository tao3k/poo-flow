;;; -*- Gerbil -*-
;;; Boundary: public facade for tool-core specs and catalog receipts.
;;; Invariant: users author POO tool specs; runtime execution remains external.

(import (only-in :std/sugar filter)
        (only-in :clan/poo/object .o .ref .slot? object? object<-alist)
        :poo-flow/src/module-system/base
        :poo-flow/src/modules/tool-core/objects)

(export (import: :poo-flow/src/modules/tool-core/objects)
        tool-spec
        tool-catalog
        poo-flow-tool-core-poo-spec?
        poo-flow-tool-core-poo-catalog?
        poo-flow-tool-core-poo-spec->tool-spec
        poo-flow-tool-core-poo-catalog->catalog
        poo-flow-tool-core-poo-config-flags
        poo-flow-tool-core-module-bundles)

;; : PooToolSpecPrototype
(def tool-spec
  (object<-alist
   (list
    (cons 'kind +poo-flow-tool-core-spec-kind+)
    (cons 'tool-ref #f)
    (cons 'tool-kind 'custom)
    (cons 'actions '())
    (cons 'input-schema '())
    (cons 'output-schema '())
    (cons 'runtime-owner "marlin-agent-core")
    (cons 'handoff-operation 'tool/custom)
    (cons 'sandbox-required? #f)
    (cons 'sandbox-profile-ref #f)
    (cons 'runtime-backend 'marlin-tool-adapter)
    (cons 'metadata '())
    (cons 'runtime-executed #f))))

;; : PooToolCatalogPrototype
(def tool-catalog
  (.o kind: +poo-flow-tool-core-catalog-kind+
      catalog-ref: 'tool-core/catalog
      tools: '()
      metadata: '()
      runtime-owner: "marlin-agent-core"
      runtime-executed: #f))

;; : (-> POOObject Boolean)
(def (poo-flow-tool-core-poo-spec? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) +poo-flow-tool-core-spec-kind+)))

;; : (-> POOObject Boolean)
(def (poo-flow-tool-core-poo-catalog? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) +poo-flow-tool-core-catalog-kind+)))

;; : (-> PooToolSpecPrototype PooToolSpec)
(def (poo-flow-tool-core-poo-spec->tool-spec spec)
  (poo-flow-tool-spec
   (.ref spec 'tool-ref)
   (.ref spec 'tool-kind)
   (.ref spec 'actions)
   (.ref spec 'input-schema)
   (.ref spec 'output-schema)
   (.ref spec 'runtime-owner)
   (.ref spec 'handoff-operation)
   (.ref spec 'sandbox-required?)
   (.ref spec 'sandbox-profile-ref)
   (.ref spec 'runtime-backend)
   (.ref spec 'metadata)))

;; : (-> [PooToolSpecPrototype] [PooToolSpec])
(def (poo-flow-tool-core-poo-specs->tool-specs specs)
  (map poo-flow-tool-core-poo-spec->tool-spec specs))

;; : (-> PooToolCatalogPrototype [PooToolSpec] PooToolCatalog)
(def (poo-flow-tool-core-poo-catalog->catalog catalog specs)
  (poo-flow-tool-catalog
   (.ref catalog 'catalog-ref)
   specs
   (.ref catalog 'metadata)))

;; : (-> [POOObject] [POOObject])
(def (poo-flow-tool-core-poo-config-specs prototypes)
  (filter poo-flow-tool-core-poo-spec? prototypes))

;; : (-> [POOObject] [POOObject])
(def (poo-flow-tool-core-poo-config-catalogs prototypes)
  (filter poo-flow-tool-core-poo-catalog? prototypes))

;; : (-> PooToolCatalog [Alist])
(def (poo-flow-tool-core-catalog-manifests catalog)
  (map (lambda (spec)
         (poo-flow-tool-handoff-manifest->alist
          (poo-flow-tool-handoff-manifest
           (string->symbol
            (string-append
             "tool/request/"
             (symbol->string (poo-flow-tool-spec-ref spec))))
           spec)))
       (.ref catalog 'tools)))

;; : (-> [POOObject] Alist [UserModuleFlagEntry])
(def (poo-flow-tool-core-poo-config-flags prototypes user-config)
  (let* ((specs
          (poo-flow-tool-core-poo-specs->tool-specs
           (poo-flow-tool-core-poo-config-specs prototypes)))
         (catalogs (poo-flow-tool-core-poo-config-catalogs prototypes))
         (catalog
          (if (null? catalogs)
            (poo-flow-tool-catalog 'tool-core/user specs)
            (poo-flow-tool-core-poo-catalog->catalog (car catalogs) specs))))
    (list '+catalog
          '+typed-receipts
          '+runtime-manifest
          (cons ':config (list catalog))
          (cons ':tool-catalog catalog)
          (cons ':tool-manifests
                (poo-flow-tool-core-catalog-manifests catalog))
          (cons ':user-config user-config))))

;; : [[PooUserModuleSelection]]
(def poo-flow-tool-core-module-bundles
  (list
   (poo-flow-user-module-bundle
    (session tool-core +catalog +typed-receipts +runtime-manifest))))
