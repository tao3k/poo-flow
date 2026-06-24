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
                 poo-flow-cli-usage))

(export cli-test)

(def cli-test
  (test-suite "poo-flow cli"
    (test-case "prints help without loading the user interface graph"
      (check-equal? (poo-flow-cli-run '("help")) 0)
      (check-equal? (string? (poo-flow-cli-usage)) #t))

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
