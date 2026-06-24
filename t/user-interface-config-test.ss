;;; -*- Gerbil -*-
;;; Boundary: keep the public user-interface config test as a small aggregator.
;;; Scenario owners live in separate files so warning policy can isolate failures.

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
        "user-interface-config-modules-test.ss"
        "user-interface-cicd-profile-case-test.ss"
        "user-interface-config-core-case-test.ss"
        "user-interface-config-sandbox-case-test.ss"
        "user-interface-profile-set-case-test.ss")

(export user-interface-config-test)

;; : (-> Unit TestSuite)
(def user-interface-config-test
  (test-suite "poo-flow user interface config"
    user-interface-config-modules-test
    user-interface-cicd-profile-case-test
    user-interface-config-core-case-test
    user-interface-config-sandbox-case-test
    user-interface-profile-set-case-test))
