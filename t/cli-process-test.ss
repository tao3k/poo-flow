;;; -*- Gerbil -*-
;;; Boundary: process-level CLI smoke tests stay out of the aggregate unit root.

(import (only-in :std/test
                 test-suite
                 test-case
                 check-equal?
                 run-tests!)
        (only-in :std/misc/process run-process))

(export cli-process-test)

;; : (-> Unit Path)
(def (poo-flow-cli-process-test-root)
  (cond
   ((file-exists? "src/cli.ss") (current-directory))
   ((file-exists? "../src/cli.ss") "..")
   (else (current-directory))))

;; : (forall (a) (-> [a] [a] [a]))
(def (poo-flow-cli-process-test-values/tail values tail)
  (let loop ((remaining-values values)
             (values-rev '()))
    (if (null? remaining-values)
      (let restore ((remaining-rev values-rev)
                    (result tail))
        (if (null? remaining-rev)
          result
          (restore (cdr remaining-rev)
                   (cons (car remaining-rev) result))))
      (loop (cdr remaining-values)
            (cons (car remaining-values) values-rev)))))

;;; Process boundary: start the source CLI directly; the `run` command itself
;;; owns the package-env hop needed for user scripts.
;; : (-> [String] Pair)
(def (run-poo-flow-cli-process args)
  (let (status 0)
    (let (output
          (run-process (poo-flow-cli-process-test-values/tail
                        (list "env"
                              "GERBIL_LOADPATH=.:.gerbil/lib"
                              "gxi"
                              "src/cli.ss")
                        args)
                       directory: (poo-flow-cli-process-test-root)
                       stderr-redirection: #t
                       check-status:
                       (lambda (exit-status _settings)
                         (set! status exit-status))))
      (cons status output))))

(def cli-process-test
  (test-suite "poo-flow cli process"
    (test-case "runs a Scheme file through the functional flow kernel"
      (let (result (run-poo-flow-cli-process '("run" "t/fixtures/cli-run-smoke.ss" "3")))
        (check-equal? (cdr result) "poo-flow-run:8\n")
        (check-equal? (car result) 0)))))
