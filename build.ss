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
        (only-in :gerbil/gambit
                 exit
                 pretty-print
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

(def (poo-flow-load-testing!)
  (eval '(import :gslph/src/testing/build-runner
                 :gslph/src/testing/model
                 "./src/cli-support/testing-project.ss")))

(def (poo-flow-package-entry-options release optimized debug cli force verbose)
  (poo-flow-load-package-build!)
  ((eval 'poo-flow-entry-options) release optimized debug cli force verbose))

(def (poo-flow-test-error-status exn files)
  (display "|poo-flow-test-error ")
  (write [files: files
          exception: exn])
  (newline)
  (force-output)
  11)

(def (poo-flow-test files)
  (with-exception-catcher
   (lambda (exn)
     (poo-flow-test-error-status exn files))
   (lambda ()
     (poo-flow-load-testing!)
     (let (receipt
           ((eval 'testing-build-main)
            ((eval 'poo-flow-testing-project) "." ".")
            files))
       (if ((eval 'testing-receipt-ok?) receipt) 0 1)))))

(define-entry-point (meta)
  (help: "List package build targets"
   getopt: [])
  (write '("spec" "compile" "test" "clean"))
  (newline))

(define-entry-point (spec release: (release #f)
                          optimized: (optimized #f)
                          debug: (debug #f)
                          cli: (cli #f)
                          force: (force #f)
                          verbose: (verbose #f))
  (help: "Print the package build spec"
   getopt: +poo-flow-build-getopt+)
  (poo-flow-load-package-build!)
  (pretty-print
   ((eval 'poo-flow-compile-build-spec)
    (poo-flow-package-entry-options release optimized debug cli force verbose))))

(define-entry-point (compile release: (release #f)
                             optimized: (optimized #f)
                             debug: (debug #f)
                             cli: (cli #f)
                             force: (force #f)
                             verbose: (verbose #f))
  (help: "Compile the package"
   getopt: +poo-flow-build-getopt+)
  (poo-flow-load-package-build!)
  ((eval 'poo-flow-package-compile)
   (poo-flow-package-entry-options release optimized debug cli force verbose)))

(define-entry-point (test . files)
  (help: "Run selected gxtest files through the harness testing framework"
   getopt: +poo-flow-test-getopt+)
  (exit (poo-flow-test files)))

(define-entry-point (clean)
  (help: "Clean package build artifacts"
   getopt: [])
  (poo-flow-load-package-build!)
  ((eval 'poo-flow-clean))
  (exit 0))
