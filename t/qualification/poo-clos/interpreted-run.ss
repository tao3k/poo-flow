;;; -*- Gerbil -*-
;;; Source-owned interpreted half of the POO CLOS qualification.
(import (only-in :std/test run-tests! test-report-summary! set-test-verbose!)
        "interface.ss")

(set-test-verbose! #f)

(def (fixture-marker kind name)
  (let (port (current-error-port))
    (display "POO_CLOS_FIXTURE_" port)
    (display kind port)
    (display " " port)
    (write name port)
    (newline port)
    (force-output port)))

(def (run-fixture! name suites)
  (fixture-marker "BEGIN" name)
  (poo-clos-observe-fixture!
   name (lambda () (unless (apply run-tests! suites) (exit 42))))
  (fixture-marker "END" name))

(run-fixture! 'method-combination-compatibility
              (list poo-method-combination-test))
(run-fixture! 'generic-dispatch (list poo-clos-dispatch-test))
(run-fixture! 'class-and-instance-lifecycle (list poo-clos-lifecycle-test))
(run-fixture! 'declaration-surface (list poo-clos-syntax-test))
(run-fixture! 'method-combination (list poo-clos-method-combination-test))
(run-fixture! 'evolution-reflection-and-load-form
              (list poo-clos-evolution-test poo-clos-generic-evolution-test
                    poo-clos-load-form-test))
(run-fixture! 'ansi-clause-ledger (list poo-clos-clause-ledger-test))
(test-report-summary!)
