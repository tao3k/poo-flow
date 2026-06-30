;;; -*- Gerbil -*-
;;; Boundary: agent-scoped tool permission policy.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        :poo-flow/src/modules/session/config)

(export session-agent-tool-policy-test)

;; : TestSuite
(def session-agent-tool-policy-test
  (test-suite "poo-flow session agent tool policy"
    (test-case "admits only explicitly granted agent tools"
      (let* ((read-grant
              (poo-flow-session-tool-grant
               'grant/read
               'read-workspace-file
               '(read)
               '(project-workspace)
               '(agent-turn)))
             (run-grant
              (poo-flow-session-tool-grant
               'grant/build
               'run-build-command
               '(run)
               '(project-workspace build-cache)
               '(agent-turn)))
             (policy
              (poo-flow-session-tool-permission-policy
               'policy/build-agent-tools
               'session/build
               (list read-grant run-grant)
               '(write-workspace-file)
               'deny)))
        (check-equal? (poo-flow-session-tool-permission-policy-allows?
                       policy
                       'read-workspace-file
                       'read)
                      #t)
        (check-equal? (poo-flow-session-tool-permission-policy-allows?
                       policy
                       'run-build-command
                       'run)
                      #t)
        (check-equal? (poo-flow-session-tool-permission-policy-allows?
                       policy
                       'write-workspace-file
                       'write)
                      #f)
        (check-equal? (poo-flow-session-policy-default-action policy)
                      'deny)))))

(run-tests! session-agent-tool-policy-test)
