;;; -*- Gerbil -*-
;;; Boundary: package policy is a dependency-provided gxtest suite.

(import (only-in :gslph/src/policy/gxtest
                 make-policy-test))

(export project-policy-test)

(def project-policy-test
  (make-policy-test "." ["t/project-policy-test.ss"]))
