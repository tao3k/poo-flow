;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal?)
        (only-in :poo-flow/src/module-system/observability/testing-case
                 poo-flow-test-case)
        (only-in :poo-flow/modules/funflow/interface
                 poo-flow-funflow-workflow-agreement)
        (only-in :poo-flow/modules/funflow/funs
                 poo-flow-funflow-method-combination-module-ref)
        (only-in :poo-flow/src/module-system/loader/source
                 poo-flow-module-source-ref-kind))

(export funflow-public-module-test)

(def funflow-public-module-test
  (test-suite "Funflow top-level module ownership"
    (poo-flow-test-case "functional interface remains callable"
      (check-equal? (procedure? poo-flow-funflow-workflow-agreement) #t))
    (poo-flow-test-case "functional role remains directly importable"
      (check-equal?
       (poo-flow-module-source-ref-kind
        poo-flow-funflow-method-combination-module-ref)
       'standard-library))))
