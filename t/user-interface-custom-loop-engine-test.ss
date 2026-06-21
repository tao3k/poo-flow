;;; -*- Gerbil -*-
;;; Boundary: tests verify custom user-interface loop-engine declarations.
;;; Invariant: custom loop cases project intent data and never execute loops.

(import (only-in :std/test
                 check
                 check-eq?
                 check-equal?
                 check-false
                 check-not-equal?
                 check-output
                 check-true
                 run-tests!
                 test-case
                 test-error
                 test-suite)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/facade
        (only-in :poo-flow/user-interface/custom/my-module/config
                 poo-flow-custom-my-module-loop-engine-case
                 poo-flow-custom-my-module-loops-module))

(export user-interface-custom-loop-engine-test)

;;; Intent rows are projected as alists for presentation only. The helper keeps
;;; the test at the public presentation boundary instead of reaching into the
;;; loop-engine module constructors.
;; | LoopEngineIntentRow = Alist
;; | LoopEngineIntentKey = Symbol
;; : (-> LoopEngineIntentRow LoopEngineIntentKey MaybeValue)
(def (test-ref alist key)
  (let (entry (assoc key alist))
    (if entry (cdr entry) #f)))

;;; Custom loop fixtures are tested through the same config presentation used
;;; by downstream user declarations. This helper avoids constructing a module
;;; descriptor or executing loop runtime code in the test.
;; : (-> [PooUserModuleSelection] POOObject)
(def (custom-loop-presentation/bundles module-bundles)
  (pooFlowUserConfigPresentation
   (pooFlowUserConfig
    (poo-flow-user-module-bundles->modules module-bundles)
    (poo-flow-settings))))

;; : (-> [PooUserModuleSelection] POOObject)
(def (custom-loop-presentation module-bundle)
  (custom-loop-presentation/bundles (list module-bundle)))

;;; The concrete loop case references `ci/build`. This local sandbox module
;;; lets one test resolve that profile into sandbox-owned runtime summaries.
;; : [PooUserModuleSelection]
(def custom-loop-sandbox-profile-module
  (use-module nono-sandbox
    :config
    (profiles
     (ci/build
      (network deny-by-default)
      (capabilities process-run filesystem-read filesystem-write tmpdir)
      (resources (filesystem
                  (scope . project-workspace)
                  (paths
                   ((role . project-workspace)
                    (source . ".")
                    (project-marker . "gerbil.pkg")
                    (target . "/workspace/project")
                    (mode . read-write)))
                  (access . read-write))
                 (cpu . 2)
                 (memory . "4Gi")
                 (timeout-ms . 300000))
      (metadata (intent . loop-engine-ci-build)
                (scope . test))))))

;;; The suite compares user-facing loop intent rows after profile projection.
;;; It deliberately stops before module descriptor realization so custom user
;;; cases stay inspectable declaration data.
;; : TestSuite
(def user-interface-custom-loop-engine-test
  (test-suite "poo-flow custom user-interface loop-engine cases"
    (test-case "projects custom loop-engine profile use cases"
      (let* ((presentation
              (custom-loop-presentation
               poo-flow-custom-my-module-loops-module))
             (intent
              (car (.ref presentation 'loop-engine-intents))))
        (check-equal? (.ref presentation 'module-count) 1)
        (check-equal? (.ref presentation 'module-keys)
                      '((flow . loop-engine)))
        (check-equal? (.ref presentation 'loop-engine-intent-count) 1)
        (check-equal? (test-ref intent 'workflow-owned?) #t)
        (check-equal? (test-ref intent 'governor)
                      '(+strategy +policy +node-graph))
        (check-equal? (map car (test-ref intent 'use-cases))
                      '(repo-doctor pull-request-review release-approval))
        (check-equal? (test-ref intent 'sandbox)
                      '((repo-doctor . agent/task)
                        (pull-request-review . agent/task-cache)
                        (release-approval . ci/build)))
        (check-equal? (test-ref intent 'runtime-handoff)
                      'loop-governor-marlin-runtime-manifest)
        (check-equal? (test-ref intent 'runtime-handoff-contracts)
                      '(start-workflow-run
                        admit-dispatch
                        open-agent-session
                        execute-agent-operation
                        stream-events
                        read-runtime-snapshot))
        (check-equal? (test-ref intent 'runtime-executed) #f)))
    (test-case "projects custom concrete loop-engine case"
      (let* ((presentation
              (custom-loop-presentation
               poo-flow-custom-my-module-loop-engine-case))
             (intent
              (car (.ref presentation 'loop-engine-intents)))
             (handoff
              (test-ref intent 'runtime-handoff-facts))
             (workflow-run
              (test-ref intent 'workflow-run))
             (dispatch-receipt
              (test-ref intent 'dispatch-receipt))
             (agent-operation
              (test-ref intent 'agent-operation))
             (runtime-manifest
              (test-ref intent 'runtime-command-manifest))
             (runtime-manifest-request
              (test-ref runtime-manifest 'request))
             (runtime-manifest-metadata
              (test-ref runtime-manifest 'metadata))
             (runtime-manifest-summary
              (test-ref intent 'runtime-command-manifest-summary))
             (runtime-snapshot
              (test-ref intent 'runtime-snapshot))
             (sandbox-profile-refs
              (test-ref intent 'sandbox-profile-refs))
             (sandbox-runtime-summaries
              (test-ref intent 'sandbox-runtime-summaries))
             (sandbox-handoff-summaries
              (test-ref intent 'sandbox-handoff-summaries))
             (sandbox-unresolved-profile-refs
              (test-ref intent 'sandbox-unresolved-profile-refs))
             (presentation-snapshot
              (car (.ref presentation 'loop-engine-runtime-snapshots)))
             (presentation-operation
              (car (.ref presentation 'loop-engine-agent-operations)))
             (presentation-manifest
              (car (.ref presentation
                         'loop-engine-runtime-command-manifests)))
             (presentation-manifest-summary
              (car (.ref presentation
                         'loop-engine-runtime-command-manifest-summaries)))
             (operation-runtime-intent
              (test-ref agent-operation 'runtime-intent)))
        (check-equal? (.ref presentation 'module-count) 1)
        (check-equal? (test-ref intent 'use-case)
                      '(current-system-build-loop
                        (level . l2)
                        (mode . guarded-handoff)
                        (workflow . funflow-cicd)))
        (check-equal? (test-ref intent 'agent-judges)
                      '((auditor ci-audit-agent)
                        (verifier build-verifier-agent)
                        (governor ci-loop-governor)))
        (check-equal? (test-ref intent 'human-audit)
                      '(+manual-gate +changes-requested))
        (check-equal? (test-ref intent 'sandbox)
                      '((profile . ci/build)
                        (isolation . project-copy)))
        (check-equal? sandbox-profile-refs '(ci/build))
        (check-equal? sandbox-runtime-summaries '())
        (check-equal? sandbox-handoff-summaries '())
        (check-equal? sandbox-unresolved-profile-refs '(ci/build))
        (check-equal? (test-ref handoff 'contract)
                      'poo-flow.loop-governor.runtime-handoff.v1)
        (check-equal? (test-ref handoff 'workflow-ref) 'funflow-cicd)
        (check-equal? (test-ref handoff 'runtime-executed) #f)
        (check-equal? (test-ref workflow-run 'kind) 'workflow-run)
        (check-equal? (test-ref workflow-run 'workflow-ref) 'funflow-cicd)
        (check-equal? (test-ref workflow-run 'status) 'waiting-human)
        (check-equal? (test-ref dispatch-receipt 'kind) 'dispatch-receipt)
        (check-equal? (test-ref dispatch-receipt 'target-agent)
                      'ci-audit-agent)
        (check-equal? (test-ref dispatch-receipt 'admission-status)
                      'admitted)
        (check-equal? (test-ref agent-operation 'kind) 'agent-operation)
        (check-equal? (test-ref agent-operation 'operation-kind)
                      'human-audit)
        (check-equal? (test-ref agent-operation 'status) 'waiting-human)
        (check-equal? (test-ref operation-runtime-intent 'executes-runtime)
                      #f)
        (check-equal? (test-ref runtime-manifest 'schema)
                      'poo-flow.runtime-command-descriptor.v1)
        (check-equal? (test-ref runtime-manifest 'request-schema)
                      'poo-flow.runtime-request.v1)
        (check-equal? (test-ref runtime-manifest 'operation)
                      'loop-engine-handoff)
        (check-equal? (test-ref runtime-manifest 'executable)
                      "marlin-agent-core")
        (check-equal? (test-ref runtime-manifest 'argv)
                      '("marlin-agent-core"
                        "poo-flow"
                        "runtime"
                        "loop-engine-handoff"))
        (check-equal? (test-ref runtime-manifest-request 'kind)
                      'loop-engine-runtime-handoff-request)
        (check-equal? (test-ref runtime-manifest-request 'contract)
                      'poo-flow.loop-governor.runtime-command-manifest.v1)
        (check-equal? (test-ref runtime-manifest-request 'object-families)
                      '(workflow-run
                        dispatch-receipt
                        agent-operation
                        runtime-snapshot))
        (check-equal? (test-ref runtime-manifest-request
                                 'sandbox-profile-refs)
                      '(ci/build))
        (check-equal? (test-ref runtime-manifest-request
                                 'sandbox-runtime-summaries)
                      '())
        (check-equal? (test-ref runtime-manifest-request
                                 'sandbox-unresolved-profile-refs)
                      '(ci/build))
        (check-equal? (test-ref (test-ref runtime-manifest-request
                                           'agent-operation)
                                'operation-kind)
                      'human-audit)
        (check-equal? (test-ref runtime-manifest-metadata 'contract)
                      'poo-flow.loop-governor.runtime-command-manifest.v1)
        (check-equal? (test-ref runtime-manifest-summary 'kind)
                      'runtime-command-manifest-summary)
        (check-equal? (test-ref runtime-manifest-summary 'operation)
                      'loop-engine-handoff)
        (check-equal? (test-ref runtime-manifest-summary 'object-families)
                      '(workflow-run
                        dispatch-receipt
                        agent-operation
                        runtime-snapshot))
        (check-equal? (test-ref runtime-snapshot 'kind) 'runtime-snapshot)
        (check-equal? (test-ref runtime-snapshot 'subject-kind)
                      'loop-engine)
        (check-equal? (test-ref runtime-snapshot 'subject-id)
                      'current-system-build-loop)
        (check-equal? (test-ref runtime-snapshot 'status) 'waiting-human)
        (check-equal? (.ref presentation 'loop-engine-runtime-snapshot-count)
                      1)
        (check-equal? (test-ref presentation-snapshot 'status)
                      'waiting-human)
        (check-equal? (test-ref presentation-operation 'operation-kind)
                      'human-audit)
        (check-equal? (test-ref presentation-manifest 'operation)
                      'loop-engine-handoff)
        (check-equal? (test-ref presentation-manifest-summary 'contract)
                      'poo-flow.loop-governor.runtime-command-manifest.v1)
        (check-equal? (test-ref intent 'runtime-executed) #f)))
    (test-case "resolves sandbox profile summaries into loop-engine manifest"
      (let* ((presentation
              (custom-loop-presentation/bundles
               (list custom-loop-sandbox-profile-module
                     poo-flow-custom-my-module-loop-engine-case)))
             (intent
              (car (.ref presentation 'loop-engine-intents)))
             (runtime-manifest
              (test-ref intent 'runtime-command-manifest))
             (runtime-manifest-request
              (test-ref runtime-manifest 'request))
             (sandbox-runtime-summaries
              (test-ref intent 'sandbox-runtime-summaries))
             (sandbox-runtime-summary
              (car sandbox-runtime-summaries))
             (sandbox-filesystem
              (test-ref sandbox-runtime-summary 'filesystem))
             (sandbox-handoff-summaries
              (test-ref intent 'sandbox-handoff-summaries))
             (sandbox-handoff-summary
              (car sandbox-handoff-summaries)))
        (check-equal? (.ref presentation 'module-count) 2)
        (check-equal? (test-ref intent 'sandbox-profile-refs) '(ci/build))
        (check-equal? (test-ref intent 'sandbox-unresolved-profile-refs) '())
        (check-equal? (test-ref sandbox-runtime-summary 'schema)
                      'poo-flow.agent-sandbox-profile.runtime-summary.v1)
        (check-equal? (test-ref sandbox-runtime-summary 'profile-name)
                      'ci/build)
        (check-equal? (test-ref sandbox-runtime-summary 'backend-kind) 'nono)
        (check-equal? (test-ref sandbox-runtime-summary 'valid?) #t)
        (check-equal? (test-ref sandbox-filesystem 'path-count) 1)
        (check-equal? (test-ref sandbox-filesystem 'scope)
                      'project-workspace)
        (check-equal? (test-ref sandbox-handoff-summary 'schema)
                      'poo-flow.agent-sandbox-profile.handoff-summary.v1)
        (check-equal? (test-ref sandbox-handoff-summary 'profile-name)
                      'ci/build)
        (check-equal? (test-ref runtime-manifest-request
                                 'sandbox-runtime-summaries)
                      sandbox-runtime-summaries)
        (check-equal? (test-ref runtime-manifest-request
                                 'sandbox-handoff-summaries)
                      sandbox-handoff-summaries)
        (check-equal? (test-ref runtime-manifest-request
                                 'sandbox-unresolved-profile-refs)
                      '())
        (check-equal? (car (.ref presentation
                                  'loop-engine-sandbox-runtime-summaries))
                      sandbox-runtime-summaries)
        (check-equal? (car (.ref presentation
                                  'loop-engine-sandbox-handoff-summaries))
                      sandbox-handoff-summaries)))))

(run-tests! user-interface-custom-loop-engine-test)
