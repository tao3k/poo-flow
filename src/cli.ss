;;; -*- Gerbil -*-
;;; Boundary: CLI process entrypoints stay thin.
;;; Invariant: `poo-flow run` starts a Gerbil process; focused build/test gates
;;; call gxc or the compiled-module test runner directly; full package builds
;;; remain owned by gxpkg build.

(import :gerbil/gambit
        :poo-flow/src/cli-support/support)

(export poo-flow-cli-main
        main
        poo-flow-cli-run
        poo-flow-cli-run-file
        poo-flow-cli-exit-code
        poo-flow-cli-script-args
        poo-flow-cli-executable-args
        poo-flow-cli-max-rss-bytes
        poo-flow-cli-usage)

;; : (-> Unit String)
(def (poo-flow-cli-usage)
  "Usage:
  poo-flow run <file>.ss [args...]
  poo-flow help

Commands:
  run    Execute a Scheme file through gxpkg env gxi in the poo-flow package context.
")

;; : (-> String MaybeInteger)
;;; Boundary: cli run command is the policy-visible edge for CLI behavior,
;;; keeping validation, lookup, or projection responsibilities centralized for
;;; callers.
;; : (-> String [String] Integer)
(def (poo-flow-cli-run-command command rest)
  (parameterize ((current-error-port (current-error-port)))
    (cond
     ((equal? command "run")
      (if (null? rest)
        (begin
          (poo-flow-cli-error "poo-flow run: missing <file>.ss")
          (display (poo-flow-cli-usage) (current-error-port))
          64)
        (poo-flow-cli-run-file (car rest) (cdr rest))))
     (else
      (poo-flow-cli-error (string-append "poo-flow: unknown command " command))
      (display (poo-flow-cli-usage) (current-error-port))
      64))))

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
