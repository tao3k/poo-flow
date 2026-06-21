;;; -*- Gerbil -*-
;;; Boundary: downstream Funflow CI/CD pipeline declaration.
;;; Invariant: this file declares workflow check-map data only; it does not
;;; execute commands or realize sandbox descriptors.

(use-module funflow
  :config
  (pipeline default
    (check build
      :inherits ci/build
      :command ("gxpkg" "build")
      :artifacts (build-log)
      :cache (gerbil-build-cache)
      :result (read :lines)
      :runtime manifest-handoff)
    (check test
      :inherits ci/check
      :needs (build)
      :command ("gxpkg" "env" "gxtest" "t/unit-tests.ss")
      :artifacts (test-receipt)
      :result (read :lines)
      :runtime manifest-handoff)
    (check package
      :inherits ci/check
      :needs (test)
      :command ("gxpkg" "env" "gxtest" "t/workflow-cicd-dependency-graph-test.ss")
      :artifacts (dependency-graph-receipt)
      :result (read :lines)
      :runtime manifest-handoff)))
