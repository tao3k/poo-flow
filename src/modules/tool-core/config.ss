;;; -*- Gerbil -*-
;;; Boundary: public facade for tool-core specs and catalog receipts.
;;; Invariant: users author POO tool specs; runtime execution remains external.

(import (only-in :std/sugar filter)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/base
        :poo-flow/src/module-system/config-prototype-syntax
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
(defpoo-module-config-prototype
  tool-spec
  (slots ((kind +poo-flow-tool-core-spec-kind+)
          (tool-ref #f)
          (tool-kind 'custom)
          (actions '())
          (input-schema '())
          (output-schema '())
          (runtime-owner "marlin-agent-core")
          (handoff-operation 'tool/custom)
          (sandbox-required? #f)
          (sandbox-profile-ref #f)
          (runtime-backend 'marlin-tool-adapter)
          (metadata '())
          (runtime-executed #f))))

;; : PooToolCatalogPrototype
(defpoo-module-config-prototype
  tool-catalog
  (slots ((kind +poo-flow-tool-core-catalog-kind+)
          (catalog-ref 'tool-core/catalog)
          (tools '())
          (metadata '())
          (runtime-owner "marlin-agent-core")
          (runtime-executed #f))))

;; : (-> POOObject Boolean)
(defpoo-module-config-kind-predicate
  poo-flow-tool-core-poo-spec?
  +poo-flow-tool-core-spec-kind+)

;; : (-> POOObject Boolean)
(defpoo-module-config-kind-predicate
  poo-flow-tool-core-poo-catalog?
  +poo-flow-tool-core-catalog-kind+)

;; : (-> PooToolSpecPrototype PooToolSpec)
(defpoo-module-config-converter
  poo-flow-tool-core-poo-spec->tool-spec (spec)
  (constructor poo-flow-tool-spec)
  (arguments (slot tool-ref)
             (slot tool-kind)
             (slot actions)
             (slot input-schema)
             (slot output-schema)
             (slot runtime-owner)
             (slot handoff-operation)
             (slot sandbox-required?)
             (slot sandbox-profile-ref)
             (slot runtime-backend)
             (slot metadata)))

;; : (-> [PooToolSpecPrototype] [PooToolSpec])
(def (poo-flow-tool-core-poo-specs->tool-specs specs)
  (map poo-flow-tool-core-poo-spec->tool-spec specs))

;; : (-> PooToolCatalogPrototype [PooToolSpec] PooToolCatalog)
(defpoo-module-config-converter
  poo-flow-tool-core-poo-catalog->catalog (catalog specs)
  (constructor poo-flow-tool-catalog)
  (arguments (slot catalog-ref)
             (value specs)
             (slot metadata)))

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
