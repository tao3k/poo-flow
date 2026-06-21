;;; -*- Gerbil -*-
;;; Boundary: user profile and doctor facade for the hot-plug config surface.
;;; Invariant: selection/config primitives stay in :poo-flow/src/module-system/base.
;;; Descriptor realization stays in package-root modules.
;;; Intent: keep Doom-style user declarations inspectable before activation.

(import (only-in :clan/poo/object .all-slots .o .ref object?)
        :poo-flow/src/module-system/interface
        :poo-flow/src/module-system/base)

(export (import: :poo-flow/src/module-system/base)
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

;;; User profiles group Doom-style module bundles and settings without crossing
;;; into descriptor realization or runtime activation.
;; : (-> Unit PooFlowUserProfileKind)
(def poo-flow-user-profile-kind
  "poo-flow.modules.user-profile.v1")

;;; Profile sets model Doom's profile registry as declarative data.
;; : (-> Unit PooFlowUserProfileSetKind)
(def poo-flow-user-profile-set-kind
  "poo-flow.modules.user-profile-set.v1")

;;; Profile diagnostics are user-facing doctor facts for profile declarations.
;; : (-> Unit PooFlowUserProfileDiagnosticKind)
(def poo-flow-user-profile-diagnostic-kind
  "poo-flow.modules.user-profile.diagnostic.v1")

;;; Profile presentation ids expose the higher-level user entrypoint shape.
;; : (-> Unit PooFlowUserProfilePresentationKind)
(def poo-flow-user-profile-presentation-kind
  "poo-flow.modules.user-profile.presentation.v1")

;;; Profile set presentations expose selection state without loading profiles.
;; : (-> Unit PooFlowUserProfileSetPresentationKind)
(def poo-flow-user-profile-set-presentation-kind
  "poo-flow.modules.user-profile-set.presentation.v1")

;;; Profile doctor reports are user-facing diagnostics, not activation receipts.
;; : (-> Unit PooFlowUserProfileDoctorReportKind)
(def poo-flow-user-profile-doctor-report-kind
  "poo-flow.modules.user-profile.doctor-report.v1")

;;; Profile doctor presentations mirror Doom-style doctor output for users.
;; : (-> Unit PooFlowUserProfileDoctorPresentationKind)
(def poo-flow-user-profile-doctor-presentation-kind
  "poo-flow.modules.user-profile.doctor.presentation.v1")

;;; Profile set doctor reports validate profile registries before selection.
;; : (-> Unit PooFlowUserProfileSetDoctorReportKind)
(def poo-flow-user-profile-set-doctor-report-kind
  "poo-flow.modules.user-profile-set.doctor-report.v1")

;;; Profile set doctor presentations mirror registry health for downstream UI.
;; : (-> Unit PooFlowUserProfileSetDoctorPresentationKind)
(def poo-flow-user-profile-set-doctor-presentation-kind
  "poo-flow.modules.user-profile-set.doctor.presentation.v1")

;;; Boundary: profile checks keep root user files independent of constructors.
;; : (-> POOObject String Boolean)
(def (poo-flow-user-profile-object-kind? value expected-kind)
  (and (object? value)
       (equal? (.ref value 'kind) expected-kind)))

;; : (-> Alist Symbol Value Value)
(def (poo-flow-user-profile-alist-ref entries key default-value)
  (let (entry (assoc key entries))
    (if entry (cdr entry) default-value)))

;;; Boundary: a user profile is the Doom-style high-level entrypoint; it groups
;;; module bundles, settings, and public setting keys without realizing modules.
;; : (-> Symbol [[PooUserModuleSelection]] POOObject [Symbol] POOObject)
(def (pooFlowUserProfile name module-bundles settings setting-keys)
  (.o kind: poo-flow-user-profile-kind
      profile-name: name
      profile-selection-bundles: module-bundles
      user-settings: settings
      public-setting-keys: setting-keys))

;;; Profile sets are the POO Flow analogue of Doom's profiles.el: a named
;;; registry, a default profile key, and profile objects. No package or runtime
;;; synchronization happens here.
;; : (-> Symbol Symbol [PooUserProfile] POOObject)
(def (pooFlowUserProfileSet set-name default-name profile-list)
  (.o kind: poo-flow-user-profile-set-kind
      profile-set-name: set-name
      default-profile-name: default-name
      user-profiles: profile-list))

;;; Default user settings are upstream-owned so root init.ss can stay close to
;;; Doom's init.el: module activation only, no strategy projection details.
;; : (-> Symbol POOObject)
(def (pooFlowDefaultUserSettings profile-name)
  (poo-flow-settings
   surface: "poo-flow"
   profile: (symbol->string profile-name)
   flow-mode: 'funflow
   loop-strategy: 'governed
   sandbox-policy: 'module-gated
   sandbox-backends: '(nono cube docker)
   mode-lock: "stable"))

;; : [Symbol]
(def poo-flow-default-user-setting-keys
  '(surface
    profile
    flow-mode
    loop-strategy
    sandbox-policy
    sandbox-backends
    mode-lock))

;;; Profile projection is the only adapter from Doom-style profile data into
;;; the stable config object consumed by existing tests and tooling.
;; : (-> PooUserProfile PooUserConfig)
(def (pooFlowUserConfigFromProfile profile)
  (pooFlowUserConfig
   (poo-flow-user-profile-modules profile)
   (poo-flow-user-profile-settings profile)))

;; : (-> PooUserProfileCandidate Boolean)
(def (poo-flow-user-profile? value)
  (poo-flow-user-profile-object-kind? value poo-flow-user-profile-kind))

;; : (-> PooUserProfileSetCandidate Boolean)
(def (poo-flow-user-profile-set? value)
  (poo-flow-user-profile-object-kind? value poo-flow-user-profile-set-kind))

;; : (-> PooUserProfile Symbol)
(def (poo-flow-user-profile-name profile)
  (.ref profile 'profile-name))

;; : (-> PooUserProfileSet Symbol)
(def (poo-flow-user-profile-set-name profile-set)
  (.ref profile-set 'profile-set-name))

;; : (-> PooUserProfileSet Symbol)
(def (poo-flow-user-profile-set-default-profile-name profile-set)
  (.ref profile-set 'default-profile-name))

;; : (-> PooUserProfileSet [PooUserProfile])
(def (poo-flow-user-profile-set-profiles profile-set)
  (.ref profile-set 'user-profiles))

;;; Profile names are registry keys. They are stable user-facing selectors,
;;; matching Doom's profile name role without inheriting its env var machinery.
;; : (-> PooUserProfileSet [Symbol])
(def (poo-flow-user-profile-set-profile-names profile-set)
  (map poo-flow-user-profile-name
       (poo-flow-user-profile-set-profiles profile-set)))

;;; Profile lookup is pure data selection; missing profiles are reported by the
;;; doctor path instead of triggering runtime loading.
;; : (-> Symbol [PooUserProfile] MaybePooUserProfile)
(def (poo-flow-user-profile-set-find-profile/add profile-name profiles)
  (cond
   ((null? profiles) #f)
   ((equal? profile-name (poo-flow-user-profile-name (car profiles))) (car profiles))
   (else
    (poo-flow-user-profile-set-find-profile/add profile-name (cdr profiles)))))

;; : (-> PooUserProfileSet Symbol MaybePooUserProfile)
(def (poo-flow-user-profile-set-find-profile profile-set profile-name)
  (poo-flow-user-profile-set-find-profile/add
   profile-name
   (poo-flow-user-profile-set-profiles profile-set)))

;; : (-> PooUserProfileSet MaybePooUserProfile)
(def (poo-flow-user-profile-set-default-profile profile-set)
  (poo-flow-user-profile-set-find-profile
   profile-set
   (poo-flow-user-profile-set-default-profile-name profile-set)))

;; : (-> PooUserProfile [[PooUserModuleSelection]])
(def (poo-flow-user-profile-module-bundles profile)
  (.ref profile 'profile-selection-bundles))

;; : (-> PooUserProfile [PooUserModuleSelection])
(def (poo-flow-user-profile-modules profile)
  (poo-flow-user-module-bundles->modules
   (poo-flow-user-profile-module-bundles profile)))

;; : (-> PooUserProfile POOObject)
(def (poo-flow-user-profile-settings profile)
  (.ref profile 'user-settings))

;; : (-> PooUserProfile [Symbol])
(def (poo-flow-user-profile-setting-keys profile)
  (.ref profile 'public-setting-keys))

;;; Profile extension is an upstream helper for user init surfaces. Downstream
;;; init.ss files can patch kernel module features or append custom modules
;;; without manually rebuilding config objects. The derived profile receives
;;; user defaults for its own name; kernel settings remain kernel-owned.
;; : (-> Symbol PooUserProfile [[PooUserModuleSelection]] PooUserProfile)
(def (pooFlowUserProfileExtend profile-name base-profile extra-module-bundles)
  (pooFlowUserProfile profile-name
                      (poo-flow-user-module-bundles-extend
                       (poo-flow-user-profile-module-bundles base-profile)
                       extra-module-bundles)
                      (pooFlowDefaultUserSettings profile-name)
                      poo-flow-default-user-setting-keys))

;;; Membership is local to user profile doctor logic so diagnostics do not take
;;; a dependency on descriptor-level diagnostic helpers.
;; : (-> DiagnosticKey [DiagnosticKey] Boolean)
(def (poo-flow-user-profile-member? value values)
  (cond
   ((null? values) #f)
   ((equal? value (car values)) #t)
   (else
    (poo-flow-user-profile-member? value (cdr values)))))

;;; Duplicate detection emits each repeated key once, preserving user-facing
;;; order rather than reporting every repeated occurrence.
;; : (-> [DiagnosticKey] [DiagnosticKey] [DiagnosticKey])
(def (poo-flow-user-profile-duplicate-values/add values emitted)
  (cond
   ((null? values) '())
   ((and (poo-flow-user-profile-member? (car values) (cdr values))
         (not (poo-flow-user-profile-member? (car values) emitted)))
    (cons (car values)
          (poo-flow-user-profile-duplicate-values/add
           (cdr values)
           (cons (car values) emitted))))
   (else
    (poo-flow-user-profile-duplicate-values/add (cdr values) emitted))))

;;; This wrapper keeps callers from knowing about the emitted accumulator.
;; : (-> [DiagnosticKey] [DiagnosticKey])
(def (poo-flow-user-profile-duplicate-values values)
  (poo-flow-user-profile-duplicate-values/add values '()))

;;; Empty bundle indexes are reported rather than rejected because a false
;;; conditional gate is a legitimate Doom-style declaration state.
;; : (-> [[PooUserModuleSelection]] Integer [Integer])
(def (poo-flow-user-profile-empty-bundle-indexes/add bundles index)
  (cond
   ((null? bundles) '())
   ((null? (car bundles))
    (cons index
          (poo-flow-user-profile-empty-bundle-indexes/add
           (cdr bundles)
           (+ index 1))))
   (else
    (poo-flow-user-profile-empty-bundle-indexes/add
     (cdr bundles)
     (+ index 1)))))

;;; User-facing indexes make disabled bundle diagnostics stable and concise.
;; : (-> [[PooUserModuleSelection]] [Integer])
(def (poo-flow-user-profile-empty-bundle-indexes bundles)
  (poo-flow-user-profile-empty-bundle-indexes/add bundles 0))

;;; Setting-key validation uses slot introspection instead of `.ref` so doctor
;;; can report missing user settings without throwing during presentation.
;; : (-> POOObject Symbol Boolean)
(def (poo-flow-user-settings-key-present? settings key)
  (and (object? settings)
       (poo-flow-user-profile-member? key (.all-slots settings))))

;;; Missing keys are accumulated as data because the user profile can still be
;;; presented even when it is not yet valid for activation.
;; : (-> POOObject [Symbol] [Symbol])
(def (poo-flow-user-missing-setting-keys settings setting-keys)
  (cond
   ((null? setting-keys) '())
   ((poo-flow-user-settings-key-present? settings (car setting-keys))
    (poo-flow-user-missing-setting-keys settings (cdr setting-keys)))
   (else
    (cons (car setting-keys)
          (poo-flow-user-missing-setting-keys settings (cdr setting-keys))))))

;;; Profile diagnostics are plain alists so doctor output stays cheap to print.
;; : (-> Symbol Symbol Symbol Alist Alist)
(def (poo-flow-user-profile-diagnostic severity code target detail)
  (list (cons 'kind poo-flow-user-profile-diagnostic-kind)
        (cons 'severity severity)
        (cons 'code code)
        (cons 'target target)
        (cons 'detail detail)))

;;; The alist projection is intentionally identity: profile diagnostics are
;;; already presentation-safe facts and should not require object realization.
;; : (-> PooUserProfileDiagnostic Alist)
(def (poo-flow-user-profile-diagnostic->alist diagnostic)
  diagnostic)

;;; Diagnostic access stays alist-based because profile doctor output is printed
;;; by downstream tools; wrapping dynamic diagnostic details in POO slots makes
;;; the display path depend on object printer behavior rather than data shape.
;; : (-> PooUserProfileDiagnostic Symbol MaybeValue)
(def (poo-flow-user-profile-diagnostic-ref diagnostic key)
  (cond
   ((null? diagnostic) #f)
   ((equal? key (caar diagnostic)) (cdar diagnostic))
   (else
    (poo-flow-user-profile-diagnostic-ref (cdr diagnostic) key))))

;;; A profile with no selected modules is actionable: there is no downstream
;;; activation graph to inspect, so doctor reports it as an error.
;; : (-> PooUserProfile [PooUserProfileDiagnostic])
(def (poo-flow-user-profile-empty-diagnostics profile)
  (if (null? (poo-flow-user-profile-modules profile))
    (list
     (poo-flow-user-profile-diagnostic
      'error
      'empty-profile
      (poo-flow-user-profile-name profile)
      '((message . "profile selects no modules"))))
    '()))

;;; Disabled conditional bundles are informational, matching the expectation
;;; that user configuration may contain machine- or profile-specific branches.
;; : (-> PooUserProfile [PooUserProfileDiagnostic])
(def (poo-flow-user-profile-empty-bundle-diagnostics profile)
  (let ((indexes
         (poo-flow-user-profile-empty-bundle-indexes
          (poo-flow-user-profile-module-bundles profile))))
    (if (null? indexes)
      '()
      (list
       (poo-flow-user-profile-diagnostic
        'info
        'inactive-module-bundle
        (poo-flow-user-profile-name profile)
        (list (cons 'bundle-indexes indexes)
              (cons 'message
                    "empty bundles are usually disabled conditions")))))))

;;; Duplicate module selections are warnings because later descriptor
;;; realization may still choose a merge policy, but users should see them.
;; : (-> PooUserProfile [PooUserProfileDiagnostic])
(def (poo-flow-user-profile-duplicate-module-diagnostics profile)
  (let ((duplicates
         (poo-flow-user-profile-duplicate-values
          (map poo-flow-user-module-selection-key
               (poo-flow-user-profile-modules profile)))))
    (if (null? duplicates)
      '()
      (list
       (poo-flow-user-profile-diagnostic
        'warning
        'duplicate-module-selection
        (poo-flow-user-profile-name profile)
        (list (cons 'module-keys duplicates)))))))

;;; Missing public setting keys are errors: presentation would otherwise need
;;; to read absent slots and fail after the doctor phase.
;; : (-> PooUserProfile [PooUserProfileDiagnostic])
(def (poo-flow-user-profile-missing-setting-diagnostics profile)
  (let ((missing
         (poo-flow-user-missing-setting-keys
          (poo-flow-user-profile-settings profile)
          (poo-flow-user-profile-setting-keys profile))))
    (if (null? missing)
      '()
      (list
       (poo-flow-user-profile-diagnostic
        'error
        'missing-setting-key
        (poo-flow-user-profile-name profile)
        (list (cons 'setting-keys missing)))))))

;;; Empty profile registries are errors because no default profile can be
;;; selected for downstream init-style composition.
;; : (-> PooUserProfileSet [PooUserProfileDiagnostic])
(def (poo-flow-user-profile-set-empty-diagnostics profile-set)
  (if (null? (poo-flow-user-profile-set-profiles profile-set))
    (list
     (poo-flow-user-profile-diagnostic
      'error
      'empty-profile-set
      (poo-flow-user-profile-set-name profile-set)
      '((message . "profile set contains no profiles"))))
    '()))

;;; Duplicate profile names make default selection ambiguous, so the registry
;;; doctor reports them before any profile is projected into config.
;; : (-> PooUserProfileSet [PooUserProfileDiagnostic])
(def (poo-flow-user-profile-set-duplicate-name-diagnostics profile-set)
  (let ((duplicates
         (poo-flow-user-profile-duplicate-values
          (poo-flow-user-profile-set-profile-names profile-set))))
    (if (null? duplicates)
      '()
      (list
       (poo-flow-user-profile-diagnostic
        'error
        'duplicate-profile-name
        (poo-flow-user-profile-set-name profile-set)
        (list (cons 'profile-names duplicates)))))))

;;; Missing defaults are registry errors. This mirrors Doom profile startup:
;;; profile selection is explicit, but the selected profile must exist.
;; : (-> PooUserProfileSet [PooUserProfileDiagnostic])
(def (poo-flow-user-profile-set-missing-default-diagnostics profile-set)
  (if (poo-flow-user-profile-set-default-profile profile-set)
    '()
    (list
     (poo-flow-user-profile-diagnostic
      'error
      'missing-default-profile
      (poo-flow-user-profile-set-name profile-set)
      (list
       (cons 'default-profile
             (poo-flow-user-profile-set-default-profile-name profile-set))
       (cons 'profile-names
             (poo-flow-user-profile-set-profile-names profile-set)))))))

;;; The profile diagnostic set is the user-level analogue of `doom doctor`:
;;; it checks declaration mistakes before module descriptors are realized.
;; : (-> PooUserProfile [PooUserProfileDiagnostic])
(def (poo-flow-user-profile-diagnostics profile)
  (append
   (poo-flow-user-profile-empty-diagnostics profile)
   (poo-flow-user-profile-empty-bundle-diagnostics profile)
   (poo-flow-user-profile-duplicate-module-diagnostics profile)
   (poo-flow-user-profile-missing-setting-diagnostics profile)))

;;; Profile set diagnostics validate the registry layer separately from each
;;; profile's module/settings declaration.
;; : (-> PooUserProfileSet [PooUserProfileDiagnostic])
(def (poo-flow-user-profile-set-diagnostics profile-set)
  (append
   (poo-flow-user-profile-set-empty-diagnostics profile-set)
   (poo-flow-user-profile-set-duplicate-name-diagnostics profile-set)
   (poo-flow-user-profile-set-missing-default-diagnostics profile-set)))

;;; Severity scanning is deliberately independent of diagnostic count: info
;;; diagnostics should remain visible without turning the profile unhealthy.
;; : (-> Symbol [PooUserProfileDiagnostic] Boolean)
(def (poo-flow-user-profile-diagnostics-has-severity? severity diagnostics)
  (cond
   ((null? diagnostics) #f)
   ((eq? severity (poo-flow-user-profile-diagnostic-ref
                   (car diagnostics)
                   'severity))
    #t)
   (else
    (poo-flow-user-profile-diagnostics-has-severity? severity (cdr diagnostics)))))

;;; Status treats inactive conditional bundles as informational: only missing
;;; settings or duplicate selections change the actionable doctor state.
;; : (-> [PooUserProfileDiagnostic] Symbol)
(def (poo-flow-user-profile-diagnostics-status diagnostics)
  (cond
   ((poo-flow-user-profile-diagnostics-has-severity? 'error diagnostics) 'error)
   ((poo-flow-user-profile-diagnostics-has-severity? 'warning diagnostics) 'warning)
   (else 'ok)))

;;; Profile doctor mirrors Doom's user-facing doctor idea: validate the user's
;;; declaration surface before descriptor realization or runtime activation.
;; : (-> PooUserProfile POOObject)
(def (pooFlowUserProfileDoctor profile)
  (let* ((diagnostics (poo-flow-user-profile-diagnostics profile))
         (status (poo-flow-user-profile-diagnostics-status diagnostics)))
    (.o kind: poo-flow-user-profile-doctor-report-kind
        profile-name: (poo-flow-user-profile-name profile)
        doctor-status: status
        doctor-ok: (eq? status 'ok)
        diagnostic-count: (length diagnostics)
        profile-diagnostics: diagnostics
        module-keys:
        (map poo-flow-user-module-selection-key
             (poo-flow-user-profile-modules profile))
        setting-keys: (poo-flow-user-profile-setting-keys profile)
        descriptor-realized?: #f
        runtime-executed: #f)))

;;; Profile set doctor mirrors Doom profile startup checks while staying a pure
;;; declaration receipt. It does not load files, mutate env, or sync packages.
;; : (-> PooUserProfileSet POOObject)
(def (pooFlowUserProfileSetDoctor profile-set)
  (let* ((diagnostics (poo-flow-user-profile-set-diagnostics profile-set))
         (status (poo-flow-user-profile-diagnostics-status diagnostics)))
    (.o kind: poo-flow-user-profile-set-doctor-report-kind
        profile-set-name: (poo-flow-user-profile-set-name profile-set)
        default-profile-name:
        (poo-flow-user-profile-set-default-profile-name profile-set)
        profile-names: (poo-flow-user-profile-set-profile-names profile-set)
        doctor-status: status
        doctor-ok: (eq? status 'ok)
        diagnostic-count: (length diagnostics)
        profile-diagnostics: diagnostics
        descriptor-realized?: #f
        runtime-executed: #f)))

;;; The ok predicate is deliberately report-only so callers can inspect doctor
;;; health without depending on presentation slots or CLI rendering.
;; : (-> PooUserProfileDoctorReport Boolean)
(def (poo-flow-user-profile-doctor-ok? report)
  (.ref report 'doctor-ok))

;; : (-> PooUserProfileSetDoctorReport Boolean)
(def (poo-flow-user-profile-set-doctor-ok? report)
  (.ref report 'doctor-ok))

;;; Profile summaries avoid embedding POO profile objects in presentations.
;; : (-> PooUserProfile Alist)
(def (poo-flow-user-profile-summary->alist profile)
  (list
   (cons 'profile-name (poo-flow-user-profile-name profile))
   (cons 'module-count (length (poo-flow-user-profile-modules profile)))
   (cons 'module-keys
         (map poo-flow-user-module-selection-key
              (poo-flow-user-profile-modules profile)))
   (cons 'module-bundle-count
         (length (poo-flow-user-profile-module-bundles profile)))
   (cons 'setting-keys (poo-flow-user-profile-setting-keys profile))
   (cons 'descriptor-realized? #f)
   (cons 'runtime-executed #f)))

;;; Profile presentation is the downstream view for the high-level user
;;; entrypoint. It keeps config fields shallow to avoid recursive POO printing.
;; : (-> PooUserProfile POOObject)
(def (pooFlowUserProfilePresentation profile)
  (let* ((config (pooFlowUserConfigFromProfile profile))
         (config-presentation
          (pooFlowUserConfigPresentation
           config
           (poo-flow-user-profile-setting-keys profile))))
    (.o kind: poo-flow-user-profile-presentation-kind
        profile-name: (poo-flow-user-profile-name profile)
        module-bundle-count: (length (poo-flow-user-profile-module-bundles profile))
        module-count: (.ref config-presentation 'module-count)
        module-keys: (.ref config-presentation 'module-keys)
        modules: (.ref config-presentation 'modules)
        feature-count: (.ref config-presentation 'feature-count)
        feature-facts: (.ref config-presentation 'feature-facts)
        cicd-intent-count: (.ref config-presentation 'cicd-intent-count)
        cicd-intents: (.ref config-presentation 'cicd-intents)
        workflow-cicd-pipeline-count:
        (.ref config-presentation 'workflow-cicd-pipeline-count)
        workflow-cicd-pipelines:
        (.ref config-presentation 'workflow-cicd-pipelines)
        workflow-cicd-runtime-readiness-count:
        (.ref config-presentation 'workflow-cicd-runtime-readiness-count)
        workflow-cicd-runtime-readiness:
        (.ref config-presentation 'workflow-cicd-runtime-readiness)
        workflow-cicd-runtime-command-manifest-map-count:
        (.ref config-presentation
              'workflow-cicd-runtime-command-manifest-map-count)
        workflow-cicd-runtime-command-manifests:
        (.ref config-presentation 'workflow-cicd-runtime-command-manifests)
        workflow-cicd-runtime-command-manifest-summary-count:
        (.ref config-presentation
              'workflow-cicd-runtime-command-manifest-summary-count)
        workflow-cicd-runtime-command-manifest-summaries:
        (.ref config-presentation
              'workflow-cicd-runtime-command-manifest-summaries)
        workflow-cicd-runtime-command-manifest-agreement:
        (.ref config-presentation
              'workflow-cicd-runtime-command-manifest-agreement)
        workflow-cicd-runtime-command-manifest-agreement-valid?:
        (.ref config-presentation
              'workflow-cicd-runtime-command-manifest-agreement-valid?)
        workflow-cicd-runtime-command-manifest-agreement-diagnostics:
        (.ref config-presentation
              'workflow-cicd-runtime-command-manifest-agreement-diagnostics)
        workflow-cicd-marlin-runtime-handoff-abi-count:
        (.ref config-presentation
              'workflow-cicd-marlin-runtime-handoff-abi-count)
        workflow-cicd-marlin-runtime-handoff-abis:
        (.ref config-presentation
              'workflow-cicd-marlin-runtime-handoff-abis)
        workflow-cicd-marlin-runtime-handoff-summary-count:
        (.ref config-presentation
              'workflow-cicd-marlin-runtime-handoff-summary-count)
        workflow-cicd-marlin-runtime-handoff-summaries:
        (.ref config-presentation
              'workflow-cicd-marlin-runtime-handoff-summaries)
        workflow-cicd-receipt-count:
        (.ref config-presentation 'workflow-cicd-receipt-count)
        workflow-cicd-receipts:
        (.ref config-presentation 'workflow-cicd-receipts)
        workflow-cicd-sandbox-runtime-summaries:
        (.ref config-presentation 'workflow-cicd-sandbox-runtime-summaries)
        workflow-cicd-sandbox-handoff-summaries:
        (.ref config-presentation 'workflow-cicd-sandbox-handoff-summaries)
        workflow-cicd-sandbox-unresolved-profile-refs:
        (.ref config-presentation
              'workflow-cicd-sandbox-unresolved-profile-refs)
        loop-engine-intent-count:
        (.ref config-presentation 'loop-engine-intent-count)
        loop-engine-intents: (.ref config-presentation 'loop-engine-intents)
        loop-engine-runtime-handoff-count:
        (.ref config-presentation 'loop-engine-runtime-handoff-count)
        loop-engine-runtime-handoffs:
        (.ref config-presentation 'loop-engine-runtime-handoffs)
        loop-engine-workflow-runs:
        (.ref config-presentation 'loop-engine-workflow-runs)
        loop-engine-dispatch-receipts:
        (.ref config-presentation 'loop-engine-dispatch-receipts)
        loop-engine-agent-operations:
        (.ref config-presentation 'loop-engine-agent-operations)
        loop-engine-runtime-command-manifests:
        (.ref config-presentation 'loop-engine-runtime-command-manifests)
        loop-engine-runtime-command-manifest-summaries:
        (.ref config-presentation
              'loop-engine-runtime-command-manifest-summaries)
        loop-engine-sandbox-runtime-summaries:
        (.ref config-presentation 'loop-engine-sandbox-runtime-summaries)
        loop-engine-sandbox-handoff-summaries:
        (.ref config-presentation 'loop-engine-sandbox-handoff-summaries)
        loop-engine-sandbox-unresolved-profile-refs:
        (.ref config-presentation 'loop-engine-sandbox-unresolved-profile-refs)
        loop-engine-runtime-snapshot-count:
        (.ref config-presentation 'loop-engine-runtime-snapshot-count)
        loop-engine-runtime-snapshots:
        (.ref config-presentation 'loop-engine-runtime-snapshots)
        presentation-trace: (.ref config-presentation 'presentation-trace)
        setting-count: (.ref config-presentation 'setting-count)
        setting-keys: (.ref config-presentation 'setting-keys)
        settings: (.ref config-presentation 'settings)
        config-presentation-kind: (.ref config-presentation 'kind)
        config-module-count: (.ref config-presentation 'module-count)
        user-entrypoints: poo-flow-user-config-public-entrypoints
        api-entrypoints: poo-flow-user-config-api-entrypoints
        boundary: poo-flow-user-config-boundary
        brand-name: poo-flow-brand-name
        brand-group: poo-flow-brand-group
        scheme-owner: poo-flow-scheme-owner
        module-system-owner: poo-flow-module-system-owner
        runtime-owner: "marlin-agent-core"
        descriptor-realized?: #f
        runtime-executed: #f
        replayable: #t)))

;;; Profile set presentation is the inspectable registry view. It keeps the
;;; selected profile shallow and does not trigger descriptor realization.
;; : (-> PooUserProfileSet POOObject)
(def (pooFlowUserProfileSetPresentation profile-set)
  (let ((selected-profile
         (poo-flow-user-profile-set-default-profile profile-set)))
    (.o kind: poo-flow-user-profile-set-presentation-kind
        profile-set-name: (poo-flow-user-profile-set-name profile-set)
        default-profile-name:
        (poo-flow-user-profile-set-default-profile-name profile-set)
        selected-profile-name:
        (if selected-profile
          (poo-flow-user-profile-name selected-profile)
          #f)
        selected-profile?:
        (not (not selected-profile))
        profile-count:
        (length (poo-flow-user-profile-set-profiles profile-set))
        profile-names: (poo-flow-user-profile-set-profile-names profile-set)
        profiles:
        (map poo-flow-user-profile-summary->alist
             (poo-flow-user-profile-set-profiles profile-set))
        user-entrypoints: poo-flow-user-config-public-entrypoints
        api-entrypoints: poo-flow-user-config-api-entrypoints
        boundary: poo-flow-user-config-boundary
        brand-name: poo-flow-brand-name
        brand-group: poo-flow-brand-group
        scheme-owner: poo-flow-scheme-owner
        module-system-owner: poo-flow-module-system-owner
        runtime-owner: "marlin-agent-core"
        package-management?: #f
        dependency-installation?: #f
        descriptor-realized?: #f
        runtime-executed: #f
        replayable: #t)))

;;; Doctor presentation combines high-level profile facts with shallow
;;; diagnostics, keeping the report inspectable for downstream config tooling.
;;; It deliberately avoids full profile presentation so missing settings and
;;; disabled module bundles can still be reported instead of blocking doctor.
;; : (-> PooUserProfile POOObject)
(def (pooFlowUserProfileDoctorPresentation profile)
  (let* ((doctor-report (pooFlowUserProfileDoctor profile))
         (diagnostics (.ref doctor-report 'profile-diagnostics))
         (profile-modules (poo-flow-user-profile-modules profile))
         (feature-fact-rows
          (poo-flow-user-config-feature-facts
           (pooFlowUserConfigFromProfile profile)))
         (cicd-intent-rows
          (poo-flow-user-config-cicd-intents
           (pooFlowUserConfigFromProfile profile)))
         (workflow-cicd-check-maps
          (poo-flow-user-config-workflow-cicd-check-maps
           (pooFlowUserConfigFromProfile profile)))
         (workflow-cicd-readiness-rows
          (poo-flow-user-config-workflow-cicd-runtime-readiness
           (pooFlowUserConfigFromProfile profile)))
         (workflow-cicd-runtime-command-manifest-rows
          (poo-flow-user-config-workflow-cicd-runtime-command-manifests
           (pooFlowUserConfigFromProfile profile)))
         (workflow-cicd-runtime-command-manifest-summary-rows
          (poo-flow-user-workflow-cicd-runtime-command-manifest-summaries
           workflow-cicd-runtime-command-manifest-rows))
         (workflow-cicd-runtime-command-manifest-agreement-report
          (poo-flow-user-workflow-cicd-runtime-command-manifest-agreement
           workflow-cicd-runtime-command-manifest-rows
           workflow-cicd-runtime-command-manifest-summary-rows))
         (workflow-cicd-marlin-runtime-handoff-abi-rows
          (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abis
           workflow-cicd-runtime-command-manifest-rows))
         (workflow-cicd-marlin-runtime-handoff-abi-summary-rows
          (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abi-summaries
           workflow-cicd-marlin-runtime-handoff-abi-rows))
         (workflow-cicd-receipt-rows
          (poo-flow-user-config-workflow-cicd-receipts
           (pooFlowUserConfigFromProfile profile)))
         (workflow-cicd-check-rows
          (poo-flow-user-workflow-cicd-readiness-checks
           workflow-cicd-readiness-rows))
         (loop-engine-intent-rows
          (poo-flow-user-config-loop-engine-intents
           (pooFlowUserConfigFromProfile profile)))
         (public-setting-keys (poo-flow-user-profile-setting-keys profile)))
    (.o kind: poo-flow-user-profile-doctor-presentation-kind
        profile-name: (.ref doctor-report 'profile-name)
        doctor-status: (.ref doctor-report 'doctor-status)
        doctor-ok: (.ref doctor-report 'doctor-ok)
        diagnostic-count: (.ref doctor-report 'diagnostic-count)
        profile-diagnostics: diagnostics
        profile-presentation-kind: poo-flow-user-profile-presentation-kind
        module-bundle-count: (length (poo-flow-user-profile-module-bundles profile))
        module-count: (length profile-modules)
        module-keys: (map poo-flow-user-module-selection-key profile-modules)
        feature-count: (length profile-modules)
        feature-facts: feature-fact-rows
        cicd-intent-count: (length cicd-intent-rows)
        cicd-intents: cicd-intent-rows
        workflow-cicd-runtime-readiness-count:
        (length workflow-cicd-readiness-rows)
        workflow-cicd-runtime-readiness: workflow-cicd-readiness-rows
        workflow-cicd-runtime-command-manifest-map-count:
        (length workflow-cicd-runtime-command-manifest-rows)
        workflow-cicd-runtime-command-manifests:
        workflow-cicd-runtime-command-manifest-rows
        workflow-cicd-runtime-command-manifest-summary-count:
        (length workflow-cicd-runtime-command-manifest-summary-rows)
        workflow-cicd-runtime-command-manifest-summaries:
        workflow-cicd-runtime-command-manifest-summary-rows
        workflow-cicd-runtime-command-manifest-agreement:
        workflow-cicd-runtime-command-manifest-agreement-report
        workflow-cicd-runtime-command-manifest-agreement-valid?:
        (poo-flow-user-profile-alist-ref
         workflow-cicd-runtime-command-manifest-agreement-report
         'valid?
         #f)
        workflow-cicd-runtime-command-manifest-agreement-diagnostics:
        (poo-flow-user-profile-alist-ref
         workflow-cicd-runtime-command-manifest-agreement-report
         'diagnostics
         '())
        workflow-cicd-marlin-runtime-handoff-abi-count:
        (length workflow-cicd-marlin-runtime-handoff-abi-rows)
        workflow-cicd-marlin-runtime-handoff-abis:
        workflow-cicd-marlin-runtime-handoff-abi-rows
        workflow-cicd-marlin-runtime-handoff-summary-count:
        (length workflow-cicd-marlin-runtime-handoff-abi-summary-rows)
        workflow-cicd-marlin-runtime-handoff-summaries:
        workflow-cicd-marlin-runtime-handoff-abi-summary-rows
        workflow-cicd-receipt-count: (length workflow-cicd-receipt-rows)
        workflow-cicd-receipts: workflow-cicd-receipt-rows
        workflow-cicd-sandbox-runtime-summaries:
        (poo-flow-user-workflow-cicd-checks-field-values
         workflow-cicd-check-rows
         'sandbox-runtime-summaries)
        workflow-cicd-sandbox-handoff-summaries:
        (poo-flow-user-workflow-cicd-checks-field-values
         workflow-cicd-check-rows
         'sandbox-handoff-summaries)
        workflow-cicd-sandbox-unresolved-profile-refs:
        (poo-flow-user-workflow-cicd-checks-field-values
         workflow-cicd-check-rows
         'sandbox-unresolved-profile-refs)
        loop-engine-intent-count: (length loop-engine-intent-rows)
        loop-engine-intents: loop-engine-intent-rows
        loop-engine-runtime-handoff-count: (length loop-engine-intent-rows)
        loop-engine-runtime-handoffs:
        (poo-flow-user-loop-engine-intents-field-values
         loop-engine-intent-rows
         'runtime-handoff-facts)
        loop-engine-workflow-runs:
        (poo-flow-user-loop-engine-intents-field-values
         loop-engine-intent-rows
         'workflow-run)
        loop-engine-dispatch-receipts:
        (poo-flow-user-loop-engine-intents-field-values
         loop-engine-intent-rows
         'dispatch-receipt)
        loop-engine-agent-operations:
        (poo-flow-user-loop-engine-intents-field-values
         loop-engine-intent-rows
         'agent-operation)
        loop-engine-runtime-command-manifests:
        (poo-flow-user-loop-engine-intents-field-values
         loop-engine-intent-rows
         'runtime-command-manifest)
        loop-engine-runtime-command-manifest-summaries:
        (poo-flow-user-loop-engine-intents-field-values
         loop-engine-intent-rows
         'runtime-command-manifest-summary)
        loop-engine-runtime-snapshot-count: (length loop-engine-intent-rows)
        loop-engine-runtime-snapshots:
        (poo-flow-user-loop-engine-intents-field-values
         loop-engine-intent-rows
         'runtime-snapshot)
        presentation-trace:
        (poo-flow-user-config-presentation-trace
         profile-modules
         feature-fact-rows
         cicd-intent-rows
         workflow-cicd-check-maps
         workflow-cicd-readiness-rows
         workflow-cicd-runtime-command-manifest-rows
         workflow-cicd-runtime-command-manifest-summary-rows
         workflow-cicd-runtime-command-manifest-agreement-report
         workflow-cicd-marlin-runtime-handoff-abi-rows
         workflow-cicd-receipt-rows
         loop-engine-intent-rows
         public-setting-keys)
        setting-count: (length public-setting-keys)
        setting-keys: public-setting-keys
        user-entrypoints: poo-flow-user-config-public-entrypoints
        api-entrypoints: poo-flow-user-config-api-entrypoints
        boundary: poo-flow-user-config-boundary
        brand-name: poo-flow-brand-name
        brand-group: poo-flow-brand-group
        scheme-owner: poo-flow-scheme-owner
        module-system-owner: poo-flow-module-system-owner
        runtime-owner: "marlin-agent-core"
        package-management?: #f
        dependency-installation?: #f
        descriptor-realized?: #f
        runtime-executed: #f
        replayable: #t)))

;;; Profile set doctor presentation exposes registry health and selected
;;; profile state in one shallow receipt.
;; : (-> PooUserProfileSet POOObject)
(def (pooFlowUserProfileSetDoctorPresentation profile-set)
  (let* ((doctor-report (pooFlowUserProfileSetDoctor profile-set))
         (selected-profile
          (poo-flow-user-profile-set-default-profile profile-set)))
    (.o kind: poo-flow-user-profile-set-doctor-presentation-kind
        profile-set-name: (.ref doctor-report 'profile-set-name)
        default-profile-name: (.ref doctor-report 'default-profile-name)
        selected-profile-name:
        (if selected-profile
          (poo-flow-user-profile-name selected-profile)
          #f)
        selected-profile?:
        (not (not selected-profile))
        doctor-status: (.ref doctor-report 'doctor-status)
        doctor-ok: (.ref doctor-report 'doctor-ok)
        diagnostic-count: (.ref doctor-report 'diagnostic-count)
        profile-diagnostics: (.ref doctor-report 'profile-diagnostics)
        profile-count:
        (length (poo-flow-user-profile-set-profiles profile-set))
        profile-names: (.ref doctor-report 'profile-names)
        user-entrypoints: poo-flow-user-config-public-entrypoints
        api-entrypoints: poo-flow-user-config-api-entrypoints
        boundary: poo-flow-user-config-boundary
        brand-name: poo-flow-brand-name
        brand-group: poo-flow-brand-group
        scheme-owner: poo-flow-scheme-owner
        module-system-owner: poo-flow-module-system-owner
        runtime-owner: "marlin-agent-core"
        package-management?: #f
        dependency-installation?: #f
        descriptor-realized?: #f
        runtime-executed: #f
        replayable: #t)))
