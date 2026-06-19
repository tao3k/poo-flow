;;; -*- Gerbil -*-
;;; Boundary: sandbox profile user interface stays on the module-system facade.

(import :std/test
        (only-in :clan/poo/object .ref)
        :poo-flow/src/modules/module-system)

(export agent-sandbox-profile-user-interface-test)

;; : [PooSandboxProfile]
(def user-sandbox-profiles
  (poo-flow-sandbox-profiles
   (agent/nono
    (backend nono)
    (network deny-by-default)
    (capabilities process-run filesystem-read filesystem-write tmpdir)
    (resources (filesystem . scoped)
               (cpu . 2)
               (memory . "4Gi")
               (timeout-ms . 300000))
    (metadata (intent . coding-agent) (risk . high-demand)))
   (agent/cube
    (backend cubeSandbox cube-local)
    (network allowlisted "github.com" "crates.io")
    (capabilities process-run filesystem-read cache-mount)
    (resources (filesystem . scoped)
               (cpu . 4)
               (memory . "8Gi")
               (timeout-ms . 600000))
    (metadata (intent . ci-agent) (risk . hermetic)))))

;; : PooUserModuleSelection
(def user-nono-operator-module
  (car
   (use-module nono-sandbox
     :config
     (profiles
      (agent/operator
       (network :override allowlisted "github.com" "crates.io")
       (capabilities process-run filesystem-read filesystem-write tmpdir)
       (capabilities :remove filesystem-write)
       (capabilities :append cache-mount)
       (resources (filesystem . scoped) (cpu . 2) (memory . "4Gi"))
       (resources :append (timeout-ms . 300000))
       (metadata (intent . operator-demo)
                 (scope . profile))
       (metadata :append (stage . extension))
       (metadata :remove (scope . profile)))))))

;; : PooUserModuleSelection
(def user-cube-build-module
  (car
   (use-module cubeSandbox
     :config
     (profiles
      (ci/cube
       (network allowlisted "github.com" "crates.io")
       (resources :append (cpu . 4) (memory . "8Gi"))
       (metadata (intent . cube-build)
                 (scope . profile)))))))

;; : PooUserModuleSelection
(def user-docker-build-module
  (car
   (use-module docker-sandbox
     :config
     (profiles
      (ci/docker
       (network allowlisted "ghcr.io")
       (capabilities :remove filesystem-write)
       (resources :append (cpu . 2) (memory . "4Gi"))
       (metadata (intent . docker-build)
                 (scope . profile)))))))

;; : (-> Symbol Alist MaybeValue)
(def (alist-value key entries)
  (cond
   ((null? entries) #f)
   ((equal? key (caar entries)) (cdar entries))
   (else
    (alist-value key (cdr entries)))))

;; : TestSuite
(def agent-sandbox-profile-user-interface-test
  (test-suite "poo-flow agent sandbox profile user interface"
    (test-case "declares nono and cubeSandbox profiles as inert user data"
      (let* ((nono-profile
              (poo-flow-sandbox-profile-by-name user-sandbox-profiles
                                                'agent/nono))
             (cube-profile
              (poo-flow-sandbox-profile-by-name user-sandbox-profiles
                                                'agent/cube)))
        (check-equal? (length user-sandbox-profiles) 2)
        (check-equal? (poo-flow-sandbox-profile? nono-profile) #t)
        (check-equal? (poo-flow-sandbox-profile-name nono-profile) 'agent/nono)
        (check-equal? (poo-flow-sandbox-profile-backend-kind nono-profile)
                      'nono)
        (check-equal? (poo-flow-sandbox-profile-backend-ref cube-profile)
                      'cube-local)
        (check-equal? (poo-flow-sandbox-profile-network-policy cube-profile)
                      '(allowlisted "github.com" "crates.io"))))
    (test-case "applies profile row operators through nono object validation"
      (let* ((profile-payload
              (poo-flow-user-module-selection-flag-entry
               user-nono-operator-module
               ':config))
             (profiles (cdr profile-payload))
             (operator-profile
              (poo-flow-sandbox-profile-by-name profiles 'agent/operator)))
        (check-equal? (poo-flow-user-module-selection-key
                       user-nono-operator-module)
                      '(sandbox . nono-sandbox))
        (check-equal? (length profiles) 1)
        (check-equal? (poo-flow-sandbox-profile-name operator-profile)
                      'agent/operator)
        (check-equal? (poo-flow-sandbox-profile-backend-kind operator-profile)
                      'nono)
        (check-equal? (poo-flow-sandbox-profile-backend-ref operator-profile)
                      'agent/operator)
        (check-equal? (poo-flow-sandbox-profile-network-policy
                       operator-profile)
                      '(allowlisted "github.com" "crates.io"))
        (check-equal? (poo-flow-sandbox-profile-capabilities
                       operator-profile)
                      '(process-run filesystem-read tmpdir cache-mount))
        (check-equal? (poo-flow-sandbox-profile-resource-policy
                       operator-profile)
                      '((filesystem . scoped)
                        (cpu . 2)
                        (memory . "4Gi")
                        (timeout-ms . 300000)))
        (check-equal? (poo-flow-sandbox-profile-metadata operator-profile)
                      '((declared-by . poo-flow-user-interface)
                        (runtime-executed . #f)
                        (intent . operator-demo)
                        (stage . extension)))))
    (test-case "applies profile inheritance for cube and docker sandbox objects"
      (let* ((cube-profiles
              (cdr (poo-flow-user-module-selection-flag-entry
                    user-cube-build-module
                    ':config)))
             (docker-profiles
              (cdr (poo-flow-user-module-selection-flag-entry
                    user-docker-build-module
                    ':config)))
             (cube-profile
              (poo-flow-sandbox-profile-by-name cube-profiles 'ci/cube))
             (docker-profile
              (poo-flow-sandbox-profile-by-name docker-profiles 'ci/docker)))
        (check-equal? (poo-flow-user-module-selection-key
                       user-cube-build-module)
                      '(sandbox . cubeSandbox))
        (check-equal? (poo-flow-user-module-selection-key
                       user-docker-build-module)
                      '(sandbox . docker-sandbox))
        (check-equal? (poo-flow-sandbox-profile-backend-kind cube-profile)
                      'cube)
        (check-equal? (poo-flow-sandbox-profile-resource-policy cube-profile)
                      '((filesystem . snapshot)
                        (cpu . 4)
                        (memory . "8Gi")))
        (check-equal? (poo-flow-sandbox-profile-backend-kind docker-profile)
                      'docker)
        (check-equal? (poo-flow-sandbox-profile-capabilities docker-profile)
                      '(process-run filesystem-read tmpdir))
        (check-equal? (poo-flow-sandbox-profile-resource-policy docker-profile)
                      '((filesystem . volume)
                        (cpu . 2)
                        (memory . "4Gi")))
        (check-equal? (alist-value
                       'backend-kind
                       (poo-flow-sandbox-profile->profile cube-profile))
                      'cube)
        (check-equal? (alist-value
                       'backend-kind
                       (poo-flow-sandbox-profile->profile docker-profile))
                      'docker)))
    (test-case "projects user declarations into validated agent sandbox profiles"
      (let* ((nono-profile
              (poo-flow-sandbox-profile-by-name user-sandbox-profiles
                                                'agent/nono))
             (profile
              (poo-flow-sandbox-profile->profile nono-profile)))
        (check-equal? (alist-value 'schema profile)
                      'poo-flow.agent-sandbox-profile.v1)
        (check-equal? (alist-value 'backend-kind profile) 'nono)
        (check-equal? (alist-value 'backend-ref profile) 'nono)
        (check-equal? (alist-value 'network-policy profile)
                      '(deny-by-default))
        (check-equal? (alist-value 'capabilities profile)
                      '(process-run filesystem-read filesystem-write tmpdir))
        (check-equal? (alist-value 'resource-policy profile)
                      '((filesystem . scoped)
                        (cpu . 2)
                        (memory . "4Gi")
                        (timeout-ms . 300000)))))
    (test-case "presents profile collections as runtime handoff intent data"
      (let* ((presentation
              (pooFlowSandboxProfilesPresentation user-sandbox-profiles))
             (runtime-intents (.ref presentation 'runtime-intents))
             (nono-intent (car runtime-intents))
             (cube-intent (cadr runtime-intents)))
        (check-equal? (.ref presentation 'kind)
                      poo-flow-sandbox-profiles-presentation-kind)
        (check-equal? (.ref presentation 'profile-count) 2)
        (check-equal? (.ref presentation 'profile-names)
                      '(agent/nono agent/cube))
        (check-equal? (alist-value 'backend-kind nono-intent) 'nono)
        (check-equal? (alist-value 'backend-ref cube-intent) 'cube-local)
        (check-equal? (alist-value 'runtime-owner nono-intent)
                      "marlin-agent-core")
        (check-equal? (alist-value 'descriptor-realized? cube-intent) #f)
        (check-equal? (alist-value 'runtime-executed cube-intent) #f)
        (check-equal? (.ref presentation 'runtime-executed) #f)))))

(run-tests! agent-sandbox-profile-user-interface-test)
