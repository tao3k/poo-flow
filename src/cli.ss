;;; -*- Gerbil -*-
;;; Boundary: CLI process entrypoints stay thin and delegate flow semantics to scripts.
;;; Invariant: `poo-flow run` starts a Gerbil process; it does not schedule flows.

(import (only-in :std/misc/process run-process))

(export poo-flow-cli-main
        main
        poo-flow-cli-run
        poo-flow-cli-run-file
        poo-flow-cli-exit-code
        poo-flow-cli-script-args
        poo-flow-cli-executable-args
        poo-flow-cli-usage)

;; : (-> Unit String)
(def (poo-flow-cli-usage)
  "Usage:
  poo-flow run <file>.ss [args...]
  poo-flow help

Commands:
  run   Execute a Scheme file through gxpkg env gxi in the poo-flow package context.
")

;; : (-> String Unit)
(def (poo-flow-cli-error message)
  (display message (current-error-port))
  (newline (current-error-port)))

;; : (-> Integer Integer)
(def (poo-flow-cli-exit-code status)
  (cond
   ((< status 0) 1)
   ((> status 255) (quotient status 256))
   (else status)))

;; : (-> [String] [String])
(def (poo-flow-cli-script-args command-line-args)
  (if (and (pair? command-line-args)
           (pair? (cdr command-line-args)))
    (cddr command-line-args)
    '()))

;; : (-> [String] [String])
(def (poo-flow-cli-executable-args command-line-args)
  (if (pair? command-line-args)
    (cdr command-line-args)
    '()))

;;; Boundary: child output is passed through as the run receipt surface.
;;; Intent: scripts own funflow construction; CLI only reports process status.
;; : (-> Path [String] Integer)
(def (poo-flow-cli-run-file file args)
  (let (status 0)
    (let (output
          (run-process
           (append (list "gxpkg"
                         "env"
                         "gxi"
                         file)
                   args)
           stderr-redirection: #t
           check-status:
           (lambda (exit-status _settings)
             (set! status exit-status))))
      (display output)
      (poo-flow-cli-exit-code status))))

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
   ((equal? (car args) "run")
    (if (null? (cdr args))
      (begin
        (poo-flow-cli-error "poo-flow run: missing <file>.ss")
        (display (poo-flow-cli-usage) (current-error-port))
        64)
      (poo-flow-cli-run-file (cadr args) (cddr args))))
   (else
    (poo-flow-cli-error (string-append "poo-flow: unknown command " (car args)))
    (display (poo-flow-cli-usage) (current-error-port))
    64)))

;; : (-> [String] Unit)
(def (poo-flow-cli-main args)
  (exit (poo-flow-cli-run args)))

;;; Native executable entrypoint. Gerbil's exe builder supplies args in native
;;; mode; script-style runs fall back to `(command-line)`.
;; Unit <- [String]
(def (main . args)
  (poo-flow-cli-main
   (if (null? args)
     (poo-flow-cli-executable-args (command-line))
     args)))
