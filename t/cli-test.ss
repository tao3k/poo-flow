;;; -*- Gerbil -*-
;;; Boundary: CLI tests execute the Gerbil CLI entrypoint and a real Scheme flow file.

(import (only-in :std/test
                 test-suite
                 test-case
                 check-equal?
                 run-tests!)
        (only-in :std/srfi/13
                 string-contains)
        (only-in :poo-flow/src/cli
                 poo-flow-cli-max-rss-bytes
                 poo-flow-cli-run
                 poo-flow-cli-usage)
        (only-in :poo-flow/src/testing/project
                 poo-flow-testing-project)
        (only-in :gslph/src/testing/model
                 testing-object-ref))

(export cli-test)

;; : (-> String [[String]] Boolean)
(def (gxtest-root-registered? name specs)
  (cond
   ((null? specs) #f)
   ((and (pair? (car specs))
         (equal? (caar specs) name))
    #t)
   (else
    (gxtest-root-registered? name (cdr specs)))))

(def cli-test
  (test-suite "poo-flow cli"
    (test-case "prints help without loading the user interface graph"
      (check-equal? (poo-flow-cli-run '("help")) 0)
      (let (usage (poo-flow-cli-usage))
        (check-equal? (string? usage) #t)
        (check-equal?
         (if (string-contains usage "poo-flow test") #t #f)
         #f)
        (check-equal?
         (if (string-contains usage "gxtest <file>") #t #f)
         #t)))

    (test-case "rejects removed test command"
      (check-equal? (poo-flow-cli-run '("test")) 64))

    (test-case "declares policy-enabled testing project without explicit loadpath"
      (let (project (poo-flow-testing-project "." "."))
        (check-equal?
         (testing-object-ref project 'policy #f)
         #t)
        (check-equal?
         (testing-object-ref project 'loadpath #f)
         #f)))

    (test-case "registers session, durable, and user-interface scenarios as project roots"
      (let (specs
            (testing-object-ref (poo-flow-testing-project "." ".") 'gxtest '()))
        (check-equal? (gxtest-root-registered?
                       "scenario-session-transform"
                       specs)
                      #t)
        (check-equal? (gxtest-root-registered?
                       "scenario-session-policy"
                       specs)
                      #t)
        (check-equal? (gxtest-root-registered?
                       "scenario-session-registry"
                       specs)
                      #t)
        (check-equal? (gxtest-root-registered?
                       "scenario-session-communication"
                       specs)
                      #t)
        (check-equal? (gxtest-root-registered?
                       "scenario-session-agent-param"
                       specs)
                      #t)
        (check-equal? (gxtest-root-registered?
                       "scenario-session-memory-durable"
                       specs)
                      #t)
        (check-equal? (gxtest-root-registered?
                       "scenario-durable-recovery"
                       specs)
                      #t)
        (check-equal? (gxtest-root-registered?
                       "scenario-user-interface-sandbox-config"
                       specs)
                      #t)
        (check-equal? (gxtest-root-registered?
                       "scenario-user-interface-custom-scenario-batch"
                       specs)
                      #t)))

    (test-case "parses macOS time rss receipts"
      (check-equal?
       (poo-flow-cli-max-rss-bytes
        "        231047168  maximum resident set size\n")
       231047168))

    (test-case "parses GNU time rss receipts"
      (check-equal?
       (poo-flow-cli-max-rss-bytes
        "        Maximum resident set size (kbytes): 226912\n")
       232357888))))
