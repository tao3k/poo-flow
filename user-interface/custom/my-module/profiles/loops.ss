;;; -*- Gerbil -*-
;;; Boundary: downstream loop-engine profile declarations.
;;; Invariant: included by ../config.ss; it declares workflow loop intent only.

(use-module loop-engine
  :config
  (.def (repo-doctor-loop @ loop-engine-use-case
                          name level mode goal)
    name: 'repo-doctor
    level: 'l1
    mode: 'report-only
    goal: 'inspect-profile-and-policy-warnings)

  (.def (pull-request-review-loop @ loop-engine-use-case
                                  name level mode goal)
    name: 'pull-request-review
    level: 'l2
    mode: 'worktree-review
    goal: 'verify-maker-output-before-handoff)

  (.def (release-approval-loop @ loop-engine-use-case
                               name level mode goal)
    name: 'release-approval
    level: 'l2+
    mode: 'human-gated
    goal: 'require-human-signoff-before-release)

  (.def (repo-loop-governor-config @ loop-engine-governor capabilities)
    capabilities: '(+strategy +policy +node-graph))

  (.def (repo-loop-judges @ loop-engine-agent-judges
                          auditor verifier governor)
    auditor: 'repo-audit-agent
    verifier: 'repo-verifier-agent
    governor: 'repo-governor)

  (.def (repo-loop-human-audit @ loop-engine-human-audit actions)
    actions: '(+approval +rejection +changes-requested))

  (.def (repo-loop-result @ loop-engine-result
                          default auditor verifier governor human-audit
                          format required-fields)
    default: 'poo-flow.loop-governor.profile-node-result.v1
    auditor: 'poo-flow.loop-governor.profile-audit-result.v1
    verifier: 'poo-flow.loop-governor.profile-review-result.v1
    governor: 'poo-flow.loop-governor.profile-governor-result.v1
    human-audit: 'poo-flow.loop-governor.profile-human-audit-decision.v1
    format: 'structured-alist
    required-fields: '(decision summary evidence action-items))

  (.def (repo-loop-schedule @ loop-engine-schedule entries)
    entries: '((repo-doctor . manual)
               (pull-request-review . on-pr)
               (release-approval . manual-gate)))

  (.def (repo-loop-state @ loop-engine-state store path acting-on)
    store: 'file
    path: "loop-state/custom-my-module.org"
    acting-on: 'project-workspace)

  (.def (repo-loop-sandbox @ loop-engine-sandbox case-profile-refs)
    case-profile-refs: '((repo-doctor . agent/task)
                         (pull-request-review . agent/task-cache)
                         (release-approval . ci/build)))

  (.def (repo-loop-budget @ loop-engine-budget
                          max-actionable max-attempts weekly-runs)
    max-actionable: 1
    max-attempts: 2
    weekly-runs: 20)

  (.def (repo-loop-observability @ loop-engine-observability
                                 receipt run-log)
    receipt: 'loop-engine-intent
    run-log: "loop-run-log/custom-my-module.org")

  (.def (repo-loop-runtime @ loop-engine-runtime capabilities)
    capabilities: '(+manifest-handoff +l1-receipts))

  (.def (repo-loop-lineage @ loop-engine-lineage-policy
                           parent-session-refs lineage-kind
                           lineage-operator journal export)
    parent-session-refs: '(repo-root-session)
    lineage-kind: 'profile-loop
    lineage-operator: 'repo-loop-profile
    journal: 'report-only
    export: 'jsonl)

  (.def (repo-loop-selector @ loop-engine-selector-policy
                            candidates judge-inputs fallback selected-branch)
    candidates: '(repo-doctor pull-request-review release-approval)
    judge-inputs: '(repo-audit-agent repo-verifier-agent repo-governor)
    fallback: 'repo-doctor
    selected-branch: 'repo-doctor)

  (.def (repo-loop-resource-policy @ loop-engine-resource-policy
                                   tool-refs resource-keys
                                   collision-classes dispatch-groups)
    tool-refs: '(inspect-policy run-harness write-report)
    resource-keys: '((inspect-policy . repo-state)
                     (run-harness . exec)
                     (write-report . repo-state))
    collision-classes: '((repo-state . serial)
                         (exec . serial))
    dispatch-groups: '(((inspect-policy write-report) . serial)
                       ((run-harness) . serial)))

  (.def (repo-loop-capability-policy @ loop-engine-capability-policy
                                     backend isolation required optional
                                     unsupported-behavior)
    backend: 'cube-sandbox
    isolation: 'profile-selected
    required: '(command-run files-read files-write)
    optional: '(stream-events memory-recall compression-handoff)
    unsupported-behavior: 'report-only-warning)

  (.def (repo-loop-memory-policy @ loop-engine-memory-policy
                                 store scope recall commit ranking retention)
    store: 'repo-memory
    scope: 'profile
    recall: '(repo-state prior-findings human-decisions)
    commit: '(audit-summary selected-branch release-decision)
    ranking: 'priority
    retention: 'profile-scoped)

  (.def (repo-loop-profile @ loop-engine-profile
                           use-cases governor agent-judges human-audit
                           result schedule state sandbox budget
                           observability runtime lineage-policy
                           selector-policy resource-policy
                           capability-policy memory-policy)
    use-cases: (list repo-doctor-loop
                     pull-request-review-loop
                     release-approval-loop)
    governor: repo-loop-governor-config
    agent-judges: repo-loop-judges
    human-audit: repo-loop-human-audit
    result: repo-loop-result
    schedule: repo-loop-schedule
    state: repo-loop-state
    sandbox: repo-loop-sandbox
    budget: repo-loop-budget
    observability: repo-loop-observability
    runtime: repo-loop-runtime
    lineage-policy: repo-loop-lineage
    selector-policy: repo-loop-selector
    resource-policy: repo-loop-resource-policy
    capability-policy: repo-loop-capability-policy
    memory-policy: repo-loop-memory-policy))
