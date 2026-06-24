;;; -*- Gerbil -*-
;;; Boundary: tests inspect the user-facing Funflow CI/CD dependency graph.
;;; Invariant: graph projection stays declarative and runtime-free.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/facade
        (only-in :poo-flow/user-interface/custom/my-module/config
                 poo-flow-custom-my-module-cicd-module
                 poo-flow-custom-my-module-funflow-cicd-case)
        :poo-flow/t/user-interface-fixtures)

(export user-interface-cicd-runtime-graph-test)

;; : (-> Alist Symbol Value)
(def (user-interface-cicd-runtime-graph-alist-ref entries key)
  (let (entry (assoc key entries))
    (if entry (cdr entry) #f)))

;; : (-> Unit PooUserConfig)
(def (user-interface-cicd-runtime-graph-funflow-config)
  (pooFlowUserConfig
   (append poo-flow-custom-my-module-cicd-module
           poo-flow-custom-my-module-funflow-cicd-case)
   (poo-flow-settings)))

;;; The custom module is the downstream user contract: the presentation must
;;; expose the three-node graph and the same ordered rows used for runtime
;;; manifest handoff, without executing the handoff adapter.
;; : TestSuite
(def user-interface-cicd-runtime-graph-test
  (test-suite "poo-flow user interface cicd runtime graph"
    (test-case "keeps workflow CI/CD graph projection inspectable"
      (let* ((presentation
              (pooFlowUserConfigPresentation
               (user-interface-cicd-runtime-graph-funflow-config)))
             (readiness
              (car (.ref presentation 'workflow-cicd-runtime-readiness)))
             (checks
              (user-interface-cicd-runtime-graph-alist-ref readiness 'checks))
             (manifest-map
              (car (.ref presentation
                         'workflow-cicd-runtime-command-manifests)))
             (dependency-graph
              (user-interface-cicd-runtime-graph-alist-ref
               manifest-map
               'dependency-graph))
             (dependency-edges
              (user-interface-cicd-runtime-graph-alist-ref
               dependency-graph
               'edges))
             (build-edge (car dependency-edges))
             (package-edge (cadr dependency-edges))
             (manifests
              (user-interface-cicd-runtime-graph-alist-ref
               manifest-map
               'manifests))
             (build-manifest (car manifests))
             (build-request
              (user-interface-cicd-runtime-graph-alist-ref
               build-manifest
               'request))
             (manifest-summaries
              (.ref presentation
                    'workflow-cicd-runtime-command-manifest-summaries))
             (build-summary (car manifest-summaries))
             (test-summary (cadr manifest-summaries))
             (package-summary (caddr manifest-summaries))
             (agreement
              (.ref presentation
                    'workflow-cicd-runtime-command-manifest-agreement))
             (agreement-rows
              (user-interface-cicd-runtime-graph-alist-ref agreement 'rows))
             (build-agreement-row (car agreement-rows))
             (runtime-summaries
              (.ref presentation 'workflow-cicd-sandbox-runtime-summaries)))
        (check-equal? (length checks) 3)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref (car checks) 'check)
         'build)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref (cadr checks) 'check)
         'test)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref (caddr checks) 'check)
         'package)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref
          (car runtime-summaries)
          'profile-name)
         'ci/build)
        (check-equal?
         (.ref presentation 'workflow-cicd-runtime-command-manifest-map-count)
         1)
        (check-equal?
         (.ref presentation 'workflow-cicd-runtime-command-manifest-summary-count)
         3)
        (check-equal?
         (.ref presentation
               'workflow-cicd-runtime-command-manifest-agreement-valid?)
         #t)
        (check-equal?
         (.ref presentation
               'workflow-cicd-runtime-command-manifest-agreement-diagnostics)
         '())
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref agreement 'manifest-count)
         3)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref agreement 'summary-count)
         3)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref agreement 'agreement-count)
         3)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref agreement 'valid?)
         #t)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref
          build-agreement-row
          'check)
         'build)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref
          build-agreement-row
          'argv-match?)
         #t)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref
          build-agreement-row
          'runtime-owner-match?)
         #t)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref
          build-agreement-row
          'unresolved-profile-refs-match?)
         #t)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref
          build-agreement-row
          'runtime-executed-match?)
         #t)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref
          build-agreement-row
          'valid?)
         #t)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref manifest-map 'kind)
         'poo-flow.workflow.cicd.runtime-command-manifest-map)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref dependency-graph 'nodes)
         '(build test package))
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref
          dependency-graph
          'order-policy)
         'declaration-topological-report)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref
          dependency-graph
          'ready-order)
         '(build test package))
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref
          dependency-graph
          'unordered-nodes)
         '())
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref
          dependency-graph
          'blocked-order?)
         #f)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref
          dependency-graph
          'valid?)
         #t)
        (check-equal? (length dependency-edges) 2)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref build-edge 'from)
         'build)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref build-edge 'to)
         'test)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref package-edge 'from)
         'test)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref package-edge 'to)
         'package)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref
          dependency-graph
          'unresolved-dependency-refs)
         '())
        (check-equal? (length manifests) 3)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref build-manifest 'argv)
         '("gxpkg" "build"))
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref build-request 'check)
         'build)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref build-summary 'kind)
         'workflow-cicd-runtime-command-manifest-summary)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref build-summary 'check)
         'build)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref build-summary 'argv)
         '("gxpkg" "build"))
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref
          build-summary
          'runtime-owner)
         "marlin-agent-core")
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref
          build-summary
          'sandbox-unresolved-profile-refs)
         '())
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref build-summary 'status)
         'ready)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref
          build-summary
          'handoff-ready)
         #t)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref
          test-summary
          'dependency-refs)
         '(build))
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref package-summary 'check)
         'package)
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref
          package-summary
          'dependency-refs)
         '(test))
        (check-equal?
         (user-interface-cicd-runtime-graph-alist-ref
          readiness
          'runtime-executed)
         #f)))))
