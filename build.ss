#!/usr/bin/env gxi
;; -*- Gerbil -*-
;;; Build file for the POO Flow Gerbil runtime package.
;;; The runtime package root is src, matching imports such as :core/roles.

(import (only-in :std/make make))

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
    "modules/user-interface/objects"
    "modules/nono-sandbox/objects"
    "modules/cubeSandbox/objects"
    "modules/funflow/config"
    "modules/loop-governor/config"
    "modules/nono-sandbox/config"
    "modules/cubeSandbox/config"
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
    "sandbox/resource"
    "extensions/custom-task"
    "extensions/docker"
    "extensions/store"
    "extensions/text"
    "extensions/workflow"
    "extensions/workflow-syntax"
    "extensions/agent-sandbox-util"
    "extensions/agent-sandbox-profile"
    "extensions/agent-sandbox-request-field"
    "extensions/agent-sandbox-request-accessor"
    "extensions/agent-sandbox-request-validation"
    "extensions/agent-sandbox-request-builder"
    "extensions/agent-sandbox-request-macro"
    "extensions/agent-sandbox-request"
    "extensions/agent-sandbox-bridge"
    "extensions/agent-sandbox-cube-interface"
    "extensions/agent-sandbox-cube"
    "extensions/agent-sandbox-nono-c-binding-descriptor"
    "extensions/agent-sandbox-nono-c-binding-runtime"
    "extensions/agent-sandbox-nono-c-binding"
    "extensions/agent-sandbox-nono"
    "extensions/agent-sandbox-marlin-interface"
    "extensions/agent-sandbox"))

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

(make (runtime-build-spec)
      srcdir: (string-append (current-directory) "src"))

(make (user-interface-module-build-spec)
      srcdir: (current-directory))

(make (cli-module-build-spec)
      srcdir: (string-append (current-directory) "src")
      bindir: (string-append (current-directory) ".bin"))

(make (cli-executable-build-spec)
      srcdir: (string-append (current-directory) "src")
      bindir: (string-append (current-directory) ".bin"))
