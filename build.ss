#!/usr/bin/env gxi

(import :std/build-script)

(defbuild-script
  '("src/poo-flow/poo"
    "src/poo-flow/receipt"
    "src/poo-flow/task"
    "src/poo-flow/flow"
    "src/poo-flow/strategy"
    "src/poo-flow/runtime-adapter"
    "src/poo-flow/runner"
    "src/poo-flow"))
