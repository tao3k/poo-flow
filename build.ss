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
        (only-in :gslph/src/build-api/source-coverage
                 gslph-source-coverage)
        (only-in :gerbil/gambit
                 current-directory
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
  (poo-flow-package-modules
   +poo-flow-test-include-dirs+
   +poo-flow-test-exclude-dirs+
   #f))

;; : (List -> [String])
(def (poo-flow-test-modules options)
  (poo-flow-all-test-modules))

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

;; : (String BuildSpec List -> Void)
(def (poo-flow-make label stage options)
  (poo-flow-package-message "compile" label stage)
  (apply make stage
         srcdir: (poo-flow-package-srcdir)
         (poo-flow-package-options options)))

;; : (String BuildSpec -> Void)
(def (poo-flow-make-clean label stage)
  (poo-flow-package-message "clean" label stage)
  (apply make-clean stage
         srcdir: (poo-flow-package-srcdir)
         (poo-flow-package-options [])))

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
    (["meta"] (write '("spec" "compile" "clean")) (newline))
    (["spec" . options]
     (pretty-print (poo-flow-compile-build-spec
                    (poo-flow-package-parse-options options))))
    (["compile" . options] (poo-flow-package-compile (poo-flow-package-parse-options options)))
    (["clean"] (poo-flow-clean))
    ([] (poo-flow-package-compile []))))
