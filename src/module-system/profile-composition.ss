;;; -*- Gerbil -*-
;;; Boundary: public facade for POO-native profile composition.
;;; Invariant: public import stays stable while owner modules remain small.

(import :poo-flow/src/module-system/profile-composition-core
        :poo-flow/src/module-system/profile-composition-clause-syntax
        :poo-flow/src/module-system/profile-composition-main-syntax
        :poo-flow/src/module-system/profile-composition-profile-syntax
        :poo-flow/src/module-system/profile-composition-inline-runtime
        :poo-flow/src/module-system/profile-composition-use-syntax)

(export (import: :poo-flow/src/module-system/profile-composition-core)
        (import: :poo-flow/src/module-system/profile-composition-clause-syntax)
        (import: :poo-flow/src/module-system/profile-composition-main-syntax)
        (import: :poo-flow/src/module-system/profile-composition-profile-syntax)
        (import: :poo-flow/src/module-system/profile-composition-inline-runtime)
        (import: :poo-flow/src/module-system/profile-composition-use-syntax))
