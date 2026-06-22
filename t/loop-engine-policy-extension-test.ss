;;; -*- Gerbil -*-
;;; Boundary: focused tests for loop-engine POO-native policy extensions.
;;; Invariant: extension receipts are report-only and runtime-owned by Marlin.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/facade
        (only-in :poo-flow/user-interface/custom/my-module/config
                 poo-flow-custom-my-module-loops-module))

(export loop-engine-policy-extension-test)

;;; Test helpers intentionally operate on receipt alists, not internal POO
;;; objects, because the public contract here is the Marlin handoff surface.
;; : (-> Alist Symbol MaybeValue)
(def (test-ref alist key)
  (let (entry (assoc key alist))
    (if entry (cdr entry) #f)))

;;; Policy extensions share one generic receipt collection, so test lookup is
;;; keyed by receipt kind instead of by concrete Scheme prototype names.
;; : (-> [Alist] Symbol Value MaybeAlist)
(def (test-row-by-field rows key value)
  (cond
   ((null? rows) #f)
   ((equal? (test-ref (car rows) key) value) (car rows))
   (else (test-row-by-field (cdr rows) key value))))

;;; Presentation construction uses the same public config wrapper as downstream
;;; modules so the test proves user-level extension objects, not private helpers.
;; : (-> [PooUserModuleSelection] POOObject)
(def (custom-loop-presentation module-bundle)
  (pooFlowUserConfigPresentation
   (pooFlowUserConfig
    (poo-flow-user-module-bundles->modules (list module-bundle))
    (poo-flow-settings))))

;;; Malformed extension slots fail before runtime manifests can carry ambiguous
;;; policy receipts.
;; : (-> [PooUserModuleSelection])
(def (custom-loop-invalid-policy-extension-slot-module)
  (use-module loop-engine
    :config
    (.def (invalid-policy-extension-loop @ loop-engine-use-case
                                         name workflow)
      name: 'invalid-policy-extension-loop
      workflow: 'funflow-cicd)

    (.def (invalid-policy-extension @ loop-engine-policy-extension
                                    name receipt-kind contract priority)
      name: 'invalid-policy-extension
      receipt-kind: 'coordination-receipt
      contract: 'poo-flow.loop-engine.coordination-receipt.v1
      priority: 'bad-priority)

    (.def (invalid-policy-extension-profile @ loop-engine-profile
                                            use-case policy-extensions)
      use-case: invalid-policy-extension-loop
      policy-extensions: (list invalid-policy-extension))))

;;; The profile scenario proves concrete operational policies remain normal POO
;;; extension objects while runtime surfaces only see the generic collection.
;; : TestCase
(def loop-engine-policy-extension-profile-case
  (test-case "projects loop-engine policy-extension receipts"
    (let* ((presentation
            (custom-loop-presentation
             poo-flow-custom-my-module-loops-module))
           (intent (car (.ref presentation 'loop-engine-intents)))
           (receipts (test-ref intent 'policy-extension-receipts))
           (coordination-receipt
            (test-row-by-field receipts 'kind 'coordination-receipt))
           (observability-receipt
            (test-row-by-field receipts 'kind 'observability-receipt))
           (safety-receipt
            (test-row-by-field receipts 'kind 'safety-receipt))
           (manifest-request
            (test-ref (test-ref intent 'runtime-command-manifest)
                      'request))
           (handoff (test-ref intent 'runtime-handoff-facts)))
      (check-equal? (length receipts) 3)
      (check-equal? (test-ref coordination-receipt 'kind)
                    'coordination-receipt)
      (check-equal? (test-ref coordination-receipt 'contract)
                    'poo-flow.loop-engine.coordination-receipt.v1)
      (check-equal? (test-ref coordination-receipt 'priority)
                    '(ci-sweeper
                      dependency-sweeper
                      post-merge-cleanup
                      issue-triage
                      daily-triage))
      (check-equal? (test-ref coordination-receipt 'state-files)
                    '((daily-triage . "STATE.md")
                      (ci-sweeper . "ci-sweeper-state.md")
                      (issue-triage . "issue-triage-state.md")
                      (dependency-sweeper
                       . "dependency-sweeper-state.md")
                      (post-merge-cleanup . "post-merge-state.md")))
      (check-equal? (test-ref coordination-receipt 'acting-on-key)
                    'acting_on)
      (check-equal? (test-ref coordination-receipt 'conflict-action)
                    'skip-and-log)
      (check-equal? (test-ref coordination-receipt 'runtime-executed) #f)
      (check-equal? (test-ref observability-receipt 'contract)
                    'poo-flow.loop-engine.observability-receipt.v1)
      (check-equal? (test-ref observability-receipt 'run-log)
                    "loop-run-log.md")
      (check-equal? (test-ref observability-receipt 'metric-keys)
                    '(duration_s items_found actions_taken escalations
                      tokens_estimate outcome))
      (check-equal? (test-ref observability-receipt 'pause-signals)
                    '(reviewer-absence repeated-escalation))
      (check-equal? (test-ref observability-receipt 'runtime-executed) #f)
      (check-equal? (test-ref safety-receipt 'contract)
                    'poo-flow.loop-engine.safety-receipt.v1)
      (check-equal? (test-ref safety-receipt 'denylist-paths)
                    '(".env"
                      ".env.local"
                      "secrets/"
                      ".github/workflows/release.yml"))
      (check-equal? (test-ref safety-receipt 'human-gates)
                    '(release-risk secrets-touch protected-branch))
      (check-equal? (test-ref safety-receipt 'auto-merge) 'never)
      (check-equal? (test-ref safety-receipt 'max-attempts) 2)
      (check-equal? (test-ref safety-receipt 'runtime-executed) #f)
      (check-equal? (test-ref handoff 'policy-extension-receipts)
                    receipts)
      (check-equal? (test-ref manifest-request 'policy-extension-receipts)
                    receipts)
      (check-equal? (car (.ref presentation
                              'loop-engine-policy-extension-receipts))
                    receipts))))

;;; Invalid-slot coverage keeps policy-extension mixins honest: user-facing POO
;;; declarations must fail at presentation time before any runtime handoff row
;;; can be assembled from malformed slot values.
;; : TestCase
(def loop-engine-policy-extension-invalid-slot-case
  (test-case "rejects invalid loop-engine policy-extension slot types"
    (check-equal?
     (with-catch
      (lambda (_) #t)
      (lambda ()
        (custom-loop-presentation
         (custom-loop-invalid-policy-extension-slot-module))
        #f))
     #t)))

;;; The suite covers both the positive receipt propagation path and the contract
;;; rejection path for POO-native loop-engine policy extensions.
;; : TestSuite
(def loop-engine-policy-extension-test
  (test-suite "loop-engine POO-native policy extension"
    loop-engine-policy-extension-profile-case
    loop-engine-policy-extension-invalid-slot-case))

(run-tests! loop-engine-policy-extension-test)
