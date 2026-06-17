#!/usr/bin/env gxi

(import :std/build-script)

(defbuild-script
  '("src/core/roles"
    "src/core/receipt"
    "src/core/task"
    "src/core/flow"
    "src/core/plan"
    "src/core/strategy"
    "src/core/policy"
    "src/core/runtime-adapter"
    "src/core/replay"
    "src/core/runner"
    "src/core/api"))
