;;; -*- Gerbil -*-
;;; Boundary: downstream loop-engine case loaded by custom/my-module/config.ss.
;;; Invariant: pure use-module declaration; runtime work stays in Marlin.

;;; This case configures one concrete loop handoff story: an agent proposes a
;;; CI/CD repair, peer agents judge it, and a human node reviews release risk.
;; : [PooUserModuleSelection]
(use-module loop-engine
  :config
  (.def (current-system-build-loop @ loop-engine-use-case
                                   name level mode workflow)
    name: 'current-system-build-loop
    level: 'l2
    mode: 'guarded-handoff
    workflow: 'funflow-cicd)

  (.def (current-system-build-governor @ loop-engine-governor
                                       capabilities)
    capabilities: '(+strategy +policy +collision-check))

  (.def (current-system-build-judges @ loop-engine-agent-judges
                                     auditor verifier governor)
    auditor: 'ci-audit-agent
    verifier: 'build-verifier-agent
    governor: 'ci-loop-governor)

  (.def (current-system-build-human-audit @ loop-engine-human-audit
                                          actions)
    actions: '(+manual-gate +changes-requested))

  (.def (current-system-build-schedule @ loop-engine-schedule
                                       trigger cadence)
    trigger: 'manual
    cadence: 'on-demand)

  (.def (current-system-build-state @ loop-engine-state store path)
    store: 'file
    path: "loop-state/current-system-build.org")

  (.def (current-system-build-sandbox @ loop-engine-sandbox
                                      profile isolation)
    profile: 'ci/build
    isolation: 'project-copy)

  (.def (current-system-build-budget @ loop-engine-budget
                                     max-actionable max-attempts)
    max-actionable: 1
    max-attempts: 1)

  (.def (current-system-build-result @ loop-engine-result
                                     default auditor verifier governor
                                     human-audit format required-fields)
    default: 'poo-flow.loop-governor.node-result.v1
    auditor: 'poo-flow.loop-governor.audit-result.v1
    verifier: 'poo-flow.loop-governor.review-result.v1
    governor: 'poo-flow.loop-governor.governor-result.v1
    human-audit: 'poo-flow.loop-governor.human-audit-decision.v1
    format: 'structured-alist
    required-fields: '(decision summary evidence))

  (.def (current-system-build-observability @ loop-engine-observability
                                            receipt)
    receipt: 'l2-guarded-handoff)

  (.def (current-system-build-runtime @ loop-engine-runtime capabilities)
    capabilities: '(+manifest-handoff))

  (.def (current-system-build-lineage @ loop-engine-lineage-policy
                                      parent-session-refs lineage-kind
                                      lineage-operator journal export)
    parent-session-refs: '(incoming-ci-request-session)
    lineage-kind: 'guarded-handoff
    lineage-operator: 'current-system-build-loop
    journal: 'report-only
    export: 'jsonl)

  (.def (current-system-build-selector @ loop-engine-selector-policy
                                       candidates judge-inputs fallback
                                       selected-branch)
    candidates: '(current-system-build-loop)
    judge-inputs: '(ci-audit-agent build-verifier-agent ci-loop-governor)
    fallback: 'current-system-build-loop
    selected-branch: 'current-system-build-loop)

  (.def (current-system-build-resource-policy @ loop-engine-resource-policy
                                              tool-refs resource-keys
                                              collision-classes
                                              dispatch-groups)
    tool-refs: '(run-shell-command write-workspace-file read-workspace-file)
    resource-keys: '((run-shell-command . exec)
                     (write-workspace-file . (fs:write build-log))
                     (read-workspace-file . (fs:read build-log)))
    collision-classes: '((exec . serial)
                         ((fs:write build-log) . serial)
                         ((fs:read build-log) . parallel))
    dispatch-groups: '(((run-shell-command) . serial)
                       ((write-workspace-file read-workspace-file) . serial)))

  (.def (current-system-build-capability-policy
         @ loop-engine-capability-policy
         backend isolation required optional unsupported-behavior)
    backend: 'nono-sandbox
    isolation: 'project-copy
    required: '(command-run files-read files-write)
    optional: '(stream-events code-run)
    unsupported-behavior: 'handoff-diagnostic)

  (.def (current-system-build-memory-policy @ loop-engine-memory-policy
                                            use-case store state-path scope
                                            recall commit ranking retention)
    use-case: 'current-system-build-loop
    store: 'project-memory
    state-path: "loop-state/current-system-build.org"
    scope: 'session
    recall: '(last-user-message build-context prior-failure)
    commit: '(decision-summary evidence-index handoff-receipt)
    ranking: 'recency
    retention: 'report-only)

  (.def (current-system-build-compression-policy
         @ loop-engine-compression-policy
         strategy trigger summary-format lineage-kind retention)
    strategy: 'handoff-summary
    trigger: 'after-human-audit
    summary-format: 'structured-alist
    lineage-kind: 'compressed-ci-session
    retention: 'report-only)

  (.def (current-system-build-profile @ loop-engine-profile
                                      use-case governor agent-judges
                                      human-audit schedule state sandbox budget
                                      result observability runtime
                                      lineage-policy selector-policy
                                      resource-policy capability-policy
                                      memory-policies compression-policy)
    use-case: current-system-build-loop
    governor: current-system-build-governor
    agent-judges: current-system-build-judges
    human-audit: current-system-build-human-audit
    schedule: current-system-build-schedule
    state: current-system-build-state
    sandbox: current-system-build-sandbox
    budget: current-system-build-budget
    result: current-system-build-result
    observability: current-system-build-observability
    runtime: current-system-build-runtime
    lineage-policy: current-system-build-lineage
    selector-policy: current-system-build-selector
    resource-policy: current-system-build-resource-policy
    capability-policy: current-system-build-capability-policy
    memory-policies: (list current-system-build-memory-policy)
    compression-policy: current-system-build-compression-policy))
