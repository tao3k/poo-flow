;;; -*- Gerbil -*-
;;; Boundary: CLI process entrypoints stay thin.
;;; Invariant: `poo-flow run` starts a Gerbil process; focused build/test gates
;;; call gxc/gxtest directly; full package builds remain owned by gxpkg build.

(import :gerbil/gambit
        (only-in :std/misc/process run-process))

(export poo-flow-cli-main
        main
        poo-flow-cli-run
        poo-flow-cli-run-file
        poo-flow-cli-exit-code
        poo-flow-cli-script-args
        poo-flow-cli-executable-args
        poo-flow-cli-usage)

;; : String
(def poo-flow-cli-local-source-loadpath ".")

;; : String
(def poo-flow-cli-local-compiled-loadpath ".gerbil/lib")

;; : (-> Unit String)
(def (poo-flow-cli-usage)
  "Usage:
  poo-flow run <file>.ss [args...]
  poo-flow build meta
  poo-flow build spec --module <file>.ss
  poo-flow build compile --module <file>.ss
  poo-flow test [test-file.ss...]
  poo-flow help

Commands:
  run    Execute a Scheme file through gxpkg env gxi in the poo-flow package context.
  build  Run focused single-module build gates; full package builds use gxpkg build -R -O.
  test   Run focused tests through gxtest directly.
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

;; : (-> String)
(def (poo-flow-cli-local-loadpath)
  (if (file-exists? poo-flow-cli-local-compiled-loadpath)
    (string-append poo-flow-cli-local-source-loadpath
                   ":"
                   poo-flow-cli-local-compiled-loadpath)
    poo-flow-cli-local-source-loadpath))

;; : (-> String)
(def (poo-flow-cli-gerbil-loadpath)
  (let ((current (getenv "GERBIL_LOADPATH" #f))
        (local-loadpath (poo-flow-cli-local-loadpath)))
    (if (and current (not (string=? current "")))
      (string-append local-loadpath ":" current)
      local-loadpath)))

;; : (-> Path [String] [String])
(def (poo-flow-cli-run-command file args)
  (append
   (list "env"
         (string-append "GERBIL_LOADPATH="
                        (poo-flow-cli-gerbil-loadpath))
         "gxpkg"
         "env"
         "gxi"
         file)
   args))

;;; Boundary: child output is passed through as the run receipt surface.
;;; Intent: scripts own funflow construction; CLI only reports process status.
;; : (-> Path [String] Integer)
(def (poo-flow-cli-run-file file args)
  (let (status 0)
    (let (output
          (run-process
           (poo-flow-cli-run-command file args)
           stderr-redirection: #t
           check-status:
           (lambda (exit-status _settings)
             (set! status exit-status))))
      (display output)
      (poo-flow-cli-exit-code status))))

;; : [String]
(def +poo-flow-cli-default-test-files+ ["t/unit-tests.ss"])

;; : ([String] -> Void)
(def (poo-flow-cli-run-inherited argv)
  (run-process argv
               stdin-redirection: #f
               stdout-redirection: #f
               stderr-redirection: #f))

;; : (String [String] -> Bool)
(def (poo-flow-cli-arg-present? flag args)
  (cond
   ((null? args) #f)
   ((equal? (car args) flag) #t)
   (else (poo-flow-cli-arg-present? flag (cdr args)))))

;; : ([String] -> (OrFalse String))
(def (poo-flow-cli-module-arg args)
  (match args
    ([] #f)
    (["--module" file . _] file)
    ([_ . rest] (poo-flow-cli-module-arg rest))))

;; : ([String] -> Bool)
(def (poo-flow-cli-native-module-build? args)
  (or (poo-flow-cli-arg-present? "--release" args)
      (poo-flow-cli-arg-present? "--optimized" args)
      (poo-flow-cli-arg-present? "--debug" args)))

;; : (String -> Integer)
(def (poo-flow-cli-reject-native-module-build! module-file)
  (poo-flow-cli-error "poo-flow build: single-module native builds are not supported; use the package build graph")
  (poo-flow-cli-error (string-append "module: " module-file))
  (poo-flow-cli-error "next: gxpkg build -R -O")
  70)

;; : (String [String] -> [String])
(def (poo-flow-cli-module-gxc-argv module-file args)
  (if (poo-flow-cli-native-module-build? args)
    #f
    ["gxc" module-file]))

;; : (String [String] -> BuildSpec)
(def (poo-flow-cli-module-spec module-file args)
  (if (poo-flow-cli-native-module-build? args)
    #f
    [[gxc: module-file]]))

;; : ([String] -> Integer)
(def (poo-flow-cli-reject-package-build! args)
  (poo-flow-cli-error "poo-flow build: full package builds are owned by gxpkg build")
  (poo-flow-cli-error (string-append "args: " (object->string args)))
  (poo-flow-cli-error "next: gxpkg build -R -O")
  64)

;; : ([String] -> [String])
(def (poo-flow-cli-test-argv args)
  (cons "gxtest"
        (if (null? args)
          +poo-flow-cli-default-test-files+
          args)))

;; : ([String] -> Integer)
(def (poo-flow-cli-build args)
  (match args
    (["meta"]
     (write '("spec" "compile"))
     (newline)
     0)
    (["spec" . rest]
     (let (module-file (poo-flow-cli-module-arg rest))
       (if module-file
         (let (spec (poo-flow-cli-module-spec module-file rest))
           (if spec
             (begin
               (write spec)
               (newline)
               0)
             (poo-flow-cli-reject-native-module-build! module-file)))
         (poo-flow-cli-reject-package-build! args))))
    (["compile" . rest]
     (let (module-file (poo-flow-cli-module-arg rest))
       (if module-file
         (let (argv (poo-flow-cli-module-gxc-argv module-file rest))
           (if argv
             (begin
               (poo-flow-cli-run-inherited argv)
               0)
             (poo-flow-cli-reject-native-module-build! module-file)))
         (poo-flow-cli-reject-package-build! args))))
    (_ (poo-flow-cli-reject-package-build! args))))

;; : ([String] -> Integer)
(def (poo-flow-cli-test args)
  (poo-flow-cli-run-inherited (poo-flow-cli-test-argv args))
  0)

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
   ((equal? (car args) "build")
    (poo-flow-cli-build (cdr args)))
   ((equal? (car args) "test")
    (poo-flow-cli-test (cdr args)))
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
