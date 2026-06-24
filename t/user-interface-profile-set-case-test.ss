;;; -*- Gerbil -*-
;;; Boundary: profile-set cases mirror Doom-style selection before realization.
;;; Doctor output is checked as POO data so user config remains declarative.

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
        "user-interface-fixtures.ss"
        :poo-flow/src/module-system/facade
        :poo-flow/src/module-system/profile-config)

(export user-interface-profile-set-case-test)

;; : (-> Unit TestSuite)
;;; This suite protects profile-set configuration as a downstream case composed
;;; from upstream module contracts.
(def user-interface-profile-set-case-test
  (test-suite "poo-flow user interface profile sets"
    (test-case "manages Doom-style profile sets before realization"
      (let* ((selected-profile
              (poo-flow-user-profile-set-default-profile
               test-poo-flow-user-profile-set))
             (presentation
              (pooFlowUserProfileSetPresentation
               test-poo-flow-user-profile-set)))
        (check-equal? (poo-flow-user-profile-set?
                       test-poo-flow-user-profile-set)
                      #t)
        (check-equal? (poo-flow-user-profile-set-name
                       test-poo-flow-user-profile-set)
                      'workspace)
        (check-equal? (poo-flow-user-profile-set-default-profile-name
                       test-poo-flow-user-profile-set)
                      'developer)
        (check-equal? (poo-flow-user-profile-set-profile-names
                       test-poo-flow-user-profile-set)
                      '(developer custom-developer))
        (check-equal? (poo-flow-user-profile-name selected-profile) 'developer)
        (check-equal? (.ref presentation 'kind)
                      poo-flow-user-profile-set-presentation-kind)
        (check-equal? (.ref presentation 'profile-count) 2)
        (check-equal? (.ref presentation 'selected-profile-name)
                      'developer)
        (check-equal? (.ref presentation 'selected-profile?) #t)
        (check-equal? (not
                       (not
                        (member "poo-flow-profile-set"
                                (.ref presentation 'user-entrypoints))))
                      #t)
        (check-equal? (not
                       (not
                        (member "pooFlowUserProfileSetPresentation"
                                (.ref presentation 'api-entrypoints))))
                      #t)
        (check-equal? (.ref presentation 'package-management?) #f)
        (check-equal? (.ref presentation 'descriptor-realized?) #f)
        (check-equal? (.ref presentation 'runtime-executed) #f)))
    (test-case "doctors Doom-style profile sets before selection"
      (let* ((valid-report
              (pooFlowUserProfileSetDoctor test-poo-flow-user-profile-set))
             (broken-presentation
              (pooFlowUserProfileSetDoctorPresentation
               test-poo-flow-user-broken-profile-set))
             (diagnostics (.ref broken-presentation 'profile-diagnostics)))
        (check-equal? (poo-flow-user-profile-set-doctor-ok? valid-report) #t)
        (check-equal? (.ref valid-report 'diagnostic-count) 0)
        (check-equal? (.ref broken-presentation 'doctor-status) 'error)
        (check-equal? (.ref broken-presentation 'doctor-ok) #f)
        (check-equal? (.ref broken-presentation 'diagnostic-count) 2)
        (check-equal? (diagnostic-code-member?
                       'duplicate-profile-name
                       diagnostics)
                      #t)
        (check-equal? (diagnostic-code-member?
                       'missing-default-profile
                       diagnostics)
                      #t)
        (check-equal? (.ref broken-presentation 'selected-profile?) #f)
        (check-equal? (.ref broken-presentation 'package-management?) #f)
        (check-equal? (.ref broken-presentation 'runtime-executed) #f)))))
