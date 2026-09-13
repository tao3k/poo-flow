;;; -*- Gerbil -*-
;;; Boundary: upstream kernel profile for built-in POO Flow modules.
;;; Invariant: profiles compose kernel modules; no parallel registry owns rows.

(import (only-in :poo-flow/src/user-interface/profile-presentation
                 pooFlowUserProfileSetPresentation
                 pooFlowUserProfileSetDoctorPresentation)
        "core.ss")

(export (import: "core.ss")
        poo-flow-kernel-profile-set-presentation
        poo-flow-kernel-profile-set-doctor)

;; : (-> Unit POOObject)
(def (poo-flow-kernel-profile-set-presentation)
  (pooFlowUserProfileSetPresentation poo-flow-kernel-profile-set))

;; : (-> Unit POOObject)
(def (poo-flow-kernel-profile-set-doctor)
  (pooFlowUserProfileSetDoctorPresentation poo-flow-kernel-profile-set))
