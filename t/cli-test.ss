;;; -*- Gerbil -*-
;;; Boundary: CLI tests execute the Gerbil CLI entrypoint and a real Scheme flow file.

(import (only-in :std/test
                 test-suite
                 test-case
                 check-equal?
                 run-tests!)
        (only-in :poo-flow/src/cli
                 poo-flow-cli-expand-test-args
                 poo-flow-cli-max-rss-bytes
                 poo-flow-cli-run
                 poo-flow-cli-runnable-test-form?
                 poo-flow-cli-usage)
        (only-in :poo-flow/src/cli-support/support
                 poo-flow-cli-gerbil-env-argv
                 poo-flow-cli-string-contains?
                 poo-flow-cli-string-prefix?)
        (only-in :poo-flow/src/cli-support/test
                 poo-flow-cli-policy-test-file
                 poo-flow-cli-test-files-env-binding))

(export cli-test)

(def cli-test
  (test-suite "poo-flow cli"
    (test-case "prints help without loading the user interface graph"
      (check-equal? (poo-flow-cli-run '("help")) 0)
      (let (usage (poo-flow-cli-usage))
        (check-equal? (string? usage) #t)))

    (test-case "expands the unit test root into bounded leaf tests"
      (let (files (poo-flow-cli-expand-test-args '("t/unit-tests.ss")))
        (check-equal? (not (member "t/unit-tests.ss" files)) #t)
        (check-equal? (not (not (member "t/cli-test.ss" files))) #t)))

    (test-case "rejects import-only files without an explicit test marker"
      (check-equal?
       (poo-flow-cli-runnable-test-form?
        '(import (only-in :std/test test-suite)))
       #f)
      (check-equal?
       (poo-flow-cli-runnable-test-form?
        '(def sample-test (test-suite "sample")))
       #t)
      (check-equal?
       (poo-flow-cli-runnable-test-form?
        '(define-poo-flow-module-system-live-case-test
           sample-live-case-test
           sample-live-case))
       #t)
      (check-equal?
       (poo-flow-cli-runnable-test-form?
        '(def poo-flow-import-side-effect-test-suite? #t))
       #t))

    (test-case "passes policy file scope as data to the static gxtest bridge"
      (let* ((files '("t/agent-sandbox-descriptor-test.ss"))
             (binding (poo-flow-cli-test-files-env-binding files))
             (prefix "POO_FLOW_TEST_FILES="))
        (check-equal?
         (poo-flow-cli-policy-test-file)
         "t/poo-flow-policy-test.ss")
        (check-equal?
         (poo-flow-cli-string-prefix? prefix binding)
         #t)
        (check-equal?
         (poo-flow-cli-string-contains?
          "t/agent-sandbox-descriptor-test.ss"
          binding)
         #t)))

    (test-case "uses package-local Gerbil loadpath for focused commands"
      (let (loadpath (cadr (poo-flow-cli-gerbil-env-argv
                            "gxc"
                            '("src/module-system/module-registry.ss"))))
        (check-equal?
         (poo-flow-cli-string-prefix?
          "GERBIL_LOADPATH=.:.gerbil/lib"
          loadpath)
         #t)
        (check-equal?
         (poo-flow-cli-string-contains? "~/.gerbil/lib" loadpath)
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
