;;; -*- Gerbil -*-
;;; Boundary: nono sandbox kernel module selection.
;;; Invariant: this module declares nono capability flags only.

(import :modules/user-config-base)

(export poo-flow-nono-sandbox-module-bundles)

;;; Nono is a sandbox module row; Marlin remains the runtime owner, not the row.
;; : (-> Unit [[PooUserModuleSelection]])
(def poo-flow-nono-sandbox-module-bundles
  (list
   (poo-flow-user-module-bundle
    (sandbox nono-sandbox +nono +doctor))))
