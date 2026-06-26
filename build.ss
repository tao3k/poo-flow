#!/usr/bin/env gxi

;;; -*- Gerbil -*-
;;; Package build implementation for the POO Flow Gerbil runtime.
;;;
;;; This file intentionally owns the heavy clan/std/make package graph and is
;;; not a single-module fast gate.
;;;
;;; Source discovery follows clan/building. gxpkg owns package builds; focused
;;; perf gates should call direct gxc or the compiled build runner instead.

(import :clan/building
        (only-in :gslph/src/build-api/package-receipt
                 gslph-package-build-receipt-status
                 gslph-package-build-receipt-status-ref
                 gslph-package-build-receipt-write)
        (only-in :gslph/src/build-api/source-coverage
                 gslph-source-coverage)
        (only-in :gerbil/gambit
                 current-directory
                 file-exists?
                 getenv
                 path-expand
                 pretty-print
                 string=?
                 string-append
                 ##cpu-count)
        (only-in :gerbil/compiler/base
                 __available-cores)
        (only-in :std/make
                 make
                 make-clean))

;; : (-> String)
(def (nono-c-binding-include-option)
  (string-append "-I" (path-expand "bindings/nono-c")))

;; : (Listof String)
(def +poo-flow-runtime-include-dirs+
  '("src"))

;; : (Listof String)
(def +poo-flow-test-include-dirs+
  '("t"))

;; : (Listof String)
(def +poo-flow-test-exclude-dirs+
  '("fixtures" "scenarios"))

;; Fixture wrappers stay out of broad test discovery, but integration tests may
;; declare specific source fixtures that need package-local import artifacts.
(def +poo-flow-test-fixture-source-files+
  '("t/fixtures/object-load-valid/objects.ss"))

;; : (Listof String)
(def +poo-flow-test-root-files+
  '("t/unit-tests.ss"
    "t/contract-tests.ss"
    "t/integration-tests.ss"
    "t/performance-tests.ss"))

;; : (Listof String)
(def +poo-flow-special-source-files+
  '("src/modules/nono-sandbox/_nono.ss"
    "src/cli.ss"
    "main.ss"
    "manifest.ss"))

(gslph-source-coverage
 roots: '("src" "user-interface")
 runtime-roots: +poo-flow-runtime-include-dirs+
 explanation: "POO Flow runtime owners live under src; user-interface modules are declarative package sources that still need policy coverage.")

;; : BuildSpec
(def +poo-flow-ffi-build-spec+
  `((gsc: "src/modules/nono-sandbox/_nono"
          "-cc-options" ,(nono-c-binding-include-option))
    (ssi: "src/modules/nono-sandbox/_nono")))

;; : BuildSpec
(def +poo-flow-cli-library-build-spec+
  '((gxc: "src/cli.ss")))

;; : BuildSpec
(def +poo-flow-cli-entry-module-build-spec+
  '((gxc: "user-interface/init")
    (gxc: "user-interface/custom/my-module/config")))

;; : BuildSpec
(def (poo-flow-static-executable-supported?)
  (cond-expand
   (darwin #f)
   (else #t)))

;; : (List -> Symbol)
(def (poo-flow-cli-entry-exe-spec-type options)
  (let ((release? (poo-flow-release-build-options? options))
        (optimized? (poo-flow-optimized-build-options? options))
        (static? (poo-flow-static-executable-supported?)))
    (cond
     ((and release? optimized? static?) 'optimized-static-exe:)
     ((and release? static?) 'static-exe:)
     (optimized? 'optimized-exe:)
     (else 'exe:))))

;; : (List -> BuildSpec)
(def (poo-flow-cli-entry-build-spec options)
  (append +poo-flow-cli-entry-module-build-spec+
          (list (list (poo-flow-cli-entry-exe-spec-type options)
                      "src/cli"
                      bin:
                      "poo-flow"))))

;; : (List -> BuildSpec)
(def (poo-flow-entry-build-spec options)
  (poo-flow-cli-entry-build-spec options))

;; : (String -> Bool)
;; : (forall (a) (-> String (-> a) a))
(def (poo-flow-with-directory directory thunk)
  (let (previous (current-directory))
    (dynamic-wind
      (lambda () (current-directory directory))
      thunk
      (lambda () (current-directory previous)))))

;; : (String -> Bool)
(def (poo-flow-root-module-path? path)
  (let loop ((index 0))
    (cond
     ((= index (string-length path)) #t)
     ((char=? (string-ref path index) #\/) #f)
     (else (loop (+ index 1))))))

;; : (String (Listof String) Bool -> (Listof String))
(def (poo-flow-module-files dir exclude-dirs root-only?)
  (poo-flow-with-directory dir
    (lambda ()
      (let (modules (all-gerbil-modules exclude-dirs: exclude-dirs))
        (map (lambda (path) (string-append dir "/" path))
             (if root-only?
               (filter poo-flow-root-module-path? modules)
               modules))))))

;; : ((Listof String) (Listof String) Bool -> (Listof String))
(def (poo-flow-package-modules dirs exclude-dirs root-only?)
  (apply append
         (map (lambda (dir)
                (poo-flow-module-files dir exclude-dirs root-only?))
              dirs)))

;; : (-> [String])
(def (poo-flow-runtime-modules)
  (filter (lambda (file)
            (not (member file +poo-flow-special-source-files+)))
          (poo-flow-package-modules +poo-flow-runtime-include-dirs+ '() #f)))

;; : (-> [String])
(def (poo-flow-all-test-modules)
  (append
   (poo-flow-package-modules
    +poo-flow-test-include-dirs+
    +poo-flow-test-exclude-dirs+
    #f)
   +poo-flow-test-fixture-source-files+))

;; : (List -> [String])
(def (poo-flow-test-modules options)
  (if (poo-flow-all-test-build-options? options)
    (poo-flow-all-test-modules)
    +poo-flow-test-root-files+))

;; : (String List -> BuildSpec)
(def (poo-flow-gxc-target file options)
  [gxc: file])

;; : ([String] List -> BuildSpec)
(def (poo-flow-gxc-spec files options)
  (map (lambda (file) (poo-flow-gxc-target file options)) files))

;; : (List -> BuildSpec)
(def (poo-flow-runtime-build-spec options)
  (poo-flow-gxc-spec (poo-flow-runtime-modules) options))

;; : (List -> BuildSpec)
(def (poo-flow-test-build-spec options)
  (poo-flow-gxc-spec (poo-flow-test-modules options) options))

;; : (List -> BuildSpec)
(def (poo-flow-package-build-spec options)
  (if (poo-flow-native-build-options? options)
    (append +poo-flow-ffi-build-spec+
            (poo-flow-runtime-build-spec options)
            (poo-flow-entry-build-spec options))
    (append (poo-flow-runtime-build-spec options)
            +poo-flow-cli-library-build-spec+)))

;; : (List -> BuildSpec)
(def (poo-flow-package-and-test-spec options)
  (append (poo-flow-package-build-spec options)
          (poo-flow-test-build-spec options)))

;; : (-> BuildSpec)
(def (spec)
  (poo-flow-package-and-test-spec []))

;; : (-> String)
(def (poo-flow-package-srcdir)
  (path-expand "."))

;; : (-> Void)
(def (poo-flow-package-require-gxpkg-env!)
  (unless (getenv "GERBIL_PATH" #f)
    (error "poo-flow package builds require gxpkg env; run gxpkg env ./build.ss compile --tests")))

;; : (-> String (OrFalse Fixnum))
(def (poo-flow-package-cores-from-env name)
  (let (value (getenv name #f))
    (and value
         (let (cores (string->number value))
           (and (integer? cores)
                (> cores 0)
                cores)))))

;; : (-> Fixnum)
(def (poo-flow-package-worker-count)
  (or (poo-flow-package-cores-from-env "GERBIL_BUILD_CORES")
      (max 1 (##cpu-count))))

;; : (-> Fixnum)
(def (poo-flow-package-parallelize)
  (let (worker-count (poo-flow-package-worker-count))
    (set! __available-cores worker-count)
    worker-count))

;; : (List -> List)
(def (poo-flow-make-options options)
  (match options
    ([build-tests: _ . rest]
     (poo-flow-make-options rest))
    ([build-all-tests: _ . rest]
     (poo-flow-make-options rest))
    ([force: _ . rest]
     (poo-flow-make-options rest))
    ([key value . rest]
     (cons key
           (cons value
                 (poo-flow-make-options rest))))
    ([] [])))

;; : (-> List List)
(def (poo-flow-package-options options)
  (let (parallelize (poo-flow-package-parallelize))
    (if parallelize
      (append (poo-flow-make-options options) [parallelize: parallelize])
      (poo-flow-make-options options))))

;; : (String String BuildSpec -> Void)
(def (poo-flow-package-message action label stage)
  (display "... poo-flow ")
  (display action)
  (display " ")
  (display label)
  (display " targets=")
  (display (length stage))
  (let (parallelize (poo-flow-package-parallelize))
    (when parallelize
      (display " parallelize=")
      (display parallelize)))
  (newline)
  (force-output))

;; : ((a -> Bool) [a] -> Bool)
(def (poo-flow-all? pred xs)
  (match xs
    ([] #t)
    ([x . rest]
     (and (pred x) (poo-flow-all? pred rest)))))

;; : ((a -> Bool) [a] -> Bool)
(def (poo-flow-any? pred xs)
  (match xs
    ([] #f)
    ([x . rest]
     (or (pred x) (poo-flow-any? pred rest)))))

;; : (-> String)
(def (poo-flow-package-libdir)
  (path-expand "lib" (getenv "GERBIL_PATH")))

;; : (-> String)
(def (poo-flow-package-libdir-prefix)
  (path-expand "poo-flow" (poo-flow-package-libdir)))

;; : (List -> String)
(def (poo-flow-stage-cache-stamp-path options)
  (path-expand
   (cond
    ((poo-flow-all-test-build-options? options) ".compile-package-all-tests.stamp")
    ((poo-flow-test-build-options? options) ".compile-package-tests.stamp")
    (else ".compile-package.stamp"))
   (poo-flow-package-libdir-prefix)))

;; : (BuildSpec -> String)
(def (poo-flow-diagnostic-source-path spec)
  (match spec
    ([gxc: file . _] (path-expand file (poo-flow-package-srcdir)))
    (_ #f)))

;; : (BuildSpec -> [String])
(def (poo-flow-stage-source-files stage)
  (let lp ((rest stage) (sources []))
    (match rest
      ([] (append (reverse sources)
                  (map (lambda (file)
                         (path-expand file (poo-flow-package-srcdir)))
                       '("build.ss" "gerbil.pkg"))))
      ([spec . rest]
       (let (source (poo-flow-diagnostic-source-path spec))
         (if source
           (lp rest (cons source sources))
           (lp rest sources)))))))

;; : (BuildSpec -> Bool)
(def (poo-flow-diagnostic-gxc-spec? spec)
  (match spec
    ([gxc: . _] #t)
    (_ #f)))

;; : (BuildSpec -> [String])
(def (poo-flow-diagnostic-outputs spec)
  (match spec
    ([gxc: file . _] (poo-flow-diagnostic-gxc-outputs file))
    (_ [])))

;; : (BuildSpec -> [String])
(def (poo-flow-diagnostic-missing-outputs spec)
  (filter (lambda (output) (not (file-exists? output)))
          (poo-flow-diagnostic-outputs spec)))

;; : (BuildSpec -> Bool)
(def (poo-flow-diagnostic-output-clean? spec)
  (null? (poo-flow-diagnostic-missing-outputs spec)))

;; : (BuildSpec List -> Bool)
(def (poo-flow-stage-cacheable? stage options)
  (and (not (poo-flow-native-build-options? options))
       (poo-flow-all? poo-flow-diagnostic-gxc-spec? stage)))

;; : (BuildSpec List -> Bool)
(def (poo-flow-stage-cache-valid? stage options)
  (let* ((stamp (poo-flow-stage-cache-stamp-path options))
         (sources (poo-flow-stage-source-files stage))
         (outputs (apply append (map poo-flow-diagnostic-outputs stage)))
         (status (gslph-package-build-receipt-status
                  stamp
                  expected-sources: sources
                  expected-outputs: outputs)))
    (and (not (poo-flow-force-build-options? options))
         (poo-flow-stage-cacheable? stage options)
         (eq? (gslph-package-build-receipt-status-ref status 'status 'stale)
              'current))))

;; : (BuildSpec List -> Void)
(def (poo-flow-stage-cache-touch! stage options)
  (when (poo-flow-stage-cacheable? stage options)
    (gslph-package-build-receipt-write
     (poo-flow-stage-cache-stamp-path options)
     (poo-flow-stage-source-files stage)
     (apply append (map poo-flow-diagnostic-outputs stage)))))

;; : (String BuildSpec List -> Void)
(def (poo-flow-make label stage options)
  (poo-flow-package-require-gxpkg-env!)
  (if (poo-flow-stage-cache-valid? stage options)
    (begin
      (poo-flow-package-message "skip" label stage)
      (display "|note kind=build-cache message=\"package-local gxc direct outputs are current; skipped std/make no-op rebuild\"")
      (newline))
    (begin
      (poo-flow-package-message "compile" label stage)
      (apply make stage
             srcdir: (poo-flow-package-srcdir)
             (poo-flow-package-options options))
      (poo-flow-stage-cache-touch! stage options))))

;; : (String BuildSpec -> Void)
(def (poo-flow-make-clean label stage)
  (poo-flow-package-require-gxpkg-env!)
  (poo-flow-package-message "clean" label stage)
  (apply make-clean stage
         srcdir: (poo-flow-package-srcdir)
         (poo-flow-package-options [])))

;; : (String -> [String])
(def (poo-flow-diagnostic-gxc-outputs file)
  [(path-expand (string-append file "i")
                (poo-flow-package-libdir-prefix))])

;; : (BuildSpec -> String)
(def (poo-flow-diagnostic-label spec)
  (match spec
    ([gxc: file . _] file)
    ([gsc: file . _] file)
    ([ssi: file . _] file)
    ([(or exe: static-exe: optimized-exe: optimized-static-exe:) file . _] file)
    (_ "unsupported")))

;; : (BuildSpec [String] -> Void)
(def (poo-flow-diagnostic-display-missing spec missing)
  (display "|stale reason=missing-output spec=")
  (write (poo-flow-diagnostic-label spec))
  (display " missing=")
  (write missing)
  (newline))

;; : (List -> Void)
(def (poo-flow-diagnose-build-spec options)
  (poo-flow-package-require-gxpkg-env!)
  (let ((stage (poo-flow-compile-build-spec options))
        (gxc-count 0)
        (missing-count 0)
        (clean-count 0)
        (unsupported-count 0))
    (for-each
     (lambda (spec)
       (cond
        ((poo-flow-diagnostic-gxc-spec? spec)
         (set! gxc-count (+ gxc-count 1))
         (let (missing (poo-flow-diagnostic-missing-outputs spec))
           (if (null? missing)
             (set! clean-count (+ clean-count 1))
             (begin
               (set! missing-count (+ missing-count 1))
               (poo-flow-diagnostic-display-missing spec missing)))))
        (else
         (set! unsupported-count (+ unsupported-count 1)))))
     stage)
    (display "[poo-flow-build-diagnose]")
    (display " targets=")
    (display (length stage))
    (display " gxc=")
    (display gxc-count)
    (display " directOutputClean=")
    (display clean-count)
    (display " missingOutput=")
    (display missing-count)
    (display " unsupported=")
    (display unsupported-count)
    (newline)
    (when (and (= missing-count 0) (> gxc-count 0))
      (display "|note kind=inference message=\"direct gxc .ssi outputs exist; repeated rebuilds point to dependency timestamp/import freshness rather than missing direct outputs\"")
      (newline))))

;; : (List -> List)
(def (poo-flow-package-parse-options opts)
  (let lp ((rest opts) (options []))
    (match rest
      ([] options)
      (["--release" . rest]
       (lp rest [build-release: #t . options]))
      (["--optimized" . rest]
       (lp rest [build-optimized: #t . options]))
      (["--debug" . rest]
       (lp rest [debug: #t . options]))
      (["--tests" . rest]
       (lp rest [build-tests: #t . options]))
      (["--all-tests" . rest]
       (lp rest [build-all-tests: #t build-tests: #t . options]))
      (["--force" . rest]
       (lp rest [force: #t . options]))
      (["--verbose" . rest]
       (lp rest [verbose: 9 . options]))
      (["-V" . rest]
       (lp rest [verbose: 9 . options]))
      (else
       (error "Unexpected build option" rest)))))

;; : (List -> Bool)
(def (poo-flow-release-build-options? options)
  (match options
    ([build-release: value . _] value)
    ([_ _ . rest] (poo-flow-release-build-options? rest))
    ([] #f)))

;; : (List -> Bool)
(def (poo-flow-optimized-build-options? options)
  (match options
    ([build-optimized: value . _] value)
    ([_ _ . rest] (poo-flow-optimized-build-options? rest))
    ([] #f)))

;; : (List -> Bool)
(def (poo-flow-debug-build-options? options)
  (match options
    ([debug: value . _] value)
    ([_ _ . rest] (poo-flow-debug-build-options? rest))
    ([] #f)))

;; : (List -> Bool)
(def (poo-flow-test-build-options? options)
  (match options
    ([build-tests: value . _] value)
    ([_ _ . rest] (poo-flow-test-build-options? rest))
    ([] #f)))

;; : (List -> Bool)
(def (poo-flow-all-test-build-options? options)
  (match options
    ([build-all-tests: value . _] value)
    ([_ _ . rest] (poo-flow-all-test-build-options? rest))
    ([] #f)))

;; : (List -> Bool)
(def (poo-flow-force-build-options? options)
  (match options
    ([force: value . _] value)
    ([_ _ . rest] (poo-flow-force-build-options? rest))
    ([] #f)))

;; : (List -> Bool)
(def (poo-flow-native-build-options? options)
  (or (poo-flow-release-build-options? options)
      (poo-flow-optimized-build-options? options)
      (poo-flow-debug-build-options? options)))

;; : (List -> BuildSpec)
(def (poo-flow-compile-build-spec options)
  (if (poo-flow-release-build-options? options)
    (poo-flow-package-build-spec options)
    (if (poo-flow-test-build-options? options)
      (poo-flow-package-and-test-spec options)
      (poo-flow-package-build-spec options))))

;; : (List -> Void)
(def (poo-flow-package-compile options)
  (poo-flow-make "package" (poo-flow-compile-build-spec options) options))

;; : (-> Void)
(def (poo-flow-clean)
  (poo-flow-make-clean "package" (poo-flow-package-and-test-spec [])))

(def (main . args)
  (match args
    (["meta"] (write '("spec" "compile" "diagnose" "clean")) (newline))
    (["spec" . options]
     (pretty-print (poo-flow-compile-build-spec
                    (poo-flow-package-parse-options options))))
    (["diagnose" . options]
     (poo-flow-diagnose-build-spec (poo-flow-package-parse-options options)))
    (["compile" . options] (poo-flow-package-compile (poo-flow-package-parse-options options)))
    (["clean"] (poo-flow-clean))
    ([] (poo-flow-package-compile []))))
