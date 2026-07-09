;;; -*- Gerbil -*-
;;; Boundary: process-level CLI smoke tests stay out of the aggregate unit root.

(import (only-in :std/test
                 test-suite
                 test-case
                 check-equal?
                 run-tests!)
        (only-in :std/misc/process run-process))

(export cli-process-test)

;; : (-> Path)
(def (poo-flow-cli-process-test-root)
  (cond
   ((file-exists? "src/cli.ss") (current-directory))
   ((file-exists? "../src/cli.ss") "..")
   (else (current-directory))))

;; poo-flow-cli-process-test-values/tail
;;   : (forall (a) (-> [a] [a] [a]))
;;   | doc m%
;;       Append CLI process output fragments onto the current tail while
;;       preserving the order expected by test-process-output.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-cli-process-test-values/tail '(a) '(b))
;;       ;; => (a b)
;;       ```
;;     %
(def (poo-flow-cli-process-test-values/tail values tail)
  (append values tail))

;;; Process boundary: start the source CLI directly; the `run` command itself
;;; owns the package-env hop needed for user scripts.
;; : (-> [String] (Values Integer String))
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
      (values status output))))

;; : TestSuite
(def cli-process-test
  (test-suite "poo-flow cli process"
    (test-case "runs a Scheme file through the functional flow kernel"
      (call-with-values
       (lambda ()
         (run-poo-flow-cli-process
          '("run" "t/fixtures/cli-run-smoke.ss" "3")))
       (lambda (status output)
         (check-equal? output "poo-flow-run:8\n")
         (check-equal? status 0))))))
