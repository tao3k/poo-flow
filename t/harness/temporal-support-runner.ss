;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; Native completed-import boundaries; no timer output or semantic shortcuts.
(for-each (lambda (module)
  (displayln "IMPORT " module) (force-output)
  (eval `(import ,module))
  (displayln "IMPORT-OK " module) (force-output))
 '( :clan/poo/object
    :clan/poo/mop
    :core/types
    :core/module-system/schema/slot-contracts
    :core/observability/types
    :core/observability/funcs
    :core/observability/slot-debug
    :core/observability/debug
    :core/observability/testing-case
    :asp-gerbil-scheme/src/build-api/core-capacity
    :asp-gerbil-scheme/src/testing/import-footprint-reader
    :asp-gerbil-scheme/src/testing/extension
    :asp-gerbil-scheme/testing-api
    :core/observability/output
    :poo-flow/src/testing/testing-extension
    :core/module-system/schema/relations
    :core/module-system/types
    :core/module-system/config
    :core/module-system/objects
    :poo-flow/src/authoring/semantic-module
    :poo-flow/src/authoring/module-interface
    :core/object-family/syntax
    :poo-flow/src/utilities/product-syntax
    :poo-flow/src/utilities/final-projection-syntax
    :core/module-system/source/objects
    :poo-flow/src/authoring/module-imports
    :poo-flow/src/user-interface/selection-flags
    :poo-flow/src/user-interface/module-selection
    :poo-flow/src/user-interface/profile-core
    :poo-flow/src/utilities/functional
    :poo-flow/src/user-interface/profile-policy
    :poo-flow/testing-api
    :poo-flow/modules/temporal-causality/time/types
    :poo-flow/modules/temporal-causality/time/objects
    :poo-flow/modules/temporal-causality/revisions/types
    :poo-flow/modules/temporal-causality/revisions/objects
    :poo-flow/modules/temporal-causality/time/funs
    :poo-flow/modules/temporal-causality/revisions/funs
    :poo-flow/modules/temporal-causality/revisions/interface
    :poo-flow/modules/temporal-causality/truth-maintenance/support/types
    :poo-flow/modules/temporal-causality/truth-maintenance/support/objects
    :poo-flow/modules/temporal-causality/truth-maintenance/support/funs
    :poo-flow/modules/temporal-causality/truth-maintenance/support/interface
    :poo-flow/modules/temporal-causality/truth-maintenance/interface
    :gerbil/tools/gxtest))
(eval '(exit (gerbil/tools/gxtest#main "-v" "5" "t/temporal-support-test.ss")))
