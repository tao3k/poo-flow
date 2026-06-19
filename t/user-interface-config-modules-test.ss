;;; -*- Gerbil -*-
;;; Boundary: tests custom user config fragments loaded by `load!`.
;;; Invariant: user fragments remain declarative module selections.

(import :std/test
        :modules/module-system
        (only-in :poo-flow/user-interface/custom/my-module/config
                 poo-flow-custom-my-module-session-module
                 poo-flow-custom-my-module-task-module
                 poo-flow-custom-my-module-cicd-module))

(export user-interface-config-modules-test)

;; : (-> PooUserModuleSelection [PooSandboxProfile])
(def (config-module-profiles module-selection)
  (cdr (poo-flow-user-module-selection-flag-entry module-selection ':config)))

;; : (-> [PooSandboxProfile] Symbol PooSandboxProfile)
(def (config-profile profiles name)
  (poo-flow-sandbox-profile-by-name profiles name))

;; : TestSuite
(def user-interface-config-modules-test
  (test-suite "poo-flow user interface config modules"
    (test-case "loads custom profile fragments with load!"
      (let* ((session-profiles
              (config-module-profiles
               (car poo-flow-custom-my-module-session-module)))
             (task-profiles
              (config-module-profiles
               (car poo-flow-custom-my-module-task-module)))
             (cicd-profiles
              (config-module-profiles
               (car poo-flow-custom-my-module-cicd-module)))
             (session-profile
              (config-profile session-profiles 'agent/session))
             (task-cache-profile
              (config-profile task-profiles 'agent/task-cache))
             (build-profile
              (config-profile cicd-profiles 'ci/build)))
        (check-equal? (length session-profiles) 1)
        (check-equal? (length task-profiles) 2)
        (check-equal? (length cicd-profiles) 4)
        (check-equal? (poo-flow-sandbox-profile-capabilities
                       session-profile)
                      '(process-run filesystem-read tmpdir cache-mount))
        (check-equal? (poo-flow-sandbox-profile-resource-policy
                       task-cache-profile)
                      '((cpu . 2)
                        (memory . "2Gi")
                        (timeout-ms . 180000)))
        (check-equal? (poo-flow-sandbox-profile-network-policy
                       build-profile)
                      '(allowlisted "github.com" "crates.io"))))))
