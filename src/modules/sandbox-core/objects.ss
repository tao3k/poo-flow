;;; -*- Gerbil -*-
;;; Boundary: sandbox-core object aggregate.
;;; Invariant: sandbox-core is a developer-owned object namespace, not a module row.

(import :poo-flow/src/modules/sandbox-core/profile)

(export (import: :poo-flow/src/modules/sandbox-core/profile)
        poo-flow-sandbox-core-module-objects)

;; : [PooModuleObject]
(def poo-flow-sandbox-core-module-objects
  (list poo-flow-sandbox-core-profile-object))
