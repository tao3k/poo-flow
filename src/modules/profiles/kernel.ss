;;; -*- Gerbil -*-
;;; Boundary: upstream kernel profile for built-in POO Flow modules.
;;; Invariant: profiles compose kernel modules; no parallel registry owns rows.

(import :modules/user-config
        :modules/user-config-syntax
        :modules/funflow/config
        :modules/loop-governor/config
        :modules/docker-sandbox/config
        :modules/nono-sandbox/config
        :modules/cubeSandbox/config)

(export (import: :modules/funflow/config)
        (import: :modules/loop-governor/config)
        (import: :modules/docker-sandbox/config)
        (import: :modules/nono-sandbox/config)
        (import: :modules/cubeSandbox/config)
        poo-flow-kernel-profile-module-bundles
        poo-flow-kernel-profile
        poo-flow-kernel-profile-set
        poo-flow-kernel-profile-set-presentation
        poo-flow-kernel-profile-set-doctor
        poo-flow-kernel-profile-modules)

;;; Kernel profile bundles are loaded through profile composition.
;; : (-> Unit [[PooUserModuleSelection]])
(def poo-flow-kernel-profile-module-bundles
  (append
   poo-flow-funflow-module-bundles
   poo-flow-loop-governor-module-bundles
   poo-flow-nono-sandbox-module-bundles
   poo-flow-cubeSandbox-module-bundles
   poo-flow-docker-sandbox-module-bundles))

;;; The kernel profile is inspectable user-profile data, not descriptor activation.
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

;;; Kernel profile set mirrors Doom's profiles.el registry shape while staying
;;; upstream-owned and declarative.
;; : (-> Unit PooUserProfileSet)
(def poo-flow-kernel-profile-set
  (poo-flow-profile-set kernel-profiles
   (default kernel)
   (profiles
    poo-flow-kernel-profile)))

;; : (-> Unit POOObject)
(def (poo-flow-kernel-profile-set-presentation)
  (pooFlowUserProfileSetPresentation poo-flow-kernel-profile-set))

;; : (-> Unit POOObject)
(def (poo-flow-kernel-profile-set-doctor)
  (pooFlowUserProfileSetDoctorPresentation poo-flow-kernel-profile-set))

;; : (-> Unit [PooUserModuleSelection])
(def poo-flow-kernel-profile-modules
  (poo-flow-user-profile-modules poo-flow-kernel-profile))
