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

;; : (-> PooUserConfig)
(def (user-interface-cicd-runtime-graph-funflow-config)
  (pooFlowUserConfig
   (append poo-flow-custom-my-module-cicd-module
           poo-flow-custom-my-module-funflow-cicd-case)
   (poo-flow-settings)))

;; : (-> CicdRuntimeGraphContext Symbol Value)
(def (user-interface-cicd-runtime-graph-context-ref context key)
  (user-interface-cicd-runtime-graph-alist-ref context key))

;; : (-> CicdRuntimeGraphContext)
(def (user-interface-cicd-runtime-graph-context)
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
         (manifests
          (user-interface-cicd-runtime-graph-alist-ref
           manifest-map
           'manifests))
         (build-manifest (car manifests))
         (manifest-summaries
          (.ref presentation
                'workflow-cicd-runtime-command-manifest-summaries))
         (agreement
          (.ref presentation
                'workflow-cicd-runtime-command-manifest-agreement))
         (agreement-rows
          (user-interface-cicd-runtime-graph-alist-ref agreement 'rows))
         (handoff-abis
          (.ref presentation
                'workflow-cicd-marlin-runtime-handoff-abis))
         (handoff-entries
          (user-interface-cicd-runtime-graph-alist-ref
           (car handoff-abis)
           'entries)))
    (list
     (cons 'presentation presentation)
     (cons 'readiness readiness)
     (cons 'checks checks)
     (cons 'manifest-map manifest-map)
     (cons 'dependency-graph dependency-graph)
     (cons 'dependency-edges dependency-edges)
     (cons 'build-edge (car dependency-edges))
     (cons 'package-edge (cadr dependency-edges))
     (cons 'manifests manifests)
     (cons 'build-manifest build-manifest)
     (cons 'build-request
           (user-interface-cicd-runtime-graph-alist-ref
            build-manifest
            'request))
     (cons 'build-policy
           (user-interface-cicd-runtime-graph-alist-ref
            build-manifest
            'policy))
     (cons 'build-summary (car manifest-summaries))
     (cons 'test-summary (cadr manifest-summaries))
     (cons 'package-summary (caddr manifest-summaries))
     (cons 'agreement agreement)
     (cons 'build-agreement-row (car agreement-rows))
     (cons 'package-agreement-row (caddr agreement-rows))
     (cons 'build-handoff-entry (car handoff-entries))
     (cons 'runtime-summaries
           (.ref presentation 'workflow-cicd-sandbox-runtime-summaries)))))

;; : (-> CicdRuntimeGraphContext Void)
(def (check-cicd-runtime-readiness! context)
  (let* ((presentation
          (user-interface-cicd-runtime-graph-context-ref context 'presentation))
         (readiness
          (user-interface-cicd-runtime-graph-context-ref context 'readiness))
         (checks
          (user-interface-cicd-runtime-graph-context-ref context 'checks))
         (agreement
          (user-interface-cicd-runtime-graph-context-ref context 'agreement))
         (build-agreement-row
          (user-interface-cicd-runtime-graph-context-ref context
                                                         'build-agreement-row))
         (package-agreement-row
          (user-interface-cicd-runtime-graph-context-ref
           context
           'package-agreement-row))
         (runtime-summaries
          (user-interface-cicd-runtime-graph-context-ref context
                                                         'runtime-summaries)))
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
     (user-interface-cicd-runtime-graph-alist-ref build-agreement-row 'check)
     'build)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref build-agreement-row
                                                  'argv-match?)
     #t)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref build-agreement-row
                                                  'runtime-owner-match?)
     #t)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref
      build-agreement-row
      'unresolved-profile-refs-match?)
     #t)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref build-agreement-row
                                                  'runtime-executed-match?)
     #t)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref build-agreement-row
                                                  'durable-task-id-match?)
     #t)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref build-agreement-row
                                                  'artifact-provenance-match?)
     #t)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref package-agreement-row
                                                  'compensation-refs-match?)
     #t)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref build-agreement-row 'valid?)
     #t)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref readiness 'runtime-executed)
     #f)))

;; : (-> CicdRuntimeGraphContext Void)
(def (check-cicd-dependency-graph! context)
  (let* ((manifest-map
          (user-interface-cicd-runtime-graph-context-ref context 'manifest-map))
         (dependency-graph
          (user-interface-cicd-runtime-graph-context-ref context
                                                         'dependency-graph))
         (dependency-edges
          (user-interface-cicd-runtime-graph-context-ref context
                                                         'dependency-edges))
         (build-edge
          (user-interface-cicd-runtime-graph-context-ref context 'build-edge))
         (package-edge
          (user-interface-cicd-runtime-graph-context-ref context
                                                         'package-edge)))
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref manifest-map 'kind)
     'poo-flow.workflow.cicd.runtime-command-manifest-map)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref dependency-graph 'nodes)
     '(build test package))
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref dependency-graph
                                                  'order-policy)
     'declaration-topological-report)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref dependency-graph
                                                  'ready-order)
     '(build test package))
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref dependency-graph
                                                  'unordered-nodes)
     '())
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref dependency-graph
                                                  'blocked-order?)
     #f)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref dependency-graph 'valid?)
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
     (user-interface-cicd-runtime-graph-alist-ref dependency-graph
                                                  'unresolved-dependency-refs)
     '())))

;; : (-> CicdRuntimeGraphContext Void)
(def (check-cicd-build-manifest! context)
  (let* ((manifests
          (user-interface-cicd-runtime-graph-context-ref context 'manifests))
         (build-manifest
          (user-interface-cicd-runtime-graph-context-ref context
                                                         'build-manifest))
         (build-request
          (user-interface-cicd-runtime-graph-context-ref context
                                                         'build-request))
         (build-policy
          (user-interface-cicd-runtime-graph-context-ref context
                                                         'build-policy)))
    (check-equal? (length manifests) 3)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref build-manifest 'argv)
     '("gxpkg" "build"))
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref build-request 'check)
     'build)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref build-request
                                                  'durable-task-id)
     'task/build)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref build-request 'action-class)
     'idempotent)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref build-request 'artifact-refs)
     '(build-log))
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref build-request
                                                  'artifact-retention)
     'project-retained)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref build-request 'sandbox-refs)
     '(ci/build))
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref build-request
                                                  'checkpoint-ref)
     '(workflow-cicd-check build))
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref build-request
                                                  'compensation-refs)
     '())
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref build-policy
                                                  'durable-task-id)
     'task/build)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref build-policy
                                                  'artifact-provenance)
     '(((artifact-ref . build-log)
        (producer-check . build)
        (durable-task-id . task/build)
        (retention . project-retained)
        (runtime-owner . "marlin-agent-core")
        (runtime-executed . #f))))))

;; : (-> CicdRuntimeGraphContext Void)
(def (check-cicd-manifest-summaries! context)
  (let* ((build-summary
          (user-interface-cicd-runtime-graph-context-ref context
                                                         'build-summary))
         (test-summary
          (user-interface-cicd-runtime-graph-context-ref context
                                                         'test-summary))
         (package-summary
          (user-interface-cicd-runtime-graph-context-ref context
                                                         'package-summary)))
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
     (user-interface-cicd-runtime-graph-alist-ref build-summary
                                                  'durable-task-id)
     'task/build)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref build-summary
                                                  'artifact-provenance)
     '(((artifact-ref . build-log)
        (producer-check . build)
        (durable-task-id . task/build)
        (retention . project-retained)
        (runtime-owner . "marlin-agent-core")
        (runtime-executed . #f))))
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref build-summary
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
     (user-interface-cicd-runtime-graph-alist-ref build-summary 'handoff-ready)
     #t)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref test-summary
                                                  'dependency-refs)
     '(build))
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref package-summary 'check)
     'package)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref package-summary
                                                  'dependency-refs)
     '(test))
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref package-summary
                                                  'durable-task-id)
     'task/package)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref package-summary
                                                  'action-class)
     'compensatable)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref package-summary
                                                  'artifact-retention)
     'release-retained)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref package-summary
                                                  'compensation-refs)
     '(cleanup/package-artifacts))))

;; : (-> CicdRuntimeGraphContext Void)
(def (check-cicd-handoff-entry! context)
  (let (build-handoff-entry
        (user-interface-cicd-runtime-graph-context-ref context
                                                       'build-handoff-entry))
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref build-handoff-entry
                                                  'durable-task-id)
     'task/build)
    (check-equal?
     (user-interface-cicd-runtime-graph-alist-ref build-handoff-entry
                                                  'artifact-refs)
     '(build-log))))

;;; The custom module is the downstream user contract: the presentation must
;;; expose the three-node graph and the same ordered rows used for runtime
;;; manifest handoff, without executing the handoff adapter.
;; : TestSuite
(def user-interface-cicd-runtime-graph-test
  (test-suite "poo-flow user interface cicd runtime graph"
    (test-case "keeps workflow CI/CD graph projection inspectable"
      (let (context (user-interface-cicd-runtime-graph-context))
        (check-cicd-runtime-readiness! context)
        (check-cicd-dependency-graph! context)
        (check-cicd-build-manifest! context)
        (check-cicd-manifest-summaries! context)
        (check-cicd-handoff-entry! context)))))
