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
        :poo-flow/src/cli-support/project-build
        (only-in :gerbil/gambit
                 exit
                 pretty-print))

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
   (flag 'verbose "-V" "--verbose"
         help: "Enable verbose build output")])

(define-multicall-main)

(poo-flow-project-configure-build-root! ".")

(define-build-options poo-flow-project-options
  make: (lambda () poo-flow-project-build-options))

(define-entry-point (meta)
  (help: "List package build targets"
   getopt: [])
  (write '("spec" "compile" "clean"))
  (newline))

(define-entry-point (spec release: (release #f)
                          optimized: (optimized #f)
                          debug: (debug #f)
                          verbose: (verbose #f))
  (help: "Print the package build spec"
   getopt: +poo-flow-build-getopt+)
  (pretty-print
   (poo-flow-project-build-spec
    (poo-flow-project-options release optimized debug verbose))))

(define-entry-point (compile release: (release #f)
                             optimized: (optimized #f)
                             debug: (debug #f)
                             verbose: (verbose #f))
  (help: "Compile the package"
   getopt: +poo-flow-build-getopt+)
  (poo-flow-project-compile!
   (poo-flow-project-options release optimized debug verbose)))

(define-entry-point (clean)
  (help: "Clean package build artifacts"
   getopt: [])
  (poo-flow-project-clean!)
  (exit 0))
