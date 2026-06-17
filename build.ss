#!/usr/bin/env gxi

(import :std/build-script)

(defbuild-script
  '("src/core/roles"
    "src/core/receipt"
    "src/core/task"
    "src/core/flow"
    "src/core/plan"
    "src/core/strategy"
    "src/core/runtime-adapter"
    "src/core/runner"
    "src/core/api"))
