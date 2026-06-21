;;; -*- Gerbil -*-
;;; Boundary: CI/CD downstream sandbox profile cases live here.
;;; Invariant: cases stay declarative and do not execute release workflows.

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
        :poo-flow/src/core/api
        (only-in :poo-flow/user-interface/custom/my-module/config
                 poo-flow-custom-my-module-cicd-module)
        :poo-flow/src/module-system/facade)

(export user-interface-cicd-profile-case-test)

;; : TestSuite
;;; This suite protects the CI/CD profile case as an executable downstream
;;; configuration story.
(def user-interface-cicd-profile-case-test
  (test-suite "poo-flow user interface CI/CD sandbox profiles"
    (test-case "loads CI/CD sandbox profiles from root user-interface config"
      (let* ((nono-config
              (car poo-flow-custom-my-module-cicd-module))
             (profiles
              (cdr (poo-flow-user-module-selection-flag-entry
                    nono-config
                    ':config)))
             (binding
              (cdr (poo-flow-user-module-selection-flag-entry
                    nono-config
                    ':binding)))
             (check-profile
              (poo-flow-sandbox-profile-by-name profiles 'ci/check))
             (build-profile
              (poo-flow-sandbox-profile-by-name profiles 'ci/build))
             (release-profile
              (poo-flow-sandbox-profile-by-name profiles 'cd/release))
             (promote-profile
              (poo-flow-sandbox-profile-by-name profiles
                                                'cicd/artifact-promote)))
        (check-equal? binding 'native-ffi)
        (check-equal? (length profiles) 4)
        (check-equal? (poo-flow-sandbox-profile-network-policy check-profile)
                      '(deny-by-default))
        (check-equal? (poo-flow-sandbox-profile-capabilities build-profile)
                      '(process-run filesystem-read filesystem-write tmpdir
                        cache-mount))
        (check-equal? (poo-flow-sandbox-profile-resource-policy check-profile)
                      '((filesystem
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
    (test-case "defaults nono use-module config to native FFI binding"
      (let* ((nono-config
              (car (use-module nono-sandbox
                    :config
                    (profiles
                     (ci/check
                      (network deny-by-default)
                      (capabilities process-run filesystem-read tmpdir)
                      (resources (filesystem
                                  (scope . project-workspace)
                                  (paths
                                   ((role . project-workspace)
                                    (source . ".")
                                    (project-marker . "gerbil.pkg")
                                    (target . "/workspace/project")
                                    (mode . read-only)))))
                      (metadata (intent . ci-check)))))))
             (binding
              (cdr (poo-flow-user-module-selection-flag-entry
                    nono-config
                    ':binding))))
        (check-equal? binding 'native-ffi)))
    (test-case "rejects empty filesystem sandbox marker in use-module profiles"
      (let ((failure
             (with-catch
              (lambda (failure) failure)
              (lambda ()
                (use-module nono-sandbox
                  :config
                  (profiles
                   (ci/unsafe
                    (network deny-by-default)
                    (capabilities process-run filesystem-read tmpdir)
                    (resources (filesystem . scoped))
                    (metadata (intent . ci-unsafe)))))))))
        (check-equal? (error-object? failure) #t)))
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
