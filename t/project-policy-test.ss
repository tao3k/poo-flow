;;; -*- Gerbil -*-
;;; Boundary: package policy is part of the normal gxtest suite.

(import (only-in :gslph/src/build-api/source-coverage
                 gslph-source-coverage)
        (only-in :gslph/src/policy/gxtest
                 display-project-policy-report
                 project-policy-report)
        (only-in :std/test
                 check
                 test-case
                 test-suite))

(export project-policy-test)

(gslph-source-coverage
 roots: '("src" "user-interface")
 runtime-roots: '("src"))

(def project-policy-test
  (test-suite "gerbil scheme project policy"
    (test-case "package policy has no warnings"
      (let (report (project-policy-report "."))
        (when (not (equal? (hash-get report 'status) "pass"))
          (display-project-policy-report report))
        (check (hash-get report 'status) => "pass")))))
