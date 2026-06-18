;;; -*- Gerbil -*-
;;; Boundary: user-owned module enablement for POO Flow.
;;; Invariant: this file only chooses module groups, module ids, and flags.

(import :modules/module-system)

(export poo-user-modules)

;; [PooUserModuleSelection] <- Unit
(def poo-user-modules
  (list (poo-user-module-selection 'flow 'workflow '(+typed-receipts))
        (poo-user-module-selection 'loop 'governor '(+strategy +policy))
        (poo-user-module-selection 'sandbox 'marlin '(+nono +cube +doctor))))
