;;; -*- Gerbil -*-
;;; Boundary: upstream helpers for root user-interface declarations.
;;; Invariant: root user-interface files declare rows; this module projects them.

(import :poo-flow/src/modules/agent-sandbox/config
        :poo-flow/src/modules/profiles/kernel
        :poo-flow/src/modules/user-config
        :poo-flow/src/modules/user-config-syntax
        :poo-flow/src/modules/user-interface/objects)

(export (import: :poo-flow/src/modules/agent-sandbox/config)
        (import: :poo-flow/src/modules/profiles/kernel)
        (import: :poo-flow/src/modules/user-config)
        (import: :poo-flow/src/modules/user-config-syntax)
        (import: :poo-flow/src/modules/user-interface/objects)
        poo-flow-user-interface-profile-name
        poo-flow-user-interface-profile-set-name
        pooFlowUserInterfaceProfile
        pooFlowUserInterfaceProfileSet
        pooFlowUserInterfaceSelectedProfile
        pooFlowUserInterfaceProfileSetPresentation
        pooFlowUserInterfaceProfileSetDoctorPresentation
        pooFlowUserInterfaceModules
        pooFlowUserInterfaceSettings
        pooFlowUserInterfaceSettingKeys
        pooFlowUserInterfaceConfig)

(def poo-flow-user-interface-profile-name 'users)

(def poo-flow-user-interface-profile-set-name 'users)

;; : (-> [[PooUserModuleSelection]] PooUserProfile)
(def (pooFlowUserInterfaceProfile module-bundles)
  (pooFlowUserProfileExtend
   poo-flow-user-interface-profile-name
   poo-flow-kernel-profile
   module-bundles))

;; : (-> PooUserProfile PooUserProfileSet)
(def (pooFlowUserInterfaceProfileSet profile)
  (pooFlowUserProfileSet
   poo-flow-user-interface-profile-set-name
   poo-flow-user-interface-profile-name
   (list profile)))

;; : (-> PooUserProfileSet MaybePooUserProfile)
(def (pooFlowUserInterfaceSelectedProfile profile-set)
  (poo-flow-user-profile-set-default-profile profile-set))

;; : (-> PooUserProfileSet POOObject)
(def (pooFlowUserInterfaceProfileSetPresentation profile-set)
  (pooFlowUserProfileSetPresentation profile-set))

;; : (-> PooUserProfileSet POOObject)
(def (pooFlowUserInterfaceProfileSetDoctorPresentation profile-set)
  (pooFlowUserProfileSetDoctorPresentation profile-set))

;; : (-> PooUserProfile [PooUserModuleSelection])
(def (pooFlowUserInterfaceModules profile)
  (poo-flow-user-profile-modules profile))

;; : (-> PooUserProfile POOObject)
(def (pooFlowUserInterfaceSettings profile)
  (poo-flow-user-profile-settings profile))

;; : (-> PooUserProfile [Symbol])
(def (pooFlowUserInterfaceSettingKeys profile)
  (poo-flow-user-profile-setting-keys profile))

;; : (-> [[PooUserModuleSelection]] PooUserConfig)
(def (pooFlowUserInterfaceConfig module-bundles)
  (pooFlowUserConfigFromProfile
   (pooFlowUserInterfaceProfile module-bundles)))
