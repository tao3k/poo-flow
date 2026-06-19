;;; -*- Gerbil -*-
;;; Boundary: user-owned custom module body.
;;; Invariant: root init.ss decides whether this module is enabled.

(import :modules/module-system)

(export poo-flow-custom-my-module-entrypoint)

;;; The loader entrypoint is declared by the custom row in root init.ss:
;;; (my-module "./custom/my-module" +private +doctor)
;; : String
(def poo-flow-custom-my-module-entrypoint
  "./custom/my-module/config.ss")
