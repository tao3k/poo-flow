#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Thin package entrypoints for the POO Flow Gerbil runtime.

(import (only-in :std/cli/getopt
                 flag
                 rest-arguments)
        (only-in :std/cli/multicall
                 define-entry-point
                 define-multicall-main)
        (only-in :gslph/src/build-api/source-coverage
                 gslph-source-coverage)
        :gslph/src/build-api/framework
        :gslph/src/testing/framework
        (only-in :gerbil/gambit
                 exit
                 file-exists?
                 file-info
                 file-info-last-modification-time
                 getenv
                 path-expand
                 pretty-print
                 string-append
                 with-exception-catcher))

(gslph-source-coverage
 roots: '("src" "user-interface")
 runtime-roots: '("src")
 explanation: "POO Flow runtime owners live under src; user-interface modules are declarative package sources that still need policy coverage.")

(def +poo-flow-build-getopt+
  [(flag 'release "--release"
         help: "Build released artifacts")
   (flag 'optimized "--optimized"
         help: "Build optimized artifacts")
   (flag 'debug "--debug"
         help: "Include debug information")
   (flag 'cli "--cli"
         help: "Build only CLI modules")
   (flag 'tests "--tests"
         help: "Build test modules during compile")
   (flag 'force "--force"
         help: "Force rebuild")
   (flag 'verbose "-V" "--verbose"
         help: "Enable verbose build output")])

(def +poo-flow-test-getopt+
  [(rest-arguments 'files
                   help: "Selected gxtest files or manifest roots")])

(define-multicall-main)

(def (poo-flow-load-package-build!)
  (eval '(import "./src/cli-support/package-build.ss")))

(def (poo-flow-build-testing-bootstrap!)
  (poo-flow-load-package-build!)
  ((eval 'poo-flow-package-build-testing-bootstrap!)))

(def (poo-flow-load-testing!)
  (poo-flow-build-testing-bootstrap!)
  (eval '(import :gslph/src/testing/build-runner
                 :gslph/src/testing/model
                 "./src/testing/project.ss"
                 "./src/testing/policy-debug.ss")))

(def (poo-flow-package-entry-options release optimized debug cli tests force verbose)
  ((eval 'poo-flow-entry-options) release optimized debug cli tests force verbose))

(def (poo-flow-package-entry-options . arguments)
  (poo-flow-load-package-build!)
  (apply (eval 'poo-flow-entry-options) arguments))

(define-build-commands
 (poo-flow-build-spec! poo-flow-build-compile! poo-flow-build-clean!)
 load!: poo-flow-load-package-build!
 spec: (lambda () (eval 'poo-flow-compile-build-spec))
 compile: (lambda () (eval 'poo-flow-package-compile))
 clean: (lambda () (eval 'poo-flow-clean)))

(define-project-test poo-flow-test
  bootstrap!: poo-flow-load-testing!
  project: (lambda () ((eval 'poo-flow-testing-project) "." "."))
  run: (lambda (project files) ((eval 'testing-build-main) project files))
  ok?: (lambda (receipt) ((eval 'testing-receipt-ok?) receipt)))

(define-entry-point (meta)
  (help: "List package build targets"
   getopt: [])
  (write '("spec" "compile" "test" "policy-debug" "clean"))
  (newline))

(define-entry-point (spec release: (release #f)
                          optimized: (optimized #f)
                          debug: (debug #f)
                          cli: (cli #f)
                          tests: (tests #f)
                          force: (force #f)
                          verbose: (verbose #f))
  (help: "Print the package build spec"
   getopt: +poo-flow-build-getopt+)
  (pretty-print
   (poo-flow-build-spec!
    (poo-flow-package-entry-options release optimized debug cli tests force verbose))))

(define-entry-point (compile release: (release #f)
                             optimized: (optimized #f)
                             debug: (debug #f)
                             cli: (cli #f)
                             tests: (tests #f)
                             force: (force #f)
                             verbose: (verbose #f))
  (help: "Compile the package"
   getopt: +poo-flow-build-getopt+)
  (poo-flow-build-compile!
   (poo-flow-package-entry-options release optimized debug cli tests force verbose)))

(define-entry-point (test . files)
  (help: "Run selected gxtest files through the harness testing framework"
   getopt: +poo-flow-test-getopt+)
  (exit (poo-flow-test files)))

(define-entry-point (policy-debug . files)
  (help: "Print parser-backed Harness policy repair targets for selected tests"
   getopt: +poo-flow-test-getopt+)
  (poo-flow-load-testing!)
  (exit ((eval 'poo-flow-policy-debug-report!) files)))

(define-entry-point (clean)
  (help: "Clean package build artifacts"
   getopt: [])
  (poo-flow-build-clean!)
  (exit 0))
