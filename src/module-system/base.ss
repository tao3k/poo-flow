;;; -*- Gerbil -*-
;;; Boundary: module-system base facts for hot-plug module selection.
;;; Invariant: this module stays below profile/doctor presentation logic.
;;; Descriptor realization stays in package-root modules.
;;; Intent: keep the downstream surface focused on POO Flow module activation.

(import (only-in :clan/poo/object .o .ref object?)
        (only-in :poo-flow/src/core/agent-harness
                 make-poo-flow-agent-operation
                 make-poo-flow-dispatch-receipt
                 make-poo-flow-runtime-snapshot
                 make-poo-flow-workflow-run
                 poo-flow-agent-operation->alist
                 poo-flow-dispatch-receipt->alist
                 poo-flow-runtime-snapshot->alist
                 poo-flow-workflow-run->alist)
        (only-in :poo-flow/src/core/runtime-adapter
                 +runtime-request-schema+
                 make-stdout-runtime-command-descriptor
                 runtime-command-descriptor->manifest)
        (only-in :poo-flow/src/modules/agent-sandbox/config
                 poo-flow-default-sandbox-profiles
                 poo-flow-sandbox-profile?
                 poo-flow-sandbox-profile-by-name
                 poo-flow-sandbox-profile-handoff-summary
                 poo-flow-sandbox-profile-runtime-summary)
        (only-in :poo-flow/src/modules/workflow/cicd
                 poo-flow-cicd-check-map?
                 poo-flow-cicd-check-map-name
                 poo-flow-cicd-check-map->receipts
                 poo-flow-cicd-check-map->runtime-manifest-readiness
                 poo-flow-cicd-check-map->runtime-command-manifests
                 poo-flow-cicd-runtime-command-manifest-map->marlin-runtime-handoff-abi)
        :poo-flow/src/module-system/interface
        :poo-flow/src/module-system/source
        :poo-flow/src/module-system/observability)

(export poo-flow-user-config-kind
        poo-flow-user-module-selection-kind
        poo-flow-user-config-presentation-kind
        poo-flow-user-config-public-entrypoints
        poo-flow-user-config-api-entrypoints
        poo-flow-user-config-boundary
        pooFlowUserConfig
        pooFlowUserConfigPresentation
        poo-flow-user-config?
        poo-flow-user-config-modules
        poo-flow-user-config-settings
        poo-flow-user-config-module-keys
        poo-flow-user-module-bundles->modules
        poo-flow-user-module-bundles-extend
        poo-flow-user-module-selections-extend
        poo-flow-user-module-selection-extend
        poo-flow-user-module-selection-extend-flags
        poo-flow-user-module-selection->alist
        poo-flow-user-module-selection?
        poo-flow-user-module-selection-key
        poo-flow-user-module-selection-flags
        poo-flow-user-module-selection-source-ref
        poo-flow-user-module-selection-entrypoint
        poo-flow-user-module-selection-has-flag?
        poo-flow-user-module-selection-has-flags?
        poo-flow-user-module-selection-flag-entry
        poo-flow-user-cicd-payload?
        poo-flow-user-cicd-payload-section
        poo-flow-user-module-selection-cicd-intent
        poo-flow-user-config-cicd-intents
        poo-flow-user-module-selection-workflow-cicd-check-map
        poo-flow-user-config-workflow-cicd-check-maps
        poo-flow-user-config-workflow-cicd-runtime-readiness
        poo-flow-user-config-workflow-cicd-runtime-command-manifests
        poo-flow-user-workflow-cicd-runtime-command-manifest-map-manifests
        poo-flow-user-workflow-cicd-runtime-command-manifest-summary
        poo-flow-user-workflow-cicd-runtime-command-manifest-summaries
        poo-flow-user-workflow-cicd-runtime-command-manifest-agreement
        poo-flow-user-config-workflow-cicd-runtime-command-manifest-agreement
        poo-flow-user-workflow-cicd-marlin-runtime-handoff-abis
        poo-flow-user-config-workflow-cicd-marlin-runtime-handoff-abis
        poo-flow-user-workflow-cicd-marlin-runtime-handoff-abi-summary
        poo-flow-user-workflow-cicd-marlin-runtime-handoff-abi-summaries
        poo-flow-user-config-workflow-cicd-receipts
        poo-flow-user-workflow-cicd-readiness-checks
        poo-flow-user-workflow-cicd-checks-field-values
        +poo-flow-user-loop-engine-runtime-command-arguments+
        +poo-flow-user-loop-engine-runtime-command-contract+
        +poo-flow-user-loop-engine-runtime-command-executable+
        +poo-flow-user-loop-engine-runtime-command-name+
        +poo-flow-user-loop-engine-runtime-object-families+
        +poo-flow-user-loop-engine-handoff-contracts+
        poo-flow-user-module-selection-loop-engine-intent
        poo-flow-user-loop-engine-intent-agent-operation
        poo-flow-user-loop-engine-intent-dispatch-receipt
        poo-flow-user-loop-engine-intent-runtime-command-manifest
        poo-flow-user-loop-engine-intent-runtime-command-manifest-summary
        poo-flow-user-loop-engine-intent-runtime-envelope
        poo-flow-user-loop-engine-intent-runtime-handoff-facts
        poo-flow-user-loop-engine-intent-runtime-snapshot
        poo-flow-user-loop-engine-intent-workflow-run
        poo-flow-user-loop-engine-intents-field-values
        poo-flow-user-config-loop-engine-intents
        poo-flow-user-config-presentation-trace
        poo-flow-user-module-selection-feature-fact
        poo-flow-user-module-selection
        poo-flow-user-custom-module-selection
        poo-flow-user-module-selection-feature?
        poo-flow-user-modules-feature?
        poo-flow-user-config-feature?
        poo-flow-user-config-feature-facts
        poo-flow-settings
        poo-flow-modules-system-use-module-group
        poo-flow-modules-system-use-module
        poo-flow-user-module-bundle
        poo-flow-user-module-when)

;;; Boundary: public ids are receipt vocabulary, not runtime owners.
;; : (-> Unit PooFlowUserConfigKind)
(def poo-flow-user-config-kind
  "poo-flow.modules.user-config.v1")

;;; Module selections are user-facing hot-plug facts, so their kind id stays
;;; separate from realized descriptor and module contract ids.
;; : (-> Unit PooFlowUserModuleSelectionKind)
(def poo-flow-user-module-selection-kind
  "poo-flow.modules.user-selection.v1")

;;; Presentation ids are user-facing doctor data, not activation receipts.
;; : (-> Unit PooFlowUserConfigPresentationKind)
(def poo-flow-user-config-presentation-kind
  "poo-flow.modules.user-config.presentation.v1")

;;; Boundary: these names are the manual-facing declaration surface, not an
;;; implementation map. Programmatic constructors stay in the API list below.
;; : (-> Unit [String])
(def poo-flow-user-config-public-entrypoints
  '("poo-flow!"
    "load!"
    "use-module"
    ":workflow"
    "loop-engine"
    ":loop"
    ":sandbox"
    ":custom"
    ":config"
    "profiles"
    "poo-flow-profile"
    "poo-flow-profile-set"
    "poo-flow-profile-extend"
    "poo-flow-sandbox-profile"
    "poo-flow-sandbox-profiles"
    "poo-flow-nono-sandbox-profile"
    "poo-flow-nono-sandbox-profiles"
    "poo-flow-cubeSandbox-profile"
    "poo-flow-cubeSandbox-profiles"
    "poo-flow-docker-sandbox-profile"
    "poo-flow-docker-sandbox-profiles"))

;;; Boundary: these names are the programmatic API exposed for tests, doctors,
;;; presentations, and advanced module code. They should not be required in
;;; everyday init.ss/config.ss files.
;; : (-> Unit [String])
(def poo-flow-user-config-api-entrypoints
  '("poo-flow-module-bundles"
    "poo-flow-custom-module-bundles"
    "poo-flow-init-module-bundles"
    "poo-flow-user-module-selection"
    "poo-flow-user-custom-module-selection"
    "poo-flow-user-module-selection-feature?"
    "poo-flow-user-modules-feature?"
    "poo-flow-user-config-feature?"
    "poo-flow-user-config-feature-facts"
    "poo-flow-user-module-bundle"
    "poo-flow-use-module"
    "poo-flow-user-module-when"
    "poo-flow-settings"
    "poo-flow-sandbox-profile->profile"
    "pooFlowSandboxProfilesPresentation"
    "pooFlowUserProfile"
    "pooFlowUserProfileSet"
    "pooFlowUserProfileExtend"
    "pooFlowUserConfigFromProfile"
    "pooFlowUserConfig"
    "pooFlowUserConfigPresentation"
    "poo-flow-user-workflow-cicd-runtime-command-manifest-agreement"
    "poo-flow-user-config-workflow-cicd-runtime-command-manifest-agreement"
    "poo-flow-user-workflow-cicd-marlin-runtime-handoff-abis"
    "poo-flow-user-config-workflow-cicd-marlin-runtime-handoff-abis"
    "pooFlowUserProfilePresentation"
    "pooFlowUserProfileSetPresentation"
    "pooFlowUserProfileDoctor"
    "pooFlowUserProfileDoctorPresentation"
    "pooFlowUserProfileSetDoctor"
    "pooFlowUserProfileSetDoctorPresentation"))

;;; Boundary: user files own declarations; upstream owns realization and diagnostics.
;; : (-> Unit Alist)
(def poo-flow-user-config-boundary
  '((user-owned . (module-selection settings presentation))
    (module-system-owned . (descriptor-realization validation doctor))
    (package-management . #f)
    (dependency-installation . #f)
    (declarative-module-selection-only . #t)
    (brand-name . "poo-flow")
    (scheme-owner . "poo-flow.scheme")
    (runtime-owner . "marlin-agent-core")
    (runtime-executed . #f)))

;;; Boundary: kind checks keep root user files independent of constructor identity.
;; : (-> POOObject String Boolean)
(def (poo-flow-user-config-object-kind? value expected-kind)
  (and (object? value)
       (equal? (.ref value 'kind) expected-kind)))

;;; Boundary: user modules are hot-plug selections, not descriptors.
;; : (-> Symbol Symbol [Symbol] MaybePooModuleSourceRef MaybePath POOObject)
(def (poo-flow-user-module-selection/source
      group
      module
      flags
      source-ref-value
      entrypoint-value)
  (.o kind: poo-flow-user-module-selection-kind
      user-group: group
      user-module: module
      selection-flags: flags
      source-ref: source-ref-value
      entrypoint: entrypoint-value
      enabled?: #t))

;;; The short constructor is the normal user-facing path for root init rows; it
;;; intentionally leaves source and entrypoint empty until custom modules opt in.
;; : (-> Symbol Symbol [Symbol] POOObject)
(def (poo-flow-user-module-selection group module flags)
  (poo-flow-user-module-selection/source group module flags 'none 'none))

;;; Custom module selections mirror Doom private modules: init.ss selects the
;;; module, and the user-owned directory contributes config.ss as entrypoint.
;; : (-> Symbol Path [Symbol] POOObject)
(def (poo-flow-user-custom-module-selection module module-root-path flags)
  (poo-flow-user-module-selection/source
   'custom
   module
   flags
   (make-poo-flow-module-custom-config-source module-root-path)
   (poo-flow-module-custom-config-entrypoint module-root-path)))

;;; Module-name routing keeps the user DSL on concrete modules such as
;;; `(use-module nono-sandbox ...)`, while the profile data still stores the
;;; canonical group/module key used by feature checks and presentation.
;; : (-> Symbol Symbol)
(def (poo-flow-modules-system-use-module-group module)
  (cond
   ((eq? module 'funflow) 'flow)
   ((eq? module 'loop-engine) 'flow)
   ((eq? module 'governor) 'loop)
   ((or (eq? module 'nono-sandbox)
        (eq? module 'cubeSandbox)
        (eq? module 'docker-sandbox))
    'sandbox)
   (else 'custom)))

;; : (-> Symbol [UserModuleFlagEntry] [PooUserModuleSelection])
(def (poo-flow-modules-system-use-module module flags)
  (list
   (poo-flow-user-module-selection
    (poo-flow-modules-system-use-module-group module)
    module
    flags)))

;;; Doom-style module bundles keep the user surface compact: users write
;;; unquoted group/module/flag symbols, while upstream stores plain data.
;; | UserModuleBundleClause = (Group Module Flag...)
;; poo-flow-user-module-bundle
;;   : (-> UserModuleBundleClause... [PooFlowUserModuleSelection])
;;   | contract: produces user selections only, never descriptors
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-user-module-bundle
;;         (flow workflow +typed-receipts)
;;         (sandbox marlin +nono +cube +doctor))
;;       ;; => selections
;;       ```
;;     %
(defrules poo-flow-user-module-bundle (custom)
  ((_)
   '())
  ((_ (custom module module-root-path flag ...) module-clause ...)
   (cons (poo-flow-user-custom-module-selection
          'module
          module-root-path
          (list 'flag ...))
         (poo-flow-user-module-bundle module-clause ...)))
  ((_ (group module flag ...) module-clause ...)
   (cons (poo-flow-user-module-selection 'group 'module (list 'flag ...))
         (poo-flow-user-module-bundle module-clause ...))))

;;; Conditional module bundles mirror Doom-style feature gates while remaining
;;; ordinary Scheme control flow at the user declaration site.
;; | UserModuleCondition = Boolean
;; poo-flow-user-module-when
;;   : (-> UserModuleCondition UserModuleBundleClause... [PooFlowUserModuleSelection])
;;   | contract: false conditions return an empty selection list
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-user-module-when enable-sandbox?
;;         (sandbox marlin +doctor))
;;       ;; => selections-or-empty
;;       ```
;;     %
(defrules poo-flow-user-module-when ()
  ((_ condition module-clause ...)
   (if condition
     (poo-flow-user-module-bundle module-clause ...)
     '())))

;; : (-> PooUserModuleSelectionCandidate Boolean)
(def (poo-flow-user-module-selection? value)
  (poo-flow-user-config-object-kind? value poo-flow-user-module-selection-kind))

;; : (-> POOObject Pair)
(def (poo-flow-user-module-selection-key selection)
  (cons (.ref selection 'user-group)
        (.ref selection 'user-module)))

;; : (-> POOObject [Symbol])
(def (poo-flow-user-module-selection-flags selection)
  (.ref selection 'selection-flags))

;;; Flag metadata is keyed by the flag symbol so extension profiles can replace
;;; or preserve one logical flag without comparing full metadata payloads.
;; : (-> UserModuleFlagEntry Symbol)
(def (poo-flow-user-module-selection-flag-entry-key entry)
  (if (pair? entry) (car entry) entry))

;;; Membership is scoped to a single selection's flags; it does not inspect
;;; descriptor feature facts or any realized module catalog.
;; : (-> Symbol [UserModuleFlagEntry] Boolean)
(def (poo-flow-user-module-selection-flag-key-member? flag-key flags)
  (cond
   ((null? flags) #f)
   ((equal? flag-key
            (poo-flow-user-module-selection-flag-entry-key (car flags)))
    #t)
   (else
    (poo-flow-user-module-selection-flag-key-member? flag-key (cdr flags)))))

;;; Repeated logical flag keys patch the existing slot in place. This keeps the
;;; kernel order visible while letting user init rows refine nested payloads.
;; : (-> [UserModuleFlagEntry] UserModuleFlagEntry [UserModuleFlagEntry])
(def (poo-flow-user-module-selection-replace-flag flags replacement)
  (cond
   ((null? flags) '())
   ((equal? (poo-flow-user-module-selection-flag-entry-key (car flags))
            (poo-flow-user-module-selection-flag-entry-key replacement))
    (cons replacement (cdr flags)))
   (else
    (cons (car flags)
          (poo-flow-user-module-selection-replace-flag
           (cdr flags)
           replacement)))))

;;; Flag extension appends unseen keys and patches seen keys in place, preserving
;;; the user-facing feature order reported by doctor and presentation output.
;; : (-> [UserModuleFlagEntry] [UserModuleFlagEntry] [UserModuleFlagEntry])
(def (poo-flow-user-module-selection-extend-flags/add normalized extra-flags)
  (cond
   ((null? extra-flags) normalized)
   ((poo-flow-user-module-selection-flag-key-member?
     (poo-flow-user-module-selection-flag-entry-key (car extra-flags))
     normalized)
    (poo-flow-user-module-selection-extend-flags/add
     (poo-flow-user-module-selection-replace-flag normalized (car extra-flags))
     (cdr extra-flags)))
   (else
    (poo-flow-user-module-selection-extend-flags/add
     (append normalized (list (car extra-flags)))
     (cdr extra-flags)))))

;;; Profile extension adds feature flags to an existing module row instead of
;;; creating duplicate user selections for the same `(group . module)` key.
;; : (-> [UserModuleFlagEntry] [UserModuleFlagEntry] [UserModuleFlagEntry])
(def (poo-flow-user-module-selection-extend-flags base-flags extra-flags)
  (poo-flow-user-module-selection-extend-flags/add base-flags extra-flags))

;;; Source and entrypoint metadata remain first-writer-wins so profile
;;; extensions can add flags without silently retargeting user-owned files.
;; : (-> MaybeValue MaybeValue MaybeValue)
(def (poo-flow-user-module-selection-extend-slot base-value extra-value)
  (if (eq? base-value 'none) extra-value base-value))

;;; Selection extension is declaration-layer normalization only; the result is
;;; still a user selection and is not a descriptor or activation closure.
;; : (-> PooUserModuleSelection PooUserModuleSelection PooUserModuleSelection)
(def (poo-flow-user-module-selection-extend base-selection extra-selection)
  (poo-flow-user-module-selection/source
   (.ref base-selection 'user-group)
   (.ref base-selection 'user-module)
   (poo-flow-user-module-selection-extend-flags
    (poo-flow-user-module-selection-flags base-selection)
    (poo-flow-user-module-selection-flags extra-selection))
   (poo-flow-user-module-selection-extend-slot
    (.ref base-selection 'source-ref)
    (.ref extra-selection 'source-ref))
   (poo-flow-user-module-selection-extend-slot
    (.ref base-selection 'entrypoint)
    (.ref extra-selection 'entrypoint))))

;;; A matching `(group . module)` row is updated in place so extension profiles
;;; do not manufacture duplicate-module warnings for intentional flag patches.
;; : (-> [PooUserModuleSelection] PooUserModuleSelection [PooUserModuleSelection])
(def (poo-flow-user-module-selections-extend-one selections extra-selection)
  (cond
   ((null? selections) (list extra-selection))
   ((equal? (poo-flow-user-module-selection-key (car selections))
            (poo-flow-user-module-selection-key extra-selection))
    (cons (poo-flow-user-module-selection-extend (car selections) extra-selection)
          (cdr selections)))
   (else
    (cons (car selections)
          (poo-flow-user-module-selections-extend-one
           (cdr selections)
           extra-selection)))))

;;; The fold is explicit to keep declaration order stable and visible in
;;; downstream presentation receipts.
;; : (-> [PooUserModuleSelection] [PooUserModuleSelection] [PooUserModuleSelection])
(def (poo-flow-user-module-selections-extend/add normalized extra-selections)
  (cond
   ((null? extra-selections) normalized)
   (else
    (poo-flow-user-module-selections-extend/add
     (poo-flow-user-module-selections-extend-one normalized (car extra-selections))
     (cdr extra-selections)))))

;;; Public selection extension stays below profile construction so callers can
;;; normalize bundles without importing profile or doctor presentation logic.
;; : (-> [PooUserModuleSelection] [PooUserModuleSelection] [PooUserModuleSelection])
(def (poo-flow-user-module-selections-extend base-selections extra-selections)
  (poo-flow-user-module-selections-extend/add base-selections extra-selections))

;;; Bundle reconstruction keeps the public profile shape intact after extension
;;; normalization; each normalized selection becomes one declarative bundle row.
;; : (-> [PooUserModuleSelection] [[PooUserModuleSelection]])
(def (poo-flow-user-module-selections->bundles selections)
  (map list selections))

;;; Profile extension produces normalized bundles so user-visible optional flags
;;; can patch kernel modules without surfacing duplicate-module diagnostics.
;; : (-> [[PooUserModuleSelection]] [[PooUserModuleSelection]] [[PooUserModuleSelection]])
(def (poo-flow-user-module-bundles-extend base-bundles extra-bundles)
  (poo-flow-user-module-selections->bundles
   (poo-flow-user-module-selections-extend
    (poo-flow-user-module-bundles->modules base-bundles)
    (poo-flow-user-module-bundles->modules extra-bundles))))

;; : (-> POOObject MaybePooModuleSourceRef)
(def (poo-flow-user-module-selection-source-ref selection)
  (let ((source-ref (.ref selection 'source-ref)))
    (if (eq? source-ref 'none) #f source-ref)))

;; : (-> POOObject MaybePath)
(def (poo-flow-user-module-selection-entrypoint selection)
  (let ((entrypoint (.ref selection 'entrypoint)))
    (if (eq? entrypoint 'none) #f entrypoint)))

;; : (-> UserModuleFlagEntry Symbol Boolean)
(def (poo-flow-user-module-selection-flag-entry? entry flag)
  (or (equal? entry flag)
      (and (pair? entry)
           (equal? (car entry) flag))))

;;; Flag lookup accepts either a bare flag or a pair-shaped flag entry, because
;;; user declarations may attach metadata while predicates still answer yes/no.
;; poo-flow-user-module-selection-has-flag?
;;   : (-> POOObject Symbol Boolean)
;;   | contract: checks declared user-module flags without descriptor realization
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-user-module-selection-has-flag? selection '+doctor)
;;       ;; => #t
;;       ```
;;     %
(def (poo-flow-user-module-selection-has-flag? selection flag)
  (and (find (lambda (entry)
               (poo-flow-user-module-selection-flag-entry? entry flag))
             (poo-flow-user-module-selection-flags selection))
       #t))

;;; Flag entry lookup returns the raw flag payload so nested declarations such
;;; as =(+cicd ...)= can be presented without descriptor realization.
;; : (-> Symbol [UserModuleFlagEntry] MaybeUserModuleFlagEntry)
(def (poo-flow-user-module-selection-flag-entry/find flag flags)
  (cond
   ((null? flags) #f)
   ((poo-flow-user-module-selection-flag-entry? (car flags) flag)
    (car flags))
   (else
    (poo-flow-user-module-selection-flag-entry/find flag (cdr flags)))))

;; : (-> POOObject Symbol MaybeUserModuleFlagEntry)
(def (poo-flow-user-module-selection-flag-entry selection flag)
  (poo-flow-user-module-selection-flag-entry/find
   flag
   (poo-flow-user-module-selection-flags selection)))

;;; User-interface presentation must show the config body the user wrote, not
;;; the resolved backend profile objects used for validation and runtime handoff.
;; : (-> Symbol Boolean)
(def (poo-flow-user-module-selection-presentation-config-flag? flag-key)
  (or (equal? flag-key ':binding)
      (equal? flag-key ':config)
      (equal? flag-key ':user-config)))

;; : (-> [UserModuleFlagEntry] [UserModuleFlagEntry])
(def (poo-flow-user-module-selection-presentation-flags/drop-config flags)
  (cond
   ((null? flags) '())
   ((and (pair? (car flags))
         (poo-flow-user-module-selection-presentation-config-flag?
          (caar flags)))
    (poo-flow-user-module-selection-presentation-flags/drop-config
     (cdr flags)))
   (else
    (cons (car flags)
          (poo-flow-user-module-selection-presentation-flags/drop-config
           (cdr flags))))))

;; : (-> PooUserModuleSelection [UserModuleFlagEntry])
(def (poo-flow-user-module-selection-presentation-flags selection)
  (let* ((flags (poo-flow-user-module-selection-flags selection))
         (user-config-entry
          (poo-flow-user-module-selection-flag-entry/find ':user-config flags)))
    (if (and user-config-entry (pair? user-config-entry))
      (append
       (poo-flow-user-module-selection-presentation-flags/drop-config flags)
       (list (cons ':config (cdr user-config-entry))))
      flags)))

;;; Multiple-flag checks keep callers from reimplementing list scans when they
;;; need to test a declared module mode such as `+strategy +policy`.
;; : (-> POOObject [Symbol] Boolean)
(def (poo-flow-user-module-selection-has-flags? selection flags)
  (cond
   ((null? flags) #t)
   ((poo-flow-user-module-selection-has-flag? selection (car flags))
    (poo-flow-user-module-selection-has-flags? selection (cdr flags)))
   (else #f)))

;;; Boundary: a feature is a selected module plus flags in the user declaration
;;; layer. This mirrors Doom's convenient predicate shape without inheriting
;;; Doom's package or load-cache semantics.
;; : (-> PooUserModuleSelection Symbol Symbol [Symbol] Boolean)
(def (poo-flow-user-module-selection-feature? selection group module flags)
  (and (equal? (poo-flow-user-module-selection-key selection)
               (cons group module))
       (poo-flow-user-module-selection-has-flags? selection flags)))

;;; Module-list feature checks are used by profiles and config projections so
;;; downstream tooling can ask about capabilities without realizing descriptors.
;; : (-> [PooUserModuleSelection] Symbol Symbol Symbol... Boolean)
(def (poo-flow-user-modules-feature? selected-modules group module . flags)
  (cond
   ((null? selected-modules) #f)
   ((poo-flow-user-module-selection-feature? (car selected-modules)
                                             group
                                             module
                                             flags)
    #t)
   (else
    (apply poo-flow-user-modules-feature?
           (cdr selected-modules)
           group
           module
           flags))))

;;; Config-level feature checks are the stable public predicate for user tools;
;;; callers pass declared group/module/flags and receive a pure Boolean fact.
;; : (-> PooUserConfig Symbol Symbol Symbol... Boolean)
(def (poo-flow-user-config-feature? config group module . flags)
  (apply poo-flow-user-modules-feature?
         (poo-flow-user-config-modules config)
         group
         module
         flags))

;;; CI/CD payload predicates recognize the nested flag shape emitted by init.ss.
;;; They avoid descriptor lookup so user tools can inspect declared intent first.
;; : (-> UserCicdPayloadCandidate Boolean)
(def (poo-flow-user-cicd-payload? payload)
  (and (pair? payload)
       (eq? (car payload) '+cicd)))

;;; Payload section reads are deliberately lossy: missing sections become empty
;;; lists, which keeps partial user declarations presentable before validation.
;; : (-> UserCicdPayload Symbol [Symbol])
(def (poo-flow-user-cicd-payload-section payload section)
  (let (entry (assoc section (cdr payload)))
    (if entry (cdr entry) '())))

;;; CI/CD intent facts are user-interface presentation data. They describe the
;;; Funflow vocabulary selected by init.ss and never imply adapter execution.
;; : (-> PooUserModuleSelection MaybeAlist)
(def (poo-flow-user-module-selection-cicd-intent selection)
  (let ((payload
         (poo-flow-user-module-selection-flag-entry selection '+cicd)))
    (if (and (equal? (poo-flow-user-module-selection-key selection)
                     '(flow . funflow))
             (poo-flow-user-cicd-payload? payload))
      (list (cons 'key (poo-flow-user-module-selection-key selection))
            (cons 'feature '+cicd)
            (cons 'checks
                  (poo-flow-user-cicd-payload-section payload 'checks))
            (cons 'artifacts
                  (poo-flow-user-cicd-payload-section payload 'artifacts))
            (cons 'release
                  (poo-flow-user-cicd-payload-section payload 'release))
            (cons 'webhook
                  (poo-flow-user-cicd-payload-section payload 'webhook))
            (cons 'runtime
                  (poo-flow-user-cicd-payload-section payload 'runtime))
            (cons 'runtime-handoff 'runtime-command-manifest)
            (cons 'runtime-owner "marlin-agent-core")
            (cons 'descriptor-realized? #f)
            (cons 'runtime-executed #f))
      #f)))

;;; CI/CD intent accumulation is a report-only filter over selected modules. It
;;; preserves init.ss declaration order and never asks the resolver for descriptors.
;; : (-> [PooUserModuleSelection] [Alist])
(def (poo-flow-user-config-cicd-intents/add selected-modules)
  (cond
   ((null? selected-modules) '())
   ((poo-flow-user-module-selection-cicd-intent (car selected-modules))
    => (lambda (intent)
         (cons intent
               (poo-flow-user-config-cicd-intents/add
                (cdr selected-modules)))))
   (else
    (poo-flow-user-config-cicd-intents/add (cdr selected-modules)))))

;;; Config-level CI/CD intents are the stable downstream presentation surface
;;; for the Bass-inspired Funflow CI/CD payload.
;; : (-> PooUserConfig [Alist])
(def (poo-flow-user-config-cicd-intents config)
  (poo-flow-user-config-cicd-intents/add
   (poo-flow-user-config-modules config)))

;;; Workflow CI/CD check-maps are the typed pipeline objects attached by the
;;; Funflow module. Presentation consumes them, but still performs no runtime
;;; descriptor realization or provider execution.
;; : (-> PooUserModuleSelection MaybePooFlowCicdCheckMap)
(def (poo-flow-user-module-selection-workflow-cicd-check-map selection)
  (let (entry
        (poo-flow-user-module-selection-flag-entry selection ':workflow-pipeline))
    (if (and entry
             (pair? entry)
             (poo-flow-cicd-check-map? (cdr entry)))
      (cdr entry)
      #f)))

;; : (-> [PooUserModuleSelection] [PooFlowCicdCheckMap])
(def (poo-flow-user-config-workflow-cicd-check-maps/add selected-modules)
  (cond
   ((null? selected-modules) '())
   ((poo-flow-user-module-selection-workflow-cicd-check-map
     (car selected-modules))
    => (lambda (check-map)
         (cons check-map
               (poo-flow-user-config-workflow-cicd-check-maps/add
                (cdr selected-modules)))))
   (else
    (poo-flow-user-config-workflow-cicd-check-maps/add
     (cdr selected-modules)))))

;;; Config-level check-map discovery keeps the user interface on the declared
;;; POO object graph: sandbox profile resolution happens against selected
;;; module config plus upstream defaults, not by probing the filesystem.
;; : (-> PooUserConfig [PooFlowCicdCheckMap])
(def (poo-flow-user-config-workflow-cicd-check-maps config)
  (poo-flow-user-config-workflow-cicd-check-maps/add
   (poo-flow-user-config-modules config)))

;; : (-> [PooFlowCicdCheckMap] [PooSandboxProfile] [Alist])
(def (poo-flow-user-workflow-cicd-runtime-readiness/add check-maps
                                                        profile-catalog)
  (cond
   ((null? check-maps) '())
   (else
    (cons
     (poo-flow-cicd-check-map->runtime-manifest-readiness
      (car check-maps)
      profile-catalog)
     (poo-flow-user-workflow-cicd-runtime-readiness/add
      (cdr check-maps)
      profile-catalog)))))

;; : (-> PooUserConfig [Alist])
(def (poo-flow-user-config-workflow-cicd-runtime-readiness config)
  (let* ((selected-modules (poo-flow-user-config-modules config))
         (profile-catalog
          (poo-flow-user-config-sandbox-profile-catalog selected-modules)))
    (poo-flow-user-workflow-cicd-runtime-readiness/add
     (poo-flow-user-config-workflow-cicd-check-maps config)
     profile-catalog)))

;; : (-> [PooFlowCicdCheckMap] [PooSandboxProfile] [Alist])
(def (poo-flow-user-workflow-cicd-runtime-command-manifests/add
      check-maps
      profile-catalog)
  (cond
   ((null? check-maps) '())
   (else
    (cons
     (poo-flow-cicd-check-map->runtime-command-manifests
      (car check-maps)
      profile-catalog)
     (poo-flow-user-workflow-cicd-runtime-command-manifests/add
      (cdr check-maps)
      profile-catalog)))))

;;; Runtime command manifests use the same configured profile catalog as
;;; readiness, so user/project overrides are visible before Marlin consumes the
;;; handoff data.
;; : (-> PooUserConfig [Alist])
(def (poo-flow-user-config-workflow-cicd-runtime-command-manifests config)
  (let* ((selected-modules (poo-flow-user-config-modules config))
         (profile-catalog
          (poo-flow-user-config-sandbox-profile-catalog selected-modules)))
    (poo-flow-user-workflow-cicd-runtime-command-manifests/add
     (poo-flow-user-config-workflow-cicd-check-maps config)
     profile-catalog)))

;;; Manifest maps stay grouped by pipeline in the full presentation; summaries
;;; flatten them only for audit rows, preserving the full map as source data.
;; : (-> [Alist] [Alist])
(def (poo-flow-user-workflow-cicd-runtime-command-manifest-map-manifests
      manifest-maps)
  (cond
   ((null? manifest-maps) '())
   (else
    (append
     (poo-flow-user-alist-ref (car manifest-maps) 'manifests '())
     (poo-flow-user-workflow-cicd-runtime-command-manifest-map-manifests
      (cdr manifest-maps))))))

;;; Compact summaries are the agent-facing audit rows for runtime handoff. The
;;; full manifest remains available, but presentation code and docs can inspect
;;; these rows without traversing nested sandbox summaries.
;; : (-> Alist Alist)
(def (poo-flow-user-workflow-cicd-runtime-command-manifest-summary manifest)
  (let* ((request (poo-flow-user-alist-ref manifest 'request '()))
         (policy (poo-flow-user-alist-ref manifest 'policy '()))
         (unresolved
          (poo-flow-user-alist-ref request
                                   'sandbox-unresolved-profile-refs
                                   '()))
         (handoff-ready (null? unresolved)))
    (list
     (cons 'kind 'workflow-cicd-runtime-command-manifest-summary)
     (cons 'operation
           (poo-flow-user-alist-ref manifest 'operation #f))
     (cons 'request-id
           (poo-flow-user-alist-ref manifest 'request-id #f))
     (cons 'artifact-handle
           (poo-flow-user-alist-ref manifest 'artifact-handle #f))
     (cons 'argv
           (poo-flow-user-alist-ref manifest 'argv '()))
     (cons 'check
           (poo-flow-user-alist-ref request 'check #f))
     (cons 'profile
           (poo-flow-user-alist-ref request 'profile #f))
     (cons 'profile-refs
           (poo-flow-user-alist-ref request 'profile-refs '()))
     (cons 'dependency-refs
           (poo-flow-user-alist-ref request 'dependency-refs '()))
     (cons 'runtime
           (poo-flow-user-alist-ref request 'runtime #f))
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'sandbox-unresolved-profile-refs unresolved)
     (cons 'status (if handoff-ready 'ready 'blocked))
     (cons 'handoff-ready handoff-ready)
     (cons 'handoff-required
           (poo-flow-user-alist-ref policy 'handoff-required #t))
     (cons 'runtime-executed
           (poo-flow-user-alist-ref request 'runtime-executed #f)))))

;; : (-> [Alist] [Alist])
(def (poo-flow-user-workflow-cicd-runtime-command-manifest-summaries
      manifest-maps)
  (map poo-flow-user-workflow-cicd-runtime-command-manifest-summary
       (poo-flow-user-workflow-cicd-runtime-command-manifest-map-manifests
        manifest-maps)))

;; : RuntimeOwnerName
(def +poo-flow-user-workflow-cicd-runtime-owner+ "marlin-agent-core")

;; : (-> [RuntimeExecutedFlag] Boolean)
(def (poo-flow-user-list-all-false? values)
  (cond
   ((null? values) #t)
   ((equal? (car values) #f)
    (poo-flow-user-list-all-false? (cdr values)))
   (else #f)))

;; : (-> [Alist] Value Value [Alist])
(def (poo-flow-user-workflow-cicd-runtime-command-manifest-summaries-for
      summaries
      request-id
      check-name)
  (cond
   ((null? summaries) '())
   ((and (equal? (poo-flow-user-alist-ref (car summaries)
                                          'request-id
                                          #f)
                 request-id)
         (equal? (poo-flow-user-alist-ref (car summaries) 'check #f)
                 check-name))
    (cons
     (car summaries)
     (poo-flow-user-workflow-cicd-runtime-command-manifest-summaries-for
      (cdr summaries)
      request-id
      check-name)))
   (else
    (poo-flow-user-workflow-cicd-runtime-command-manifest-summaries-for
     (cdr summaries)
     request-id
     check-name))))

;; : (-> [Alist] Alist Boolean)
(def (poo-flow-user-workflow-cicd-runtime-command-manifest-summary-has-manifest?
      manifests
      summary)
  (cond
   ((null? manifests) #f)
   (else
    (let* ((manifest (car manifests))
           (request (poo-flow-user-alist-ref manifest 'request '()))
           (request-id (poo-flow-user-alist-ref manifest 'request-id #f))
           (check-name (poo-flow-user-alist-ref request 'check #f)))
      (if (and (equal? (poo-flow-user-alist-ref summary 'request-id #f)
                       request-id)
               (equal? (poo-flow-user-alist-ref summary 'check #f)
                       check-name))
        #t
        (poo-flow-user-workflow-cicd-runtime-command-manifest-summary-has-manifest?
         (cdr manifests)
         summary))))))

;; : (-> [Alist] [Alist] [Symbol])
(def (poo-flow-user-workflow-cicd-runtime-command-manifest-extra-summary-diagnostics
      manifests
      summaries)
  (cond
   ((null? summaries) '())
   ((poo-flow-user-workflow-cicd-runtime-command-manifest-summary-has-manifest?
     manifests
     (car summaries))
    (poo-flow-user-workflow-cicd-runtime-command-manifest-extra-summary-diagnostics
     manifests
     (cdr summaries)))
   (else
    (cons
     'extra-summary
     (poo-flow-user-workflow-cicd-runtime-command-manifest-extra-summary-diagnostics
      manifests
      (cdr summaries))))))

;; : (-> Alist MaybeAlist Integer Alist)
(def (poo-flow-user-workflow-cicd-runtime-command-manifest-agreement-row
      manifest
      summary
      summary-count)
  (let* ((summary-row (if summary summary '()))
         (request (poo-flow-user-alist-ref manifest 'request '()))
         (policy (poo-flow-user-alist-ref manifest 'policy '()))
         (metadata (poo-flow-user-alist-ref manifest 'metadata '()))
         (request-id (poo-flow-user-alist-ref manifest 'request-id #f))
         (check-name (poo-flow-user-alist-ref request 'check #f))
         (manifest-argv (poo-flow-user-alist-ref manifest 'argv '()))
         (request-unresolved
          (poo-flow-user-alist-ref request
                                   'sandbox-unresolved-profile-refs
                                   '()))
         (runtime-executed-values
          (list (poo-flow-user-alist-ref request 'runtime-executed #f)
                (poo-flow-user-alist-ref policy 'runtime-executed #f)
                (poo-flow-user-alist-ref metadata 'runtime-executed #f)))
         (summary-present? (= summary-count 1))
         (check-match?
          (and summary-present?
               (equal? (poo-flow-user-alist-ref summary-row 'request-id #f)
                       request-id)
               (equal? (poo-flow-user-alist-ref summary-row 'check #f)
                       check-name)
               (equal? (poo-flow-user-alist-ref manifest 'name #f)
                       check-name)))
         (argv-match?
          (and summary-present?
               (equal? (poo-flow-user-alist-ref summary-row 'argv '())
                       manifest-argv)))
         (runtime-owner-match?
          (and summary-present?
               (equal? (poo-flow-user-alist-ref summary-row
                                                'runtime-owner
                                                #f)
                       +poo-flow-user-workflow-cicd-runtime-owner+)))
         (unresolved-profile-refs-match?
          (and summary-present?
               (equal? (poo-flow-user-alist-ref
                        summary-row
                        'sandbox-unresolved-profile-refs
                        '())
                       request-unresolved)))
         (runtime-executed-match?
          (and summary-present?
               (poo-flow-user-list-all-false? runtime-executed-values)
               (equal? (poo-flow-user-alist-ref summary-row
                                                'runtime-executed
                                                #t)
                       #f)))
         (diagnostics
          (append
           (cond
            ((= summary-count 1) '())
            ((= summary-count 0) '(missing-summary))
            (else '(duplicate-summary)))
           (if (or (not summary-present?) check-match?)
             '()
             '(check-mismatch))
           (if (or (not summary-present?) argv-match?)
             '()
             '(argv-mismatch))
           (if (or (not summary-present?) runtime-owner-match?)
             '()
             '(runtime-owner-mismatch))
           (if (or (not summary-present?) unresolved-profile-refs-match?)
             '()
             '(unresolved-profile-refs-mismatch))
           (if (or (not summary-present?) runtime-executed-match?)
             '()
             '(runtime-executed-mismatch)))))
    (list
     (cons 'kind
           'workflow-cicd-runtime-command-manifest-agreement-row)
     (cons 'request-id request-id)
     (cons 'check check-name)
     (cons 'manifest? #t)
     (cons 'summary? summary-present?)
     (cons 'summary-count summary-count)
     (cons 'check-match? check-match?)
     (cons 'argv-match? argv-match?)
     (cons 'runtime-owner-match? runtime-owner-match?)
     (cons 'unresolved-profile-refs-match?
           unresolved-profile-refs-match?)
     (cons 'runtime-executed-match? runtime-executed-match?)
     (cons 'runtime-owner
           (poo-flow-user-alist-ref summary-row 'runtime-owner #f))
     (cons 'runtime-executed
           (poo-flow-user-alist-ref summary-row 'runtime-executed #f))
     (cons 'diagnostics diagnostics)
     (cons 'valid? (null? diagnostics)))))

;; : (-> [Alist] [Alist] [Alist])
(def (poo-flow-user-workflow-cicd-runtime-command-manifest-agreement-rows
      manifests
      summaries)
  (cond
   ((null? manifests) '())
   (else
    (let* ((manifest (car manifests))
           (request (poo-flow-user-alist-ref manifest 'request '()))
           (request-id (poo-flow-user-alist-ref manifest 'request-id #f))
           (check-name (poo-flow-user-alist-ref request 'check #f))
           (matching-summaries
            (poo-flow-user-workflow-cicd-runtime-command-manifest-summaries-for
             summaries
             request-id
             check-name)))
      (cons
       (poo-flow-user-workflow-cicd-runtime-command-manifest-agreement-row
        manifest
        (if (null? matching-summaries) #f (car matching-summaries))
        (length matching-summaries))
       (poo-flow-user-workflow-cicd-runtime-command-manifest-agreement-rows
        (cdr manifests)
        summaries))))))

;; : (-> [Alist] [Symbol])
(def (poo-flow-user-workflow-cicd-runtime-command-manifest-agreement-row-diagnostics
      rows)
  (cond
   ((null? rows) '())
   (else
    (append
     (poo-flow-user-alist-ref (car rows) 'diagnostics '())
     (poo-flow-user-workflow-cicd-runtime-command-manifest-agreement-row-diagnostics
      (cdr rows))))))

;;; Agreement validation is the pure contract between the full runtime handoff
;;; payload and compact user/agent audit rows. It checks shape equivalence only;
;;; runtime execution and provider semantics stay outside Scheme.
;; : (-> [Alist] [Alist] Alist)
(def (poo-flow-user-workflow-cicd-runtime-command-manifest-agreement
      manifest-maps
      summaries)
  (let* ((manifests
          (poo-flow-user-workflow-cicd-runtime-command-manifest-map-manifests
           manifest-maps))
         (rows
          (poo-flow-user-workflow-cicd-runtime-command-manifest-agreement-rows
           manifests
           summaries))
         (diagnostics
          (append
           (if (= (length manifests) (length summaries))
             '()
             '(manifest-summary-count-mismatch))
           (poo-flow-user-workflow-cicd-runtime-command-manifest-extra-summary-diagnostics
            manifests
            summaries)
           (poo-flow-user-workflow-cicd-runtime-command-manifest-agreement-row-diagnostics
            rows))))
    (list
     (cons 'kind 'workflow-cicd-runtime-command-manifest-agreement)
     (cons 'manifest-count (length manifests))
     (cons 'summary-count (length summaries))
     (cons 'agreement-count (length rows))
     (cons 'valid? (null? diagnostics))
     (cons 'diagnostics diagnostics)
     (cons 'rows rows)
     (cons 'runtime-owner +poo-flow-user-workflow-cicd-runtime-owner+)
     (cons 'runtime-executed #f))))

;; : (-> PooUserConfig Alist)
(def (poo-flow-user-config-workflow-cicd-runtime-command-manifest-agreement
      config)
  (let* ((manifest-maps
          (poo-flow-user-config-workflow-cicd-runtime-command-manifests
           config))
         (summaries
          (poo-flow-user-workflow-cicd-runtime-command-manifest-summaries
           manifest-maps)))
    (poo-flow-user-workflow-cicd-runtime-command-manifest-agreement
     manifest-maps
     summaries)))

;;; Marlin ABI projections reuse the already validated manifest maps. The user
;;; interface sees a stable handoff payload without learning workflow object
;;; internals or executing any runtime adapter.
;; : (-> [Alist] [Alist])
(def (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abis manifest-maps)
  (map poo-flow-cicd-runtime-command-manifest-map->marlin-runtime-handoff-abi
       manifest-maps))

;; : (-> PooUserConfig [Alist])
(def (poo-flow-user-config-workflow-cicd-marlin-runtime-handoff-abis config)
  (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abis
   (poo-flow-user-config-workflow-cicd-runtime-command-manifests config)))

;;; ABI summaries are the receipt-sized view used by user-interface tests and
;;; handoff diagnostics; they keep the full per-check entries available only in
;;; the ABI payload.
;; : (-> MarlinRuntimeHandoffAbi MarlinRuntimeHandoffAbiSummary)
(def (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abi-summary abi)
  (let ((entries (poo-flow-user-alist-ref abi 'entries '())))
    (list
     (cons 'kind 'workflow-cicd-marlin-runtime-handoff-abi-summary)
     (cons 'schema (poo-flow-user-alist-ref abi 'schema #f))
     (cons 'check-map (poo-flow-user-alist-ref abi 'check-map #f))
     (cons 'runtime-owner
           (poo-flow-user-alist-ref abi 'runtime-owner
                                    +poo-flow-user-workflow-cicd-runtime-owner+))
     (cons 'manifest-count
           (poo-flow-user-alist-ref abi 'manifest-count (length entries)))
     (cons 'entry-count (length entries))
     (cons 'required-fields
           (poo-flow-user-alist-ref abi 'required-fields '()))
     (cons 'handoff-required
           (poo-flow-user-alist-ref abi 'handoff-required #t))
     (cons 'runtime-executed
           (poo-flow-user-alist-ref abi 'runtime-executed #f))
     (cons 'runtime-parses-scheme-source
           (poo-flow-user-alist-ref abi 'runtime-parses-scheme-source #f))
     (cons 'scheme-manufactures-runtime-handlers
           (poo-flow-user-alist-ref
            abi
            'scheme-manufactures-runtime-handlers
            #f)))))

;; : (-> [MarlinRuntimeHandoffAbi] [MarlinRuntimeHandoffAbiSummary])
(def (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abi-summaries
      abi-rows)
  (map poo-flow-user-workflow-cicd-marlin-runtime-handoff-abi-summary
       abi-rows))

;; : (-> [PooFlowCicdCheckMap] [PooSandboxProfile] [Alist])
(def (poo-flow-user-workflow-cicd-receipts/add check-maps profile-catalog)
  (cond
   ((null? check-maps) '())
   (else
    (append
     (poo-flow-cicd-check-map->receipts (car check-maps) profile-catalog)
     (poo-flow-user-workflow-cicd-receipts/add
      (cdr check-maps)
      profile-catalog)))))

;; : (-> PooUserConfig [Alist])
(def (poo-flow-user-config-workflow-cicd-receipts config)
  (let* ((selected-modules (poo-flow-user-config-modules config))
         (profile-catalog
          (poo-flow-user-config-sandbox-profile-catalog selected-modules)))
    (poo-flow-user-workflow-cicd-receipts/add
     (poo-flow-user-config-workflow-cicd-check-maps config)
     profile-catalog)))

;; : (-> Alist Symbol Value Value)
(def (poo-flow-user-alist-ref entries key default-value)
  (let (entry (assoc key entries))
    (if entry (cdr entry) default-value)))

;; : (-> [Alist] [Alist])
(def (poo-flow-user-workflow-cicd-readiness-checks readiness-rows)
  (cond
   ((null? readiness-rows) '())
   (else
    (append
     (poo-flow-user-alist-ref (car readiness-rows) 'checks '())
     (poo-flow-user-workflow-cicd-readiness-checks
      (cdr readiness-rows))))))

;; : (-> [Alist] Symbol [Value])
(def (poo-flow-user-workflow-cicd-checks-field-values checks field)
  (cond
   ((null? checks) '())
   (else
    (append
     (poo-flow-user-alist-ref (car checks) field '())
     (poo-flow-user-workflow-cicd-checks-field-values
      (cdr checks)
      field)))))

;;; Loop-engine sections keep workflow-owned loop configuration visible without
;;; realizing loop descriptors or constructing a runtime request.
;; : (-> PooUserModuleSelection Symbol [Value])
(def (poo-flow-user-loop-engine-section selection section)
  (let (entry (poo-flow-user-module-selection-flag-entry selection section))
    (cond
     ((and entry (pair? entry)) (cdr entry))
     (entry (list entry))
     (else '()))))

;;; Runtime handoff contracts are names, not function pointers. Scheme exposes
;;; the command shape that Rust or another runtime can implement later.
;; : [Symbol]
(def +poo-flow-user-loop-engine-handoff-contracts+
  '(start-workflow-run
    admit-dispatch
    open-agent-session
    execute-agent-operation
    stream-events
    read-runtime-snapshot))

;; : Symbol
(def +poo-flow-user-loop-engine-runtime-command-contract+
  'poo-flow.loop-governor.runtime-command-manifest.v1)

;; : Symbol
(def +poo-flow-user-loop-engine-runtime-command-name+
  'loop-engine-runtime-handoff)

;; : String
(def +poo-flow-user-loop-engine-runtime-command-executable+
  "marlin-agent-core")

;; : [String]
(def +poo-flow-user-loop-engine-runtime-command-arguments+
  '("poo-flow" "runtime" "loop-engine-handoff"))

;; : [Symbol]
(def +poo-flow-user-loop-engine-runtime-object-families+
  '(workflow-run
    dispatch-receipt
    agent-operation
    runtime-snapshot))

;; : (-> Alist Symbol Value Value)
(def (poo-flow-user-loop-engine-intent-ref intent key default-value)
  (let (entry (assoc key intent))
    (if entry (cdr entry) default-value)))

;; : (-> [Value] Symbol Value Value)
(def (poo-flow-user-loop-engine-section-ref entries key default-value)
  (cond
   ((null? entries) default-value)
   ((and (pair? (car entries))
         (equal? (caar entries) key))
    (cdar entries))
   (else
    (poo-flow-user-loop-engine-section-ref (cdr entries) key default-value))))

;; : (-> [Value] [PooSandboxProfile])
(def (poo-flow-user-module-selection-sandbox-profiles/filter values)
  (cond
   ((null? values) '())
   ((poo-flow-sandbox-profile? (car values))
    (cons (car values)
          (poo-flow-user-module-selection-sandbox-profiles/filter
           (cdr values))))
   (else
    (poo-flow-user-module-selection-sandbox-profiles/filter (cdr values)))))

;; : (-> PooUserModuleSelection [PooSandboxProfile])
(def (poo-flow-user-module-selection-sandbox-profiles selection)
  (let (entry (poo-flow-user-module-selection-flag-entry selection ':config))
    (if (and entry (pair? entry))
      (poo-flow-user-module-selection-sandbox-profiles/filter (cdr entry))
      '())))

;; : (-> [PooUserModuleSelection] [PooSandboxProfile])
(def (poo-flow-user-config-sandbox-profile-catalog/add selected-modules)
  (cond
   ((null? selected-modules) '())
   (else
    (append
     (poo-flow-user-module-selection-sandbox-profiles (car selected-modules))
     (poo-flow-user-config-sandbox-profile-catalog/add
      (cdr selected-modules))))))

;;; The catalog includes selected module config first, then upstream defaults.
;;; This lets project/session profiles override names while keeping built-ins
;;; available for simple loop-engine profile refs.
;; : (-> [PooUserModuleSelection] [PooSandboxProfile])
(def (poo-flow-user-config-sandbox-profile-catalog selected-modules)
  (append (poo-flow-user-config-sandbox-profile-catalog/add selected-modules)
          poo-flow-default-sandbox-profiles))

;; : (-> [Value] [Value] Symbol)
(def (poo-flow-user-loop-engine-use-case-name use-case use-cases)
  (cond
   ((and (pair? use-case) (symbol? (car use-case))) (car use-case))
   ((and (pair? use-cases)
         (pair? (car use-cases))
         (symbol? (caar use-cases)))
    (caar use-cases))
   (else 'loop-engine)))

;; : (-> Alist Symbol)
(def (poo-flow-user-loop-engine-intent-use-case-name intent)
  (poo-flow-user-loop-engine-use-case-name
   (poo-flow-user-loop-engine-intent-ref intent 'use-case '())
   (poo-flow-user-loop-engine-intent-ref intent 'use-cases '())))

;; : (-> [Value] [Symbol])
(def (poo-flow-user-loop-engine-use-case-names/add use-cases)
  (cond
   ((null? use-cases) '())
   ((and (pair? (car use-cases))
         (symbol? (caar use-cases)))
    (cons (caar use-cases)
          (poo-flow-user-loop-engine-use-case-names/add (cdr use-cases))))
   (else
    (poo-flow-user-loop-engine-use-case-names/add (cdr use-cases)))))

;; : (-> Alist [Symbol])
(def (poo-flow-user-loop-engine-use-case-names intent)
  (let ((use-case
         (poo-flow-user-loop-engine-intent-ref intent 'use-case '()))
        (use-cases
         (poo-flow-user-loop-engine-intent-ref intent 'use-cases '())))
    (append
     (if (and (pair? use-case) (symbol? (car use-case)))
       (list (car use-case))
       '())
     (poo-flow-user-loop-engine-use-case-names/add use-cases))))

;; : (-> Symbol [Symbol] Boolean)
(def (poo-flow-user-loop-engine-use-case-name? value use-case-names)
  (and (member value use-case-names) #t))

;; : (-> Value [Symbol] MaybeSymbol)
(def (poo-flow-user-loop-engine-sandbox-entry-profile-ref entry use-case-names)
  (cond
   ((symbol? entry) entry)
   ((and (pair? entry)
         (eq? (car entry) 'profile)
         (symbol? (cdr entry)))
    (cdr entry))
   ((and (pair? entry)
         (symbol? (car entry))
         (poo-flow-user-loop-engine-use-case-name? (car entry)
                                                   use-case-names)
         (symbol? (cdr entry)))
    (cdr entry))
   (else #f)))

;; : (-> Symbol [Symbol] Boolean)
(def (poo-flow-user-loop-engine-profile-ref-member? value refs)
  (and (member value refs) #t))

;; : (-> MaybeSymbol [Symbol] [Symbol])
(def (poo-flow-user-loop-engine-profile-ref-add value refs)
  (if (and value
           (not (poo-flow-user-loop-engine-profile-ref-member? value refs)))
    (append refs (list value))
    refs))

;; : (-> [Value] [Symbol] [Symbol] [Symbol])
(def (poo-flow-user-loop-engine-sandbox-profile-refs/add entries
                                                         use-case-names
                                                         refs)
  (cond
   ((null? entries) refs)
   (else
    (poo-flow-user-loop-engine-sandbox-profile-refs/add
     (cdr entries)
     use-case-names
     (poo-flow-user-loop-engine-profile-ref-add
      (poo-flow-user-loop-engine-sandbox-entry-profile-ref
       (car entries)
       use-case-names)
      refs)))))

;; : (-> Alist [Symbol])
(def (poo-flow-user-loop-engine-sandbox-profile-refs intent)
  (poo-flow-user-loop-engine-sandbox-profile-refs/add
   (poo-flow-user-loop-engine-intent-ref intent 'sandbox '())
   (poo-flow-user-loop-engine-use-case-names intent)
   '()))

;; : (-> Symbol [PooSandboxProfile] MaybePooSandboxProfile)
(def (poo-flow-user-loop-engine-sandbox-profile-ref->profile profile-ref
                                                             profile-catalog)
  (poo-flow-sandbox-profile-by-name profile-catalog profile-ref))

;; : (-> Symbol [PooSandboxProfile] MaybeAlist)
(def (poo-flow-user-loop-engine-sandbox-profile-ref->runtime-summary
      profile-ref
      profile-catalog)
  (let (profile
        (poo-flow-user-loop-engine-sandbox-profile-ref->profile
         profile-ref
         profile-catalog))
    (and profile (poo-flow-sandbox-profile-runtime-summary profile))))

;; : (-> Symbol [PooSandboxProfile] MaybeAlist)
(def (poo-flow-user-loop-engine-sandbox-profile-ref->handoff-summary
      profile-ref
      profile-catalog)
  (let (profile
        (poo-flow-user-loop-engine-sandbox-profile-ref->profile
         profile-ref
         profile-catalog))
    (and profile (poo-flow-sandbox-profile-handoff-summary profile))))

;; : (-> [Symbol] [PooSandboxProfile] [Alist])
(def (poo-flow-user-loop-engine-sandbox-runtime-summaries refs profile-catalog)
  (cond
   ((null? refs) '())
   ((poo-flow-user-loop-engine-sandbox-profile-ref->runtime-summary
     (car refs)
     profile-catalog)
    => (lambda (summary)
         (cons summary
               (poo-flow-user-loop-engine-sandbox-runtime-summaries
                (cdr refs)
                profile-catalog))))
   (else
    (poo-flow-user-loop-engine-sandbox-runtime-summaries
     (cdr refs)
     profile-catalog))))

;; : (-> [Symbol] [PooSandboxProfile] [Alist])
(def (poo-flow-user-loop-engine-sandbox-handoff-summaries refs profile-catalog)
  (cond
   ((null? refs) '())
   ((poo-flow-user-loop-engine-sandbox-profile-ref->handoff-summary
     (car refs)
     profile-catalog)
    => (lambda (summary)
         (cons summary
               (poo-flow-user-loop-engine-sandbox-handoff-summaries
                (cdr refs)
                profile-catalog))))
   (else
    (poo-flow-user-loop-engine-sandbox-handoff-summaries
     (cdr refs)
     profile-catalog))))

;; : (-> [Symbol] [PooSandboxProfile] [Symbol])
(def (poo-flow-user-loop-engine-sandbox-unresolved-profile-refs refs
                                                                profile-catalog)
  (cond
   ((null? refs) '())
   ((poo-flow-user-loop-engine-sandbox-profile-ref->profile
     (car refs)
     profile-catalog)
    (poo-flow-user-loop-engine-sandbox-unresolved-profile-refs
     (cdr refs)
     profile-catalog))
   (else
    (cons (car refs)
          (poo-flow-user-loop-engine-sandbox-unresolved-profile-refs
           (cdr refs)
           profile-catalog)))))

;; : (-> Symbol String Symbol)
(def (poo-flow-user-loop-engine-runtime-id use-case-name suffix)
  (string->symbol
   (string-append "loop-engine/"
                  (symbol->string use-case-name)
                  "/"
                  suffix)))

;; : (-> Alist Symbol)
(def (poo-flow-user-loop-engine-intent-workflow-ref intent)
  (let ((workflow-ref
         (poo-flow-user-loop-engine-section-ref
          (poo-flow-user-loop-engine-intent-ref intent 'use-case '())
          'workflow
          #f)))
    (if workflow-ref workflow-ref 'loop-engine)))

;; : (-> [Value] Symbol)
(def (poo-flow-user-loop-engine-primary-agent agent-judges)
  (cond
   ((null? agent-judges) 'loop-governor-agent)
   ((and (pair? (car agent-judges))
         (pair? (cdr (car agent-judges))))
    (cadr (car agent-judges)))
   ((pair? (car agent-judges)) (cdr (car agent-judges)))
   (else (car agent-judges))))

;; : (-> Alist Symbol)
(def (poo-flow-user-loop-engine-intent-status intent)
  (if (null? (poo-flow-user-loop-engine-intent-ref intent 'human-audit '()))
    'admitted
    'waiting-human))

;; : (-> Alist Symbol)
(def (poo-flow-user-loop-engine-intent-operation-kind intent)
  (if (null? (poo-flow-user-loop-engine-intent-ref intent 'human-audit '()))
    'governor-judge
    'human-audit))

;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-runtime-intent intent)
  (list
   (cons 'runtime-handoff
         (poo-flow-user-loop-engine-intent-ref
          intent
          'runtime-handoff
          'loop-governor-marlin-runtime-manifest))
   (cons 'runtime-owner
         (poo-flow-user-loop-engine-intent-ref
          intent
          'runtime-owner
          "marlin-agent-core"))
   (cons 'handoff-contracts +poo-flow-user-loop-engine-handoff-contracts+)
   (cons 'runtime-command-contract
         +poo-flow-user-loop-engine-runtime-command-contract+)
   (cons 'object-families
         +poo-flow-user-loop-engine-runtime-object-families+)
   (cons 'workflow-ref
         (poo-flow-user-loop-engine-intent-workflow-ref intent))
   (cons 'executes-runtime #f)))

;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-policy intent)
  (list
   (cons 'governor
         (poo-flow-user-loop-engine-intent-ref intent 'governor '()))
   (cons 'human-audit
         (poo-flow-user-loop-engine-intent-ref intent 'human-audit '()))
   (cons 'sandbox
         (poo-flow-user-loop-engine-intent-ref intent 'sandbox '()))
   (cons 'sandbox-profile-refs
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-profile-refs
          '()))
   (cons 'sandbox-runtime-summaries
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-runtime-summaries
          '()))
   (cons 'sandbox-handoff-summaries
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-handoff-summaries
          '()))
   (cons 'sandbox-unresolved-profile-refs
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-unresolved-profile-refs
          '()))
   (cons 'budget
         (poo-flow-user-loop-engine-intent-ref intent 'budget '()))
   (cons 'observability
         (poo-flow-user-loop-engine-intent-ref intent 'observability '()))
   (cons 'runtime-executed #f)))

;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-runtime-envelope intent)
  (let ((use-case-name
         (poo-flow-user-loop-engine-intent-use-case-name intent)))
    (list
     (cons 'schema +runtime-request-schema+)
     (cons 'runtime 'manifest)
     (cons 'operation 'loop-engine-handoff)
     (cons 'request-id
           (poo-flow-user-loop-engine-runtime-id use-case-name "request"))
     (cons 'artifact-handle
           (poo-flow-user-loop-engine-runtime-id use-case-name "artifact"))
     (cons 'request
           (list
            (cons 'kind 'loop-engine-runtime-handoff-request)
            (cons 'contract
                  +poo-flow-user-loop-engine-runtime-command-contract+)
            (cons 'runtime-owner "marlin-agent-core")
            (cons 'object-families
                  +poo-flow-user-loop-engine-runtime-object-families+)
            (cons 'use-case
                  (poo-flow-user-loop-engine-intent-ref intent 'use-case '()))
            (cons 'use-cases
                  (poo-flow-user-loop-engine-intent-ref intent 'use-cases '()))
            (cons 'workflow-run
                  (poo-flow-user-loop-engine-intent-workflow-run intent))
            (cons 'dispatch-receipt
                  (poo-flow-user-loop-engine-intent-dispatch-receipt intent))
            (cons 'agent-operation
                  (poo-flow-user-loop-engine-intent-agent-operation intent))
            (cons 'runtime-snapshot
                  (poo-flow-user-loop-engine-intent-runtime-snapshot intent))
            (cons 'sandbox-profile-refs
                  (poo-flow-user-loop-engine-intent-ref
                   intent
                   'sandbox-profile-refs
                   '()))
            (cons 'sandbox-runtime-summaries
                  (poo-flow-user-loop-engine-intent-ref
                   intent
                   'sandbox-runtime-summaries
                   '()))
            (cons 'sandbox-handoff-summaries
                  (poo-flow-user-loop-engine-intent-ref
                   intent
                   'sandbox-handoff-summaries
                   '()))
            (cons 'sandbox-unresolved-profile-refs
                  (poo-flow-user-loop-engine-intent-ref
                   intent
                   'sandbox-unresolved-profile-refs
                   '()))
            (cons 'runtime-executed #f)))
     (cons 'policy
           (poo-flow-user-loop-engine-intent-policy intent))
     (cons 'plan-id
           (poo-flow-user-loop-engine-runtime-id use-case-name "plan"))
     (cons 'node-id
           (poo-flow-user-loop-engine-runtime-id use-case-name "node"))
     (cons 'frontier
           (poo-flow-user-loop-engine-intent-ref intent 'agent-judges '())))))

;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-runtime-command-manifest intent)
  (runtime-command-descriptor->manifest
   (make-stdout-runtime-command-descriptor
    +poo-flow-user-loop-engine-runtime-command-name+
    +poo-flow-user-loop-engine-runtime-command-executable+
    +poo-flow-user-loop-engine-runtime-command-arguments+
    (list
     (cons 'source 'user-config-loop-engine)
     (cons 'contract
           +poo-flow-user-loop-engine-runtime-command-contract+)
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'object-families
           +poo-flow-user-loop-engine-runtime-object-families+)
     (cons 'runtime-executed #f)))
   (poo-flow-user-loop-engine-intent-runtime-envelope intent)))

;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-runtime-command-manifest-summary intent)
  (let ((manifest
         (poo-flow-user-loop-engine-intent-runtime-command-manifest intent)))
    (list
     (cons 'kind 'runtime-command-manifest-summary)
     (cons 'contract +poo-flow-user-loop-engine-runtime-command-contract+)
     (cons 'schema
           (poo-flow-user-loop-engine-intent-ref manifest 'schema #f))
     (cons 'request-schema
           (poo-flow-user-loop-engine-intent-ref manifest 'request-schema #f))
     (cons 'operation
           (poo-flow-user-loop-engine-intent-ref manifest 'operation #f))
     (cons 'request-id
           (poo-flow-user-loop-engine-intent-ref manifest 'request-id #f))
     (cons 'artifact-handle
           (poo-flow-user-loop-engine-intent-ref manifest 'artifact-handle #f))
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'object-families
           +poo-flow-user-loop-engine-runtime-object-families+)
     (cons 'argv
           (poo-flow-user-loop-engine-intent-ref manifest 'argv '()))
     (cons 'runtime-executed #f))))

;;; The workflow-run projection is an admission plan for runtime lowering. It
;;; is not evidence that a workflow has started.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-workflow-run intent)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (run-id
          (poo-flow-user-loop-engine-runtime-id use-case-name "workflow-run")))
    (poo-flow-workflow-run->alist
     (make-poo-flow-workflow-run
      run-id
      (poo-flow-user-loop-engine-intent-workflow-ref intent)
      (list (cons 'use-case
                  (poo-flow-user-loop-engine-intent-ref intent 'use-case '()))
            (cons 'use-cases
                  (poo-flow-user-loop-engine-intent-ref intent 'use-cases '())))
      (poo-flow-user-loop-engine-intent-status intent)
      (poo-flow-user-loop-engine-intent-ref intent 'agent-judges '())
      (list 'loop-engine-events use-case-name)
      '()
      #f
      #f
      #f
      (list (cons 'source 'user-config-loop-engine)
            (cons 'runtime-owner "marlin-agent-core")
            (cons 'runtime-executed #f))))))

;;; Dispatch receipts are projected separately from workflow runs so async
;;; agent input does not pretend to be a terminal workflow result.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-dispatch-receipt intent)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (target-agent
          (poo-flow-user-loop-engine-primary-agent
           (poo-flow-user-loop-engine-intent-ref intent 'agent-judges '()))))
    (poo-flow-dispatch-receipt->alist
     (make-poo-flow-dispatch-receipt
      (poo-flow-user-loop-engine-runtime-id use-case-name "dispatch")
      target-agent
      (poo-flow-user-loop-engine-runtime-id use-case-name "runtime-instance")
      (poo-flow-user-loop-engine-runtime-id use-case-name "session")
      (list 'loop-engine-payload use-case-name)
      #f
      'admitted
      (poo-flow-user-loop-engine-intent-runtime-intent intent)
      (list (cons 'source 'user-config-loop-engine)
            (cons 'runtime-owner "marlin-agent-core")
            (cons 'runtime-executed #f))))))

;;; Agent operations capture the node-level action: governor judge by default,
;;; or human-audit when the user declares a manual loop gate.
;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-agent-operation intent)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (operation-kind
          (poo-flow-user-loop-engine-intent-operation-kind intent)))
    (poo-flow-agent-operation->alist
     (make-poo-flow-agent-operation
      (poo-flow-user-loop-engine-runtime-id use-case-name "operation")
      operation-kind
      (poo-flow-user-loop-engine-runtime-id use-case-name "session")
      (poo-flow-user-loop-engine-runtime-id use-case-name "workflow-run")
      (list (cons 'use-case
                  (poo-flow-user-loop-engine-intent-ref intent 'use-case '()))
            (cons 'governor
                  (poo-flow-user-loop-engine-intent-ref intent 'governor '()))
            (cons 'agent-judges
                  (poo-flow-user-loop-engine-intent-ref intent 'agent-judges '()))
            (cons 'human-audit
                  (poo-flow-user-loop-engine-intent-ref intent 'human-audit '())))
      'poo-flow.loop-governor.node-result.v1
      (poo-flow-user-loop-engine-intent-runtime-intent intent)
      (poo-flow-user-loop-engine-intent-status intent)
      #f
      (list (cons 'source 'user-config-loop-engine)
            (cons 'runtime-owner "marlin-agent-core")
            (cons 'runtime-executed #f))))))

;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-runtime-snapshot intent)
  (let* ((use-case-name
          (poo-flow-user-loop-engine-intent-use-case-name intent))
         (workflow-ref
          (poo-flow-user-loop-engine-intent-workflow-ref intent)))
    (poo-flow-runtime-snapshot->alist
     (make-poo-flow-runtime-snapshot
      'loop-engine
      use-case-name
      (poo-flow-user-loop-engine-intent-status intent)
      #f
      (list (cons 'workflow-ref workflow-ref)
            (cons 'handoff-ready? #t)
            (cons 'runtime-executed #f))
      #f
      '((stage . user-config-loop-engine-runtime-snapshot)
        (runtime-executed . #f))
      (list (cons 'contract 'poo-flow.loop-governor.v1)
            (cons 'runtime-owner "marlin-agent-core"))))))

;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-runtime-handoff-facts intent)
  (list
   (cons 'kind 'loop-engine-runtime-handoff)
   (cons 'contract 'poo-flow.loop-governor.runtime-handoff.v1)
   (cons 'runtime-owner "marlin-agent-core")
   (cons 'runtime-handoff
         (poo-flow-user-loop-engine-intent-ref
          intent
          'runtime-handoff
          'loop-governor-marlin-runtime-manifest))
   (cons 'handoff-contracts +poo-flow-user-loop-engine-handoff-contracts+)
   (cons 'runtime-command-contract
         +poo-flow-user-loop-engine-runtime-command-contract+)
   (cons 'object-families
         +poo-flow-user-loop-engine-runtime-object-families+)
   (cons 'workflow-ref
         (poo-flow-user-loop-engine-intent-workflow-ref intent))
   (cons 'runtime-command-manifest
         (poo-flow-user-loop-engine-intent-runtime-command-manifest intent))
   (cons 'runtime-command-manifest-summary
         (poo-flow-user-loop-engine-intent-runtime-command-manifest-summary
          intent))
   (cons 'sandbox
         (poo-flow-user-loop-engine-intent-ref intent 'sandbox '()))
   (cons 'sandbox-profile-refs
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-profile-refs
          '()))
   (cons 'sandbox-runtime-summaries
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-runtime-summaries
          '()))
   (cons 'sandbox-handoff-summaries
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-handoff-summaries
          '()))
   (cons 'sandbox-unresolved-profile-refs
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-unresolved-profile-refs
          '()))
   (cons 'runtime
         (poo-flow-user-loop-engine-intent-ref intent 'runtime '()))
   (cons 'descriptor-realized? #f)
   (cons 'runtime-executed #f)))

;; : (-> Alist Alist)
(def (poo-flow-user-loop-engine-intent-runtime-projections intent)
  (list
   (cons 'runtime-handoff-contracts
         +poo-flow-user-loop-engine-handoff-contracts+)
   (cons 'runtime-handoff-facts
         (poo-flow-user-loop-engine-intent-runtime-handoff-facts intent))
   (cons 'workflow-run
         (poo-flow-user-loop-engine-intent-workflow-run intent))
   (cons 'dispatch-receipt
         (poo-flow-user-loop-engine-intent-dispatch-receipt intent))
   (cons 'agent-operation
         (poo-flow-user-loop-engine-intent-agent-operation intent))
   (cons 'runtime-command-manifest
         (poo-flow-user-loop-engine-intent-runtime-command-manifest intent))
   (cons 'runtime-command-manifest-summary
         (poo-flow-user-loop-engine-intent-runtime-command-manifest-summary
          intent))
   (cons 'sandbox-runtime-summaries
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-runtime-summaries
          '()))
   (cons 'sandbox-handoff-summaries
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-handoff-summaries
          '()))
   (cons 'sandbox-unresolved-profile-refs
         (poo-flow-user-loop-engine-intent-ref
          intent
          'sandbox-unresolved-profile-refs
          '()))
   (cons 'runtime-snapshot
         (poo-flow-user-loop-engine-intent-runtime-snapshot intent))))

;; : (-> [Alist] Symbol [Value])
(def (poo-flow-user-loop-engine-intents-field-values intents field)
  (cond
   ((null? intents) '())
   (else
    (cons
     (poo-flow-user-loop-engine-intent-ref (car intents) field #f)
     (poo-flow-user-loop-engine-intents-field-values (cdr intents) field)))))

;;; Loop-engine intents are the workflow-facing surface for configuring the
;;; governor node graph from init.ss. The result is report-only contract data.
;; : (-> PooUserModuleSelection [PooSandboxProfile] MaybeAlist)
(def (poo-flow-user-module-selection-loop-engine-intent selection
                                                       . maybe-profile-catalog)
  (if (equal? (poo-flow-user-module-selection-key selection)
              '(flow . loop-engine))
    (let* ((profile-catalog
            (if (null? maybe-profile-catalog)
              poo-flow-default-sandbox-profiles
              (car maybe-profile-catalog)))
           (base-intent
            (list (cons 'key (poo-flow-user-module-selection-key selection))
                  (cons 'feature '+loop-engine)
                  (cons 'workflow-owned? #t)
                  (cons 'governor-derived? #t)
                  (cons 'use-case
                        (poo-flow-user-loop-engine-section selection '+use-case))
                  (cons 'use-cases
                        (poo-flow-user-loop-engine-section selection '+use-cases))
                  (cons 'governor
                        (poo-flow-user-loop-engine-section selection '+governor))
                  (cons 'agent-judges
                        (poo-flow-user-loop-engine-section selection '+agent-judges))
                  (cons 'human-audit
                        (poo-flow-user-loop-engine-section selection '+human-audit))
                  (cons 'schedule
                        (poo-flow-user-loop-engine-section selection '+schedule))
                  (cons 'state
                        (poo-flow-user-loop-engine-section selection '+state))
                  (cons 'sandbox
                        (poo-flow-user-loop-engine-section selection '+sandbox))
                  (cons 'budget
                        (poo-flow-user-loop-engine-section selection '+budget))
                  (cons 'observability
                        (poo-flow-user-loop-engine-section selection '+observability))
                  (cons 'runtime
                        (poo-flow-user-loop-engine-section selection '+runtime))
                  (cons 'contract 'poo-flow.loop-governor.v1)
                  (cons 'node-contract 'poo-flow.loop-governor.node.v1)
                  (cons 'runtime-handoff 'loop-governor-marlin-runtime-manifest)
                  (cons 'runtime-owner "marlin-agent-core")
                  (cons 'descriptor-realized? #f)
                  (cons 'runtime-executed #f)))
           (sandbox-profile-refs
            (poo-flow-user-loop-engine-sandbox-profile-refs base-intent))
           (intent
            (append
             base-intent
             (list
              (cons 'sandbox-profile-refs sandbox-profile-refs)
              (cons 'sandbox-runtime-summaries
                    (poo-flow-user-loop-engine-sandbox-runtime-summaries
                     sandbox-profile-refs
                     profile-catalog))
              (cons 'sandbox-handoff-summaries
                    (poo-flow-user-loop-engine-sandbox-handoff-summaries
                     sandbox-profile-refs
                     profile-catalog))
              (cons 'sandbox-unresolved-profile-refs
                    (poo-flow-user-loop-engine-sandbox-unresolved-profile-refs
                     sandbox-profile-refs
                     profile-catalog))))))
      (append intent
              (poo-flow-user-loop-engine-intent-runtime-projections intent)))
    #f))

;;; Loop engine intents are collected with a recursive add/fold shape so module
;;; selection order becomes the handoff order for later runtime descriptors.
;; : (-> [PooUserModuleSelection] [PooSandboxProfile] [Alist])
(def (poo-flow-user-config-loop-engine-intents/add selected-modules
                                                   profile-catalog)
  (cond
   ((null? selected-modules) '())
   ((poo-flow-user-module-selection-loop-engine-intent (car selected-modules)
                                                       profile-catalog)
    => (lambda (intent)
         (cons intent
               (poo-flow-user-config-loop-engine-intents/add
                (cdr selected-modules)
                profile-catalog))))
   (else
    (poo-flow-user-config-loop-engine-intents/add
     (cdr selected-modules)
     profile-catalog))))

;;; Config-level loop-engine intents let workflow docs and tests show the real
;;; governor configuration result from `:workflow` without starting a loop.
;; : (-> PooUserConfig [Alist])
(def (poo-flow-user-config-loop-engine-intents config)
  (let* ((selected-modules (poo-flow-user-config-modules config))
         (profile-catalog
          (poo-flow-user-config-sandbox-profile-catalog selected-modules)))
    (poo-flow-user-config-loop-engine-intents/add
     selected-modules
     profile-catalog)))

;;; The trace is deterministic and strict. It is the first slot tests should
;;; inspect when a presentation hangs, because it does not call back into POO.
;; : (-> [PooUserModuleSelection] [Alist] [Alist] [PooFlowCicdCheckMap] [Alist] [Alist] [Alist] Alist [Alist] [Alist] [Symbol] [Alist])
(def (poo-flow-user-config-presentation-trace
      selected-modules
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
  (poo-flow-module-presentation-trace
   'user-config-presentation
   (list (cons 'selected-modules (length selected-modules))
         (cons 'feature-facts (length feature-fact-rows))
         (cons 'cicd-intents (length cicd-intent-rows))
         (cons 'workflow-cicd-pipelines
               (length workflow-cicd-check-maps))
         (cons 'workflow-cicd-runtime-readiness
               (length workflow-cicd-readiness-rows))
         (cons 'workflow-cicd-runtime-command-manifest-maps
               (length workflow-cicd-runtime-command-manifest-rows))
         (cons 'workflow-cicd-runtime-command-manifest-summaries
               (length workflow-cicd-runtime-command-manifest-summary-rows))
         (cons 'workflow-cicd-runtime-command-manifest-agreement
               (if (poo-flow-user-alist-ref
                    workflow-cicd-runtime-command-manifest-agreement-report
                    'valid?
                    #f)
                 1
                 0))
         (cons 'workflow-cicd-marlin-runtime-handoff-abis
               (length workflow-cicd-marlin-runtime-handoff-abi-rows))
         (cons 'workflow-cicd-receipts
               (length workflow-cicd-receipt-rows))
         (cons 'loop-engine-intents (length loop-engine-intent-rows))
         (cons 'settings (length public-setting-keys)))))

;;; Boundary: indexed feature facts preserve init.ss declaration order for help
;;; and doctor output. The index is explanatory metadata only; resolver and
;;; loader code remain responsible for any later execution ordering.
;; : (-> PooUserModuleSelection MaybeInteger Alist)
(def (poo-flow-user-module-selection-feature-fact/index selection index)
  (list (cons 'declaration-index index)
        (cons 'declaration-phase 'init-selection)
        (cons 'key (poo-flow-user-module-selection-key selection))
        (cons 'group (.ref selection 'user-group))
        (cons 'module (.ref selection 'user-module))
        (cons 'flags
              (poo-flow-user-module-selection-presentation-flags selection))
        (cons 'source-ref
              (poo-flow-user-module-selection-source-ref->alist selection))
        (cons 'entrypoint
              (poo-flow-user-module-selection-entrypoint selection))
        (cons 'package-management? #f)
        (cons 'dependency-installation? #f)
        (cons 'descriptor-realized? #f)
        (cons 'loader-executed? #f)))

;;; Single-selection facts are useful for focused assertions where no profile
;;; order exists yet, so the declaration index is intentionally absent.
;; : (-> PooUserModuleSelection Alist)
(def (poo-flow-user-module-selection-feature-fact selection)
  (poo-flow-user-module-selection-feature-fact/index selection #f))

;;; Config feature facts preserve declaration order so help and doctor output
;;; stay aligned with the user's init.ss rows.
;; : (-> [PooUserModuleSelection] Integer [Alist])
(def (poo-flow-user-config-feature-facts/add selected-modules index)
  (cond
   ((null? selected-modules) '())
   (else
    (cons (poo-flow-user-module-selection-feature-fact/index
           (car selected-modules)
           index)
          (poo-flow-user-config-feature-facts/add
           (cdr selected-modules)
           (+ index 1))))))

;; : (-> PooUserConfig [Alist])
(def (poo-flow-user-config-feature-facts config)
  (poo-flow-user-config-feature-facts/add
   (poo-flow-user-config-modules config)
   0))

;; : (-> PooUserModuleSelection MaybeAlist)
(def (poo-flow-user-module-selection-source-ref->alist selection)
  (let ((source-ref (poo-flow-user-module-selection-source-ref selection)))
    (if source-ref
      (poo-flow-module-source-ref->alist source-ref)
      #f)))

;;; Selection presentation keeps hot-plug choices inspectable without resolving
;;; them into descriptors or touching upstream catalogs.
;; : (-> PooUserModuleSelection Alist)
(def (poo-flow-user-module-selection->alist selection)
  (list (cons 'group (.ref selection 'user-group))
        (cons 'module (.ref selection 'user-module))
        (cons 'key (poo-flow-user-module-selection-key selection))
        (cons 'source-ref
              (poo-flow-user-module-selection-source-ref->alist selection))
        (cons 'entrypoint
              (poo-flow-user-module-selection-entrypoint selection))
        (cons 'flags
              (poo-flow-user-module-selection-presentation-flags selection))
        (cons 'enabled? (.ref selection 'enabled?))))

;;; Settings deliberately remain a plain POO slot object: this layer captures
;;; user-authored option facts, while option merge semantics stay in the module
;;; system evaluator.
;; | UserSettingSyntax = SlotKeyword Value ...
;; poo-flow-settings
;;   : (-> UserSettingSyntax POOObject)
;;   | contract: captures user settings without validating option schemas
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-settings timeout: 30 retries: 2)
;;       ;; => settings
;;       ```
;;     %
(defrules poo-flow-settings ()
  ((_ setting ...)
   (.o setting ...)))

;;; Empty profiles are legal for tests and downstream bootstrap templates.
;; : (-> [[PooUserModuleSelection]] [PooUserModuleSelection])
(def (poo-flow-user-module-bundles->modules module-bundles)
  (if (null? module-bundles) '() (apply append module-bundles)))

;;; Boundary: top-level user config groups module choices and strategy settings.
;; : (-> [PooUserModuleSelection] POOObject POOObject)
(def (pooFlowUserConfig modules settings)
  (.o kind: poo-flow-user-config-kind
      user-modules: modules
      user-settings: settings))

;; : (-> PooUserConfigCandidate Boolean)
(def (poo-flow-user-config? value)
  (poo-flow-user-config-object-kind? value poo-flow-user-config-kind))

;; : (-> PooUserConfig [PooUserModuleSelection])
(def (poo-flow-user-config-modules config)
  (.ref config 'user-modules))

;; : (-> PooUserConfig POOObject)
(def (poo-flow-user-config-settings config)
  (.ref config 'user-settings))

;;; Module key projection is a user-facing summary for selected groups and
;;; names. It intentionally drops flags because flag checks stay per selection.
;; : (-> PooUserConfig [Pair])
(def (poo-flow-user-config-module-keys config)
  (map poo-flow-user-module-selection-key
       (poo-flow-user-config-modules config)))

;;; Settings presentation is intentionally shallow: user settings remain slots,
;;; while schema validation and merge semantics belong to upstream descriptors.
;; : (-> POOObject [Symbol] Alist)
(def (poo-flow-user-settings->alist settings setting-keys)
  (map (lambda (slot-name)
         (cons slot-name (.ref settings slot-name)))
       setting-keys))

;;; User config presentation is the downstream-facing doctor view. It exposes
;;; choices and settings but never realizes modules or executes runtime hooks.
;; : (-> PooUserConfig [Symbol]... POOObject)
(def (pooFlowUserConfigPresentation config . maybe-setting-keys)
  (let ((selected-modules (poo-flow-user-config-modules config))
        (setting-object (poo-flow-user-config-settings config))
        (public-setting-keys
         (if (null? maybe-setting-keys) '() (car maybe-setting-keys))))
    (let* ((feature-fact-rows
            (poo-flow-user-config-feature-facts config))
           (cicd-intent-rows
            (poo-flow-user-config-cicd-intents config))
           (workflow-cicd-check-maps
            (poo-flow-user-config-workflow-cicd-check-maps config))
           (workflow-cicd-readiness-rows
            (poo-flow-user-config-workflow-cicd-runtime-readiness config))
           (workflow-cicd-runtime-command-manifest-rows
            (poo-flow-user-config-workflow-cicd-runtime-command-manifests
             config))
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
            (poo-flow-user-config-workflow-cicd-receipts config))
           (loop-engine-intent-rows
            (poo-flow-user-config-loop-engine-intents config)))
      (let (workflow-cicd-check-rows
            (poo-flow-user-workflow-cicd-readiness-checks
             workflow-cicd-readiness-rows))
        (.o kind: poo-flow-user-config-presentation-kind
            module-count: (length selected-modules)
            module-keys: (poo-flow-user-config-module-keys config)
            modules: (map poo-flow-user-module-selection->alist selected-modules)
            feature-count: (length selected-modules)
            feature-facts: feature-fact-rows
            cicd-intent-count: (length cicd-intent-rows)
            cicd-intents: cicd-intent-rows
            workflow-cicd-pipeline-count: (length workflow-cicd-check-maps)
            workflow-cicd-pipelines:
            (map poo-flow-cicd-check-map-name workflow-cicd-check-maps)
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
            (poo-flow-user-alist-ref
             workflow-cicd-runtime-command-manifest-agreement-report
             'valid?
             #f)
            workflow-cicd-runtime-command-manifest-agreement-diagnostics:
            (poo-flow-user-alist-ref
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
          loop-engine-sandbox-runtime-summaries:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'sandbox-runtime-summaries)
          loop-engine-sandbox-handoff-summaries:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'sandbox-handoff-summaries)
          loop-engine-sandbox-unresolved-profile-refs:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'sandbox-unresolved-profile-refs)
          loop-engine-runtime-snapshot-count: (length loop-engine-intent-rows)
          loop-engine-runtime-snapshots:
          (poo-flow-user-loop-engine-intents-field-values
           loop-engine-intent-rows
           'runtime-snapshot)
          presentation-trace:
          (poo-flow-user-config-presentation-trace
           selected-modules
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
          settings: (poo-flow-user-settings->alist setting-object public-setting-keys)
          user-entrypoints: poo-flow-user-config-public-entrypoints
          api-entrypoints: poo-flow-user-config-api-entrypoints
          boundary: poo-flow-user-config-boundary
          brand-name: poo-flow-brand-name
          brand-group: poo-flow-brand-group
          scheme-owner: poo-flow-scheme-owner
          module-system-owner: poo-flow-module-system-owner
          runtime-owner: "marlin-agent-core"
          runtime-parses-scheme-source: #f
          scheme-manufactures-runtime-handlers: #f
          package-management?: #f
          dependency-installation?: #f
          descriptor-realized?: #f
          runtime-executed: #f
          replayable: #t)))))
