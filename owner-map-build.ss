#!/usr/bin/env gxi

(import :std/build-script)

(defbuild-script
  '("src/utilities/functional"
    "src/projection-syntax-support"
    "src/core/projection-syntax"
    "src/core/roles"
    "src/core/failure"
    "src/core/flow-declarations"
    "src/core/flow-strand"
    "src/core/object-syntax"
    "src/core/task"
    "src/core/flow"
    "src/core/plan"
    "src/module-system/profile-composition-builders"
    "src/module-system/profile-composition-inline-runtime"
    "src/module-system/profile-composition-use-syntax"
    "src/module-system/profile-composition-accessors"
    "src/module-system/profile-composition"
    "src/module-system/profile-composition-syntax-plan"
    "src/module-system/g0-qualification"
    "src/module-system/runtime-context-recovery"
    "src/module-system/owner-map-observability"
    "src/module-system/composition-lineage"
    "src/module-system/gerbil-poo-consumption"
    "src/module-system/owner-map-contract"))
