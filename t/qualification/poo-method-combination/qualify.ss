;;; -*- Gerbil -*-
;;; Scheme owns qualification: no shell, coreutils, or install/cache mutation.
;;; Compiler and test isolation use native argv-based process execution.
(import :gerbil/gambit
        (only-in :gerbil/runtime gerbil-system-version-string)
        (only-in :clan/poo/object .o .ref)
        (only-in :std/crypto/digest sha256)
        (only-in :std/text/hex hex-encode)
        (only-in :std/misc/uuid random-uuid uuid->string)
        (only-in :std/misc/process run-process)
        (only-in :std/sort sort)
        (only-in :std/srfi/13 string-prefix? string-suffix?))
(export main combination-qualification-input combination-qualify!
        ;; Test-owned primitives; these are not exported by the maintained module.
        fingerprint unchanged! successful-check-count stream-process-log
        write-process-record! write-module-manifest!)

(def combination-qualification-input
  (.o kind: 'poo-combination/qualification-input schema: 'v1
      evidence-directory: ".data/qualification/poo-method-combination"
      modules:
      '("src/module-system/types.ss"
        "src/module-system/interface.ss"
        "src/module-system/object-family/syntax.ss"
        "src/module-system/projection/syntax.ss"
        "src/module-system/loader/source.ss"
        "src/module-system/declaration/flags.ss"
        "src/module-system/declaration/interface.ss"
        "src/module-system/descriptor/interface.ss"
        "src/module-system/observability/module-presentation.ss"
        "src/module-system/observability/module-source-observation.ss"
        "src/module-system/semantic-module/types.ss"
        "src/module-system/semantic-module/objects.ss"
        "src/module-system/observability/types.ss"
        "src/module-system/observability/funcs.ss"
        "src/module-system/observability/objects.ss"
        "src/module-system/observability/source-authoring.ss"
        "src/module-system/observability/interface.ss"
        "src/module-system/observability/slot-debug.ss"
        "src/module-system/observability/debug.ss"
        "src/module-system/poo-method-combination/types.ss"
        "src/module-system/poo-method-combination/objects.ss"
        "src/module-system/poo-method-combination/funcs.ss"
        "src/module-system/poo-method-combination/interface.ss"
        "src/module-system/poo-method-combination/plugins/observation.ss"
        "src/module-system/poo-method-combination/config.ss"
        "t/scenarios/poo-method-combination/observation.ss"
        "t/scenarios/poo-method-combination/performance.ss"
        "t/poo-method-combination-test.ss"
        "t/poo-method-combination-contract-test.ss"
        "t/poo-method-combination-next-test.ss"
        "t/poo-method-combination-observation-test.ss"
        "t/poo-method-combination-performance-test.ss"
        "t/observability-framework-test.ss"
        "t/gerbil-poo-debug-admission-test.ss")))
(def qualification-checkers
  '("t/qualification/poo-method-combination/qualify.ss"
    "t/qualification/poo-method-combination/run.ss"
    "t/qualification/poo-method-combination/artifacts.ss"
    "t/qualification/poo-method-combination/summary.ss"
    "t/qualification/poo-method-combination/preflight.ss"
    "t/qualification/poo-method-combination/io-test.ss"
    "t/qualification/poo-method-combination/summary-test.ss"))
(def (fingerprint path-value)
  ;; Snapshot eagerly: a lazy digest would observe a later version of the file.
  (let (digest-value (call-with-input-file path-value (lambda (port) (hex-encode (sha256 port)))))
    (.o path: path-value algorithm: 'sha256 purpose: 'content-integrity sha256: digest-value)))
(def (fingerprint-projection value)
  (map (lambda (key) (list key (.ref value key))) '(path algorithm purpose sha256)))
(def (snapshot paths) (map fingerprint paths))
(def (unchanged! previous)
  (for-each (lambda (value)
              (unless (equal? (.ref value 'sha256) (.ref (fingerprint (.ref value 'path)) 'sha256))
                (error "Qualification input/artifact drift" (.ref value 'path)))) previous))
(def (write-data path value)
  (call-with-output-file path (lambda (port) (write value port) (newline port))))
(def (artifact-files directory)
  (apply append
    (map (lambda (name)
           (let (path (path-expand name directory))
             (cond ((eq? (file-info-type (file-info path)) 'directory) (artifact-files path))
                   ((string-suffix? ".o1" name) (list path))
                   (else '())))) (directory-files directory))))
(def (child-environment compiler additions)
  ;; Same narrow native-Darwin boundary as devenv.nix, applied to children only.
  (let ((native-darwin?
         (and (cond-expand (darwin #t) (else #f))
              (or (string-prefix? "/opt/homebrew/" compiler)
                  (string-prefix? "/usr/local/" compiler)))))
    (append (map (lambda (pair) (string-append (car pair) "=" (cdr pair))) additions)
      (map (lambda (pair) (string-append (car pair) "=" (cdr pair)))
        (filter (lambda (pair)
                  (and (not (assoc (car pair) additions))
                       (not (and native-darwin?
                                 (member (car pair) '("SDKROOT" "DEVELOPER_DIR" "CC" "CXX"))))))
                (get-environment-variables))))))
(def (resolve-program name)
  ;; GERBIL_HOME is a library root, not necessarily the installed executable
  ;; prefix. Resolve the executable selected by this project's actual PATH.
  (let loop ((directories (string-split (getenv "PATH") #\:)))
    (when (null? directories) (error "Required qualification executable missing" name))
    (let (path (path-expand name (car directories)))
      (if (and (file-exists? path) (eq? (file-info-type (file-info path)) 'regular)
               (positive? (bitwise-and #o111 (file-info-mode (file-info path)))))
        path
        (loop (cdr directories))))))
(def (successful-check-count line)
  ;; std/test v0.18.2 success counts, retained as observed evidence.
  (let (count (and (string-prefix? "... " line) (string-suffix? " checks OK" line)
                  (string->number (substring line 4 (- (string-length line) 10)))))
    (if (and count (exact-integer? count) (> count 0)) count 0)))
(def (stream-process-log process log)
  (let loop ((checks 0))
    (let (line (read-line process))
      (cond
       ((eof-object? line) checks)
       (else
        (display line log) (newline log) (force-output log)
        (displayln line) (force-output)
        (loop (+ checks (successful-check-count line))))))))
(def (write-process-record! log kind fields)
  (write (cons kind fields) log)
  (newline log)
  (force-output log))
(def (execute! argv environment log-path)
  ;; Preserve output while streaming; errors leave a failed log, never success.
  (call-with-output-file log-path
    (lambda (log)
      (write-process-record! log 'process-begin (list (cons 'argv argv)))
      (let (result
            (run-process argv environment: environment stdin-redirection: #f stderr-redirection: #t
              check-status:
              (lambda (status _settings)
                ;; The standard ProcessError includes the entire environment. Keep
                ;; exact status and argv, but never expose the inherited environment.
                (unless (zero? status) (error "Qualification subprocess failed" status argv log-path)))
              coprocess: (lambda (process) (stream-process-log process log))))
        (write-process-record! log 'process-exit '((status . 0)))
        result))))
(def (write-module-manifest! manifest library artifacts)
  (call-with-output-file manifest
    (lambda (port)
      (for-each
       (lambda (value)
         (let (path (.ref value 'path))
           (unless (and (string-prefix? (string-append library "/") path)
                        (string-suffix? ".o1" path))
             (error "Artifact outside qualification library" path))
           (display (substring path (+ 1 (string-length library)) (- (string-length path) 3)) port)
           (newline port))) artifacts))))
(def (combination-qualify! (input combination-qualification-input))
  (let* ((root (path-normalize (current-directory)))
         (evidence (path-expand (.ref input 'evidence-directory) root))
         (run (path-expand (string-append "run." (uuid->string (random-uuid))) evidence))
         (library (path-expand "lib" run))
         (compiler (resolve-program "gxc"))
         (interpreter (resolve-program "gxi"))
         (modules (.ref input 'modules))
         (sources (snapshot (append modules qualification-checkers)))
         (environment
          (child-environment compiler
            (list (cons "GERBIL_LOADPATH" (string-append library ":" (getenv "GERBIL_LOADPATH" "")))
                  (cons "POO_COMBINATION_AOT_LIB" library)
                  (cons "POO_COMBINATION_AOT_MODULES" (path-expand "modules.txt" run))
                  (cons "POO_COMBINATION_AOT_DEPENDENCIES" (path-expand "dependencies.sexp" run))))))
    (unless (file-exists? "gerbil.pkg") (error "Run qualification from the POO Flow project root"))
    (create-directory* evidence)
    (create-directory run) ; collision is a failure, never reuse stale evidence
    (create-directory library)
    (displayln "Scheme qualification output: " run) (force-output)
    (write-data (path-expand "sources.sexp" run) (map fingerprint-projection sources))
    (write-data (path-expand "toolchain.sexp" run)
      (list 'toolchain (gerbil-system-version-string) 'compiler compiler 'flags '("-O")))
    (let (preflight-count-value
           (execute! (list interpreter "t/qualification/poo-method-combination/preflight.ss") environment
                     (path-expand "preflight.log" run)))
    (unless (> preflight-count-value 0) (error "Zero preflight assertions are not qualification"))
    (execute! (append (list compiler "-O" "-d" library) modules) environment (path-expand "compile.log" run))
    (for-each (lambda (source)
                (for-each (lambda (extension)
                            (let (artifact (path-expand
                                            (string-append "poo-flow/" (path-strip-extension source) extension) library))
                              (unless (and (file-exists? artifact) (> (file-info-size (file-info artifact)) 0))
                                (error "Missing/empty requested AOT artifact" artifact)))) '(".ssi" ".o1"))) modules)
    (unchanged! sources)
    (let* ((artifacts (snapshot (sort (artifact-files library) string<?)))
           (manifest (path-expand "modules.txt" run)))
      (when (null? artifacts) (error "Empty AOT compilation"))
      (write-data (path-expand "artifacts.sexp" run) (map fingerprint-projection artifacts))
      (write-module-manifest! manifest library artifacts)
      (let (assertion-count-value
             (execute! (list interpreter "t/qualification/poo-method-combination/run.ss") environment
                       (path-expand "qualification.sexp" run)))
      (unless (> assertion-count-value 0) (error "Zero assertions are not qualification"))
      (unchanged! sources)
      (unchanged! artifacts)
      (let* ((receipt
              (.o kind: 'poo-combination/qualification-receipt schema: 'v1 producer: 'poo-flow/module-system/poo-method-combination
                  accepted?: #t evidence-directory: run source-count: (length sources)
                  artifact-count: (length artifacts) same-process-tests?: #t
                  assertions: assertion-count-value
                  preflight-assertions: preflight-count-value
                  fingerprints: (snapshot (map (lambda (name) (path-expand name run))
                                              '("sources.sexp" "artifacts.sexp" "toolchain.sexp" "modules.txt"
                                                "dependencies.sexp" "preflight.log" "qualification.sexp")))))
             (path (path-expand "receipt.sexp" run)))
        (write-data path
          (append (map (lambda (key) (list key (.ref receipt key)))
                       '(kind schema producer accepted? evidence-directory source-count artifact-count same-process-tests? assertions preflight-assertions))
                  (list (cons 'fingerprints (map fingerprint-projection (.ref receipt 'fingerprints))))))
        (displayln "Qualification completed: " path)
        receipt))))))
(def (main . args)
  (unless (null? args) (error "Qualification takes no positional arguments" args))
  (combination-qualify!)
  (void))
