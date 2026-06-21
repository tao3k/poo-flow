;;; -*- Gerbil -*-
;;; Boundary: downstream Funflow CI/CD pipeline declaration.
;;; Invariant: this file declares POO workflow objects only; no runtime work.

(use-module funflow
  :config
  (.def (funflow/build @ funflow-check
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

  (.def (funflow/test @ funflow-check
                      check-name profile-ref command-vector
                      artifact-outputs result-protocol runtime-mode
                      dependency-refs)
    check-name: 'test
    profile-ref: 'ci/check
    command-vector: '("gxpkg" "env" "gxtest" "t/unit-tests.ss")
    artifact-outputs: '(test-receipt)
    result-protocol: '(read :lines)
    runtime-mode: 'manifest-handoff
    dependency-refs: '(build))

  (.def (funflow/package @ funflow-check
                         check-name profile-ref command-vector
                         artifact-outputs result-protocol runtime-mode
                         dependency-refs)
    check-name: 'package
    profile-ref: 'ci/check
    command-vector: '("gxpkg"
                      "env"
                      "gxtest"
                      "t/workflow-cicd-dependency-graph-test.ss")
    artifact-outputs: '(dependency-graph-receipt)
    result-protocol: '(read :lines)
    runtime-mode: 'manifest-handoff
    dependency-refs: '(test))

  (.def (funflow/default @ funflow-pipeline
                         pipeline-name checks metadata)
    pipeline-name: 'default
    checks: (list funflow/build funflow/test funflow/package)
    metadata: '((scenario . funflow-cicd)
                (authoring-style . gerbil-poo-native))))
