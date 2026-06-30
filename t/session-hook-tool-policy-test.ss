;;; -*- Gerbil -*-
;;; Boundary: hook-scoped tool permission policy.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        :poo-flow/src/modules/session/config)

(export session-hook-tool-policy-test)

;; : TestSuite
(def session-hook-tool-policy-test
  (test-suite "poo-flow session hook tool policy"
    (test-case "does not inherit child-agent command grants implicitly"
      (let* ((read-grant
              (poo-flow-session-tool-grant
               'grant/hook-read
               'read-workspace-file
               '(read)
               '(project-workspace)
               '(hook/pre-check)))
             (hook-policy
              (poo-flow-session-hook-tool-permission-policy
               'policy/pre-check-hook-tools
               'session/root
               '(hook/pre-check)
               (list read-grant)
               'human-approval-on-escalation
               'deny)))
        (check-equal? (poo-flow-session-hook-tool-permission-policy-allows?
                       hook-policy
                       'hook/pre-check
                       'read-workspace-file
                       'read)
                      #t)
        (check-equal? (poo-flow-session-hook-tool-permission-policy-allows?
                       hook-policy
                       'hook/pre-check
                       'run-build-command
                       'run)
                      #f)
        (check-equal? (poo-flow-session-hook-tool-permission-policy-allows?
                       hook-policy
                       'hook/post-check
                       'read-workspace-file
                       'read)
                      #f)
        (check-equal? (poo-flow-session-policy-default-action hook-policy)
                      'deny)))))

(run-tests! session-hook-tool-policy-test)
