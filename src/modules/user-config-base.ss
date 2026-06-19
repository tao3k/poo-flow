;;; -*- Gerbil -*-
;;; Boundary: base user configuration facts for hot-plug module selection.
;;; Invariant: this module stays below profile/doctor presentation logic.
;;; Descriptor realization stays in src/modules.
;;; Intent: keep the downstream surface focused on POO Flow module activation.

(import (only-in :clan/poo/object .o .ref object?)
        :modules/interface
        :modules/source
        :modules/observability)

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
        poo-flow-user-config-presentation-trace
        poo-flow-user-module-selection-feature-fact
        poo-flow-user-module-selection
        poo-flow-user-custom-module-selection
        poo-flow-user-module-selection-feature?
        poo-flow-user-modules-feature?
        poo-flow-user-config-feature?
        poo-flow-user-config-feature-facts
        poo-flow-settings
        poo-flow-use-module-group
        poo-flow-use-module
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
(def (poo-flow-use-module-group module)
  (cond
   ((eq? module 'funflow) 'flow)
   ((eq? module 'governor) 'loop)
   ((or (eq? module 'nono-sandbox)
        (eq? module 'cubeSandbox)
        (eq? module 'docker-sandbox))
    'sandbox)
   (else 'custom)))

;; : (-> Symbol [UserModuleFlagEntry] [PooUserModuleSelection])
(def (poo-flow-use-module module flags)
  (list
   (poo-flow-user-module-selection
    (poo-flow-use-module-group module)
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

;;; The trace is deterministic and strict. It is the first slot tests should
;;; inspect when a presentation hangs, because it does not call back into POO.
;; : (-> [PooUserModuleSelection] [Alist] [Alist] [Symbol] [Alist])
(def (poo-flow-user-config-presentation-trace
      selected-modules
      feature-fact-rows
      cicd-intent-rows
      public-setting-keys)
  (poo-flow-module-presentation-trace
   'user-config-presentation
   (list (cons 'selected-modules (length selected-modules))
         (cons 'feature-facts (length feature-fact-rows))
         (cons 'cicd-intents (length cicd-intent-rows))
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
        (cons 'flags (poo-flow-user-module-selection-flags selection))
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
        (cons 'flags (poo-flow-user-module-selection-flags selection))
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
    (let ((feature-fact-rows
           (poo-flow-user-config-feature-facts config))
          (cicd-intent-rows
           (poo-flow-user-config-cicd-intents config)))
      (.o kind: poo-flow-user-config-presentation-kind
          module-count: (length selected-modules)
          module-keys: (poo-flow-user-config-module-keys config)
          modules: (map poo-flow-user-module-selection->alist selected-modules)
          feature-count: (length selected-modules)
          feature-facts: feature-fact-rows
          cicd-intent-count: (length cicd-intent-rows)
          cicd-intents: cicd-intent-rows
          presentation-trace:
          (poo-flow-user-config-presentation-trace
           selected-modules
           feature-fact-rows
           cicd-intent-rows
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
          replayable: #t))))
