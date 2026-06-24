;;; -*- Gerbil -*-
;;; Boundary: CLI process entrypoints stay thin.
;;; Invariant: `poo-flow run` starts a Gerbil process; focused build/test gates
;;; call gxc or the compiled-module test runner directly; full package builds
;;; remain owned by gxpkg build.

(import :gerbil/gambit
        (only-in :std/misc/process run-process))

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

;; : String
(def poo-flow-cli-local-source-loadpath ".")

;; : String
(def poo-flow-cli-user-compiled-loadpath (path-expand "~/.gerbil/lib"))

;; : Fixnum
(def +poo-flow-cli-default-test-batch-size+ 4)

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
  (if (file-exists? poo-flow-cli-user-compiled-loadpath)
    (string-append poo-flow-cli-local-source-loadpath
                   ":"
                   poo-flow-cli-user-compiled-loadpath)
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
(def +poo-flow-cli-unit-test-root+ "t/unit-tests.ss")

;; : ([String] -> Integer)
(def (poo-flow-cli-run-inherited argv)
  (let (status 0)
    (run-process argv
                 stdin-redirection: #f
                 stdout-redirection: #f
                 stderr-redirection: #f
                 check-status:
                 (lambda (exit-status _settings)
                   (set! status exit-status)))
    (poo-flow-cli-exit-code status)))

;; : ([String] -> (cons Integer String))
(def (poo-flow-cli-run-captured argv)
  (let (status 0)
    (let (output
          (run-process argv
                       stderr-redirection: #t
                       check-status:
                       (lambda (exit-status _settings)
                         (set! status exit-status))))
      (cons (poo-flow-cli-exit-code status) output))))

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
(def (poo-flow-cli-gerbil-env-argv executable args)
  (append
   (list "env"
         (string-append "GERBIL_LOADPATH="
                        (poo-flow-cli-gerbil-loadpath))
         executable)
   args))

;; : (String String -> Bool)
(def (poo-flow-cli-string-prefix? prefix text)
  (let ((prefix-length (string-length prefix))
        (text-length (string-length text)))
    (and (<= prefix-length text-length)
         (string=? (substring text 0 prefix-length) prefix))))

;; : (String String -> Bool)
(def (poo-flow-cli-string-suffix? suffix text)
  (let ((suffix-length (string-length suffix))
        (text-length (string-length text)))
    (and (<= suffix-length text-length)
         (string=?
          (substring text (- text-length suffix-length) text-length)
          suffix))))

;; : (String String -> Bool)
(def (poo-flow-cli-string-contains? needle text)
  (let ((needle-length (string-length needle))
        (text-length (string-length text)))
    (let loop ((start 0))
      (cond
       ((> (+ start needle-length) text-length) #f)
       ((string=? (substring text start (+ start needle-length)) needle) #t)
       (else (loop (+ start 1)))))))

;; : (Char -> Bool)
(def (poo-flow-cli-whitespace? ch)
  (or (char=? ch #\space)
      (char=? ch #\tab)
      (char=? ch #\newline)
      (char=? ch #\return)))

;; : (Char -> Bool)
(def (poo-flow-cli-digit? ch)
  (let (code (char->integer ch))
    (and (>= code 48) (<= code 57))))

;; : (String Fixnum Fixnum -> Fixnum)
(def (poo-flow-cli-skip-whitespace text start end)
  (let loop ((index start))
    (if (and (< index end)
             (poo-flow-cli-whitespace? (string-ref text index)))
      (loop (+ index 1))
      index)))

;; : (String Fixnum Fixnum -> Fixnum)
(def (poo-flow-cli-skip-digits text start end)
  (let loop ((index start))
    (if (and (< index end)
             (poo-flow-cli-digit? (string-ref text index)))
      (loop (+ index 1))
      index)))

;; : (String Fixnum -> Fixnum)
(def (poo-flow-cli-find-newline text start)
  (let ((length (string-length text)))
    (let loop ((index start))
      (cond
       ((>= index length) length)
       ((char=? (string-ref text index) #\newline) index)
       (else (loop (+ index 1)))))))

;; : (String -> (OrFalse Integer))
(def (poo-flow-cli-leading-number text)
  (let* ((length (string-length text))
         (start (poo-flow-cli-skip-whitespace text 0 length))
         (end (poo-flow-cli-skip-digits text start length)))
    (if (> end start)
      (string->number (substring text start end))
      #f)))

;; : (String Char Fixnum Fixnum -> (OrFalse Fixnum))
(def (poo-flow-cli-find-char text ch start length)
  (let loop ((index start))
    (cond
     ((>= index length) #f)
     ((char=? (string-ref text index) ch) index)
     (else (loop (+ index 1))))))

;; : (String Char -> (OrFalse Integer))
(def (poo-flow-cli-number-after-char text ch)
  (let* ((length (string-length text))
         (anchor (poo-flow-cli-find-char text ch 0 length)))
    (if anchor
      (let* ((start (poo-flow-cli-skip-whitespace text (+ anchor 1) length))
             (end (poo-flow-cli-skip-digits text start length)))
        (if (> end start)
          (string->number (substring text start end))
          #f))
      #f)))

;; : (String -> (OrFalse Integer))
(def (poo-flow-cli-rss-line-bytes line)
  (cond
   ((poo-flow-cli-string-contains? "maximum resident set size" line)
    (poo-flow-cli-leading-number line))
   ((poo-flow-cli-string-contains? "Maximum resident set size" line)
    (let (kbytes (poo-flow-cli-number-after-char line #\:))
      (if kbytes
        (* kbytes 1024)
        #f)))
   (else #f)))

;; : (String -> (OrFalse Integer))
(def (poo-flow-cli-max-rss-bytes output)
  (let ((length (string-length output)))
    (let loop ((start 0))
      (if (>= start length)
        #f
        (let* ((line-end (poo-flow-cli-find-newline output start))
               (line (substring output start line-end))
               (rss-bytes (poo-flow-cli-rss-line-bytes line)))
          (if rss-bytes
            rss-bytes
            (loop (+ line-end 1))))))))

;; : (Integer -> Integer)
(def (poo-flow-cli-megabytes->bytes megabytes)
  (* megabytes 1024 1024))

;; : (Object -> (OrFalse String))
(def (poo-flow-cli-unit-test-import->file spec)
  (and (symbol? spec)
       (let ((module-name (symbol->string spec))
             (prefix ":poo-flow/t/"))
         (and (poo-flow-cli-string-prefix? prefix module-name)
              (string-append
               "t/"
               (substring module-name
                          (string-length prefix)
                          (string-length module-name))
               ".ss")))))

;; : (String -> String)
(def (poo-flow-cli-test-file-without-extension file)
  (if (poo-flow-cli-string-suffix? ".ss" file)
    (substring file 0 (- (string-length file) 3))
    file))

;; : (String -> String)
(def (poo-flow-cli-test-file->module file)
  (string-append ":poo-flow/"
                 (poo-flow-cli-test-file-without-extension file)))

;; : (String -> (OrFalse Fixnum))
(def (poo-flow-cli-last-slash-index text)
  (let ((length (string-length text)))
    (let loop ((index 0)
               (last #f))
      (cond
       ((>= index length) last)
       ((char=? (string-ref text index) #\/)
        (loop (+ index 1) index))
       (else
        (loop (+ index 1) last))))))

;; : (String -> String)
(def (poo-flow-cli-test-file->suite file)
  (let* ((module-path (poo-flow-cli-test-file-without-extension file))
         (slash (poo-flow-cli-last-slash-index module-path))
         (start (if slash (+ slash 1) 0)))
    (substring module-path start (string-length module-path))))

;; : ([String] -> String)
(def (poo-flow-cli-test-imports-expression files)
  (cond
   ((null? files) "")
   (else
    (string-append " "
                   (poo-flow-cli-test-file->module (car files))
                   (poo-flow-cli-test-imports-expression (cdr files))))))

;; : ([String] -> String)
(def (poo-flow-cli-test-runs-expression files)
  (cond
   ((null? files) "")
   (else
    (string-append " (run-tests! "
                   (poo-flow-cli-test-file->suite (car files))
                   ")"
                   (poo-flow-cli-test-runs-expression (cdr files))))))

;; : ([String] -> String)
(def (poo-flow-cli-test-expression files)
  (string-append "(begin (import :std/test"
                 (poo-flow-cli-test-imports-expression files)
                 ")"
                 (poo-flow-cli-test-runs-expression files)
                 ")"))

;; : ([Object] -> [String])
(def (poo-flow-cli-unit-test-files-from-imports specs)
  (cond
   ((null? specs) [])
   (else
    (let ((file (poo-flow-cli-unit-test-import->file (car specs)))
          (rest (poo-flow-cli-unit-test-files-from-imports (cdr specs))))
      (if file
        (cons file rest)
        rest)))))

;; : (-> [String])
(def (poo-flow-cli-read-unit-test-files)
  (if (file-exists? +poo-flow-cli-unit-test-root+)
    (call-with-input-file +poo-flow-cli-unit-test-root+
      (lambda (port)
        (let (expr (read port))
          (if (and (pair? expr)
                   (eq? (car expr) 'import))
            (poo-flow-cli-unit-test-files-from-imports (cdr expr))
            (list +poo-flow-cli-unit-test-root+)))))
    (list +poo-flow-cli-unit-test-root+)))

;; : (String -> Bool)
(def (poo-flow-cli-unit-test-root? file)
  (equal? file +poo-flow-cli-unit-test-root+))

;; : ([String] -> [String])
(def (poo-flow-cli-expand-test-args args)
  (cond
   ((null? args) (poo-flow-cli-read-unit-test-files))
   ((and (null? (cdr args))
         (poo-flow-cli-unit-test-root? (car args)))
    (poo-flow-cli-read-unit-test-files))
   (else args)))

;; : (Object Symbol -> Bool)
(def (poo-flow-cli-form-contains-symbol? form symbol)
  (cond
   ((eq? form symbol) #t)
   ((pair? form)
    (or (poo-flow-cli-form-contains-symbol? (car form) symbol)
        (poo-flow-cli-form-contains-symbol? (cdr form) symbol)))
   (else #f)))

;; : (Object -> Bool)
(def (poo-flow-cli-runnable-test-form? form)
  (and (pair? form)
       (not (eq? (car form) 'import))
       (or (poo-flow-cli-form-contains-symbol? form 'test-suite)
           (poo-flow-cli-form-contains-symbol? form 'run-tests!)
           (poo-flow-cli-form-contains-symbol?
            form
            'define-poo-flow-module-system-live-case-test)
           (poo-flow-cli-form-contains-symbol?
            form
            'poo-flow-import-side-effect-test-suite?))))

;; : (String -> Bool)
(def (poo-flow-cli-runnable-test-file? file)
  (and (file-exists? file)
       (call-with-input-file file
         (lambda (port)
           (let loop ()
             (let (form (read port))
               (cond
                ((eof-object? form) #f)
                ((poo-flow-cli-runnable-test-form? form) #t)
                (else (loop)))))))))

;; : (String -> Integer)
(def (poo-flow-cli-reject-empty-test-file! file)
  (poo-flow-cli-error "poo-flow test: test file has no runnable test suite")
  (poo-flow-cli-error (string-append "file: " file))
  (poo-flow-cli-error "next: add test-suite/run-tests! or an explicit poo-flow-import-side-effect-test-suite? marker")
  65)

;; : ([String] -> Integer)
(def (poo-flow-cli-validate-test-files files)
  (cond
   ((null? files) 0)
   ((poo-flow-cli-runnable-test-file? (car files))
    (poo-flow-cli-validate-test-files (cdr files)))
   (else
    (poo-flow-cli-reject-empty-test-file! (car files)))))

;; : (String [String] -> [String])
(def (poo-flow-cli-module-gxc-argv module-file args)
  (if (poo-flow-cli-native-module-build? args)
    #f
    (poo-flow-cli-gerbil-env-argv "gxc" [module-file])))

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
  (poo-flow-cli-gerbil-env-argv
   "gxi"
   ["-e" (poo-flow-cli-test-expression args)]))

;;; Sequential process batch size, not concurrency. Each batch runs in one
;;; gxtest child process; batches run one after another.
;; : (-> Integer)
(def (poo-flow-cli-test-batch-size)
  (let (value (getenv "POO_FLOW_TEST_BATCH_SIZE" #f))
    (if value
      (let (size (string->number value))
        (if (and (integer? size)
                 (> size 0))
          size
          +poo-flow-cli-default-test-batch-size+))
      +poo-flow-cli-default-test-batch-size+)))

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
             (poo-flow-cli-run-inherited argv)
             (poo-flow-cli-reject-native-module-build! module-file)))
         (poo-flow-cli-reject-package-build! args))))
    (_ (poo-flow-cli-reject-package-build! args))))

;; : ([String] Number -> Unit)
(def (poo-flow-cli-display-test-receipt files elapsed)
  (display "[poo-flow-test] done ")
  (write files)
  (display " elapsed=")
  (display elapsed)
  (display "s")
  (newline)
  (force-output))

;; : ([String] Number Integer -> Unit)
(def (poo-flow-cli-display-test-failure files elapsed status)
  (display "[poo-flow-test] fail ")
  (write files)
  (display " status=")
  (display status)
  (display " elapsed=")
  (display elapsed)
  (display "s")
  (newline)
  (force-output))

;; : ([String] -> Integer)
(def (poo-flow-cli-test-batch files)
  (display "[poo-flow-test] start ")
  (write files)
  (newline)
  (force-output)
  (let* ((started-at (time->seconds (current-time)))
         (status (poo-flow-cli-run-inherited (poo-flow-cli-test-argv files)))
         (elapsed (- (time->seconds (current-time)) started-at)))
    (if (= status 0)
      (poo-flow-cli-display-test-receipt files elapsed)
      (poo-flow-cli-display-test-failure files elapsed status))
    status))

;; : ([String] Integer -> [String])
(def (poo-flow-cli-take-tests files n)
  (cond
   ((or (zero? n) (null? files)) [])
   (else (cons (car files)
               (poo-flow-cli-take-tests (cdr files) (- n 1))))))

;; : ([String] Integer -> [String])
(def (poo-flow-cli-drop-tests files n)
  (cond
   ((or (zero? n) (null? files)) files)
   (else (poo-flow-cli-drop-tests (cdr files) (- n 1)))))

;; : ([String] -> Integer)
(def (poo-flow-cli-test-files files)
  (let (validation-status (poo-flow-cli-validate-test-files files))
    (if (= validation-status 0)
      (let (batch-size (poo-flow-cli-test-batch-size))
        (let lp ((rest files))
          (cond
           ((null? rest) 0)
           (else
            (let ((batch (poo-flow-cli-take-tests rest batch-size))
                  (next (poo-flow-cli-drop-tests rest batch-size)))
              (let (status (poo-flow-cli-test-batch batch))
                (if (= status 0)
                  (lp next)
                  status)))))))
      validation-status)))

;; : ([String] -> Integer)
(def (poo-flow-cli-test args)
  (poo-flow-cli-test-files (poo-flow-cli-expand-test-args args)))

;; : ([String] -> [String])
(def (poo-flow-cli-perf-rss-time-argv)
  (cond-expand
   (darwin (list "/usr/bin/time" "-l"))
   (else (list "/usr/bin/time" "-v"))))

;; : ([String] -> [String])
(def (poo-flow-cli-perf-rss-argv files)
  (append (poo-flow-cli-perf-rss-time-argv)
          (poo-flow-cli-test-argv files)))

;; : (Integer Integer Integer -> Unit)
(def (poo-flow-cli-display-rss-receipt rss-bytes max-bytes elapsed)
  (display "[poo-flow-perf] rss=")
  (display rss-bytes)
  (display " max=")
  (display max-bytes)
  (display " elapsed=")
  (display elapsed)
  (display "s")
  (newline)
  (force-output))

;; : (String -> Integer)
(def (poo-flow-cli-reject-rss-parse! output)
  (poo-flow-cli-error "poo-flow perf rss: could not parse maximum resident set size")
  (poo-flow-cli-error "expected: time output with `maximum resident set size`")
  66)

;; : (Integer Integer -> Integer)
(def (poo-flow-cli-reject-rss-threshold! rss-bytes max-bytes)
  (poo-flow-cli-error "poo-flow perf rss: memory threshold exceeded")
  (poo-flow-cli-error (string-append "rss-bytes: " (object->string rss-bytes)))
  (poo-flow-cli-error (string-append "max-bytes: " (object->string max-bytes)))
  75)

;; : (Integer [String] -> Integer)
(def (poo-flow-cli-perf-rss-files max-megabytes files)
  (cond
   ((not (file-exists? "/usr/bin/time"))
    (poo-flow-cli-error "poo-flow perf rss: /usr/bin/time is required for RSS gates")
    69)
   (else
    (let (validation-status (poo-flow-cli-validate-test-files files))
      (if (= validation-status 0)
        (let* ((started-at (time->seconds (current-time)))
               (result (poo-flow-cli-run-captured
                        (poo-flow-cli-perf-rss-argv files)))
               (elapsed (- (time->seconds (current-time)) started-at))
               (status (car result))
               (output (cdr result)))
          (display output)
          (force-output)
          (if (= status 0)
            (let ((rss-bytes (poo-flow-cli-max-rss-bytes output))
                  (max-bytes (poo-flow-cli-megabytes->bytes max-megabytes)))
              (if rss-bytes
                (begin
                  (poo-flow-cli-display-rss-receipt rss-bytes max-bytes elapsed)
                  (if (> rss-bytes max-bytes)
                    (poo-flow-cli-reject-rss-threshold! rss-bytes max-bytes)
                    0))
                (poo-flow-cli-reject-rss-parse! output)))
            status))
        validation-status)))))

;; : ([String] -> Integer)
(def (poo-flow-cli-perf-rss args)
  (match args
    (["--max-mb" max-megabytes . test-args]
     (let (max-value (string->number max-megabytes))
       (if (and (integer? max-value)
                (> max-value 0))
         (poo-flow-cli-perf-rss-files
          max-value
          (poo-flow-cli-expand-test-args test-args))
         (begin
           (poo-flow-cli-error "poo-flow perf rss: --max-mb must be a positive integer")
           64))))
    (_
     (poo-flow-cli-error "poo-flow perf rss: usage is `poo-flow perf rss --max-mb <megabytes> [test-file.ss...]`")
     64)))

;; : ([String] -> Integer)
(def (poo-flow-cli-perf args)
  (match args
    (["rss" . rest] (poo-flow-cli-perf-rss rest))
    (_
     (poo-flow-cli-error "poo-flow perf: usage is `poo-flow perf rss --max-mb <megabytes> [test-file.ss...]`")
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
   ((equal? (car args) "perf")
    (poo-flow-cli-perf (cdr args)))
   (else
    (poo-flow-cli-error (string-append "poo-flow: unknown command " (car args)))
    (display (poo-flow-cli-usage) (current-error-port))
    64)))

;; : (-> [String] Unit)
(def (poo-flow-cli-main args)
  (exit (poo-flow-cli-run args)))

;;; Native executable entrypoint. Keep the entry path command-line based; direct
;;; test calls should exercise `poo-flow-cli-run`/`poo-flow-cli-main`.
;; Unit <- [String]
(def (main)
  (poo-flow-cli-main
   (poo-flow-cli-executable-args (command-line))))
