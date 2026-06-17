(import :std/test
        :core/api
        :project-policy-test)

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

(def funflow-api-test
  (test-suite "funflow-style flow api"
    (test-case "builds and runs flow-level smart constructors"
      (let* ((inc (pure-flow 'inc (lambda (x) (+ x 1)) 'number 'number))
             (double (scheme-flow 'double (lambda (x) (* x 2)) 'number 'number))
             (pipeline (flow-then 'inc-then-double inc double))
             (runner (make-runner (make-local-eager-strategy)
                                  (make-request-only-adapter)))
             (result (runner-run runner pipeline 4)))
        (check-equal? (flow-step-count pipeline) 2)
        (check-equal? (flow-input-contract pipeline) 'number)
        (check-equal? (flow-output-contract pipeline) 'number)
        (check-equal? (run-result-value result) 10)))
    (test-case "keeps return-flow as identity"
      (let* ((identity (return-flow 'return-number 'number))
             (runner (make-runner (make-local-eager-strategy)
                                  (make-request-only-adapter)))
             (result (runner-run runner identity 11)))
        (check-equal? (run-result-value result) 11)))
    (test-case "lowers external-flow into adapter request"
      (let* ((compile (external-flow 'compile 'rust-build '((crate . "poo-flow")) 'artifact 'artifact))
             (runner (make-runner (make-local-eager-strategy)
                                  (make-request-only-adapter)))
             (result (runner-run runner compile 'input-artifact))
             (receipt (run-result-receipt result))
             (child (car (receipt-children receipt))))
        (check-equal? (receipt-flow receipt) 'compile)
        (check-equal? (receipt-kind child) 'external)
        (check-equal? (adapter-result-status (run-result-value result)) 'requested)))))

(def execution-plan-test
  (test-suite "execution plan"
    (test-case "strategy lowers flows into named plan nodes"
      (let* ((inc (pure-flow 'inc (lambda (x) (+ x 1)) 'number 'number))
             (double (scheme-flow 'double (lambda (x) (* x 2)) 'number 'number))
             (pipeline (flow-then 'inc-then-double inc double))
             (runner (make-runner (make-local-eager-strategy)
                                  (make-request-only-adapter)))
             (plan (runner-plan runner pipeline))
             (nodes (execution-plan-nodes plan))
             (first-node (car nodes))
             (second-node (cadr nodes)))
        (check-equal? (execution-plan-flow-name plan) 'inc-then-double)
        (check-equal? (plan-node-count plan) 2)
        (check-equal? (plan-node-id first-node) '(node inc-then-double 0 pure inc))
        (check-equal? (plan-node-kind first-node) 'pure)
        (check-equal? (plan-node-name first-node) 'inc)
        (check-equal? (plan-node-id second-node) '(node inc-then-double 1 scheme double))
        (check-equal? (plan-node-kind second-node) 'scheme)
        (check-equal? (plan-node-name second-node) 'double)))))

(def strategy-cache-test
  (test-suite "strategy cache policy"
    (test-case "records cache intent in task receipts"
      (let* ((inc (pure-flow 'inc (lambda (x) (+ x 1)) 'number 'number))
             (runner (make-runner (make-cached-local-eager-strategy)
                                  (make-request-only-adapter)))
             (result (runner-run runner inc 5))
             (receipt (run-result-receipt result))
             (child (car (receipt-children receipt))))
        (check-equal? (run-result-value result) 6)
        (check-equal? (receipt-cache receipt) 'no-cache)
        (check-equal? (receipt-cache child) '(cache-output inc pure 5 6))))))

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

(run-tests! pure-flow-test
            adapter-request-test
            funflow-api-test
            execution-plan-test
            strategy-cache-test
            poo-role-test
            project-policy-test)

(unless (zero? (project-policy-status))
  (exit 1))
