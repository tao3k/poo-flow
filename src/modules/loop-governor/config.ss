;;; -*- Gerbil -*-
;;; Boundary: loop governor kernel module selection.
;;; Invariant: profile owners compose this row; user-interface does not.

(import :poo-flow/src/module-system/base)

(export poo-flow-loop-governor-module-bundles)

;;; The loop governor module keeps policy/strategy composition enabled.
;; : (-> Unit [[PooUserModuleSelection]])
(def poo-flow-loop-governor-module-bundles
  (list
   (poo-flow-user-module-bundle
    (loop governor +strategy +policy +marlin-handoff +runtime-manifest
          +l1-report))))
