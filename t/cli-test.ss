;;; -*- Gerbil -*-
;;; Boundary: CLI tests execute the Gerbil CLI entrypoint and a real Scheme flow file.

(import :std/test
        (only-in :std/misc/process run-process))

(export cli-test)

;; : (-> Unit Path)
(def (poo-flow-cli-test-root)
  (cond
   ((file-exists? "src/cli.ss") (current-directory))
   ((file-exists? "../src/cli.ss") "..")
   (else (current-directory))))

;; : (-> [String] Pair)
(def (run-poo-flow-cli args)
  (let (status 0)
    (let (output
          (run-process (append '("gxpkg" "env" "gxi" "src/cli.ss")
                               args)
                       directory: (poo-flow-cli-test-root)
                       stderr-redirection: #t
                       check-status:
                       (lambda (exit-status _settings)
                         (set! status exit-status))))
      (cons status output))))

(def cli-test
  (test-suite "poo-flow cli"
    (test-case "runs a Scheme file through the functional flow kernel"
      (let (result (run-poo-flow-cli '("run" "t/fixtures/cli-run-smoke.ss" "3")))
        (check-equal? (cdr result) "poo-flow-run:8\n")
        (check-equal? (car result) 0)))))
