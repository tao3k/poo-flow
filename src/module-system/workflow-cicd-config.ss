;;; -*- Gerbil -*-
;;; Boundary: workflow CI/CD user-module projection for the module system.
;;; Invariant: this owner emits POO control-plane data and never executes checks.

(import :poo-flow/src/module-system/base
        :poo-flow/src/module-system/runtime-projection-syntax
        (only-in :poo-flow/src/module-system/workflow-cicd-runtime-command-config
                 poo-flow-user-alist-ref)
        :poo-flow/src/module-system/sandbox-profile-catalog
        (only-in :poo-flow/src/modules/funflow/config
                 poo-flow-funflow-check-map->functional-dag
                 poo-flow-funflow-functional-dag->alist)
        (only-in :poo-flow/src/modules/workflow/cicd
                 poo-flow-cicd-check-map?
                 poo-flow-cicd-check-map-name
                 poo-flow-cicd-check-map->receipts
                 poo-flow-cicd-check-map->runtime-manifest-readiness
                 poo-flow-cicd-check-map->runtime-command-manifests
                 poo-flow-cicd-runtime-command-manifest-map->marlin-runtime-handoff-abi))

(export poo-flow-user-cicd-payload?
        poo-flow-user-cicd-payload-section
        poo-flow-user-module-selection-cicd-intent
        poo-flow-user-config-cicd-intents
        poo-flow-user-module-selection-workflow-cicd-check-map
        poo-flow-user-config-workflow-cicd-check-maps
        poo-flow-user-workflow-cicd-functional-dags
        poo-flow-user-workflow-cicd-functional-dag-rows
        poo-flow-user-config-workflow-cicd-functional-dag-rows
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
        poo-flow-user-workflow-cicd-marlin-handoff-receipt-bundle
        poo-flow-user-config-workflow-cicd-marlin-handoff-receipt-bundle
        poo-flow-user-config-workflow-cicd-receipts
        poo-flow-user-config-workflow-cicd-runtime-projection
        poo-flow-user-alist-ref
        poo-flow-user-workflow-cicd-readiness-checks
        poo-flow-user-workflow-cicd-checks-field-values)


;;; CI/CD payload predicates recognize the nested flag shape emitted by init.ss.
;;; They avoid descriptor lookup so user tools can inspect declared intent first.
;; : (-> UserCicdPayloadCandidate Boolean)
(import :poo-flow/src/module-system/workflow-cicd-runtime-command-config)

;;; Payload section reads are deliberately lossy: missing sections become empty
;;; lists, which keeps partial user declarations presentable before validation.
;; : (-> UserCicdPayload Symbol [Symbol])
;;; CI/CD intent facts are user-interface presentation data. They describe the
;;; Funflow vocabulary selected by init.ss and never imply adapter execution.
;; : (-> PooUserModuleSelection MaybeAlist)
;;; CI/CD intent accumulation is a report-only filter over selected modules. It
;;; preserves init.ss declaration order and never asks the resolver for descriptors.
;; : (-> [PooUserModuleSelection] [Alist])
;;; Config-level CI/CD intents are the stable downstream presentation surface
;;; for the Bass-inspired Funflow CI/CD payload.
;; : (-> PooUserConfig [Alist])
;;; Workflow CI/CD check-maps are the typed pipeline objects attached by the
;;; Funflow module. Presentation consumes them, but still performs no runtime
;;; descriptor realization or provider execution.
;; : (-> PooUserModuleSelection MaybePooFlowCicdCheckMap)
;;; Check-map accumulation filters selected modules without losing declaration
;;; order. Invalid or absent CI/CD maps are skipped so presentation can stay
;;; inspectable before runtime validation.
;; : (-> [PooUserModuleSelection] [PooFlowCicdCheckMap])
;;; Config-level check-map discovery keeps the user interface on the declared
;;; POO object graph: sandbox profile resolution happens against selected
;;; module config plus upstream defaults, not by probing the filesystem.
;; : (-> PooUserConfig [PooFlowCicdCheckMap])
;;; Functional DAG discovery stays in the Funflow owner. This layer only
;;; projects check-map values into POO DAG objects and final presentation rows.
;; : (-> [PooFlowCicdCheckMap] [PooFlowFunflowFunctionalDag])
;; : (-> [PooFlowCicdCheckMap] [Alist])
;; : (-> PooUserConfig [Alist])
;;; Boundary: user workflow cicd runtime readiness add is the policy-visible
;;; edge for module-system, workflow behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> [PooFlowCicdCheckMap] [PooSandboxProfile] [Alist])
;; : (-> PooUserConfig [Alist])
;;; Boundary: user workflow cicd runtime command manifests add is the policy-
;;; visible edge for module-system, workflow behavior, keeping validation,
;;; lookup, or projection responsibilities centralized for callers.
;; : (-> [PooFlowCicdCheckMap] [PooSandboxProfile] [Alist])
;;; Runtime command manifests use the same configured profile catalog as
;;; readiness, so user/project overrides are visible before Marlin consumes the
;;; handoff data.
;; : (-> PooUserConfig [Alist])
;;; Manifest maps stay grouped by pipeline in the full presentation; summaries
;;; flatten them only for audit rows, preserving the full map as source data.
;; : (-> [Alist] [Alist])
;;; Compact summaries are the agent-facing audit rows for runtime handoff. The
;;; full manifest remains available, but presentation code and docs can inspect
;;; these rows without traversing nested sandbox summaries.
;; : (-> Alist Alist)
(defpoo-runtime-receipt-projection
  poo-flow-user-workflow-cicd-runtime-command-manifest-summary
  (manifest)
  (bindings
   ((request (poo-flow-user-alist-ref manifest 'request '()))
    (policy (poo-flow-user-alist-ref manifest 'policy '()))
    (unresolved
     (poo-flow-user-alist-ref request
                              'sandbox-unresolved-profile-refs
                              '()))
    (handoff-ready (null? unresolved))))
  (fields
   (('kind 'workflow-cicd-runtime-command-manifest-summary)
    ('operation
     (poo-flow-user-alist-ref manifest 'operation #f))
    ('request-id
     (poo-flow-user-alist-ref manifest 'request-id #f))
    ('artifact-handle
     (poo-flow-user-alist-ref manifest 'artifact-handle #f))
    ('argv
     (poo-flow-user-alist-ref manifest 'argv '()))
    ('check
     (poo-flow-user-alist-ref request 'check #f))
    ('profile
     (poo-flow-user-alist-ref request 'profile #f))
    ('profile-refs
     (poo-flow-user-alist-ref request 'profile-refs '()))
    ('dependency-refs
     (poo-flow-user-alist-ref request 'dependency-refs '()))
    ('durable-task-id
     (poo-flow-user-alist-ref request 'durable-task-id #f))
    ('action-class
     (poo-flow-user-alist-ref request 'action-class #f))
    ('artifact-refs
     (poo-flow-user-alist-ref request 'artifact-refs '()))
    ('artifact-provenance
     (poo-flow-user-alist-ref
      policy
      'artifact-provenance
      '()))
    ('artifact-retention
     (poo-flow-user-alist-ref request 'artifact-retention #f))
    ('sandbox-refs
     (poo-flow-user-alist-ref request 'sandbox-refs '()))
    ('checkpoint-ref
     (poo-flow-user-alist-ref request 'checkpoint-ref #f))
    ('compensation-refs
     (poo-flow-user-alist-ref request 'compensation-refs '()))
    ('runtime
     (poo-flow-user-alist-ref request 'runtime #f))
    ('runtime-owner "marlin-agent-core")
    ('sandbox-unresolved-profile-refs unresolved)
    ('status (if handoff-ready 'ready 'blocked))
    ('handoff-ready handoff-ready)
    ('handoff-required
     (poo-flow-user-alist-ref policy 'handoff-required #t))
    ('runtime-executed
     (poo-flow-user-alist-ref request 'runtime-executed #f)))))

;;; Summary projection is a pure sequence transform over manifest maps. It keeps
;;; user-facing audit rows small while leaving the full command payload intact.
;; : (-> [Alist] [Alist] [Alist] Values)
;; : (-> [Alist] [Alist] [Alist] Values)
;;; The manifest summary projection keeps full manifests and compact summaries
;;; in the same declaration order without building a flattened manifest list and
;;; then mapping it again.
;; : (-> [Alist] Alist)
;; : (-> [Alist] [Alist])
;;; Runtime owner is pinned at the presentation boundary so user-facing receipts
;;; do not drift from the Marlin handoff ABI when check-map internals change.
;; : RuntimeOwnerName
;;; Runtime agreement rows require every nested runtime-executed flag to remain
;;; false, because Scheme only manufactures handoff data for Marlin.
;; : (-> [RuntimeExecutedFlag] Boolean)
;;; Matching summaries by request-id and check name preserves duplicate
;;; detection; callers need the full match set, not first-match lookup.
;; : (-> [Alist] Value Value [Alist])
;;; Extra-summary detection guards presentation drift: a summary without a
;;; source manifest means UI projection has invented handoff data.
;; : (-> [Alist] Alist Boolean)
;;; Diagnostics walk summaries rather than manifests so every stray audit row
;;; is reported, even when command-manifest generation is otherwise empty.
;; : (-> [Alist] [Alist] [Symbol])
;; poo-flow-user-workflow-cicd-summary-count-diagnostics
;;   : (-> Integer (List Symbol))
;;   | doc m%
;;       `poo-flow-user-workflow-cicd-summary-count-diagnostics` records summary
;;       cardinality drift before manifest fields are compared.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-user-workflow-cicd-summary-count-diagnostics 0)
;;       ;; => (missing-summary)
;;       ```
;;     %
;;; Boundary: user workflow cicd mismatch diagnostics is the policy-visible
;;; edge for module-system, workflow behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> Boolean Boolean Symbol [Symbol])
;; : (-> Integer Boolean Boolean Boolean Boolean Boolean Boolean [Symbol])
;; : (-> Boolean Boolean Boolean Boolean Boolean Boolean Boolean Boolean Boolean [Symbol])
;;; Boundary:
;;; - Agreement rows are audit data only; they never execute CI commands.
;;; - Manifest and summary fields stay separate so each drift reason is visible.
;; : (-> Alist MaybeAlist Integer Alist)
;;; Boundary: user workflow cicd runtime command manifest agreement rows is the
;;; policy-visible edge for module-system, workflow behavior, keeping
;;; validation, lookup, or projection responsibilities centralized for callers.
;; : (-> [Alist] [Alist] [Alist])
;;; Boundary: user workflow cicd runtime command manifest agreement row
;;; diagnostics is the policy-visible edge for module-system, workflow
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> [Alist] [Symbol])
;;; Agreement validation is the pure contract between the full runtime handoff
;;; payload and compact user/agent audit rows. It checks shape equivalence only;
;;; runtime execution and provider semantics stay outside Scheme.
;; : (-> [Alist] [Alist] Alist)
;; : (-> [Alist] [Alist] Alist)
;; : (-> PooUserConfig Alist)
;;; Marlin ABI projections reuse the already validated manifest maps. The user
;;; interface sees a stable handoff payload without learning workflow object
;;; internals or executing any runtime adapter.
;; : (-> [Alist] [Alist] [Alist])
(def (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abis/rev
      manifest-maps
      abis-rev)
  (cond
   ((null? manifest-maps) abis-rev)
   (else
    (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abis/rev
     (cdr manifest-maps)
     (cons
      (poo-flow-cicd-runtime-command-manifest-map->marlin-runtime-handoff-abi
       (car manifest-maps))
      abis-rev)))))

;; : (-> [Alist] [Alist])
(def (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abis manifest-maps)
  (reverse
   (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abis/rev
    manifest-maps
    '())))

;; : (-> PooUserConfig [Alist])
(def (poo-flow-user-config-workflow-cicd-marlin-runtime-handoff-abis config)
  (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abis
   (poo-flow-user-config-workflow-cicd-runtime-command-manifests config)))

;;; ABI summaries are the receipt-sized view used by user-interface tests and
;;; handoff diagnostics; they keep the full per-check entries available only in
;;; the ABI payload.
;; : (-> MarlinRuntimeHandoffAbi MarlinRuntimeHandoffAbiSummary)
(defpoo-runtime-receipt-projection
  poo-flow-user-workflow-cicd-marlin-runtime-handoff-abi-summary
  (abi)
  (bindings
   ((entries (poo-flow-user-alist-ref abi 'entries '()))))
  (fields
   (('kind 'workflow-cicd-marlin-runtime-handoff-abi-summary)
    ('schema (poo-flow-user-alist-ref abi 'schema #f))
    ('check-map (poo-flow-user-alist-ref abi 'check-map #f))
    ('runtime-owner
     (poo-flow-user-alist-ref abi 'runtime-owner
                              +poo-flow-user-workflow-cicd-runtime-owner+))
    ('manifest-count
     (poo-flow-user-alist-ref abi 'manifest-count (length entries)))
    ('entry-count (length entries))
    ('required-fields
     (poo-flow-user-alist-ref abi 'required-fields '()))
    ('handoff-required
     (poo-flow-user-alist-ref abi 'handoff-required #t))
    ('runtime-executed
     (poo-flow-user-alist-ref abi 'runtime-executed #f))
    ('runtime-parses-scheme-source
     (poo-flow-user-alist-ref abi 'runtime-parses-scheme-source #f))
    ('scheme-manufactures-runtime-handlers
     (poo-flow-user-alist-ref
      abi
      'scheme-manufactures-runtime-handlers
      #f)))))

;; : (-> [MarlinRuntimeHandoffAbi] [MarlinRuntimeHandoffAbiSummary])
(def (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abi-summaries/rev
      abi-rows
      summaries-rev)
  (cond
   ((null? abi-rows) summaries-rev)
   (else
    (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abi-summaries/rev
     (cdr abi-rows)
     (cons
      (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abi-summary
       (car abi-rows))
      summaries-rev)))))

;; : (-> [MarlinRuntimeHandoffAbi] [MarlinRuntimeHandoffAbiSummary])
(def (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abi-summaries
      abi-rows)
  (reverse
   (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abi-summaries/rev
    abi-rows
    '())))

;; : (-> [MarlinRuntimeHandoffAbiSummary] Integer)
(def (poo-flow-user-workflow-cicd-marlin-handoff-entry-count summaries)
  (cond
   ((null? summaries) 0)
   (else
    (+ (poo-flow-user-alist-ref (car summaries) 'entry-count 0)
       (poo-flow-user-workflow-cicd-marlin-handoff-entry-count
        (cdr summaries))))))

;;; The handoff receipt bundle is the user-interface receipt-sized envelope for
;;; Marlin handoff. It keeps the full ABI payload available while giving agents
;;; one stable object to inspect for agreement, proof gate, and non-execution
;;; evidence.
;; : (-> [Alist] [Alist] Alist [Alist] [Alist] [Alist] Alist)
(defpoo-runtime-receipt-projection
  poo-flow-user-workflow-cicd-marlin-handoff-receipt-bundle
  (manifest-maps
   manifest-summaries
   manifest-agreement
   handoff-abis
   handoff-summaries
   receipts)
  (bindings
   ((handoff-entry-count
     (poo-flow-user-workflow-cicd-marlin-handoff-entry-count
      handoff-summaries))))
  (fields
   (('schema
     'poo-flow.modules.workflow-cicd.marlin-handoff-receipt-bundle.v1)
    ('kind 'workflow-cicd-marlin-handoff-receipt-bundle)
    ('source 'poo-flow-user-config-presentation)
    ('alignment-gate-id
     'stage-23-user-interface-marlin-handoff-projection)
    ('proof-command
     "gxtest t/user-interface-cicd-test.ss: projects user config into Marlin runtime handoff ABI")
    ('presentation-fields
     '(workflow-cicd-runtime-command-manifests
       workflow-cicd-runtime-command-manifest-summaries
       workflow-cicd-runtime-command-manifest-agreement
       workflow-cicd-marlin-runtime-handoff-abis
       workflow-cicd-marlin-runtime-handoff-summaries
       workflow-cicd-receipts))
    ('runtime-owner +poo-flow-user-workflow-cicd-runtime-owner+)
    ('handoff-required (> (length handoff-abis) 0))
    ('runtime-executed #f)
    ('runtime-parses-scheme-source #f)
    ('scheme-manufactures-runtime-handlers #f)
    ('manifest-map-count (length manifest-maps))
    ('manifest-summary-count (length manifest-summaries))
    ('manifest-agreement-valid?
     (poo-flow-user-alist-ref manifest-agreement 'valid? #f))
    ('manifest-agreement-diagnostics
     (poo-flow-user-alist-ref manifest-agreement 'diagnostics '()))
    ('marlin-runtime-handoff-abi-count (length handoff-abis))
    ('marlin-runtime-handoff-summary-count (length handoff-summaries))
    ('receipt-count (length receipts))
    ('manifest-agreement-schema
     (poo-flow-user-alist-ref manifest-agreement 'schema #f))
    ('manifest-agreement-row-count
     (length (poo-flow-user-alist-ref manifest-agreement 'rows '())))
    ('marlin-runtime-handoff-entry-count handoff-entry-count))))

;;; Config-level bundle construction reuses the same projection path as the
;;; presentation layer so tests can compare one receipt shape across surfaces.
;; : (-> PooUserConfig Alist)
(def (poo-flow-user-config-workflow-cicd-marlin-handoff-receipt-bundle
      config)
  (let* ((manifest-maps
          (poo-flow-user-config-workflow-cicd-runtime-command-manifests
           config))
         (manifest-summaries
          (poo-flow-user-workflow-cicd-runtime-command-manifest-summaries
           manifest-maps))
         (manifest-agreement
          (poo-flow-user-workflow-cicd-runtime-command-manifest-agreement
           manifest-maps
           manifest-summaries))
         (handoff-abis
          (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abis
           manifest-maps))
         (handoff-summaries
          (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abi-summaries
           handoff-abis))
         (receipts
          (poo-flow-user-config-workflow-cicd-receipts config)))
    (poo-flow-user-workflow-cicd-marlin-handoff-receipt-bundle
     manifest-maps
     manifest-summaries
     manifest-agreement
     handoff-abis
     handoff-summaries
     receipts)))

;;; Receipt accumulation preserves check-map declaration order while flattening
;;; per-check receipts into the presentation contract.
;; : (-> [PooFlowCicdCheckMap] [PooSandboxProfile] [Alist] [Alist])
(def (poo-flow-user-workflow-cicd-receipts/add/rev check-maps
                                                       profile-catalog
                                                       receipts-rev)
  (cond
   ((null? check-maps) receipts-rev)
   (else
    (poo-flow-user-workflow-cicd-receipts/add/rev
     (cdr check-maps)
     profile-catalog
     (poo-flow-user-workflow-cicd-reverse-prepend
      (poo-flow-cicd-check-map->receipts (car check-maps) profile-catalog)
      receipts-rev)))))

;; : (-> [PooFlowCicdCheckMap] [PooSandboxProfile] [Alist])
(def (poo-flow-user-workflow-cicd-receipts/add check-maps profile-catalog)
  (reverse
   (poo-flow-user-workflow-cicd-receipts/add/rev
    check-maps
    profile-catalog
    '())))

;;; Config-level receipts resolve sandbox profiles through selected modules,
;;; preserving user overrides before Marlin receives check receipts.
;; : (-> PooUserConfig [Alist])
(def (poo-flow-user-config-workflow-cicd-receipts config)
  (let* ((selected-modules (poo-flow-user-config-modules config))
         (profile-catalog
          (poo-flow-user-config-sandbox-profile-catalog selected-modules)))
    (poo-flow-user-workflow-cicd-receipts/add
     (poo-flow-user-config-workflow-cicd-check-maps config)
     profile-catalog)))

;; : (-> [PooFlowCicdCheckMap] [Symbol])
(def (poo-flow-user-workflow-cicd-check-map-names check-maps)
  (cond
   ((null? check-maps) '())
   (else
    (cons (poo-flow-cicd-check-map-name (car check-maps))
          (poo-flow-user-workflow-cicd-check-map-names
           (cdr check-maps))))))

;;; Runtime projection batches the CI/CD handoff rows that share the same
;;; check-map list and sandbox profile catalog. Presentation layers can then
;;; reuse one owner-local receipt instead of rebuilding each public slot by
;;; rediscovering the same module selections.
;; : (-> PooUserConfig Alist)
(def (poo-flow-user-config-workflow-cicd-runtime-projection config)
  (let* ((selected-modules (poo-flow-user-config-modules config))
         (profile-catalog
          (poo-flow-user-config-sandbox-profile-catalog selected-modules))
         (check-maps
          (poo-flow-user-config-workflow-cicd-check-maps config))
         (readiness-rows
          (poo-flow-user-workflow-cicd-runtime-readiness/add
           check-maps
           profile-catalog))
         (readiness-check-summary
          (poo-flow-user-workflow-cicd-readiness-check-summary
           readiness-rows))
         (manifest-maps
          (poo-flow-user-workflow-cicd-runtime-command-manifests/add
           check-maps
           profile-catalog))
         (manifest-summary-projection
          (poo-flow-user-workflow-cicd-runtime-command-manifest-summary-projection
           manifest-maps))
         (manifests
          (poo-flow-user-alist-ref
           manifest-summary-projection
           'manifests
           '()))
         (manifest-summaries
          (poo-flow-user-alist-ref
           manifest-summary-projection
           'summaries
           '()))
         (manifest-agreement
          (poo-flow-user-workflow-cicd-runtime-command-manifest-agreement/from-manifests
           manifests
           manifest-summaries))
         (handoff-abis
          (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abis
           manifest-maps))
         (handoff-summaries
          (poo-flow-user-workflow-cicd-marlin-runtime-handoff-abi-summaries
           handoff-abis))
         (receipts
          (poo-flow-user-workflow-cicd-receipts/add
           check-maps
           profile-catalog))
         (handoff-bundle
          (poo-flow-user-workflow-cicd-marlin-handoff-receipt-bundle
           manifest-maps
           manifest-summaries
           manifest-agreement
           handoff-abis
           handoff-summaries
           receipts)))
    (list
     (cons 'check-maps check-maps)
     (cons 'pipeline-count (length check-maps))
     (cons 'pipeline-names
           (poo-flow-user-workflow-cicd-check-map-names check-maps))
     (cons 'runtime-readiness readiness-rows)
     (cons 'readiness-checks
           (poo-flow-user-alist-ref
            readiness-check-summary
            'checks
            '()))
     (cons 'sandbox-runtime-summaries
           (poo-flow-user-alist-ref
            readiness-check-summary
            'sandbox-runtime-summaries
            '()))
     (cons 'sandbox-handoff-summaries
           (poo-flow-user-alist-ref
            readiness-check-summary
            'sandbox-handoff-summaries
            '()))
     (cons 'sandbox-unresolved-profile-refs
           (poo-flow-user-alist-ref
            readiness-check-summary
            'sandbox-unresolved-profile-refs
            '()))
     (cons 'runtime-command-manifests manifest-maps)
     (cons 'runtime-command-manifest-summaries manifest-summaries)
     (cons 'runtime-command-manifest-agreement manifest-agreement)
     (cons 'marlin-runtime-handoff-abis handoff-abis)
     (cons 'marlin-runtime-handoff-summaries handoff-summaries)
     (cons 'receipts receipts)
     (cons 'marlin-handoff-receipt-bundle handoff-bundle)
     (cons 'runtime-executed #f))))

;;; Shared alist lookup is total by design: presentation and agreement checks
;;; need to report partial payloads instead of failing on the first missing key.
;; : (-> Alist Symbol Value Value)
;; : (-> [WorkflowCicdProjectionValue] [WorkflowCicdProjectionValue] [WorkflowCicdProjectionValue])
(def (poo-flow-user-workflow-cicd-reverse-prepend values values-rev)
  (cond
   ((null? values) values-rev)
   (else
    (poo-flow-user-workflow-cicd-reverse-prepend
     (cdr values)
     (cons (car values) values-rev)))))

;; : (-> [Alist] [Alist] [Alist] [Alist] [Alist] Values)
(def (poo-flow-user-workflow-cicd-readiness-check-summary/add-checks
      checks
      checks-rev
      runtime-summaries-rev
      handoff-summaries-rev
      unresolved-profile-refs-rev)
  (cond
   ((null? checks)
    (values checks-rev
            runtime-summaries-rev
            handoff-summaries-rev
            unresolved-profile-refs-rev))
   (else
    (let (check (car checks))
      (poo-flow-user-workflow-cicd-readiness-check-summary/add-checks
       (cdr checks)
       (cons check checks-rev)
       (poo-flow-user-workflow-cicd-reverse-prepend
        (poo-flow-user-alist-ref check 'sandbox-runtime-summaries '())
        runtime-summaries-rev)
       (poo-flow-user-workflow-cicd-reverse-prepend
        (poo-flow-user-alist-ref check 'sandbox-handoff-summaries '())
        handoff-summaries-rev)
       (poo-flow-user-workflow-cicd-reverse-prepend
        (poo-flow-user-alist-ref check 'sandbox-unresolved-profile-refs '())
        unresolved-profile-refs-rev))))))

;; : (-> [Alist] [Alist] [Alist] [Alist] [Alist] Values)
(def (poo-flow-user-workflow-cicd-readiness-check-summary/add
      readiness-rows
      checks-rev
      runtime-summaries-rev
      handoff-summaries-rev
      unresolved-profile-refs-rev)
  (cond
   ((null? readiness-rows)
    (values checks-rev
            runtime-summaries-rev
            handoff-summaries-rev
            unresolved-profile-refs-rev))
   (else
    (let-values (((checks-rev
                   runtime-summaries-rev
                   handoff-summaries-rev
                   unresolved-profile-refs-rev)
                  (poo-flow-user-workflow-cicd-readiness-check-summary/add-checks
                   (poo-flow-user-alist-ref
                    (car readiness-rows)
                    'checks
                    '())
                   checks-rev
                   runtime-summaries-rev
                   handoff-summaries-rev
                   unresolved-profile-refs-rev)))
      (poo-flow-user-workflow-cicd-readiness-check-summary/add
       (cdr readiness-rows)
       checks-rev
       runtime-summaries-rev
       handoff-summaries-rev
       unresolved-profile-refs-rev)))))

;;; Readiness check summary flattens the nested per-pipeline check rows and the
;;; three sandbox presentation columns in one owner-local pass.
;; : (-> [Alist] Alist)
(def (poo-flow-user-workflow-cicd-readiness-check-summary readiness-rows)
  (let-values (((checks-rev
                 runtime-summaries-rev
                 handoff-summaries-rev
                 unresolved-profile-refs-rev)
                (poo-flow-user-workflow-cicd-readiness-check-summary/add
                 readiness-rows
                 '()
                 '()
                 '()
                 '())))
    (list
     (cons 'checks (reverse checks-rev))
     (cons 'sandbox-runtime-summaries (reverse runtime-summaries-rev))
     (cons 'sandbox-handoff-summaries (reverse handoff-summaries-rev))
     (cons 'sandbox-unresolved-profile-refs
           (reverse unresolved-profile-refs-rev)))))

;;; Readiness rows are nested by pipeline. This helper exposes the per-check
;;; rows that presentation uses for sandbox summary columns.
;; : (-> [Alist] [Alist])
(def (poo-flow-user-workflow-cicd-readiness-checks readiness-rows)
  (poo-flow-user-alist-ref
   (poo-flow-user-workflow-cicd-readiness-check-summary readiness-rows)
   'checks
   '()))

;;; Field collection keeps repeated sandbox summary fields in declaration
;;; order; empty fields stay absent rather than fabricated.
;; : (-> [Alist] Symbol [Value])
(def (poo-flow-user-workflow-cicd-checks-field-values checks field)
  (foldr
   (lambda (check values)
     (foldr cons
            values
            (poo-flow-user-alist-ref check field '())))
   '()
   checks))
