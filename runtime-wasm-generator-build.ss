#!/usr/bin/env gxi

(import :std/make
        :clan/base
        :clan/building)

(def (runtime-wasm-generator-spec)
  '("src/projection-syntax-support"
    "src/core/roles"
    "src/core/failure"
    "src/core/object-syntax"
    "src/core/projection-syntax"
    "src/core/task"
    "src/core/flow-strand"
    "src/core/flow-declarations"
    "src/core/flow"
    "src/core/plan"
    "src/utilities/functional"
    "src/feature-system/bundle-v1-lowering"
    "src/feature-system/bundle-v1-foreign-arena"
    "src/feature-system/bundle-v1-composition-writer"
    "src/module-system/profile-composition-builders"
    "src/module-system/profile-composition-inline-runtime"
    "src/module-system/profile-composition-accessors"
    "src/module-system/profile-composition-syntax-plan"
    "src/module-system/profile-composition-use-syntax"
    "src/module-system/profile-composition"))

(init-build-environment!
  name: "POO Flow runtime-wasm generators"
  deps: '("clan/poo")
  spec: runtime-wasm-generator-spec)

(displayln "POO_FLOW_RUNTIME_WASM_GENERATOR_BUILD_RECEIPT {\"status\":\"ok\"}")
