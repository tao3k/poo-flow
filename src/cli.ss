;;; -*- Gerbil -*-
;;; Boundary: CLI process entrypoints stay thin.
;;; Invariant: `poo-flow run` starts a Gerbil process; focused build/test gates
;;; call gxc or the compiled-module test runner directly; full package builds
;;; remain owned by gxpkg build.

(import :gerbil/gambit
        (rename-in :poo-flow/src/cli-support/support
                   (poo-flow-cli-max-rss-bytes
                    cli-support-max-rss-bytes))
        :poo-flow/src/cli-support/build
        (rename-in :poo-flow/src/cli-support/test
                   (poo-flow-cli-expand-test-args
                    cli-support-expand-test-args)
                   (poo-flow-cli-read-unit-test-files
                    cli-support-read-unit-test-files)
                   (poo-flow-cli-runnable-test-form?
                    cli-support-runnable-test-form?)))

(export poo-flow-cli-main
        main
        poo-flow-cli-run
        poo-flow-cli-run-file
        poo-flow-cli-exit-code
        poo-flow-cli-script-args
        poo-flow-cli-executable-args
        poo-flow-cli-expand-test-args
        poo-flow-cli-max-rss-bytes
        poo-flow-cli-read-unit-test-files
        poo-flow-cli-runnable-test-form?
        poo-flow-cli-usage)

;; : (-> Unit String)
(def (poo-flow-cli-usage)
  "Usage:
  poo-flow run <file>.ss [args...]
  poo-flow build meta
  poo-flow build spec --module <file>.ss
  poo-flow build compile --module <file>.ss
  poo-flow test [test-file.ss...]
  poo-flow perf rss --max-mb <megabytes> [test-file.ss...]
  poo-flow help

Commands:
  run    Execute a Scheme file through gxpkg env gxi in the poo-flow package context.
  build  Run focused single-module build gates; full package builds use gxpkg build -R -O.
  test   Run focused tests through the compiled module runner.
  perf   Run focused performance gates around the test runner.
")

;; : (-> [String] [String])
(def (poo-flow-cli-expand-test-args args)
  (cli-support-expand-test-args args))

;; : (-> Unit [String])
(def (poo-flow-cli-read-unit-test-files)
  (cli-support-read-unit-test-files))

;; : (-> Object Boolean)
(def (poo-flow-cli-runnable-test-form? form)
  (cli-support-runnable-test-form? form))

;; : (-> String MaybeInteger)
(def (poo-flow-cli-max-rss-bytes output)
  (cli-support-max-rss-bytes output))

;; : (-> String [String] Integer)
(def (poo-flow-cli-run-command command rest)
  (cond
   ((equal? command "run")
    (if (null? rest)
      (begin
        (poo-flow-cli-error "poo-flow run: missing <file>.ss")
        (display (poo-flow-cli-usage) (current-error-port))
        64)
      (poo-flow-cli-run-file (car rest) (cdr rest))))
   ((equal? command "build")
    (poo-flow-cli-build rest))
   ((equal? command "test")
    (poo-flow-cli-test rest))
   ((equal? command "perf")
    (poo-flow-cli-perf rest))
   (else
    (poo-flow-cli-error (string-append "poo-flow: unknown command " command))
    (display (poo-flow-cli-usage) (current-error-port))
    64)))

;;; Boundary: command dispatch is intentionally small until Marlin owns execution.
;; : (-> [String] Integer)
(def (poo-flow-cli-run args)
  (cond
   ((null? args)
    (poo-flow-cli-error "poo-flow: missing command")
    (display (poo-flow-cli-usage) (current-error-port))
    64)
   ((or (equal? (car args) "help")
        (equal? (car args) "-h")
        (equal? (car args) "--help"))
    (display (poo-flow-cli-usage))
    0)
   (else
    (poo-flow-cli-run-command (car args) (cdr args)))))

;; : (-> [String] Void)
(def (poo-flow-cli-main args)
  (exit (poo-flow-cli-run args)))

;;; Native executable entrypoint. Keep the entry path command-line based; direct
;;; test calls should exercise `poo-flow-cli-run`/`poo-flow-cli-main`.
;; : (-> String ... Void)
(def (main . args)
  (poo-flow-cli-main
   (if (null? args)
     (poo-flow-cli-executable-args (command-line))
     args)))
