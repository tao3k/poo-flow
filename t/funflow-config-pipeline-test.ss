;;; -*- Gerbil -*-
;;; Boundary: Funflow POO config syntax lowers to workflow CI/CD POO data.
;;; Invariant: tests inspect declarations and receipts only; no runtime work.

(import (only-in :std/test
                 test-suite
                 test-case
                 check-equal?
                 run-tests!)
        :poo-flow/src/module-system/facade
        :poo-flow/src/modules/agent-sandbox/config
        (only-in :poo-flow/src/modules/funflow/config
                 poo-flow-funflow-pipeline-runtime-command-manifests)
        :poo-flow/src/modules/workflow/cicd
        (only-in :poo-flow/user-interface/custom/my-module/config
                 poo-flow-custom-my-module-funflow-cicd-case))

(export funflow-config-pipeline-test)

;;; Receipt helpers may use `assoc` because runtime-readiness and check receipt
;;; payloads are proper alists; module selection flags are intentionally not.
;; : (-> Alist Symbol Value)
(def (funflow-config-test-alist-ref alist key)
  (let (entry (assoc key alist))
    (if entry (cdr entry) #f)))

;;; Funflow config flags are mixed: bare feature symbols stay next to pair
;;; metadata entries. This lookup deliberately walks the list instead of using
;;; `assoc`, which requires every element to be pair-shaped.
;; : (-> [UserModuleFlagEntry] Symbol Value)
(def (funflow-config-test-flag flags key)
  (cond
   ((null? flags) #f)
   ((and (pair? (car flags))
         (eq? (caar flags) key))
    (cdar flags))
   ((pair? flags)
    (funflow-config-test-flag (cdr flags) key))
   (else #f)))

;;; Config rejection is tested by evaluating the macro-produced form and
;;; checking that the contract wrapper raises before any runtime handoff exists.
;; : (-> (-> Value) Boolean)
(def (funflow-config-test-error? thunk)
  (let (failure (with-catch (lambda (failure) failure) thunk))
    (error-object? failure)))

;;; The direct fixture is the public contract we want downstream users to copy:
;;; `funflow` is the module, and object declarations are native Gerbil POO.
;; : (-> Unit [PooUserModuleSelection])
(def (funflow-config-test-direct-selection)
  (use-module funflow
    :config
    (.def (funflow-test/build @ funflow-check
                              check-name profile-ref command-vector
                              artifact-outputs cache-intents result-protocol
                              runtime-mode)
      check-name: 'build
      profile-ref: 'ci/build
      command-vector: '("gxpkg" "build")
      artifact-outputs: '(build-log)
      cache-intents: '(gerbil-build-cache)
      result-protocol: '(read :lines)
      runtime-mode: 'manifest-handoff)

    (.def (funflow-test/integration @ funflow-check
                                    check-name profile-ref command-vector
                                    artifact-outputs result-protocol
                                    runtime-mode dependency-refs)
      check-name: 'integration
      profile-ref: '(ci/check agent/poo-object-extension)
      command-vector: '("gxpkg" "env" "gxtest" "t/unit-tests.ss")
      artifact-outputs: '(test-receipt)
      result-protocol: '(read :lines)
      runtime-mode: 'manifest-handoff
      dependency-refs: '(build))

    (.def (funflow-test/default @ funflow-pipeline
                                pipeline-name checks metadata)
      pipeline-name: 'default
      checks: (list funflow-test/build funflow-test/integration)
      metadata: '((scenario . direct-test)
                  (authoring-style . gerbil-poo-native)))))

;;; These profiles are local catalog fixtures for projection tests, not runtime
;;; sandbox launches; they let CI/CD inherit concrete filesystem policy while
;;; keeping command execution outside Scheme.
;; : (-> Unit [PooSandboxProfile])
(def funflow-config-test-sandbox-profiles
  (poo-flow-sandbox-profiles
   (ci/build
    (backend nono)
    (network allowlisted "github.com" "crates.io")
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
               (cpu . 4)
               (memory . "8Gi")
               (timeout-ms . 600000))
    (metadata (intent . funflow-ci-build)
              (scope . funflow-test)))
   (ci/check
    (backend nono)
    (network deny-by-default)
    (capabilities process-run filesystem-read tmpdir)
    (resources (filesystem
                (scope . project-workspace)
                (paths
                 ((role . project-workspace)
                  (source . ".")
                  (project-marker . "gerbil.pkg")
                  (target . "/workspace/project")
                  (mode . read-only)))
                (access . read-only))
               (cpu . 1)
               (memory . "1Gi")
               (timeout-ms . 90000))
    (metadata (intent . funflow-ci-check)
              (scope . funflow-test)))))

;;; This suite proves the public Funflow module config shape. The workflow
;;; category remains invalid as a module, and the produced check-map stays inert.
;; : TestSuite
(def funflow-config-pipeline-test
  (test-suite "funflow POO config pipeline"
    (test-case "lowers funflow POO config into a POO check-map"
      (let* ((selection (car (funflow-config-test-direct-selection)))
             (flags (poo-flow-user-module-selection-flags selection))
             (pipeline
              (funflow-config-test-flag flags ':workflow-pipeline))
             (checks (poo-flow-cicd-check-map-checks pipeline))
             (integration-check (cadr checks))
             (receipts
              (poo-flow-cicd-check-map->receipts
               pipeline
               funflow-config-test-sandbox-profiles))
             (integration-receipt (cadr receipts))
             (manifest-map
              (poo-flow-funflow-pipeline-runtime-command-manifests
               pipeline
               funflow-config-test-sandbox-profiles))
             (dependency-graph
              (funflow-config-test-alist-ref manifest-map 'dependency-graph))
             (dependency-edges
              (funflow-config-test-alist-ref dependency-graph 'edges))
             (integration-edge (car dependency-edges))
             (manifests
              (funflow-config-test-alist-ref manifest-map 'manifests))
             (integration-manifest (cadr manifests))
             (integration-request
              (funflow-config-test-alist-ref integration-manifest 'request))
             (manifest-summaries
              (poo-flow-user-workflow-cicd-runtime-command-manifest-summaries
               (list manifest-map)))
             (integration-summary (cadr manifest-summaries)))
        ;; Manifest assertions keep this test on the configured module path:
        ;; the pipeline object is discovered from `use-module`, then lowered to
        ;; runtime handoff data without constructing a fixture-only manifest.
        (check-equal? (poo-flow-user-module-selection-key selection)
                      '(flow . funflow))
        (check-equal? (poo-flow-cicd-check-map? pipeline) #t)
        (check-equal? (poo-flow-cicd-check-map-name pipeline) 'default)
        (check-equal? (length checks) 2)
        (check-equal? (poo-flow-cicd-check-name integration-check)
                      'integration)
        (check-equal? (poo-flow-cicd-check-profile integration-check)
                      '(ci/check agent/poo-object-extension))
        (check-equal? (poo-flow-cicd-check-dependency-refs integration-check)
                      '(build))
        (check-equal? (funflow-config-test-alist-ref dependency-graph 'nodes)
                      '(build integration))
        (check-equal? (funflow-config-test-alist-ref integration-edge 'from)
                      'build)
        (check-equal? (funflow-config-test-alist-ref integration-edge 'to)
                      'integration)
        (check-equal? (funflow-config-test-alist-ref
                       dependency-graph
                       'unresolved-dependency-refs)
                      '())
        (check-equal? (funflow-config-test-alist-ref
                       integration-receipt
                       'runtime-executed)
                      #f)
        (check-equal? (funflow-config-test-alist-ref
                       integration-receipt
                       'sandbox-unresolved-profile-refs)
                      '(agent/poo-object-extension))
        (check-equal? (funflow-config-test-alist-ref manifest-map 'kind)
                      'poo-flow.workflow.cicd.runtime-command-manifest-map)
        (check-equal? (funflow-config-test-alist-ref manifest-map
                                                     'runtime-executed)
                      #f)
        (check-equal? (length manifests) 2)
        (check-equal? (funflow-config-test-alist-ref integration-manifest
                                                     'executable)
                      "gxpkg")
        (check-equal? (funflow-config-test-alist-ref integration-manifest
                                                     'arguments)
                      '("env" "gxtest" "t/unit-tests.ss"))
        (check-equal? (funflow-config-test-alist-ref integration-request
                                                     'check)
                      'integration)
        (check-equal? (funflow-config-test-alist-ref integration-request
                                                     'dependency-refs)
                      '(build))
        (check-equal? (funflow-config-test-alist-ref integration-summary
                                                     'status)
                      'blocked)
        (check-equal? (funflow-config-test-alist-ref integration-summary
                                                     'handoff-ready)
                      #f)
        (check-equal? (funflow-config-test-alist-ref
                       integration-summary
                       'sandbox-unresolved-profile-refs)
                      '(agent/poo-object-extension))))
    (test-case "rejects workflow category as a module in config form"
      (check-equal?
       (funflow-config-test-error?
        (lambda ()
          (use-module workflow
            :config
            (pipeline default))
          #f))
       #t))
    (test-case "rejects non-symbol funflow POO dependency refs"
      (check-equal?
       (funflow-config-test-error?
        (lambda ()
          (use-module funflow
            :config
            (.def (funflow-test/bad @ funflow-check
                                    check-name profile-ref command-vector
                                    dependency-refs)
              check-name: 'bad
              profile-ref: 'ci/check
              command-vector: '("gxpkg" "build")
              dependency-refs: '("build"))
            (.def (funflow-test/bad-pipeline @ funflow-pipeline
                                             pipeline-name checks)
              pipeline-name: 'bad
              checks: (list funflow-test/bad)))
          #f))
       #t))
    (test-case "loads downstream funflow cicd case through load!"
      (let* ((selection (car poo-flow-custom-my-module-funflow-cicd-case))
             (pipeline
              (funflow-config-test-flag
               (poo-flow-user-module-selection-flags selection)
               ':workflow-pipeline))
             (readiness
              (poo-flow-cicd-check-map->runtime-manifest-readiness
               pipeline
               funflow-config-test-sandbox-profiles))
             (dependency-graph
              (funflow-config-test-alist-ref readiness 'dependency-graph))
             (entries (funflow-config-test-alist-ref readiness 'checks))
             (build-entry (car entries))
             (test-entry (cadr entries))
             (package-entry (caddr entries))
             (build-summaries
              (funflow-config-test-alist-ref
               build-entry
               'sandbox-runtime-summaries))
             (build-summary (car build-summaries))
             (build-filesystem
              (funflow-config-test-alist-ref build-summary 'filesystem)))
        (check-equal? (poo-flow-user-module-selection-key selection)
                      '(flow . funflow))
        (check-equal? (poo-flow-cicd-check-map-name pipeline) 'default)
        (check-equal? (length entries) 3)
        (check-equal? (funflow-config-test-alist-ref dependency-graph
                                                     'nodes)
                      '(build test package))
        (check-equal? (funflow-config-test-alist-ref dependency-graph
                                                     'order-policy)
                      'declaration-topological-report)
        (check-equal? (funflow-config-test-alist-ref dependency-graph
                                                     'ready-order)
                      '(build test package))
        (check-equal? (funflow-config-test-alist-ref dependency-graph
                                                     'unordered-nodes)
                      '())
        (check-equal? (funflow-config-test-alist-ref dependency-graph
                                                     'blocked-order?)
                      #f)
        (check-equal? (funflow-config-test-alist-ref dependency-graph
                                                     'valid?)
                      #t)
        (check-equal? (funflow-config-test-alist-ref test-entry
                                                     'dependency-refs)
                      '(build))
        (check-equal? (funflow-config-test-alist-ref package-entry
                                                     'dependency-refs)
                      '(test))
        (check-equal? (funflow-config-test-alist-ref build-entry
                                                     'sandbox-unresolved-profile-refs)
                      '())
        (check-equal? (funflow-config-test-alist-ref build-summary
                                                     'profile-name)
                      'ci/build)
        (check-equal? (funflow-config-test-alist-ref build-filesystem
                                                     'path-count)
                      1)
        (check-equal? (funflow-config-test-alist-ref readiness
                                                     'runtime-executed)
                      #f)))))

(run-tests! funflow-config-pipeline-test)
