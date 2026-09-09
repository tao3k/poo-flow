;;; -*- Gerbil -*-
;;; Boundary: upstream kernel profile for built-in POO Flow modules.
;;; Invariant: profiles compose kernel modules; no parallel registry owns rows.

(import (only-in :poo-flow/src/module-system/profile-presentation
                 pooFlowUserProfileSetPresentation
                 pooFlowUserProfileSetDoctorPresentation)
        "kernel-core.ss"
        "../../modules/funflow/config.ss"
        "../../modules/poo-method-combination/config.ss"
        "../../modules/session-core/config.ss"
        "../../modules/governor/config.ss"
        "../../modules/docker-sandbox/config.ss"
        "../../modules/nono-sandbox/config.ss"
        "../../modules/cubeSandbox/config.ss")

(export (import: "../../modules/funflow/config.ss")
        (import: "kernel-core.ss")
        (import: "../../modules/poo-method-combination/config.ss")
        (import: "../../modules/session-core/config.ss")
        (import: "../../modules/governor/config.ss")
        (import: "../../modules/docker-sandbox/config.ss")
        (import: "../../modules/nono-sandbox/config.ss")
        (import: "../../modules/cubeSandbox/config.ss")
        poo-flow-kernel-profile-set-presentation
        poo-flow-kernel-profile-set-doctor)

;; : (-> Unit POOObject)
(def (poo-flow-kernel-profile-set-presentation)
  (pooFlowUserProfileSetPresentation poo-flow-kernel-profile-set))

;; : (-> Unit POOObject)
(def (poo-flow-kernel-profile-set-doctor)
  (pooFlowUserProfileSetDoctorPresentation poo-flow-kernel-profile-set))
