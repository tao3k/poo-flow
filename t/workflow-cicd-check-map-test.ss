;;; -*- Gerbil -*-
;;; Boundary: workflow CI/CD check maps are inert POO control-plane data.
;;; Invariant: tests prove receipts and runtime readiness without execution.

(import (only-in :std/test
                 test-suite
                 test-case
                 check-equal?
                 run-tests!)
        (only-in :clan/poo/object .ref object?)
        (only-in :poo-flow/src/core/runtime-adapter
                 +runtime-command-descriptor-schema+
                 +runtime-request-schema+)
        :poo-flow/src/modules/agent-sandbox/config
        :poo-flow/src/modules/workflow/cicd)

(export workflow-cicd-check-map-test)

;;; Tests inspect projected alists directly; this keeps assertions independent
;;; from the internal POO slot names used to avoid Gerbil object collisions.
;; : (-> Alist Symbol Value)
(def (cicd-test-alist-ref alist key)
  (let (entry (assoc key alist))
    (if entry (cdr entry) #f)))

;;; Negative cases should prove validation without leaking exception details
;;; into the public contract.
;; : (-> (-> Value) Boolean)
(def (cicd-test-error? thunk)
  (let (failure (with-catch (lambda (failure) failure) thunk))
    (error-object? failure)))

;;; The fixture mirrors user-interface CI/CD profile names but remains inert:
;;; no sandbox backend is resolved and no command is executed.
;; : (-> Unit PooFlowCicdCheckMap)
(def (cicd-test-check-map)
  (poo-flow-cicd-check-map
   'default
   (list
    (poo-flow-cicd-check
     'build
     'ci/build
     '("gxpkg" "build")
     '()
     '()
     '(build-log)
     '(gerbil-build-cache)
     '()
     '(read :lines)
     'manifest-handoff
     '((stage . build)))
    (poo-flow-cicd-check
     'test
     'ci/check
     '("gxpkg" "env" "gxtest" "t/unit-tests.ss")
     '()
     '()
     '(test-receipt)
     '()
     '()
     '(read :lines)
     'manifest-handoff
     '((stage . test)
       (dependency-refs . (build)))))))

;;; The sandbox profile catalog is optional. Tests pass it explicitly to prove
;;; check-map readiness can consume sandbox-owned summaries without owning
;;; filesystem/resource policy parsing.
;; : (-> Unit [PooSandboxProfile])
(def cicd-test-sandbox-profiles
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
    (metadata (intent . ci-build)
              (scope . cicd)))
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
    (metadata (intent . ci-check)
              (scope . cicd)))))

;;; This suite is the acceptance gate for the Milestone 3 bridge from Funflow
;;; =+cicd= intent to concrete Scheme receipts and manifest-readiness data.
;; : TestSuite
(def workflow-cicd-check-map-test
  (test-suite "workflow cicd check map"
    (test-case "constructs named POO checks and check maps"
      (let* ((check-map (cicd-test-check-map))
             (checks (poo-flow-cicd-check-map-checks check-map))
             (build-check (car checks))
             (test-check (cadr checks)))
        (check-equal? (object? check-map) #t)
        (check-equal? (poo-flow-cicd-check-map? check-map) #t)
        (check-equal? (.ref check-map 'kind)
                      (poo-flow-cicd-check-map-kind))
        (check-equal? (poo-flow-cicd-check-map-name check-map) 'default)
        (check-equal? (length checks) 2)
        (check-equal? (poo-flow-cicd-check? build-check) #t)
        (check-equal? (poo-flow-cicd-check? test-check) #t)
        (check-equal? (poo-flow-cicd-check-name build-check) 'build)
        (check-equal? (poo-flow-cicd-check-profile build-check) 'ci/build)
        (check-equal? (poo-flow-cicd-check-command test-check)
                      '("gxpkg" "env" "gxtest" "t/unit-tests.ss"))
        (check-equal? (poo-flow-cicd-check-dependency-refs build-check)
                      '())
        (check-equal? (poo-flow-cicd-check-dependency-refs test-check)
                      '(build))
        (check-equal? (.ref check-map 'runtime-executed) #f)))
    (test-case "projects check receipts without running runtime work"
      (let* ((check-map (cicd-test-check-map))
             (receipts (poo-flow-cicd-check-map->receipts check-map))
             (build-receipt (car receipts))
             (test-receipt (cadr receipts))
             (runtime-ready
              (cicd-test-alist-ref build-receipt
                                    'runtime-manifest-ready))
             (test-runtime-ready
              (cicd-test-alist-ref test-receipt
                                    'runtime-manifest-ready)))
        (check-equal? (length receipts) 2)
        (check-equal? (cicd-test-alist-ref build-receipt 'schema)
                      +poo-flow-cicd-check-receipt-schema+)
        (check-equal? (cicd-test-alist-ref build-receipt 'check) 'build)
        (check-equal? (cicd-test-alist-ref build-receipt 'profile) 'ci/build)
        (check-equal? (cicd-test-alist-ref build-receipt 'command)
                      '("gxpkg" "build"))
        (check-equal? (cicd-test-alist-ref build-receipt 'artifacts)
                      '(build-log))
        (check-equal? (cicd-test-alist-ref build-receipt 'cache)
                      '(gerbil-build-cache))
        (check-equal? (cicd-test-alist-ref build-receipt 'secrets) '())
        (check-equal? (cicd-test-alist-ref build-receipt 'runtime)
                      'manifest-handoff)
        (check-equal? (cicd-test-alist-ref build-receipt
                                           'dependency-refs)
                      '())
        (check-equal? (cicd-test-alist-ref test-receipt
                                           'dependency-refs)
                      '(build))
        (check-equal? (cicd-test-alist-ref build-receipt 'runtime-executed)
                      #f)
        (check-equal? (cicd-test-alist-ref test-runtime-ready
                                           'dependency-refs)
                      '(build))
        (check-equal? (cicd-test-alist-ref runtime-ready 'handoff-required)
                      #t)
        (check-equal? (cicd-test-alist-ref runtime-ready 'runtime-executed)
                      #f)
        (check-equal? (cicd-test-alist-ref runtime-ready
                                           'sandbox-runtime-summaries)
                      '())
        (check-equal? (cicd-test-alist-ref runtime-ready
                                           'sandbox-unresolved-profile-refs)
                      '(ci/build))
        (check-equal? (cicd-test-alist-ref runtime-ready 'argv)
                      '("gxpkg" "build"))))
    (test-case "resolves sandbox profile summaries when catalog is provided"
      (let* ((check-map (cicd-test-check-map))
             (receipts
              (poo-flow-cicd-check-map->receipts
               check-map
               cicd-test-sandbox-profiles))
             (build-receipt (car receipts))
             (runtime-ready
              (cicd-test-alist-ref build-receipt
                                    'runtime-manifest-ready))
             (sandbox-summaries
              (cicd-test-alist-ref runtime-ready
                                    'sandbox-runtime-summaries))
             (build-summary (car sandbox-summaries))
             (build-filesystem
              (cicd-test-alist-ref build-summary 'filesystem))
             (handoff-summaries
              (cicd-test-alist-ref runtime-ready
                                    'sandbox-handoff-summaries))
             (build-handoff (car handoff-summaries)))
        (check-equal? (cicd-test-alist-ref runtime-ready 'profile-refs)
                      '(ci/build))
        (check-equal? (cicd-test-alist-ref runtime-ready
                                           'sandbox-unresolved-profile-refs)
                      '())
        (check-equal? (cicd-test-alist-ref build-summary 'schema)
                      'poo-flow.agent-sandbox-profile.runtime-summary.v1)
        (check-equal? (cicd-test-alist-ref build-summary 'profile-name)
                      'ci/build)
        (check-equal? (cicd-test-alist-ref build-summary 'valid?) #t)
        (check-equal? (cicd-test-alist-ref build-filesystem 'scope)
                      'project-workspace)
        (check-equal? (cicd-test-alist-ref build-filesystem 'path-count) 1)
        (check-equal? (cicd-test-alist-ref build-handoff 'schema)
                      'poo-flow.agent-sandbox-profile.handoff-summary.v1)
        (check-equal? (cicd-test-alist-ref build-receipt
                                           'sandbox-runtime-summaries)
                      sandbox-summaries)))
    (test-case "projects check-map runtime manifest readiness"
      (let* ((check-map (cicd-test-check-map))
             (readiness
              (poo-flow-cicd-check-map->runtime-manifest-readiness check-map))
             (dependency-graph
              (cicd-test-alist-ref readiness 'dependency-graph))
             (dependency-edge
              (car (cicd-test-alist-ref dependency-graph 'edges)))
             (entries (cicd-test-alist-ref readiness 'checks))
             (test-entry (cadr entries)))
        (check-equal? (cicd-test-alist-ref readiness 'schema)
                      +poo-flow-cicd-runtime-manifest-readiness-schema+)
        (check-equal? (cicd-test-alist-ref readiness 'check-map) 'default)
        (check-equal? (cicd-test-alist-ref readiness 'runtime-executed) #f)
        (check-equal? (cicd-test-alist-ref dependency-graph 'nodes)
                      '(build test))
        (check-equal? (cicd-test-alist-ref dependency-edge 'from) 'build)
        (check-equal? (cicd-test-alist-ref dependency-edge 'to) 'test)
        (check-equal? (cicd-test-alist-ref dependency-graph
                                           'unresolved-dependency-refs)
                      '())
        (check-equal? (cicd-test-alist-ref dependency-graph
                                           'duplicate-nodes)
                      '())
        (check-equal? (cicd-test-alist-ref dependency-graph 'cycle-nodes)
                      '())
        (check-equal? (cicd-test-alist-ref dependency-graph 'diagnostics)
                      '())
        (check-equal? (cicd-test-alist-ref dependency-graph 'valid?) #t)
        (check-equal? (length entries) 2)
        (check-equal? (cicd-test-alist-ref test-entry 'check) 'test)
        (check-equal? (cicd-test-alist-ref test-entry 'profile) 'ci/check)
        (check-equal? (cicd-test-alist-ref test-entry 'dependency-refs)
                      '(build))
        (check-equal? (cicd-test-alist-ref test-entry
                                           'sandbox-unresolved-profile-refs)
                      '(ci/check))
        (check-equal? (cicd-test-alist-ref test-entry 'result)
                      '(read :lines))))
    (test-case "projects runtime command manifests from readiness"
      (let* ((check-map (cicd-test-check-map))
             (manifest-map
              (poo-flow-cicd-check-map->runtime-command-manifests
               check-map
               cicd-test-sandbox-profiles))
             (manifests (cicd-test-alist-ref manifest-map 'manifests))
             (build-manifest (car manifests))
             (test-manifest (cadr manifests))
             (dependency-graph
              (cicd-test-alist-ref manifest-map 'dependency-graph))
             (dependency-edge
              (car (cicd-test-alist-ref dependency-graph 'edges)))
             (build-request (cicd-test-alist-ref build-manifest 'request))
             (test-request (cicd-test-alist-ref test-manifest 'request))
             (build-metadata (cicd-test-alist-ref build-manifest 'metadata))
             (test-metadata (cicd-test-alist-ref test-manifest 'metadata)))
        (check-equal? (cicd-test-alist-ref manifest-map 'kind)
                      'poo-flow.workflow.cicd.runtime-command-manifest-map)
        (check-equal? (cicd-test-alist-ref manifest-map 'runtime-executed)
                      #f)
        (check-equal? (cicd-test-alist-ref dependency-graph 'nodes)
                      '(build test))
        (check-equal? (cicd-test-alist-ref dependency-edge 'from) 'build)
        (check-equal? (cicd-test-alist-ref dependency-edge 'to) 'test)
        (check-equal? (length manifests) 2)
        (check-equal? (cicd-test-alist-ref build-manifest 'schema)
                      +runtime-command-descriptor-schema+)
        (check-equal? (cicd-test-alist-ref build-manifest 'request-schema)
                      +runtime-request-schema+)
        (check-equal? (cicd-test-alist-ref build-manifest 'operation)
                      'workflow-cicd-check)
        (check-equal? (cicd-test-alist-ref build-manifest 'request-id)
                      '(poo-flow.workflow.cicd build))
        (check-equal? (cicd-test-alist-ref build-manifest 'name) 'build)
        (check-equal? (cicd-test-alist-ref build-manifest 'protocol)
                      '(read :lines))
        (check-equal? (cicd-test-alist-ref build-manifest 'executable)
                      "gxpkg")
        (check-equal? (cicd-test-alist-ref build-manifest 'arguments)
                      '("build"))
        (check-equal? (cicd-test-alist-ref build-manifest 'argv)
                      '("gxpkg" "build"))
        (check-equal? (cicd-test-alist-ref build-request 'kind)
                      'poo-flow.workflow.cicd.runtime-manifest-ready)
        (check-equal? (cicd-test-alist-ref build-request
                                           'sandbox-unresolved-profile-refs)
                      '())
        (check-equal? (cicd-test-alist-ref test-request 'dependency-refs)
                      '(build))
        (check-equal? (cicd-test-alist-ref build-metadata 'source)
                      'poo-flow.workflow.cicd.check)
        (check-equal? (cicd-test-alist-ref build-metadata 'runtime-executed)
                      #f)
        (check-equal? (cicd-test-alist-ref test-metadata 'dependency-refs)
                      '(build))
        (check-equal? (cicd-test-alist-ref test-metadata 'runtime-executed)
                      #f)))
    (test-case "exports Marlin runtime handoff ABI without execution"
      (let* ((check-map (cicd-test-check-map))
             (abi (poo-flow-cicd-check-map->marlin-runtime-handoff-abi
                   check-map
                   cicd-test-sandbox-profiles))
             (dependency-graph
              (cicd-test-alist-ref abi 'dependency-graph))
             (entries (cicd-test-alist-ref abi 'entries))
             (build-entry (car entries))
             (test-entry (cadr entries))
             (build-request
              (cicd-test-alist-ref build-entry 'request))
             (test-policy
              (cicd-test-alist-ref test-entry 'policy))
             (test-metadata
              (cicd-test-alist-ref test-entry 'metadata)))
        (check-equal? (cicd-test-alist-ref abi 'schema)
                      +poo-flow-cicd-marlin-runtime-handoff-abi-schema+)
        (check-equal? (cicd-test-alist-ref abi 'kind)
                      'poo-flow.workflow.cicd.marlin-runtime-handoff-abi)
        (check-equal? (cicd-test-alist-ref abi 'check-map) 'default)
        (check-equal? (cicd-test-alist-ref abi 'runtime-owner)
                      "marlin-agent-core")
        (check-equal? (cicd-test-alist-ref abi 'runtime-executed) #f)
        (check-equal? (cicd-test-alist-ref abi
                                           'runtime-parses-scheme-source)
                      #f)
        (check-equal? (cicd-test-alist-ref
                       abi
                       'scheme-manufactures-runtime-handlers)
                      #f)
        (check-equal? (cicd-test-alist-ref abi 'manifest-count) 2)
        (check-equal? (cicd-test-alist-ref abi 'required-fields)
                      '(operation
                        request-id
                        artifact-handle
                        argv
                        request
                        policy
                        plan-id
                        node-id
                        frontier
                        runtime-owner
                        handoff-required
                        runtime-executed))
        (check-equal? (cicd-test-alist-ref dependency-graph 'nodes)
                      '(build test))
        (check-equal? (length entries) 2)
        (check-equal? (cicd-test-alist-ref build-entry 'kind)
                      'poo-flow.workflow.cicd.marlin-runtime-handoff-entry)
        (check-equal? (cicd-test-alist-ref build-entry 'operation)
                      'workflow-cicd-check)
        (check-equal? (cicd-test-alist-ref build-entry 'request-id)
                      '(poo-flow.workflow.cicd build))
        (check-equal? (cicd-test-alist-ref build-entry 'argv)
                      '("gxpkg" "build"))
        (check-equal? (cicd-test-alist-ref build-request
                                           'sandbox-unresolved-profile-refs)
                      '())
        (check-equal? (cicd-test-alist-ref test-policy 'dependency-refs)
                      '(build))
        (check-equal? (cicd-test-alist-ref test-metadata 'dependency-refs)
                      '(build))
        (check-equal? (cicd-test-alist-ref test-entry 'runtime-owner)
                      "marlin-agent-core")
        (check-equal? (cicd-test-alist-ref test-entry 'handoff-required)
                      #t)
        (check-equal? (cicd-test-alist-ref test-entry 'runtime-executed)
                      #f)
        (check-equal? (cicd-test-alist-ref
                       test-entry
                       'runtime-parses-scheme-source)
                      #f)
        (check-equal? (cicd-test-alist-ref
                       test-entry
                       'scheme-manufactures-runtime-handlers)
                      #f)))
    (test-case "rejects unsafe fake check shapes"
      (check-equal?
       (cicd-test-error?
        (lambda ()
          (poo-flow-cicd-check
           'bad
           'ci/build
           '()
           '()
           '()
           '()
           '()
           '()
           '(read :lines)
           'manifest-handoff)))
       #t)
      (check-equal?
       (cicd-test-error?
        (lambda ()
          (poo-flow-cicd-check-map 'bad '(not-a-check))))
       #t))))

(run-tests! workflow-cicd-check-map-test)
