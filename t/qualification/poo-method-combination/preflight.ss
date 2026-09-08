;;; -*- Gerbil -*-
;;; Test-only source checks run before spending time on native compilation.
(import (only-in :std/test run-tests! set-test-verbose! test-report-summary!)
        "io-test.ss" "summary-test.ss")
(set-test-verbose! #f)
(def passed? (run-tests! combination-qualification-io-test combination-summary-test))
(test-report-summary!)
(unless passed? (exit 42))
