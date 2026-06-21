;;; -*- Gerbil -*-
;;; Boundary: module-system helpers for root user declaration profiles.
;;; Invariant: root user-interface files declare rows; this module projects them.

(import :poo-flow/src/modules/agent-sandbox/config
        :poo-flow/src/module-system/profiles/kernel
        :poo-flow/src/module-system/profile-config
        :poo-flow/src/module-system/init-syntax
        :poo-flow/src/module-system/root-objects)

(export (import: :poo-flow/src/modules/agent-sandbox/config)
        (import: :poo-flow/src/module-system/profiles/kernel)
        (import: :poo-flow/src/module-system/profile-config)
        (import: :poo-flow/src/module-system/init-syntax)
        (import: :poo-flow/src/module-system/root-objects)
        poo-flow-root-profile-name
        poo-flow-root-profile-set-name
        pooFlowRootProfile
        pooFlowRootProfileSet
        pooFlowRootSelectedProfile
        pooFlowRootProfileSetPresentation
        pooFlowRootProfileSetDoctorPresentation
        pooFlowRootModules
        pooFlowRootSettings
        pooFlowRootSettingKeys
        pooFlowRootConfig
        pooFlowRootConfigPresentation)

(def poo-flow-root-profile-name 'users)

(def poo-flow-root-profile-set-name 'users)

;; : (-> [[PooUserModuleSelection]] PooUserProfile)
(def (pooFlowRootProfile module-bundles)
  (pooFlowUserProfileExtend
   poo-flow-root-profile-name
   poo-flow-kernel-profile
   module-bundles))

;; : (-> PooUserProfile PooUserProfileSet)
(def (pooFlowRootProfileSet profile)
  (pooFlowUserProfileSet
   poo-flow-root-profile-set-name
   poo-flow-root-profile-name
   (list profile)))

;; : (-> PooUserProfileSet MaybePooUserProfile)
(def (pooFlowRootSelectedProfile profile-set)
  (poo-flow-user-profile-set-default-profile profile-set))

;; : (-> PooUserProfileSet POOObject)
(def (pooFlowRootProfileSetPresentation profile-set)
  (pooFlowUserProfileSetPresentation profile-set))

;; : (-> PooUserProfileSet POOObject)
(def (pooFlowRootProfileSetDoctorPresentation profile-set)
  (pooFlowUserProfileSetDoctorPresentation profile-set))

;; : (-> PooUserProfile [PooUserModuleSelection])
(def (pooFlowRootModules profile)
  (poo-flow-user-profile-modules profile))

;; : (-> PooUserProfile POOObject)
(def (pooFlowRootSettings profile)
  (poo-flow-user-profile-settings profile))

;; : (-> PooUserProfile [Symbol])
(def (pooFlowRootSettingKeys profile)
  (poo-flow-user-profile-setting-keys profile))

;; : (-> [[PooUserModuleSelection]] PooUserConfig)
(def (pooFlowRootConfig module-bundles)
  (pooFlowUserConfigFromProfile
   (pooFlowRootProfile module-bundles)))

;;; Visible payload sent across the root user-interface boundary. It expands
;;; init declarations into the shallow config presentation without descriptor
;;; realization or runtime execution.
;; : (-> [[PooUserModuleSelection]] POOObject)
(def (pooFlowRootConfigPresentation module-bundles)
  (let* ((profile (pooFlowRootProfile module-bundles))
         (config (pooFlowUserConfigFromProfile profile)))
    (pooFlowUserConfigPresentation
     config
     (poo-flow-user-profile-setting-keys profile))))
