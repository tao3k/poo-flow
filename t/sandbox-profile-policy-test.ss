;;; -*- Gerbil -*-
;;; Boundary: sandbox profile policy tests stay projection-only.
;;; Invariant: backend capability checks never execute sandbox runtimes.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        :poo-flow/src/modules/sandbox-core/profile-support/policy)

(export sandbox-profile-policy-test)

;; : (-> Alist Symbol Value Value)
(def (test-ref entries key default-value)
  (let (entry (assoc key entries))
    (if entry (cdr entry) default-value)))

;; : (-> Alist [Symbol])
(def (test-diagnostic-codes validation)
  (map (lambda (diagnostic)
         (test-ref diagnostic 'code #f))
       (test-ref validation 'diagnostics '())))

;; : TestSuite
(def sandbox-profile-policy-test
  (test-suite "poo-flow sandbox profile policy"
    (test-case "publishes static POO backend capability objects"
      (check-equal?
       (poo-flow-sandbox-backend-capability?
        poo-flow-sandbox-backend-capability/nono)
       #t)
      (check-equal?
       (poo-flow-sandbox-backend-capability/backend-kind
        poo-flow-sandbox-backend-capability/nono)
       'nono)
      (check-equal?
       (poo-flow-sandbox-backend-capability-supports?
        poo-flow-sandbox-backend-capability/nono
        'process-run)
       #t)
      (check-equal?
       (poo-flow-sandbox-backend-capability-supports?
        poo-flow-sandbox-backend-capability/nono
        'gpu-device)
       #f))
    (test-case "returns structured capability diagnostics"
      (let* ((policy
              (poo-flow-sandbox-profile-policy '(process-run gpu-device)))
             (validation
              (poo-flow-sandbox-profile-policy-validation
               'agent/gpu
               'nono
               'agent/gpu
               poo-flow-sandbox-backend-capability/nono
               policy
               '(filesystem-read tmpdir))))
        (check-equal?
         (poo-flow-sandbox-profile-policy-validation-valid? validation)
         #f)
        (check-equal? (test-ref validation 'diagnostic-count #f) 1)
        (check-equal? (test-diagnostic-codes validation)
                      '(missing-backend-capability))))
    (test-case "validates backend capability for profile candidates"
      (let ((validation
             (poo-flow-sandbox-profile-policy-validation
              'agent/sandbox
              'sandbox
              'agent/sandbox
              poo-flow-sandbox-backend-capability/sandbox
              poo-flow-sandbox-profile-policy/default
              '(process-run filesystem-read tmpdir))))
        (check-equal?
         (poo-flow-sandbox-profile-policy-validation-valid? validation)
         #t)
        (check-equal? (test-ref validation 'diagnostic-count #f) 0))
      (let ((validation
             (poo-flow-sandbox-profile-policy-validation
              'agent/gpu
              'sandbox
              'agent/gpu
              poo-flow-sandbox-backend-capability/sandbox
              poo-flow-sandbox-profile-policy/default
              '(process-run gpu-device))))
        (check-equal?
         (poo-flow-sandbox-profile-policy-validation-valid? validation)
         #f)
        (check-equal? (test-diagnostic-codes validation)
                      '(missing-backend-capability))))
    (test-case "projects profile policy receipts without runtime execution"
      (let* ((projection
              (poo-flow-sandbox-profile-policy-projection
               'agent/sandbox
               'sandbox
               'agent/sandbox
               (poo-flow-sandbox-backend-capability-ref
                'sandbox)
               poo-flow-sandbox-profile-policy/default
               '(process-run filesystem-read tmpdir))))
        (check-equal? (test-ref projection 'kind #f)
                      poo-flow-sandbox-profile-policy-projection-kind)
        (check-equal? (test-ref projection 'valid? #f) #t)
        (check-equal? (test-ref projection 'runtime-owner #f)
                      "marlin-agent-core")
        (check-equal? (test-ref projection 'runtime-executed #t) #f)))))

(run-tests! sandbox-profile-policy-test)
