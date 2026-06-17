(import :std/test
        :poo-flow)

(def pure-flow-test
  (test-suite "pure flow"
    (test-case "runs pure tasks sequentially and records receipts"
      (let* ((inc (make-pure-task 'inc (lambda (x) (+ x 1)) 'number 'number))
             (double (make-pure-task 'double (lambda (x) (* x 2)) 'number 'number))
             (flow (flow-compose 'math (list inc double) 'number 'number))
             (runner (make-runner (make-local-eager-strategy)
                                  (make-request-only-adapter)))
             (result (runner-run runner flow 3))
             (receipt (run-result-receipt result)))
        (check-equal? (run-result-value result) 8)
        (check-equal? (receipt-flow receipt) 'math)
        (check-equal? (receipt-status receipt) 'ok)
        (check-equal? (length (receipt-children receipt)) 2)))))

(def adapter-request-test
  (test-suite "adapter request boundary"
    (test-case "lowers external tasks into adapter requests"
      (let* ((external (make-external-task 'compile 'rust-build '((crate . "poo-flow")) 'artifact 'artifact))
             (flow (flow-compose 'external-demo (list external) 'artifact 'artifact))
             (runner (make-runner (make-local-eager-strategy)
                                  (make-request-only-adapter)))
             (result (runner-run runner flow 'input-artifact))
             (child (car (receipt-children (run-result-receipt result)))))
        (check-equal? (receipt-task child) 'compile)
        (check-equal? (receipt-kind child) 'external)
        (check-equal? (receipt-adapter-decision child) 'request-only)
        (check-equal? (adapter-result-status (run-result-value result)) 'requested)))))

(def poo-role-test
  (test-suite "poo role descriptors"
    (test-case "declares control-plane roles as Gerbil POO objects"
      (check-equal? (role-object? flow-role) #t)
      (check-equal? (role-name flow-role) 'flow)
      (check-equal? (role-kind strategy-role) 'policy)
      (check-equal? (role-runtime-owner runtime-adapter-role) 'rust-or-external-runtime)
      (check-equal? (role-responsibility receipt-role) 'execution-explanation))
    (test-case "composes role prototypes with leftmost precedence"
      (let ((composed (role-compose runtime-adapter-role flow-role)))
        (check-equal? (role-object? composed) #t)
        (check-equal? (role-name composed) 'runtime-adapter)
        (check-equal? (role-runtime-owner composed) 'rust-or-external-runtime)))))

(run-tests! pure-flow-test adapter-request-test poo-role-test)
