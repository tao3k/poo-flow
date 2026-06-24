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
        (only-in :clan/filesystem
                 find-files
                 path-is-script?)
        (only-in :gerbil/gambit
                 getenv
                 path-expand
                 pretty-print
                 string=?
                 string-append)
        (only-in :gerbil/compiler/driver
                 compile-module)
        (only-in :std/make
                 make
                 make-clean)
        (only-in :std/misc/path
                 path-extension-is?))

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
(def +poo-flow-test-root-files+
  '("t/unit-tests.ss"
    "t/contract-tests.ss"
    "t/integration-tests.ss"
    "t/performance-tests.ss"
    "t/project-policy-test.ss"))

;; : (Listof String)
(def +poo-flow-special-source-files+
  '("src/modules/nono-sandbox/_nono.ss"
    "src/cli.ss"
    "main.ss"
    "manifest.ss"))

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
(def (poo-flow-package-source-file? file)
  (and (path-extension-is? file ".ss")
       (not (path-is-script? file))
       (not (member file +poo-flow-special-source-files+))))

;; : (String String -> Bool)
(def (poo-flow-string-prefix? prefix text)
  (let ((prefix-length (string-length prefix))
        (text-length (string-length text)))
    (and (<= prefix-length text-length)
         (string=? (substring text 0 prefix-length) prefix))))

;; : (String String -> Bool)
(def (poo-flow-direct-child? dir file)
  (let (prefix (string-append dir "/"))
    (and (poo-flow-string-prefix? prefix file)
         (let lp ((index (string-length prefix)))
           (cond
            ((= index (string-length file)) #t)
            ((char=? (string-ref file index) #\/) #f)
            (else (lp (+ index 1))))))))

;; : (String -> Bool)
(def (poo-flow-root-test-source-file? file)
  (and (poo-flow-package-source-file? file)
       (poo-flow-direct-child? "t" file)))

;; : ([String] Bool (String -> Bool) -> [String])
(def (poo-flow-find-package-modules dirs recursive? source-file?)
  (apply append
         (map (lambda (dir)
                (find-files dir
                            source-file?
                            recurse?: (lambda (_) recursive?)))
              dirs)))

;; : (-> [String])
(def (poo-flow-runtime-modules)
  (poo-flow-find-package-modules
   +poo-flow-runtime-include-dirs+
   #t
   poo-flow-package-source-file?))

;; : (-> [String])
(def (poo-flow-all-test-modules)
  (poo-flow-find-package-modules
   +poo-flow-test-include-dirs+
   #t
   poo-flow-root-test-source-file?))

;; : (List -> [String])
(def (poo-flow-test-modules options)
  (if (poo-flow-all-test-modules-build-options? options)
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

;; : (-> String (OrFalse Fixnum))
(def (poo-flow-package-cores-from-env name)
  (let (value (getenv name #f))
    (and value
         (let (cores (string->number value))
           (and (integer? cores)
                (> cores 0)
                cores)))))

;; : (-> (Or Fixnum Bool))
(def (poo-flow-package-parallelize)
  (or (poo-flow-package-cores-from-env "GERBIL_BUILD_CORES")
      #t))

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

;; : (String -> Void)
(def (poo-flow-compile-test-module file)
  (display "... compile ")
  (display file)
  (newline)
  (force-output)
  (compile-module file [invoke-gsc: #t optimize: #f parallel: #f]))

;; : ([String] -> Void)
(def (poo-flow-compile-test-modules files)
  (display "... poo-flow compile tests targets=")
  (display (length files))
  (display " compile-module")
  (newline)
  (force-output)
  (for-each poo-flow-compile-test-module files))

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
      (["--all-test-modules" . rest]
       (lp rest [build-all-test-modules: #t . options]))
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
(def (poo-flow-all-test-modules-build-options? options)
  (match options
    ([build-all-test-modules: value . _] value)
    ([_ _ . rest] (poo-flow-all-test-modules-build-options? rest))
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
      (poo-flow-test-build-spec options)
      (poo-flow-package-build-spec options))))

;; : (List -> Void)
(def (poo-flow-package-compile options)
  (if (poo-flow-test-build-options? options)
    (poo-flow-compile-test-modules (poo-flow-test-modules options))
    (poo-flow-make "package" (poo-flow-compile-build-spec options) options)))

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
