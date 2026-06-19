#!/usr/bin/env gxi
;; -*- Gerbil -*-
;;; Build file for the POO Flow Gerbil runtime package.
;;; The runtime package root is src, matching imports such as :core/roles.

(import :gerbil/gambit
        (only-in :std/make make)
        (only-in :std/cli/multicall
                 define-entry-point
                 define-multicall-main
                 set-default-entry-point!))

;;; Runtime module order is explicit because core roles, request facades, and
;;; backend projections have compile-time dependencies that should not depend
;;; on filesystem traversal order.
(def (runtime-modules)
  '("core/roles"
    "core/failure"
    "core/receipt"
    "core/task"
    "core/flow"
    "core/plan"
    "core/flow-syntax"
    "core/runtime-adapter"
    "core/strategy"
    "core/policy"
    "core/replay"
    "core/runner"
    "core/config"
    "modules/interface"
    "modules/source"
    "modules/descriptor"
    "modules/context"
    "modules/diagnostics"
    "modules/observability"
    "modules/resolver"
    "modules/loader"
    "modules/projection"
    "modules/doctor"
    "modules/user-config-base"
    "modules/user-config"
    "modules/user-config-syntax"
    "modules/user-interface-case"
    "modules/extension"
    "modules/objects"
    "modules/object-validation"
    "modules/user-interface/objects"
    "modules/agent-sandbox/config"
    "modules/sandbox-core/profile"
    "modules/sandbox-core/objects"
    "modules/nono-sandbox/objects"
    "modules/cubeSandbox/objects"
    "modules/docker-sandbox/objects"
    "modules/funflow/config"
    "modules/loop-governor/config"
    "modules/nono-sandbox/config"
    "modules/cubeSandbox/config"
    "modules/docker-sandbox/config"
    "modules/profiles/kernel"
    "modules/user-interface/config"
    "modules/syntax"
    "modules/module-system"
    "loops/descriptor"
    "loops/strategy"
    "loops/governor"
    "loops/governor-marlin"
    "loops/agent"
    "core/api"
    "workflow/store"
    "modules/agent-sandbox/resource"
    "modules/custom-task"
    "modules/docker"
    "modules/text"
    "modules/workflow/flows"
    "modules/workflow/syntax"
    "modules/agent-sandbox/alist"
    "modules/agent-sandbox/profile"
    "modules/agent-sandbox/request-field"
    "modules/agent-sandbox/request-accessor"
    "modules/agent-sandbox/request-validation"
    "modules/agent-sandbox/request-builder"
    "modules/agent-sandbox/request-macro"
    "modules/agent-sandbox/request"
    "modules/agent-sandbox/bridge"
    "modules/agent-sandbox/cube-interface"
    "modules/agent-sandbox/cube"
    "modules/nono-sandbox/c-binding-descriptor"
    "modules/nono-sandbox/c-binding-runtime"
    "modules/nono-sandbox/c-binding"
    "modules/agent-sandbox/nono"
    "modules/agent-sandbox/marlin-interface"
    "modules/agent-sandbox/api"))

;;; std/make receives canonical gxc specs and an explicit source directory, so
;;; module names remain package-rooted while files stay physically under src.
(def (runtime-build-spec)
  (map (lambda (module-id) [gxc: module-id])
       (runtime-modules)))

(def (user-interface-module-build-spec)
  '((gxc: "user-interface/init")
    (gxc: "user-interface/custom/my-module/config")))

(def (cli-module-build-spec)
  '((gxc: "cli")))

(def (cli-executable-build-spec)
  '((exe: "cli" bin: "poo-flow")))

(def (compile-package!)
  (make (runtime-build-spec)
        srcdir: (string-append (current-directory) "src"))

  (make (user-interface-module-build-spec)
        srcdir: (current-directory))

  (make (cli-module-build-spec)
        srcdir: (string-append (current-directory) "src")
        bindir: (string-append (current-directory) ".bin"))

  (make (cli-executable-build-spec)
        srcdir: (string-append (current-directory) "src")
        bindir: (string-append (current-directory) ".bin")))

(def (test-package!)
  (add-load-path! (current-directory))
  (add-load-path! (string-append (current-directory) "src"))
  (add-load-path! (string-append (current-directory) "t"))
  (eval '(import :unit-tests)))

(define-entry-point (compile)
  (help: "Compile the POO Flow Gerbil package"
   getopt: [])
  (compile-package!))

(define-entry-point (test)
  (help: "Run the POO Flow Gerbil test root"
   getopt: [])
  (test-package!))

(set-default-entry-point! 'compile)
(define-multicall-main)
