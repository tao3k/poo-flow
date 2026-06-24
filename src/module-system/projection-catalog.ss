;;; -*- Gerbil -*-
;;; Boundary: lightweight module value catalog constructors for syntax paths.
;;; Invariant: catalog construction never evaluates modules or loads runtimes.

(import (only-in :clan/poo/object .o)
        :poo-flow/src/module-system/interface)

(export poo-flow-module-catalog
        pooFlowModuleCatalog)

;;; Boundary: value catalog is a user-facing catalog, separate from source catalog.
;; : (-> [PooModuleDescriptor] POOObject)
(def (poo-flow-module-catalog . module-values)
  (.o kind: poo-flow-module-value-catalog-kind
      modules: module-values))

;; : (-> [PooModuleDescriptor] POOObject)
(def (pooFlowModuleCatalog . module-values)
  (apply poo-flow-module-catalog module-values))
