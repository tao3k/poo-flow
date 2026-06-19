;;; -*- Gerbil -*-
;;; Boundary: sandbox profile user interface stays on the module-system facade.

(import :std/test
        (only-in :clan/poo/object .ref)
        :modules/module-system)

(export agent-sandbox-profile-user-interface-test)

;; : [PooSandboxProfile]
(def user-sandbox-profiles
  (poo-flow-sandbox-profiles
   (agent/nono
    (backend nono)
    (network deny-by-default)
    (capabilities process-run filesystem-read filesystem-write tmpdir)
    (resources (cpu . 2) (memory . "4Gi") (timeout-ms . 300000))
    (metadata (intent . coding-agent) (risk . high-demand)))
   (agent/cube
    (backend cubeSandbox cube-local)
    (network allowlisted "github.com" "crates.io")
    (capabilities process-run filesystem-read cache-mount)
    (resources (cpu . 4) (memory . "8Gi") (timeout-ms . 600000))
    (metadata (intent . ci-agent) (risk . hermetic)))))

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
                      '((cpu . 2)
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
