;;; -*- Gerbil -*-
;;; Boundary: CLI process entrypoints stay thin and delegate flow semantics to scripts.
;;; Invariant: `poo-flow run` starts a Gerbil process; it does not schedule flows.

(import (only-in :std/misc/process run-process)
        (only-in :std/srfi/1 filter fold))

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
  run   Execute a Scheme file through gxi with the current poo-flow loadpath.
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

;; : (-> (U #f String) Boolean)
(def (poo-flow-cli-loadpath-part? part)
  (and part (not (equal? part ""))))

;; : (-> [String] String)
;; poo-flow-cli-join-loadpath
;;   : (-> [String] String)
;;   | doc m%
;;   | Collapse an ordered loadpath candidate list into a colon-separated
;;   | string while dropping missing or empty path fragments.
;;   | # Examples
;;   | ```scheme
;;   | (poo-flow-cli-join-loadpath '("src" "t")) => "src:t"
;;   | (poo-flow-cli-join-loadpath (list "src" #f "")) => "src"
;;   | ```
;;   | result: the relative order of surviving fragments is preserved.
(def (poo-flow-cli-join-loadpath parts)
  (or (fold (lambda (part out)
              (if out
                (string-append out ":" part)
                part))
            #f
            (filter poo-flow-cli-loadpath-part? parts))
      ""))

;; : (-> String)
(def (poo-flow-cli-home-gerbil-lib)
  (let (home (getenv "HOME" #f))
    (if home
      (string-append home "/.gerbil/lib")
      #f)))

;; : (-> String String)
(def (poo-flow-cli-root-path leaf)
  (string-append (current-directory) leaf))

;; : (-> String)
(def (poo-flow-cli-child-loadpath)
  ;; The generated binary lives under .bin, but flow scripts import package
  ;; modules. Keep repo src/t first and append caller-provided extension paths.
  (poo-flow-cli-join-loadpath
   (list (poo-flow-cli-root-path "src")
         (poo-flow-cli-root-path "t")
         (poo-flow-cli-home-gerbil-lib)
         (getenv "GERBIL_LOADPATH" #f))))

;;; Boundary: child output is passed through as the run receipt surface.
;;; Intent: scripts own funflow construction; CLI only reports process status.
;; : (-> Path [String] Integer)
(def (poo-flow-cli-run-file file args)
  (let (status 0)
    (let (output
          (run-process
           (append (list "env"
                         (string-append "GERBIL_LOADPATH="
                                        (poo-flow-cli-child-loadpath))
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
