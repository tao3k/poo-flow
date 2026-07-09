;;; -*- Gerbil -*-
;;; Boundary: user-owned custom module facade.
;;; Invariant: the facade re-exports focused profile/case owners and does not
;;; load every declaration into one compiled aggregate module.

(import :poo-flow/user-interface/custom/my-module/profiles/all
        :poo-flow/user-interface/custom/my-module/cases/cicd-owner
        :poo-flow/user-interface/custom/my-module/cases/loop-engine-owner
        :poo-flow/user-interface/custom/my-module/cases/session-owner
        :poo-flow/user-interface/custom/my-module/cases/runtime-owner
        :poo-flow/user-interface/custom/my-module/cases/durable-owner)

(export (import: :poo-flow/user-interface/custom/my-module/profiles/all)
        (import: :poo-flow/user-interface/custom/my-module/cases/cicd-owner)
        (import: :poo-flow/user-interface/custom/my-module/cases/loop-engine-owner)
        (import: :poo-flow/user-interface/custom/my-module/cases/session-owner)
        (import: :poo-flow/user-interface/custom/my-module/cases/runtime-owner)
        (import: :poo-flow/user-interface/custom/my-module/cases/durable-owner))
