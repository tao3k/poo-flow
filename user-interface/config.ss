;;; -*- Gerbil -*-
;;; Boundary: user-owned POO Flow configuration entrypoint.
;;; Invariant: module realization, validation, and runtime execution stay upstream.

(import :modules/module-system
        :poo-flow/user-interface/modules)

(export (import: :poo-flow/user-interface/modules)
        poo-user-settings
        poo-user-config)

;; POOObject <- Unit
(def poo-user-settings
  (poo-settings
   surface: "poo-flow"
   profile: "developer"
   flow-mode: 'workflow
   loop-strategy: 'governed
   sandbox-policy: 'module-gated
   sandbox-backends: '(nono cube marlin)
   mode-lock: "stable"))

;; PooUserConfig <- Unit
(def poo-user-config
  (pooUserConfig
   poo-user-modules
   poo-user-settings))
