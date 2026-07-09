;;; -*- Gerbil -*-
;;; Funflow: GitHub CI profile contract backed by JSON Schema projection.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :std/srfi/1
                 member)
        (only-in :clan/poo/object
                 object<-alist)
        (only-in "../src/utilities/contracts.ss"
                 poo-flow-object-type-contract-slots
                 poo-flow-slot-contract-slot)
        (only-in "../src/contract/json-schema-source.ss"
                 poo-flow-json-schema-read-file)
        (only-in "../src/contract/json-schema-receipt.ss"
                 poo-flow-json-schema->contract-artifact
                 poo-flow-json-schema-contract-artifact-object-contract
                 poo-flow-json-schema-contract-artifact->alist)
        (only-in "../src/modules/funflow/github-ci-contract.ss"
                 +poo-flow-funflow-github-ci-schema-audit+
                 poo-flow-funflow-github-ci-contract-receipt
                 poo-flow-funflow-github-ci-validate-workflow->alist))

(export funflow-github-ci-json-schema-contract-test)

;; : (-> Alist Symbol Object)
(def (funflow-github-ci-test-ref rows key)
  (let (entry (assoc key rows))
    (if entry (cdr entry) #f)))

;; : (-> Alist Symbol Object)
(def (funflow-github-ci-audit-ref key)
  (funflow-github-ci-test-ref
   +poo-flow-funflow-github-ci-schema-audit+
   key))

;; : (-> Object [Object] Boolean)
(def (funflow-github-ci-member? value values)
  (if (member value values) #t #f))

;; : Alist
(def funflow-github-ci-valid-workflow
  '((name . "POO Flow CI")
    (on . ("push" "pull_request"))
    (jobs . ((build . ((runs-on . "macos-latest")
                       (steps . (((run . "gxpkg build -g"))))))))))

;; : PooFlowObject
(def funflow-github-ci-valid-poo-workflow
  (object<-alist
   '((name . "POO Flow CI")
     (on . ((push . #t)))
     (jobs . ((build . ((runs-on . "ubuntu-latest")
                        (steps . (((uses . "actions/checkout@v4")))))))))))

;; : Alist
(def funflow-github-ci-missing-jobs-workflow
  '((name . "POO Flow CI")
    (on . "push")))

;; : Alist
(def funflow-github-ci-empty-jobs-workflow
  '((name . "POO Flow CI")
    (on . "push")
    (jobs . ())))

;; : Alist
(def funflow-github-ci-missing-runs-on-workflow
  '((name . "POO Flow CI")
    (on . "push")
    (jobs . ((build . ((steps . (((run . "gxpkg build -g"))))))))))

;; : Alist
(def funflow-github-ci-invalid-job-key-workflow
  '((name . "POO Flow CI")
    (on . "push")
    (jobs . ((1bad . ((runs-on . "ubuntu-latest")
                      (steps . (((run . "gxpkg build -g"))))))))))

;; : Alist
(def funflow-github-ci-invalid-step-id-workflow
  '((name . "POO Flow CI")
    (on . "push")
    (jobs . ((build . ((runs-on . "ubuntu-latest")
                       (steps . (((id . "bad id")
                                  (run . "gxpkg build -g"))))))))))

;; : TestSuite
(def funflow-github-ci-json-schema-contract-test
  (test-suite "funflow github-ci json schema contract"
    (test-case "keeps the upstream workflow schema pinned in the repo"
      (let ((receipt (poo-flow-funflow-github-ci-contract-receipt)))
        (check-equal?
         (funflow-github-ci-audit-ref 'repo-path)
         "schemas/json/github-workflow.json")
        (check-equal?
         (funflow-github-ci-audit-ref 'sha256)
         "7a952fdb7c1b130732e40ccea9db9bced906c1198e97834f8a49ae3b411f3161")
        (check-equal? (funflow-github-ci-test-ref receipt 'valid?) #t)
        (check-equal? (funflow-github-ci-test-ref receipt 'diagnostic-count) 0)))
    (test-case "feeds the pinned raw github workflow schema into the bridge"
      (let* ((schema
              (poo-flow-json-schema-read-file
               "schemas/json/github-workflow.json"))
             (artifact
              (poo-flow-json-schema->contract-artifact
               schema
               '((source-ref . schemas/json/github-workflow.json)
                 (owner . funflow)
                 (object-kind . PooFlowFunflowPinnedGithubWorkflow)
                 (object-key . funflow/github-ci/pinned-workflow))))
             (receipt
              (poo-flow-json-schema-contract-artifact->alist artifact))
             (slots
              (map
               poo-flow-slot-contract-slot
               (poo-flow-object-type-contract-slots
                (poo-flow-json-schema-contract-artifact-object-contract
                 artifact)))))
        (check-equal? (funflow-github-ci-test-ref receipt 'valid?) #t)
        (check-equal? (funflow-github-ci-member? 'on slots) #t)
        (check-equal? (funflow-github-ci-member? 'jobs slots) #t)
        (check-equal?
         (>= (funflow-github-ci-test-ref receipt 'diagnostic-count) 1)
         #t)))
    (test-case "validates top-level github workflow profile shape"
      (let ((alist-receipt
             (poo-flow-funflow-github-ci-validate-workflow->alist
              funflow-github-ci-valid-workflow))
            (poo-receipt
             (poo-flow-funflow-github-ci-validate-workflow->alist
              funflow-github-ci-valid-poo-workflow)))
        (check-equal? (funflow-github-ci-test-ref alist-receipt 'valid?) #t)
        (check-equal? (funflow-github-ci-test-ref alist-receipt 'checked-slots)
                      '(name run-name on env defaults concurrency permissions jobs))
        (check-equal? (funflow-github-ci-test-ref poo-receipt 'valid?) #t)))
    (test-case "rejects missing and empty required workflow slots"
      (let ((missing-receipt
             (poo-flow-funflow-github-ci-validate-workflow->alist
              funflow-github-ci-missing-jobs-workflow))
            (empty-receipt
             (poo-flow-funflow-github-ci-validate-workflow->alist
              funflow-github-ci-empty-jobs-workflow)))
        (check-equal? (funflow-github-ci-test-ref missing-receipt 'valid?) #f)
        (check-equal? (funflow-github-ci-test-ref missing-receipt
                                                  'missing-required)
                      '(jobs))
        (check-equal? (funflow-github-ci-test-ref empty-receipt 'valid?) #f)
        (check-equal? (funflow-github-ci-test-ref empty-receipt 'invalid-slots)
                      '(jobs))))
    (test-case "recursively validates dynamic job ids and job bodies"
      (let ((missing-runs-on
             (poo-flow-funflow-github-ci-validate-workflow->alist
              funflow-github-ci-missing-runs-on-workflow))
            (invalid-job-key
             (poo-flow-funflow-github-ci-validate-workflow->alist
              funflow-github-ci-invalid-job-key-workflow))
            (invalid-step-id
             (poo-flow-funflow-github-ci-validate-workflow->alist
              funflow-github-ci-invalid-step-id-workflow)))
        (check-equal? (funflow-github-ci-test-ref missing-runs-on 'valid?) #f)
        (check-equal? (funflow-github-ci-test-ref missing-runs-on
                                                  'missing-required)
                      '(jobs/build/runs-on))
        (check-equal? (funflow-github-ci-test-ref invalid-job-key 'valid?) #f)
        (check-equal? (funflow-github-ci-test-ref invalid-job-key
                                                  'invalid-slots)
                      '(jobs/1bad))
        (check-equal? (funflow-github-ci-test-ref invalid-step-id 'valid?) #f)
        (check-equal? (funflow-github-ci-test-ref invalid-step-id
                                                  'invalid-slots)
                      '(jobs/build/steps/0/id))))))
