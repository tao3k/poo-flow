;;; -*- Gerbil -*-
;;; Fresh interpreted plus AOT qualification with fixture-attributed receipts.
(import :gerbil/gambit
        (only-in :gerbil/runtime gerbil-system-version-string)
        (only-in :clan/poo/object .o .ref)
        (only-in :std/crypto/digest sha256)
        (only-in :std/text/hex hex-encode)
        (only-in :std/misc/uuid random-uuid uuid->string)
        (only-in :std/misc/process run-process)
        (only-in :std/sort sort)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        (only-in :asp-gerbil-scheme/build-api
                 asp-gerbil-scheme-source-dependency-order
                 call-with-framework-native-build-memory-anomaly-guard)
        (only-in "clause-ledger.ss" poo-clos-open-required-ansi-rows))
(export main poo-clos-qualification-input poo-clos-qualify!)

(def poo-clos-qualification-input
  (.o kind: 'poo-clos/qualification-input
      schema: 'v1
      evidence-directory: ".data/qualification/poo-clos"
      component-entries:
      '("src/module-system/poo-clos/interface.ss"
        "t/qualification/poo-clos/interface.ss")))

(def qualification-checkers
  '("t/qualification/poo-clos/qualify.ss"
    "t/qualification/poo-clos/interpreted-run.ss"
    "t/qualification/poo-clos/run.ss"
    "t/qualification/poo-clos/README.org"
    "docs/10-19-design/10.06-poo-module-system/159-poo-native-clos-architecture.org"
    "src/module-system/observability/README.org"
    "docs/10-19-design/10.06-poo-module-system/158-poo-lazy-slot-resolution-observability.org"))
(def fixtures
  '(method-combination-compatibility
    generic-dispatch
    class-and-instance-lifecycle
    declaration-surface
    method-combination
    evolution-reflection-and-load-form
    ansi-clause-ledger))

(def (fingerprint path-value)
  (let (digest-value
        (call-with-input-file path-value (lambda (port) (hex-encode (sha256 port)))))
    (.o path: path-value algorithm: 'sha256 purpose: 'content-integrity
        sha256: digest-value)))
(def (fingerprint-projection value)
  (map (lambda (key) (list key (.ref value key))) '(path algorithm purpose sha256)))
(def (snapshot paths) (map fingerprint paths))
(def (unchanged! values)
  (for-each
   (lambda (value)
     (unless (equal? (.ref value 'sha256)
                     (.ref (fingerprint (.ref value 'path)) 'sha256))
       (error "POO CLOS qualification input/artifact drift" (.ref value 'path))))
   values))
(def (write-data path value)
  (call-with-output-file path (lambda (port) (write value port) (newline port))))
(def (artifact-files directory)
  (apply append
    (map (lambda (name)
           (let (path (path-expand name directory))
             (cond ((eq? (file-info-type (file-info path)) 'directory)
                    (artifact-files path))
                   ((string-suffix? ".o1" name) (list path))
                   (else '()))))
         (directory-files directory))))
(def (resolve-program name)
  (let loop ((directories (string-split (getenv "PATH") #\:)))
    (when (null? directories) (error "Required qualification executable missing" name))
    (let (path (path-expand name (car directories)))
      (if (and (file-exists? path)
               (positive? (bitwise-and #o111 (file-info-mode (file-info path)))))
        path
        (loop (cdr directories))))))
(def (resolve-first-program names)
  (when (null? names) (error "Required qualification guard executable missing"))
  (with-exception-catcher
   (lambda (_failure) (resolve-first-program (cdr names)))
   (lambda () (resolve-program (car names)))))
(def (guarded-argv timeout-program time-program timeout-seconds argv)
  ;; POSIX output is sufficient for elapsed/user/system attribution.  Darwin's
  ;; extended -l mode performs sysctl reads that can be denied in a sandbox and
  ;; then changes an otherwise successful child's exit status.
  (append
   (list timeout-program "--signal=TERM" "--kill-after=5s"
         (number->string timeout-seconds) time-program "-p")
   argv))
(def (child-environment compiler additions)
  ;; Homebrew Gerbil must not inherit the Nix SDK/toolchain selection used by
  ;; the outer devenv process.  This is scoped to qualification children.
  (def native-darwin?
    (and (cond-expand (darwin #t) (else #f))
         (or (string-prefix? "/opt/homebrew/" compiler)
             (string-prefix? "/usr/local/" compiler))))
  (append (map (lambda (pair) (string-append (car pair) "=" (cdr pair))) additions)
          (map (lambda (pair) (string-append (car pair) "=" (cdr pair)))
               (filter (lambda (pair)
                         (and (not (assoc (car pair) additions))
                              (not (and native-darwin?
                                        (memq (string->symbol (car pair))
                                              '(SDKROOT DEVELOPER_DIR CC CXX))))))
                       (get-environment-variables)))))
(def (successful-check-count line)
  (let (count (and (string-prefix? "... " line)
                   (string-suffix? " checks OK" line)
                   (string->number
                    (substring line 4 (- (string-length line) 10)))))
    (if (and count (exact-integer? count) (> count 0)) count 0)))
(def (increment-count counts key amount)
  (map (lambda (entry)
         (if (eq? (car entry) key)
           (cons key (+ (cdr entry) amount))
           entry))
       counts))
(def (stream-process-log process log)
  (let loop ((current #f) (total 0)
             (counts (map (lambda (name) (cons name 0)) fixtures)))
    (let (line (read-line process))
      (cond
       ((eof-object? line)
        (when current (error "Unclosed fixture marker" current))
        (cons total counts))
       (else
        (display line log) (newline log) (force-output log)
        (displayln line) (force-output)
        (cond
         ((string-prefix? "POO_CLOS_FIXTURE_BEGIN " line)
          (when current (error "Nested fixture marker" current line))
          (let (name (string->symbol (substring line 23 (string-length line))))
            (unless (memq name fixtures) (error "Unknown fixture marker" name))
            (loop name total counts)))
         ((string-prefix? "POO_CLOS_FIXTURE_END " line)
          (let (name (string->symbol (substring line 21 (string-length line))))
            (unless (eq? name current) (error "Mismatched fixture marker" current name))
            (loop #f total counts)))
         (else
          (let (amount (successful-check-count line))
            (loop current (+ total amount)
                  (if current (increment-count counts current amount) counts))))))))))
(def (execute! phase argv environment log-path timeout-program time-program
               timeout-seconds)
  (let ((status 0)
        (observed-argv
         (guarded-argv timeout-program time-program timeout-seconds argv)))
    (let (result
      (call-with-output-file log-path
       (lambda (log)
        (write (list 'process-begin
                     (list 'phase phase)
                     (list 'timeout-seconds timeout-seconds)
                     (cons 'argv argv)
                     (cons 'guarded-argv observed-argv)) log)
      (newline log)
      (force-output log)
      (let (process-result
            (parameterize ((current-error-port log))
              (call-with-framework-native-build-memory-anomaly-guard
               phase
               (lambda ()
                 (run-process observed-argv
                   environment: environment stdin-redirection: #f
                   stderr-redirection: #t
                   check-status:
                   (lambda (exit-status _settings)
                     (set! status exit-status))
                   coprocess:
                   (lambda (process) (stream-process-log process log))))
               #t phase)))
        (write (list 'process-exit (list 'status status)) log)
        (newline log)
        (force-output log)
        process-result))))
      (unless (zero? status)
        (error "POO CLOS qualification subprocess failed"
               phase status argv log-path))
      result)))
(def (require-counts! result label)
  (unless (> (car result) 0) (error "Zero assertions are not qualification" label))
  (for-each (lambda (entry)
              (unless (> (cdr entry) 0)
                (error "Fixture has zero attributable assertions" label (car entry))))
            (cdr result)))
(def (write-module-manifest! manifest library artifacts)
  (call-with-output-file manifest
    (lambda (port)
      (for-each
       (lambda (value)
         (let (path (.ref value 'path))
           (unless (and (string-prefix? (string-append library "/") path)
                        (string-suffix? ".o1" path))
             (error "Artifact outside POO CLOS qualification library" path))
           (display (substring path (+ 1 (string-length library))
                               (- (string-length path) 3)) port)
           (newline port)))
       artifacts))))

(def (poo-clos-qualify! (input poo-clos-qualification-input))
  (let (open (poo-clos-open-required-ansi-rows))
    (unless (null? open)
      (error "ANSI CLOS qualification is fail-closed: required dictionary operators remain open"
             (map (lambda (row) (.ref row 'id)) open))))
  (let* ((root (path-normalize (current-directory)))
         (evidence (path-expand (.ref input 'evidence-directory) root))
         (run (path-expand (string-append "run." (uuid->string (random-uuid))) evidence))
         (library (path-expand "lib" run))
         (compiler (resolve-program "gxc"))
         (interpreter (resolve-program "gxi"))
         (timeout-program (resolve-first-program '("gtimeout" "timeout")))
         (time-program (resolve-program "time"))
         (installed-library (path-expand ".gerbil/lib" root))
         (base-loadpath
          (string-append installed-library ":" (getenv "GERBIL_LOADPATH" "")))
         (modules
          (asp-gerbil-scheme-source-dependency-order
           root (.ref input 'component-entries)))
         (sources (snapshot (append modules qualification-checkers)))
         (plain-environment
          (child-environment compiler (list (cons "GERBIL_LOADPATH" base-loadpath))))
         (aot-environment
          (child-environment compiler
           (list (cons "GERBIL_LOADPATH"
                       (string-append library ":" base-loadpath))
                 (cons "POO_CLOS_AOT_LIB" library)
                 (cons "POO_CLOS_AOT_MODULES" (path-expand "modules.txt" run))
                 (cons "POO_CLOS_AOT_DEPENDENCIES"
                       (path-expand "dependencies.sexp" run))))))
    (unless (file-exists? "gerbil.pkg")
      (error "Run POO CLOS qualification from the project root"))
    (create-directory* evidence)
    (create-directory run)
    (create-directory library)
    (displayln "POO CLOS qualification output: " run) (force-output)
    (write-data (path-expand "sources.sexp" run)
                (map fingerprint-projection sources))
    (write-data (path-expand "toolchain.sexp" run)
                (list 'toolchain (gerbil-system-version-string)
                      'compiler compiler
                      'interpreter interpreter
                      'timeout-program timeout-program
                      'time-program time-program
                      'time-output 'posix
                      'flags '("-O")
                      'interpreter-max-heap "1G"
                      'compiler-max-heap "4G"))
    (let (interpreted
          (execute!
           'interpreted
           (list interpreter "-:max-heap=1G"
                 "t/qualification/poo-clos/interpreted-run.ss")
           plain-environment (path-expand "interpreted.log" run)
           timeout-program time-program 90))
      (require-counts! interpreted 'interpreted)
      (execute!
       'compile
       (append (list compiler "-:max-heap=4G" "-O" "-d" library) modules)
       aot-environment (path-expand "compile.log" run)
       timeout-program time-program 900)
      (for-each
       (lambda (source)
         (for-each
          (lambda (extension)
            (let (artifact
                  (path-expand
                   (string-append "poo-flow/" (path-strip-extension source) extension)
                   library))
              (unless (and (file-exists? artifact)
                           (> (file-info-size (file-info artifact)) 0))
                (error "Missing/empty requested POO CLOS AOT artifact" artifact))))
          '(".ssi" ".o1")))
       modules)
      (unchanged! sources)
      (let* ((artifacts (snapshot (sort (artifact-files library) string<?)))
             (manifest (path-expand "modules.txt" run)))
        (when (null? artifacts) (error "Empty POO CLOS AOT compilation"))
        (write-data (path-expand "artifacts.sexp" run)
                    (map fingerprint-projection artifacts))
        (write-module-manifest! manifest library artifacts)
        (let (aot
          (execute!
           'aot
           (list interpreter "-:max-heap=1G"
                 "t/qualification/poo-clos/run.ss")
           aot-environment (path-expand "aot.log" run)
           timeout-program time-program 90))
          (require-counts! aot 'aot)
          (unless (equal? (cdr interpreted) (cdr aot))
            (error "Interpreted/AOT fixture assertion mismatch"
                   (cdr interpreted) (cdr aot)))
          (unchanged! sources)
          (unchanged! artifacts)
          (let* ((receipt-path (path-expand "receipt.sexp" run))
                 (evidence-files
                  '("sources.sexp" "artifacts.sexp" "toolchain.sexp"
                    "modules.txt" "dependencies.sexp" "interpreted.log"
                    "compile.log" "aot.log")))
            (write-data
             receipt-path
             (list '(kind poo-clos/qualification-receipt)
                   '(schema v1)
                   '(producer poo-flow/module-system/poo-clos)
                   '(accepted? #t)
                   (list 'evidence-directory run)
                   (list 'source-count (length sources))
                   (list 'artifact-count (length artifacts))
                   (list 'interpreted-assertions (car interpreted))
                   (cons 'interpreted-fixtures (cdr interpreted))
                   (list 'aot-assertions (car aot))
                   (cons 'aot-fixtures (cdr aot))
                   '(open-required-ansi-rows 0)
                   '(performance-claim? #f)
                   (cons 'fingerprints
                         (map fingerprint-projection
                              (snapshot (map (lambda (name) (path-expand name run))
                                             evidence-files))))))
            (displayln "POO CLOS qualification completed: " receipt-path)
            receipt-path))))))

(def (main . args)
  (unless (null? args) (error "POO CLOS qualification takes no arguments" args))
  (poo-clos-qualify!)
  (void))
