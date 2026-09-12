;;; -*- Gerbil -*-
;;; Imports deliberately require the freshly compiled qualification library.
(import (only-in :std/test run-tests! test-report-summary! set-test-verbose!)
        :poo-flow/t/qualification/poo-clos/interface)

(def artifact-count (verify-poo-clos-artifacts!))
(def dependency-snapshot (poo-clos-dependency-snapshot))
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
(verify-poo-clos-dependencies! dependency-snapshot)
(let* ((open-count (length (poo-clos-open-required-ansi-rows)))
       (accepted? (zero? open-count)))
  (write (list 'poo-clos-qualification-terminal
               'schema 'v1
               'artifact-count artifact-count
               'open-required-ansi-rows open-count
               'performance-claim? #f
               'accepted? accepted?))
  (unless accepted? (exit 43)))
(newline)
