;;; -*- Gerbil -*-
;;; Boundary: upstream kernel profile for built-in POO Flow modules.
;;; Invariant: profiles compose kernel modules; no parallel registry owns rows.

(import (only-in :poo-flow/src/module-system/base
                 poo-flow-settings)
        (only-in :poo-flow/src/module-system/profile-core
                 pooFlowUserProfile
                 pooFlowUserProfileSet
                 poo-flow-user-profile-modules)
        (only-in :poo-flow/src/module-system/profile-presentation
                 pooFlowUserProfileSetPresentation
                 pooFlowUserProfileSetDoctorPresentation)
        :poo-flow/src/modules/funflow/config
        :poo-flow/src/modules/session-core/config
        :poo-flow/src/modules/loop-governor/config
        :poo-flow/src/modules/docker-sandbox/config
        :poo-flow/src/modules/nono-sandbox/config
        :poo-flow/src/modules/cubeSandbox/config)

(export (import: :poo-flow/src/modules/funflow/config)
        (import: :poo-flow/src/modules/session-core/config)
        (import: :poo-flow/src/modules/loop-governor/config)
        (import: :poo-flow/src/modules/docker-sandbox/config)
        (import: :poo-flow/src/modules/nono-sandbox/config)
        (import: :poo-flow/src/modules/cubeSandbox/config)
        poo-flow-kernel-profile-module-bundles
        poo-flow-kernel-profile
        poo-flow-kernel-profile-set
        poo-flow-kernel-profile-modules
        poo-flow-kernel-profile-set-presentation
        poo-flow-kernel-profile-set-doctor)

;; : (-> Unit [[PooUserModuleSelection]])
(def poo-flow-kernel-profile-module-bundles
  (append
   poo-flow-funflow-module-bundles
   poo-flow-session-core-module-bundles
   poo-flow-loop-governor-module-bundles
   poo-flow-nono-sandbox-module-bundles
   poo-flow-cubeSandbox-module-bundles
   poo-flow-docker-sandbox-module-bundles))

;; : (-> Unit PooUserProfile)
(def poo-flow-kernel-profile
  (pooFlowUserProfile
   'kernel
   poo-flow-kernel-profile-module-bundles
   (poo-flow-settings
    surface: "poo-flow"
    profile: "kernel"
    profile-kind: 'kernel)
   '(surface
     profile
     profile-kind)))

;; : (-> Unit PooUserProfileSet)
(def poo-flow-kernel-profile-set
  (pooFlowUserProfileSet
   'kernel-profiles
   'kernel
   (list poo-flow-kernel-profile)))

;; : (-> Unit [PooUserModuleSelection])
(def poo-flow-kernel-profile-modules
  (poo-flow-user-profile-modules poo-flow-kernel-profile))

;; : (-> Unit POOObject)
(def (poo-flow-kernel-profile-set-presentation)
  (pooFlowUserProfileSetPresentation poo-flow-kernel-profile-set))

;; : (-> Unit POOObject)
(def (poo-flow-kernel-profile-set-doctor)
  (pooFlowUserProfileSetDoctorPresentation poo-flow-kernel-profile-set))
