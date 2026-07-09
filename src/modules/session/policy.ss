;;; Policy Facade Boundary
;;;
;;; This file intentionally exports the stable policy surface only. Concrete
;;; policy object construction, tool grants, reusable families, and permission
;;; projections live in the split submodules so policy users keep one import
;;; path while the implementation stays below the source-owner modularity gate.

(import :poo-flow/src/modules/session/policy-core
        :poo-flow/src/modules/session/policy-tool-grant
        :poo-flow/src/modules/session/policy-families
        :poo-flow/src/modules/session/policy-permissions)

(export
  (import: :poo-flow/src/modules/session/policy-core)
  (import: :poo-flow/src/modules/session/policy-tool-grant)
  (import: :poo-flow/src/modules/session/policy-families)
  (import: :poo-flow/src/modules/session/policy-permissions))
