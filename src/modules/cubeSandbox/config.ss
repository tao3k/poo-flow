;;; -*- Gerbil -*-
;;; Boundary: CubeSandbox kernel module selection.
;;; Invariant: this module declares CubeSandbox capability flags only.

(import :modules/user-config-base)

(export poo-flow-cubeSandbox-module-bundles)

;;; CubeSandbox is a sandbox module row; runtime handoff stays outside selection.
;; : (-> Unit [[PooUserModuleSelection]])
(def poo-flow-cubeSandbox-module-bundles
  (list
   (poo-flow-user-module-bundle
    (sandbox cubeSandbox +cube +doctor))))
