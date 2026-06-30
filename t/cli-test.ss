;;; -*- Gerbil -*-
;;; Boundary: CLI tests execute the Gerbil CLI entrypoint and a real Scheme flow file.

(import (only-in :std/test
                 test-suite
                 test-case
                 check-equal?
                 run-tests!)
        (only-in :poo-flow/src/cli
                 poo-flow-cli-max-rss-bytes
                 poo-flow-cli-run
                 poo-flow-cli-usage)
        (only-in :poo-flow/src/cli-support/testing-project
                 +poo-flow-testing-project+)
        (only-in :gslph/src/testing/build
                 testing-build-gxtest-command))

(export cli-test)

(def cli-test
  (test-suite "poo-flow cli"
    (test-case "prints help without loading the user interface graph"
      (check-equal? (poo-flow-cli-run '("help")) 0)
      (let (usage (poo-flow-cli-usage))
        (check-equal? (string? usage) #t)))

    (test-case "passes policy file scope through the harness gxtest delegate"
      (let (command (testing-build-gxtest-command
                     +poo-flow-testing-project+
                     '("t/agent-sandbox-descriptor-test.ss")))
        (check-equal?
         command
         '("env"
           "POO_FLOW_TEST_FILES=(\"t/agent-sandbox-descriptor-test.ss\")"
           "gxtest"
           "t/agent-sandbox-descriptor-test.ss"
           "t/poo-flow-policy-test.ss"))
        (check-equal?
         (member "GERBIL_LOADPATH=.:.gerbil/lib" command)
         #f)))

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
