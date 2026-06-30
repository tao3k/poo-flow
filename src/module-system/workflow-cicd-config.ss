;;; -*- Gerbil -*-
;;; Boundary: workflow CI/CD user-module projection for the module system.
;;; Invariant: this owner emits POO control-plane data and never executes checks.

(import :poo-flow/src/module-system/base
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
        poo-flow-user-alist-ref
        poo-flow-user-workflow-cicd-readiness-checks
        poo-flow-user-workflow-cicd-checks-field-values)


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

;;; Check-map accumulation filters selected modules without losing declaration
;;; order. Invalid or absent CI/CD maps are skipped so presentation can stay
;;; inspectable before runtime validation.
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

;;; Functional DAG discovery stays in the Funflow owner. This layer only
;;; projects check-map values into POO DAG objects and final presentation rows.
;; : (-> [PooFlowCicdCheckMap] [PooFlowFunflowFunctionalDag])
(def (poo-flow-user-workflow-cicd-functional-dags check-maps)
  (map poo-flow-funflow-check-map->functional-dag check-maps))

;; : (-> [PooFlowCicdCheckMap] [Alist])
(def (poo-flow-user-workflow-cicd-functional-dag-rows check-maps)
  (map poo-flow-funflow-functional-dag->alist
       (poo-flow-user-workflow-cicd-functional-dags check-maps)))

;; : (-> PooUserConfig [Alist])
(def (poo-flow-user-config-workflow-cicd-functional-dag-rows config)
  (poo-flow-user-workflow-cicd-functional-dag-rows
   (poo-flow-user-config-workflow-cicd-check-maps config)))

;;; Boundary: user workflow cicd runtime readiness add is the policy-visible
;;; edge for module-system, workflow behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
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

;;; Boundary: user workflow cicd runtime command manifests add is the policy-
;;; visible edge for module-system, workflow behavior, keeping validation,
;;; lookup, or projection responsibilities centralized for callers.
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
     (cons 'durable-task-id
           (poo-flow-user-alist-ref request 'durable-task-id #f))
     (cons 'action-class
           (poo-flow-user-alist-ref request 'action-class #f))
     (cons 'artifact-refs
           (poo-flow-user-alist-ref request 'artifact-refs '()))
     (cons 'artifact-provenance
           (poo-flow-user-alist-ref
            policy
            'artifact-provenance
            '()))
     (cons 'artifact-retention
           (poo-flow-user-alist-ref request 'artifact-retention #f))
     (cons 'sandbox-refs
           (poo-flow-user-alist-ref request 'sandbox-refs '()))
     (cons 'checkpoint-ref
           (poo-flow-user-alist-ref request 'checkpoint-ref #f))
     (cons 'compensation-refs
           (poo-flow-user-alist-ref request 'compensation-refs '()))
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

;;; Summary projection is a pure sequence transform over manifest maps. It keeps
;;; user-facing audit rows small while leaving the full command payload intact.
;; : (-> [Alist] [Alist])
(def (poo-flow-user-workflow-cicd-runtime-command-manifest-summaries
      manifest-maps)
  (map poo-flow-user-workflow-cicd-runtime-command-manifest-summary
       (poo-flow-user-workflow-cicd-runtime-command-manifest-map-manifests
        manifest-maps)))

;;; Runtime owner is pinned at the presentation boundary so user-facing receipts
;;; do not drift from the Marlin handoff ABI when check-map internals change.
;; : RuntimeOwnerName
(def +poo-flow-user-workflow-cicd-runtime-owner+ "marlin-agent-core")

;;; Runtime agreement rows require every nested runtime-executed flag to remain
;;; false, because Scheme only manufactures handoff data for Marlin.
;; : (-> [RuntimeExecutedFlag] Boolean)
(def (poo-flow-user-list-all-false? values)
  (cond
   ((null? values) #t)
   ((equal? (car values) #f)
    (poo-flow-user-list-all-false? (cdr values)))
   (else #f)))

;;; Matching summaries by request-id and check name preserves duplicate
;;; detection; callers need the full match set, not first-match lookup.
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

;;; Extra-summary detection guards presentation drift: a summary without a
;;; source manifest means UI projection has invented handoff data.
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

;;; Diagnostics walk summaries rather than manifests so every stray audit row
;;; is reported, even when command-manifest generation is otherwise empty.
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
(def (poo-flow-user-workflow-cicd-summary-count-diagnostics summary-count)
  (cond
   ((= summary-count 1) '())
   ((= summary-count 0) '(missing-summary))
   (else '(duplicate-summary))))

;;; Boundary: user workflow cicd mismatch diagnostics is the policy-visible
;;; edge for module-system, workflow behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> Boolean Boolean Symbol [Symbol])
(def (poo-flow-user-workflow-cicd-mismatch-diagnostics summary-present?
                                                              match?
                                                              code)
  (if (or (not summary-present?) match?)
    '()
    (list code)))

;; : (-> Integer Boolean Boolean Boolean Boolean Boolean Boolean [Symbol])
(def (poo-flow-user-workflow-cicd-runtime-command-agreement-diagnostics
      summary-count
      summary-present?
      check-match?
      argv-match?
      runtime-owner-match?
      unresolved-profile-refs-match?
      runtime-executed-match?)
  (append
   (poo-flow-user-workflow-cicd-summary-count-diagnostics summary-count)
   (poo-flow-user-workflow-cicd-mismatch-diagnostics
    summary-present? check-match? 'check-mismatch)
   (poo-flow-user-workflow-cicd-mismatch-diagnostics
    summary-present? argv-match? 'argv-mismatch)
   (poo-flow-user-workflow-cicd-mismatch-diagnostics
    summary-present? runtime-owner-match? 'runtime-owner-mismatch)
   (poo-flow-user-workflow-cicd-mismatch-diagnostics
    summary-present?
    unresolved-profile-refs-match?
    'unresolved-profile-refs-mismatch)
   (poo-flow-user-workflow-cicd-mismatch-diagnostics
    summary-present? runtime-executed-match? 'runtime-executed-mismatch)))

;; : (-> Boolean Boolean Boolean Boolean Boolean Boolean Boolean Boolean Boolean [Symbol])
(def (poo-flow-user-workflow-cicd-runtime-command-durable-agreement-diagnostics
      summary-present?
      durable-task-id-match?
      action-class-match?
      artifact-refs-match?
      artifact-provenance-match?
      artifact-retention-match?
      sandbox-refs-match?
      checkpoint-ref-match?
      compensation-refs-match?)
  (append
   (poo-flow-user-workflow-cicd-mismatch-diagnostics
    summary-present? durable-task-id-match? 'durable-task-id-mismatch)
   (poo-flow-user-workflow-cicd-mismatch-diagnostics
    summary-present? action-class-match? 'action-class-mismatch)
   (poo-flow-user-workflow-cicd-mismatch-diagnostics
    summary-present? artifact-refs-match? 'artifact-refs-mismatch)
   (poo-flow-user-workflow-cicd-mismatch-diagnostics
    summary-present? artifact-provenance-match? 'artifact-provenance-mismatch)
   (poo-flow-user-workflow-cicd-mismatch-diagnostics
    summary-present? artifact-retention-match? 'artifact-retention-mismatch)
   (poo-flow-user-workflow-cicd-mismatch-diagnostics
    summary-present? sandbox-refs-match? 'sandbox-refs-mismatch)
   (poo-flow-user-workflow-cicd-mismatch-diagnostics
    summary-present? checkpoint-ref-match? 'checkpoint-ref-mismatch)
   (poo-flow-user-workflow-cicd-mismatch-diagnostics
    summary-present? compensation-refs-match? 'compensation-refs-mismatch)))

;;; Boundary:
;;; - Agreement rows are audit data only; they never execute CI commands.
;;; - Manifest and summary fields stay separate so each drift reason is visible.
;; : (-> Alist MaybeAlist Integer Alist)
(def (poo-flow-user-workflow-cicd-runtime-command-manifest-agreement-row
      manifest
      summary
      summary-count)
  (let* ((summary-row (or summary '()))
         (request (poo-flow-user-alist-ref manifest 'request '()))
         (policy (poo-flow-user-alist-ref manifest 'policy '()))
         (metadata (poo-flow-user-alist-ref manifest 'metadata '()))
         (request-id (poo-flow-user-alist-ref manifest 'request-id #f))
         (check-name (poo-flow-user-alist-ref request 'check #f))
         (manifest-argv (poo-flow-user-alist-ref manifest 'argv '()))
         (request-durable-task-id
          (poo-flow-user-alist-ref request 'durable-task-id #f))
         (request-action-class
          (poo-flow-user-alist-ref request 'action-class #f))
         (request-artifact-refs
          (poo-flow-user-alist-ref request 'artifact-refs '()))
         (request-artifact-retention
          (poo-flow-user-alist-ref request 'artifact-retention #f))
         (request-sandbox-refs
          (poo-flow-user-alist-ref request 'sandbox-refs '()))
         (request-checkpoint-ref
          (poo-flow-user-alist-ref request 'checkpoint-ref #f))
         (request-compensation-refs
          (poo-flow-user-alist-ref request 'compensation-refs '()))
         (policy-durable-task-id
          (poo-flow-user-alist-ref policy 'durable-task-id #f))
         (policy-action-class
          (poo-flow-user-alist-ref policy 'action-class #f))
         (policy-artifact-refs
          (poo-flow-user-alist-ref policy 'artifact-refs '()))
         (policy-artifact-provenance
          (poo-flow-user-alist-ref policy 'artifact-provenance '()))
         (policy-artifact-retention
          (poo-flow-user-alist-ref policy 'artifact-retention #f))
         (policy-sandbox-refs
          (poo-flow-user-alist-ref policy 'sandbox-refs '()))
         (policy-checkpoint-ref
          (poo-flow-user-alist-ref policy 'checkpoint-ref #f))
         (policy-compensation-refs
          (poo-flow-user-alist-ref policy 'compensation-refs '()))
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
         (durable-task-id-match?
          (and summary-present?
               (equal? (poo-flow-user-alist-ref summary-row
                                                'durable-task-id
                                                #f)
                       request-durable-task-id)
               (equal? request-durable-task-id policy-durable-task-id)))
         (action-class-match?
          (and summary-present?
               (equal? (poo-flow-user-alist-ref summary-row
                                                'action-class
                                                #f)
                       request-action-class)
               (equal? request-action-class policy-action-class)))
         (artifact-refs-match?
          (and summary-present?
               (equal? (poo-flow-user-alist-ref summary-row
                                                'artifact-refs
                                                '())
                       request-artifact-refs)
               (equal? request-artifact-refs policy-artifact-refs)))
         (artifact-provenance-match?
          (and summary-present?
               (equal? (poo-flow-user-alist-ref summary-row
                                                'artifact-provenance
                                                '())
                       policy-artifact-provenance)))
         (artifact-retention-match?
          (and summary-present?
               (equal? (poo-flow-user-alist-ref summary-row
                                                'artifact-retention
                                                #f)
                       request-artifact-retention)
               (equal? request-artifact-retention policy-artifact-retention)))
         (sandbox-refs-match?
          (and summary-present?
               (equal? (poo-flow-user-alist-ref summary-row
                                                'sandbox-refs
                                                '())
                       request-sandbox-refs)
               (equal? request-sandbox-refs policy-sandbox-refs)))
         (checkpoint-ref-match?
          (and summary-present?
               (equal? (poo-flow-user-alist-ref summary-row
                                                'checkpoint-ref
                                                #f)
                       request-checkpoint-ref)
               (equal? request-checkpoint-ref policy-checkpoint-ref)))
         (compensation-refs-match?
          (and summary-present?
               (equal? (poo-flow-user-alist-ref summary-row
                                                'compensation-refs
                                                '())
                       request-compensation-refs)
               (equal? request-compensation-refs policy-compensation-refs)))
         (diagnostics
          (append
           (poo-flow-user-workflow-cicd-runtime-command-agreement-diagnostics
            summary-count
            summary-present?
            check-match?
            argv-match?
            runtime-owner-match?
            unresolved-profile-refs-match?
            runtime-executed-match?)
           (poo-flow-user-workflow-cicd-runtime-command-durable-agreement-diagnostics
            summary-present?
            durable-task-id-match?
            action-class-match?
            artifact-refs-match?
            artifact-provenance-match?
            artifact-retention-match?
            sandbox-refs-match?
            checkpoint-ref-match?
            compensation-refs-match?))))
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
     (cons 'durable-task-id-match? durable-task-id-match?)
     (cons 'action-class-match? action-class-match?)
     (cons 'artifact-refs-match? artifact-refs-match?)
     (cons 'artifact-provenance-match? artifact-provenance-match?)
     (cons 'artifact-retention-match? artifact-retention-match?)
     (cons 'sandbox-refs-match? sandbox-refs-match?)
     (cons 'checkpoint-ref-match? checkpoint-ref-match?)
     (cons 'compensation-refs-match? compensation-refs-match?)
     (cons 'durable-task-id
           (poo-flow-user-alist-ref summary-row 'durable-task-id #f))
     (cons 'action-class
           (poo-flow-user-alist-ref summary-row 'action-class #f))
     (cons 'artifact-refs
           (poo-flow-user-alist-ref summary-row 'artifact-refs '()))
     (cons 'artifact-retention
           (poo-flow-user-alist-ref summary-row 'artifact-retention #f))
     (cons 'sandbox-refs
           (poo-flow-user-alist-ref summary-row 'sandbox-refs '()))
     (cons 'checkpoint-ref
           (poo-flow-user-alist-ref summary-row 'checkpoint-ref #f))
     (cons 'compensation-refs
           (poo-flow-user-alist-ref summary-row 'compensation-refs '()))
     (cons 'runtime-owner
           (poo-flow-user-alist-ref summary-row 'runtime-owner #f))
     (cons 'runtime-executed
           (poo-flow-user-alist-ref summary-row 'runtime-executed #f))
     (cons 'diagnostics diagnostics)
     (cons 'valid? (null? diagnostics)))))

;;; Boundary: user workflow cicd runtime command manifest agreement rows is the
;;; policy-visible edge for module-system, workflow behavior, keeping
;;; validation, lookup, or projection responsibilities centralized for callers.
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

;;; Boundary: user workflow cicd runtime command manifest agreement row
;;; diagnostics is the policy-visible edge for module-system, workflow
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
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

;;; The handoff receipt bundle is the user-interface receipt-sized envelope for
;;; Marlin handoff. It keeps the full ABI payload available while giving agents
;;; one stable object to inspect for agreement, proof gate, and non-execution
;;; evidence.
;; : (-> [Alist] [Alist] Alist [Alist] [Alist] [Alist] Alist)
(def (poo-flow-user-workflow-cicd-marlin-handoff-receipt-bundle
      manifest-maps
      manifest-summaries
      manifest-agreement
      handoff-abis
      handoff-summaries
      receipts)
  (list
   (cons 'schema
         'poo-flow.modules.workflow-cicd.marlin-handoff-receipt-bundle.v1)
   (cons 'kind 'workflow-cicd-marlin-handoff-receipt-bundle)
   (cons 'source 'poo-flow-user-config-presentation)
   (cons 'alignment-gate-id
         'stage-23-user-interface-marlin-handoff-projection)
   (cons 'proof-command
         "gxtest t/user-interface-cicd-test.ss: projects user config into Marlin runtime handoff ABI")
   (cons 'presentation-fields
         '(workflow-cicd-runtime-command-manifests
           workflow-cicd-runtime-command-manifest-summaries
           workflow-cicd-runtime-command-manifest-agreement
           workflow-cicd-marlin-runtime-handoff-abis
           workflow-cicd-marlin-runtime-handoff-summaries
           workflow-cicd-receipts))
   (cons 'runtime-owner +poo-flow-user-workflow-cicd-runtime-owner+)
   (cons 'handoff-required (> (length handoff-abis) 0))
   (cons 'runtime-executed #f)
   (cons 'runtime-parses-scheme-source #f)
   (cons 'scheme-manufactures-runtime-handlers #f)
   (cons 'manifest-map-count (length manifest-maps))
   (cons 'manifest-summary-count (length manifest-summaries))
   (cons 'manifest-agreement-valid?
         (poo-flow-user-alist-ref manifest-agreement 'valid? #f))
   (cons 'manifest-agreement-diagnostics
         (poo-flow-user-alist-ref manifest-agreement 'diagnostics '()))
   (cons 'marlin-runtime-handoff-abi-count (length handoff-abis))
   (cons 'marlin-runtime-handoff-summary-count (length handoff-summaries))
   (cons 'receipt-count (length receipts))
   (cons 'manifest-agreement-schema
         (poo-flow-user-alist-ref manifest-agreement 'schema #f))
   (cons 'manifest-agreement-row-count
         (length (poo-flow-user-alist-ref manifest-agreement 'rows '())))
   (cons 'marlin-runtime-handoff-entry-count
         (apply +
                (map (lambda (summary)
                       (poo-flow-user-alist-ref summary 'entry-count 0))
                     handoff-summaries)))))

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

;;; Shared alist lookup is total by design: presentation and agreement checks
;;; need to report partial payloads instead of failing on the first missing key.
;; : (-> Alist Symbol Value Value)
(def (poo-flow-user-alist-ref entries key default-value)
  (let (entry (assoc key entries))
    (if entry (cdr entry) default-value)))

;;; Readiness rows are nested by pipeline. This helper exposes the per-check
;;; rows that presentation uses for sandbox summary columns.
;; : (-> [Alist] [Alist])
(def (poo-flow-user-workflow-cicd-readiness-checks readiness-rows)
  (cond
   ((null? readiness-rows) '())
   (else
    (append
     (poo-flow-user-alist-ref (car readiness-rows) 'checks '())
     (poo-flow-user-workflow-cicd-readiness-checks
      (cdr readiness-rows))))))

;;; Field collection keeps repeated sandbox summary fields in declaration
;;; order; empty fields stay absent rather than fabricated.
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
