;;; -*- Gerbil -*-
;;; Boundary: CI/CD downstream sandbox profile cases live here.
;;; Invariant: cases stay declarative and do not execute release workflows.

(import :std/test
        :poo-flow/src/core/api
        (only-in :poo-flow/user-interface/custom/my-module/config
                 poo-flow-custom-my-module-cicd-module)
        :poo-flow/src/modules/module-system)

(export user-interface-cicd-profile-case-test)

;; : TestSuite
(def user-interface-cicd-profile-case-test
  (test-suite "poo-flow user interface CI/CD sandbox profiles"
    (test-case "loads CI/CD sandbox profiles from root user-interface config"
      (let* ((nono-config
              (car poo-flow-custom-my-module-cicd-module))
             (profiles
              (cdr (poo-flow-user-module-selection-flag-entry
                    nono-config
                    ':config)))
             (check-profile
              (poo-flow-sandbox-profile-by-name profiles 'ci/check))
             (build-profile
              (poo-flow-sandbox-profile-by-name profiles 'ci/build))
             (release-profile
              (poo-flow-sandbox-profile-by-name profiles 'cd/release))
             (promote-profile
              (poo-flow-sandbox-profile-by-name profiles
                                                'cicd/artifact-promote)))
        (check-equal? (length profiles) 4)
        (check-equal? (poo-flow-sandbox-profile-network-policy check-profile)
                      '(deny-by-default))
        (check-equal? (poo-flow-sandbox-profile-capabilities build-profile)
                      '(process-run filesystem-read filesystem-write tmpdir
                        cache-mount))
        (check-equal? (poo-flow-sandbox-profile-resource-policy check-profile)
                      '((filesystem . scoped)
                        (cpu . 1)
                        (memory . "1Gi")
                        (timeout-ms . 90000)))
        (check-equal? (poo-flow-sandbox-profile-network-policy release-profile)
                      '(allowlisted "github.com" "ghcr.io"))
        (check-equal? (poo-flow-sandbox-profile-metadata promote-profile)
                      '((declared-by . poo-flow-user-interface)
                        (runtime-executed . #f)
                        (intent . artifact-promote)
                        (scope . cicd)
                        (stage . promote)
                        (artifacts . consume)))))
    (test-case "rejects CI/CD resources without filesystem sandbox"
      (let* ((broken-config
              (car (use-module nono-sandbox
                    :config
                    (profiles
                     (ci/broken
                      (network deny-by-default)
                      (capabilities process-run filesystem-read tmpdir)
                      (resources (cpu . 1)
                                 (memory . "1Gi"))
                      (metadata (intent . ci-check)
                                (scope . cicd)))))))
             (profiles
              (cdr (poo-flow-user-module-selection-flag-entry
                    broken-config
                    ':config)))
             (broken-profile
              (poo-flow-sandbox-profile-by-name profiles 'ci/broken))
             (failure
              (with-catch (lambda (failure) failure)
                          (lambda ()
                            (poo-flow-sandbox-profile->profile
                             broken-profile)))))
        (check-equal? (poo-flow-sandbox-profile-capabilities broken-profile)
                      '(process-run filesystem-read tmpdir))
        (check-equal? (execution-failure? failure) #t)
        (check-equal? (execution-failure-code failure)
                      'invalid-agent-sandbox-profile)))))
