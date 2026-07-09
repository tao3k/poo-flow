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

(def +poo-flow-package-build-source-files+
  '("src/cli-support/package-build.ss"
    "src/cli-support/package-build-support/options.ss"
    "src/cli-support/package-build-support/specs.ss"
    "src/cli-support/package-build-support/env.ss"
    "src/cli-support/package-build-support/launcher.ss"
    "src/cli-support/package-build-support/receipt.ss"
    "src/cli-support/package-build-support/stage-output.ss"
    "src/cli-support/package-build-support/stage-cache.ss"
    "src/cli-support/package-build-support/observability.ss"
    "src/cli-support/package-build-support/engine.ss"
    "src/cli-support/package-build-compiled.ss"))

(def +poo-flow-package-build-compiled-files+
  '("lib/poo-flow/src/cli-support/package-build.ssi"
    "lib/poo-flow/src/cli-support/package-build-support/options.ssi"
    "lib/poo-flow/src/cli-support/package-build-support/specs.ssi"
    "lib/poo-flow/src/cli-support/package-build-support/env.ssi"
    "lib/poo-flow/src/cli-support/package-build-support/launcher.ssi"
    "lib/poo-flow/src/cli-support/package-build-support/receipt.ssi"
    "lib/poo-flow/src/cli-support/package-build-support/stage-output.ssi"
    "lib/poo-flow/src/cli-support/package-build-support/stage-cache.ssi"
    "lib/poo-flow/src/cli-support/package-build-support/observability.ssi"
    "lib/poo-flow/src/cli-support/package-build-support/engine.ssi"
    "lib/poo-flow/src/cli-support/package-build-compiled.ssi"))

(def (poo-flow-build-file-mtime-seconds path)
  (and (file-exists? path)
       (time->seconds
        (file-info-last-modification-time
         (file-info path)))))

(def (poo-flow-build-source-current-against-output?/mtime source output)
  (let ((source-time (poo-flow-build-file-mtime-seconds source))
        (output-time (poo-flow-build-file-mtime-seconds output)))
    (and source-time
         output-time
         (<= source-time output-time))))

(def (poo-flow-package-build-compiled-output-path output)
  (let (gerbil-path (getenv "GERBIL_PATH" #f))
    (and gerbil-path
         (path-expand output gerbil-path))))

(def (poo-flow-package-build-compiled-current? sources outputs)
  (cond
   ((and (null? sources) (null? outputs))
    #t)
   ((or (null? sources) (null? outputs))
    #f)
   (else
    (let (compiled-output
          (poo-flow-package-build-compiled-output-path (car outputs)))
      (and compiled-output
           (poo-flow-build-source-current-against-output?/mtime
            (path-expand (car sources))
            compiled-output)
           (poo-flow-package-build-compiled-current?
            (cdr sources)
            (cdr outputs)))))))

(def (poo-flow-load-package-build!)
  (if (poo-flow-package-build-compiled-current?
       +poo-flow-package-build-source-files+
       +poo-flow-package-build-compiled-files+)
    (with-exception-catcher
     (lambda (_exn)
       (eval '(import "./src/cli-support/package-build.ss")))
     (lambda ()
       (eval '(import :poo-flow/src/cli-support/package-build-compiled))))
    (eval '(import "./src/cli-support/package-build.ss"))))

(def (poo-flow-load-testing!)
  (eval '(import :gslph/src/testing/build-runner
                 :gslph/src/testing/model
                 "./src/testing/project.ss")))

(def (poo-flow-package-entry-options release optimized debug cli tests force verbose)
  ((eval 'poo-flow-entry-options) release optimized debug cli tests force verbose))

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
                          tests: (tests #f)
                          force: (force #f)
                          verbose: (verbose #f))
  (help: "Print the package build spec"
   getopt: +poo-flow-build-getopt+)
  (poo-flow-load-package-build!)
  (pretty-print
   ((eval 'poo-flow-compile-build-spec)
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
  (poo-flow-load-package-build!)
  ((eval 'poo-flow-package-compile)
   (poo-flow-package-entry-options release optimized debug cli tests force verbose)))

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
