;;; -*- Gerbil -*-
;;; Boundary: public facade for Doom-style profile config, doctor, and presentation.
;;; Invariant: profile objects, diagnostics, and presentations live in leaf owners.

(import :poo-flow/src/module-system/base
        :poo-flow/src/module-system/sandbox-profile-catalog
        :poo-flow/src/module-system/sandbox-backend-capability-catalog
        :poo-flow/src/module-system/workflow-cicd-config
        :poo-flow/src/module-system/loop-engine-config
        :poo-flow/src/module-system/presentation
        :poo-flow/src/module-system/profile-core
        :poo-flow/src/module-system/profile-doctor
        :poo-flow/src/module-system/profile-presentation)

(export (import: :poo-flow/src/module-system/base)
        (import: :poo-flow/src/module-system/sandbox-profile-catalog)
        (import: :poo-flow/src/module-system/sandbox-backend-capability-catalog)
        (import: :poo-flow/src/module-system/workflow-cicd-config)
        (import: :poo-flow/src/module-system/loop-engine-config)
        (import: :poo-flow/src/module-system/presentation)
        poo-flow-user-profile-kind
        poo-flow-user-profile-set-kind
        poo-flow-user-profile-diagnostic-kind
        poo-flow-user-profile-presentation-kind
        poo-flow-user-profile-set-presentation-kind
        poo-flow-user-profile-doctor-report-kind
        poo-flow-user-profile-doctor-presentation-kind
        poo-flow-user-profile-set-doctor-report-kind
        poo-flow-user-profile-set-doctor-presentation-kind
        pooFlowUserProfile
        pooFlowUserProfileSet
        pooFlowUserProfileExtend
        pooFlowDefaultUserSettings
        poo-flow-default-user-setting-keys
        pooFlowUserConfigFromProfile
        pooFlowUserProfileDoctor
        pooFlowUserProfileSetDoctor
        pooFlowUserProfilePresentation
        pooFlowUserProfileSetPresentation
        pooFlowUserProfileDoctorPresentation
        pooFlowUserProfileSetDoctorPresentation
        poo-flow-user-profile-doctor-ok?
        poo-flow-user-profile-set-doctor-ok?
        poo-flow-user-profile?
        poo-flow-user-profile-set?
        poo-flow-user-profile-name
        poo-flow-user-profile-set-name
        poo-flow-user-profile-set-default-profile-name
        poo-flow-user-profile-set-profiles
        poo-flow-user-profile-set-profile-names
        poo-flow-user-profile-set-find-profile
        poo-flow-user-profile-set-default-profile
        poo-flow-user-profile-module-bundles
        poo-flow-user-profile-modules
        poo-flow-user-profile-settings
        poo-flow-user-profile-setting-keys
        poo-flow-user-profile-diagnostics
        poo-flow-user-profile-set-diagnostics
        poo-flow-user-profile-diagnostic->alist)
