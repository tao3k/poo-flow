;;; -*- Gerbil -*-
;;; Boundary: Doom-style profile doctor diagnostics for module-system profiles.
;;; Invariant: diagnostics are data and never realize descriptors or runtimes.

(import (only-in :clan/poo/object .all-slots .o .ref object?)
        :poo-flow/src/module-system/interface
        :poo-flow/src/module-system/base
        :poo-flow/src/module-system/loop-engine-config
        :poo-flow/src/module-system/profile-core
        :poo-flow/src/module-system/projection-syntax)

(export pooFlowUserProfileDoctor
        pooFlowUserProfileSetDoctor
        poo-flow-user-profile-doctor-ok?
        poo-flow-user-profile-set-doctor-ok?
        poo-flow-user-profile-diagnostics
        poo-flow-user-profile-set-diagnostics
        poo-flow-user-profile-diagnostic->alist)

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
(defpoo-module-final-projection
  poo-flow-user-profile-diagnostic (severity code target detail)
  (bindings ())
  (fields ((kind poo-flow-user-profile-diagnostic-kind)
           (severity severity)
           (code code)
           (target target)
           (detail detail))))

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

;;; Loop-engine result contracts are user-authored structured output
;;; expectations. Doctor reports invalid shapes before activation so agents can
;;; repair the profile without waiting for runtime manifest inspection.
;; : (-> PooUserProfile Alist [PooUserProfileDiagnostic])
(def (poo-flow-user-profile-loop-engine-result-contract-diagnostic
      profile
      intent)
  (let* ((result-contract
          (poo-flow-user-profile-alist-ref intent 'result-contract '()))
         (valid?
          (poo-flow-user-profile-alist-ref result-contract 'valid? #t))
         (diagnostic-count
          (poo-flow-user-profile-alist-ref
           result-contract
           'diagnostic-count
           0))
         (diagnostics
          (poo-flow-user-profile-alist-ref
           result-contract
           'diagnostics
           '())))
    (if valid?
      '()
      (list
       (poo-flow-user-profile-diagnostic
        'error
        'invalid-loop-engine-result-contract
        (poo-flow-user-profile-name profile)
        (list
         (cons 'module-key
               (poo-flow-user-profile-alist-ref intent 'key #f))
         (cons 'use-case
               (poo-flow-user-profile-alist-ref intent 'use-case #f))
         (cons 'use-cases
               (poo-flow-user-profile-alist-ref intent 'use-cases '()))
         (cons 'diagnostic-count diagnostic-count)
         (cons 'diagnostics diagnostics)))))))

;;; The fold is deliberately separate from profile declaration diagnostics:
;;; loop-engine checks depend on the config projection but still stay report-only.
;; : (-> PooUserProfile [Alist] [PooUserProfileDiagnostic])
(def (poo-flow-user-profile-loop-engine-result-contract-diagnostics/add
      profile
      intents)
  (cond
   ((null? intents) '())
   (else
    (append
     (poo-flow-user-profile-loop-engine-result-contract-diagnostic
      profile
      (car intents))
     (poo-flow-user-profile-loop-engine-result-contract-diagnostics/add
      profile
      (cdr intents))))))

;; : (-> PooUserProfile [PooUserProfileDiagnostic])
(def (poo-flow-user-profile-loop-engine-result-contract-diagnostics profile)
  (poo-flow-user-profile-loop-engine-result-contract-diagnostics/add
   profile
   (poo-flow-user-config-loop-engine-intents
    (pooFlowUserConfigFromProfile profile))))

;;; Sandbox handoff agreement diagnostics promote unresolved or invalid sandbox
;;; profiles into doctor status while keeping profile projection report-only.
;; : (-> PooUserProfile Alist [PooUserProfileDiagnostic])
(def (poo-flow-user-profile-loop-engine-sandbox-handoff-diagnostic
      profile
      intent)
  (let* ((agreement
          (poo-flow-user-profile-alist-ref
           intent
           'sandbox-handoff-agreement
           '()))
         (valid?
          (poo-flow-user-profile-alist-ref agreement 'valid? #t))
         (diagnostics
          (poo-flow-user-profile-alist-ref agreement 'diagnostics '())))
    (if valid?
      '()
      (list
       (poo-flow-user-profile-diagnostic
        'error
        'invalid-loop-engine-sandbox-handoff
        (poo-flow-user-profile-name profile)
        (list
         (cons 'module-key
               (poo-flow-user-profile-alist-ref intent 'key #f))
         (cons 'use-case
               (poo-flow-user-profile-alist-ref intent 'use-case #f))
         (cons 'use-cases
               (poo-flow-user-profile-alist-ref intent 'use-cases '()))
         (cons 'profile-refs
               (poo-flow-user-profile-alist-ref
                agreement
                'profile-refs
                '()))
         (cons 'unresolved-profile-refs
               (poo-flow-user-profile-alist-ref
                agreement
                'unresolved-profile-refs
                '()))
         (cons 'invalid-runtime-summary-count
               (poo-flow-user-profile-alist-ref
                agreement
                'invalid-runtime-summary-count
                0))
         (cons 'diagnostics diagnostics)))))))

;;; Boundary: user profile loop engine sandbox handoff diagnostics add is the
;;; policy-visible edge for module-system behavior, keeping validation, lookup,
;;; or projection responsibilities centralized for callers.
;; : (-> PooUserProfile [Alist] [PooUserProfileDiagnostic])
(def (poo-flow-user-profile-loop-engine-sandbox-handoff-diagnostics/add
      profile
      intents)
  (cond
   ((null? intents) '())
   (else
    (append
     (poo-flow-user-profile-loop-engine-sandbox-handoff-diagnostic
      profile
      (car intents))
     (poo-flow-user-profile-loop-engine-sandbox-handoff-diagnostics/add
      profile
      (cdr intents))))))

;; : (-> PooUserProfile [PooUserProfileDiagnostic])
(def (poo-flow-user-profile-loop-engine-sandbox-handoff-diagnostics profile)
  (poo-flow-user-profile-loop-engine-sandbox-handoff-diagnostics/add
   profile
   (poo-flow-user-config-loop-engine-intents
    (pooFlowUserConfigFromProfile profile))))

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
   (poo-flow-user-profile-missing-setting-diagnostics profile)
   (poo-flow-user-profile-loop-engine-result-contract-diagnostics profile)
   (poo-flow-user-profile-loop-engine-sandbox-handoff-diagnostics profile)))

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
