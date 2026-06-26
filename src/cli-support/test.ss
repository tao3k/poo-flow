;;; -*- Gerbil -*-
;;; Boundary: focused test and RSS performance commands for the CLI.

(import :gerbil/gambit
        :poo-flow/src/cli-support/support
        (only-in :std/srfi/1 filter-map fold take drop unfold)
        (only-in :std/srfi/13 string-concatenate))

(export poo-flow-cli-expand-test-args
        poo-flow-cli-read-unit-test-files
        poo-flow-cli-runnable-test-form?
        poo-flow-cli-test-policy-file-path
        poo-flow-cli-test
        poo-flow-cli-perf)

;; : (-> Unit [String])
(def (poo-flow-cli-unit-test-root)
  "t/unit-tests.ss")

;; : (-> Unit [String])
(def (poo-flow-cli-test-roots)
  '("t/unit-tests.ss"
    "t/contract-tests.ss"
    "t/integration-tests.ss"
    "t/performance-tests.ss"))

;; : (-> Object MaybeString)
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

;; : (-> String String)
(def (poo-flow-cli-test-file-without-extension file)
  (if (poo-flow-cli-string-suffix? ".ss" file)
    (substring file 0 (- (string-length file) 3))
    file))

;; : (-> String String)
(def (poo-flow-cli-test-file->module file)
  (string-append ":poo-flow/"
                 (poo-flow-cli-test-file-without-extension file)))

;; : (-> String MaybeFixnum)
(def (poo-flow-cli-last-slash-index text)
  (string-rindex text #\/))

;; : (-> String String)
(def (poo-flow-cli-test-file->suite file)
  (let* ((module-path (poo-flow-cli-test-file-without-extension file))
         (slash (poo-flow-cli-last-slash-index module-path))
         (start (if slash (+ slash 1) 0)))
    (substring module-path start (string-length module-path))))

;; : (-> [String] String)
(def (poo-flow-cli-test-imports-expression files)
  (string-concatenate
   (map (lambda (file)
          (string-append " " (poo-flow-cli-test-file->module file)))
        files)))

;; : (-> [String] String)
(def (poo-flow-cli-top-level-run-tests-form? form)
  (and (pair? form)
       (eq? (car form) 'run-tests!)))

;; : (-> String Boolean)
(def (poo-flow-cli-file-runs-tests-on-import? file)
  (and (file-exists? file)
       (call-with-input-file file
         (lambda (port)
           (let loop ()
             (let (form (read port))
               (cond
                ((eof-object? form) #f)
                ((poo-flow-cli-top-level-run-tests-form? form) #t)
                (else (loop)))))))))

;; : (-> Object MaybeString)
(def (poo-flow-cli-export-test-suite-name entry)
  (and (symbol? entry)
       (let (name (symbol->string entry))
         (and (poo-flow-cli-string-suffix? "-test" name)
              name))))

;; : (-> Object [String])
(def (poo-flow-cli-export-form-test-suite-names form)
  (if (and (pair? form)
           (eq? (car form) 'export))
    (filter-map poo-flow-cli-export-test-suite-name (cdr form))
    []))

;; : (-> String [String])
(def (poo-flow-cli-file-exported-test-suites file)
  (if (file-exists? file)
    (call-with-input-file file
      (lambda (port)
        (let loop ((suites []))
          (let (form (read port))
            (if (eof-object? form)
              (reverse suites)
              (loop (append (poo-flow-cli-export-form-test-suite-names form)
                            suites)))))))
    []))

;; : (-> String String)
(def (poo-flow-cli-file-test-suite-names file)
  (let (exported (poo-flow-cli-file-exported-test-suites file))
    (if (null? exported)
      (list (poo-flow-cli-test-file->suite file))
      exported)))

;; : (-> String String)
(def (poo-flow-cli-run-suite-expression suite)
  (string-append " (run-tests! " suite ")"))

;; : (-> String String)
(def (poo-flow-cli-test-run-expression file)
  (if (poo-flow-cli-file-runs-tests-on-import? file)
    ""
    (string-concatenate
     (map poo-flow-cli-run-suite-expression
          (poo-flow-cli-file-test-suite-names file)))))

;; : (-> [String] String)
(def (poo-flow-cli-test-runs-expression files)
  (string-concatenate
   (map (lambda (file)
          (poo-flow-cli-test-run-expression file))
        files)))

;; : (-> [String] String)
(def (poo-flow-cli-test-files-expression files)
  (string-append "'("
                 (string-concatenate
                  (map (lambda (file)
                         (string-append " " (object->string file)))
                       files))
                 ")"))

;; : (-> [String] String)
(def (poo-flow-cli-test-policy-expression files)
  (string-append " (run-tests! (make-policy-test \".\" "
                 (poo-flow-cli-test-files-expression files)
                 "))"))

;; : (-> [String] String)
(def (poo-flow-cli-test-expression files)
  (string-append "(begin (import :std/test"
                 " (only-in :gslph/src/policy/gxtest make-policy-test)"
                 (poo-flow-cli-test-imports-expression files)
                 ")"
                 (poo-flow-cli-test-runs-expression files)
                 (poo-flow-cli-test-policy-expression files)
                 ")"))

;; : (-> [Object] [String])
(def (poo-flow-cli-unit-test-files-from-imports specs)
  (filter-map poo-flow-cli-unit-test-import->file specs))

;; : (-> Object Boolean)
(def (poo-flow-cli-native-gxtest-form? form)
  (or (poo-flow-cli-form-contains-symbol? form 'test-suite)
      (poo-flow-cli-form-contains-symbol? form 'run-tests!)
      (poo-flow-cli-form-contains-symbol?
       form
       'define-poo-flow-module-system-live-case-test)))

;; : (-> String Boolean)
(def (poo-flow-cli-native-gxtest-file? file)
  (and (file-exists? file)
       (call-with-input-file file
         (lambda (port)
           (let loop ()
             (let (form (read port))
               (cond
                ((eof-object? form) #f)
                ((poo-flow-cli-native-gxtest-form? form) #t)
                (else (loop)))))))))

;; : (-> String [String])
(def (poo-flow-cli-read-test-file-imports file)
  (if (file-exists? file)
    (call-with-input-file file
      (lambda (port)
        (let (expr (read port))
          (if (and (pair? expr)
                   (eq? (car expr) 'import))
            (poo-flow-cli-unit-test-files-from-imports (cdr expr))
            []))))
    []))

;; : (-> String [String] [String])
(def (poo-flow-cli-expand-test-manifest-file file seen)
  (if (member file seen)
    (list file)
    (let (imported (poo-flow-cli-read-test-file-imports file))
      (if (and (not (null? imported))
               (not (poo-flow-cli-native-gxtest-file? file)))
        (apply append
               (map (lambda (imported-file)
                      (poo-flow-cli-expand-test-manifest-file
                       imported-file
                       (cons file seen)))
                    imported))
        (list file)))))

;; : (-> String [String])
(def (poo-flow-cli-read-test-root-files root)
  (poo-flow-cli-expand-test-manifest-file root []))

;; : (-> Unit [String])
(def (poo-flow-cli-read-unit-test-files)
  (poo-flow-cli-read-test-root-files (poo-flow-cli-unit-test-root)))

;; : (-> String Boolean)
(def (poo-flow-cli-test-root? file)
  (member file (poo-flow-cli-test-roots)))

;; : (-> [String] [String])
(def (poo-flow-cli-expand-test-args args)
  (cond
   ((null? args) (poo-flow-cli-read-unit-test-files))
   ((and (null? (cdr args))
         (poo-flow-cli-test-root? (car args)))
    (poo-flow-cli-read-test-root-files (car args)))
   (else args)))

;; : (-> Object Symbol Boolean)
(def (poo-flow-cli-form-contains-symbol? form symbol)
  (cond
   ((eq? form symbol) #t)
   ((pair? form)
    (or (poo-flow-cli-form-contains-symbol? (car form) symbol)
        (poo-flow-cli-form-contains-symbol? (cdr form) symbol)))
   (else #f)))

;; : (-> Object Boolean)
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

;;; Intent: reject stale or side-effect-only files before launching gxtest.
;;; Boundary: reads the test form stream and stops at the first runnable form.
;; : (-> String Boolean)
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

;; : (-> String Integer)
(def (poo-flow-cli-reject-empty-test-file! file)
  (poo-flow-cli-error "poo-flow test: test file has no runnable test suite")
  (poo-flow-cli-error (string-append "file: " file))
  (poo-flow-cli-error "next: add test-suite/run-tests! or an explicit poo-flow-import-side-effect-test-suite? marker")
  65)

;; : (-> [String] Integer)
(def (poo-flow-cli-validate-test-files files)
  (cond
   ((null? files) 0)
   ((poo-flow-cli-runnable-test-file? (car files))
    (poo-flow-cli-validate-test-files (cdr files)))
   (else
    (poo-flow-cli-reject-empty-test-file! (car files)))))

;; : (-> [String] String)
(def (poo-flow-cli-test-policy-file-content files)
  (string-append
   ";;; -*- Gerbil -*-\n"
   ";;; Generated by poo-flow test; do not commit.\n"
   "(import (only-in :gslph/src/policy/gxtest make-policy-test))\n"
   "(export poo-flow-cli-policy-test)\n"
   "(def poo-flow-cli-policy-test\n"
   "  (make-policy-test \".\" "
   (poo-flow-cli-test-files-expression files)
   "))\n"))

;; : (-> String)
(def (poo-flow-cli-test-policy-dir)
  ".gerbil/tmp/poo-flow-test")

;; : (-> Unit Void)
(def (poo-flow-cli-ensure-test-policy-dir!)
  (create-directory* (poo-flow-cli-test-policy-dir)))

;; : (-> String)
(def (poo-flow-cli-test-policy-file-path)
  (string-append (poo-flow-cli-test-policy-dir)
                 "/poo-flow-policy-"
                 (object->string (time->seconds (current-time)))
                 ".ss"))

;; : (-> [String] String)
(def (poo-flow-cli-write-test-policy-file files)
  (let (path (poo-flow-cli-test-policy-file-path))
    (poo-flow-cli-ensure-test-policy-dir!)
    (call-with-output-file path
      (lambda (port)
        (display (poo-flow-cli-test-policy-file-content files) port)))
    path))

;; : (-> MaybeString Unit)
(def (poo-flow-cli-delete-file-if-exists file)
  (when (and file (file-exists? file))
    (delete-file file)))

;; : (-> [String] String [String])
(def (poo-flow-cli-test-argv files policy-file)
  (poo-flow-cli-gerbil-env-argv
   "gxtest"
   (append files [policy-file])))

;; : (-> Unit Integer)
(def (poo-flow-cli-default-test-batch-size)
  4)

;;; Sequential process batch size, not concurrency. Each batch runs in one
;;; gxtest child process; batches run one after another.
;; : (-> Unit Integer)
(def (poo-flow-cli-test-batch-size)
  (let (value (getenv "POO_FLOW_TEST_BATCH_SIZE" #f))
    (if value
      (let (size (string->number value))
        (if (and (integer? size)
                 (> size 0))
          size
          (poo-flow-cli-default-test-batch-size)))
      (poo-flow-cli-default-test-batch-size))))

;; : (-> [String] Number Void)
(def (poo-flow-cli-display-test-receipt files elapsed)
  (display "[poo-flow-test] done ")
  (write files)
  (display " elapsed=")
  (display elapsed)
  (display "s")
  (newline)
  (force-output))

;; : (-> [String] Number Integer Void)
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

;; : (-> [String] Integer)
(def (poo-flow-cli-test-batch files)
  (display "[poo-flow-test] start ")
  (write files)
  (newline)
  (force-output)
  (let (policy-file #f)
    (dynamic-wind
      (lambda ()
        (set! policy-file (poo-flow-cli-write-test-policy-file files)))
      (lambda ()
        (let* ((started-at (time->seconds (current-time)))
               (status (poo-flow-cli-run-inherited
                        (poo-flow-cli-test-argv files policy-file)))
               (elapsed (- (time->seconds (current-time)) started-at)))
          (if (= status 0)
            (poo-flow-cli-display-test-receipt files elapsed)
            (poo-flow-cli-display-test-failure files elapsed status))
          status))
      (lambda ()
        (poo-flow-cli-delete-file-if-exists policy-file)))))

;; : (-> [String] Integer Integer)
(def (poo-flow-cli-batch-width files batch-size)
  (min batch-size (length files)))

;; : (-> [String] Integer [String])
(def (poo-flow-cli-batch-head files batch-size)
  (take files (poo-flow-cli-batch-width files batch-size)))

;; : (-> [String] Integer [String])
(def (poo-flow-cli-batch-tail files batch-size)
  (drop files (poo-flow-cli-batch-width files batch-size)))

;; : (-> [String] Integer [[String]])
(def (poo-flow-cli-test-batches files batch-size)
  (unfold null?
          (lambda (rest) (poo-flow-cli-batch-head rest batch-size))
          (lambda (rest) (poo-flow-cli-batch-tail rest batch-size))
          files))

;;; Intent: execute prevalidated test batches in order and keep first failure.
;;; Boundary: batch construction is pure; process execution stays in test-batch.
;; : (-> [String] Integer)
(def (poo-flow-cli-test-files files)
  (let (validation-status (poo-flow-cli-validate-test-files files))
    (if (= validation-status 0)
      (fold (lambda (batch status)
              (if (= status 0)
                (poo-flow-cli-test-batch batch)
                status))
            0
            (poo-flow-cli-test-batches
             files
             (poo-flow-cli-test-batch-size)))
      validation-status)))

;; : (-> [String] Integer)
(def (poo-flow-cli-test args)
  (poo-flow-cli-test-files (poo-flow-cli-expand-test-args args)))

;; : (-> Unit [String])
(def (poo-flow-cli-perf-rss-time-argv)
  (cond-expand
   (darwin (list "/usr/bin/time" "-l"))
   (else (list "/usr/bin/time" "-v"))))

;; : (-> [String] String [String])
(def (poo-flow-cli-perf-rss-argv files policy-file)
  (append (poo-flow-cli-perf-rss-time-argv)
          (poo-flow-cli-test-argv files policy-file)))

;; : (-> Integer Integer Number Void)
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

;; : (-> String Integer)
(def (poo-flow-cli-reject-rss-parse! output)
  (poo-flow-cli-error "poo-flow perf rss: could not parse maximum resident set size")
  (poo-flow-cli-error "expected: time output with `maximum resident set size`")
  66)

;; : (-> Integer Integer Integer)
(def (poo-flow-cli-reject-rss-threshold! rss-bytes max-bytes)
  (poo-flow-cli-error "poo-flow perf rss: memory threshold exceeded")
  (poo-flow-cli-error (string-append "rss-bytes: " (object->string rss-bytes)))
  (poo-flow-cli-error (string-append "max-bytes: " (object->string max-bytes)))
  75)

;; : (-> Integer Integer Number Integer)
(def (poo-flow-cli-accept-or-reject-rss-threshold! rss-bytes max-bytes elapsed)
  (poo-flow-cli-display-rss-receipt rss-bytes max-bytes elapsed)
  (if (> rss-bytes max-bytes)
    (poo-flow-cli-reject-rss-threshold! rss-bytes max-bytes)
    0))

;; : (-> Integer Number String Integer)
(def (poo-flow-cli-perf-rss-parse-output max-megabytes elapsed output)
  (let ((rss-bytes (poo-flow-cli-max-rss-bytes output))
        (max-bytes (poo-flow-cli-megabytes->bytes max-megabytes)))
    (if rss-bytes
      (poo-flow-cli-accept-or-reject-rss-threshold!
       rss-bytes
       max-bytes
       elapsed)
      (poo-flow-cli-reject-rss-parse! output))))

;; : (-> Integer [String] Integer)
(def (poo-flow-cli-perf-rss-measured-files max-megabytes files)
  (let (policy-file #f)
    (dynamic-wind
      (lambda ()
        (set! policy-file (poo-flow-cli-write-test-policy-file files)))
      (lambda ()
        (let* ((started-at (time->seconds (current-time)))
               (result (poo-flow-cli-run-captured
                        (poo-flow-cli-perf-rss-argv files policy-file)))
               (elapsed (- (time->seconds (current-time)) started-at))
               (status (car result))
               (output (cdr result)))
          (display output)
          (force-output)
          (if (= status 0)
            (poo-flow-cli-perf-rss-parse-output max-megabytes elapsed output)
            status)))
      (lambda ()
        (poo-flow-cli-delete-file-if-exists policy-file)))))

;; : (-> Integer [String] Integer)
(def (poo-flow-cli-perf-rss-validated-files max-megabytes files)
  (let (validation-status (poo-flow-cli-validate-test-files files))
    (if (= validation-status 0)
      (poo-flow-cli-perf-rss-measured-files max-megabytes files)
      validation-status)))

;; : (-> Integer [String] Integer)
(def (poo-flow-cli-perf-rss-files max-megabytes files)
  (if (file-exists? "/usr/bin/time")
    (poo-flow-cli-perf-rss-validated-files max-megabytes files)
    (begin
      (poo-flow-cli-error "poo-flow perf rss: /usr/bin/time is required for RSS gates")
      69)))

;; : (-> [String] Integer)
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

;; : (-> [String] Integer)
(def (poo-flow-cli-perf args)
  (match args
    (["rss" . rest] (poo-flow-cli-perf-rss rest))
    (_
     (poo-flow-cli-error "poo-flow perf: usage is `poo-flow perf rss --max-mb <megabytes> [test-file.ss...]`")
     64)))
