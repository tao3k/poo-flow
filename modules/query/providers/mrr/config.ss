;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Inert MRR Provider declaration.  Rust owns execution; Scheme owns binding.
(import :poo-flow/src/module-system/poo-clos/interface
        (only-in :poo-flow/modules/query/objects
                 QueryReceiptBindingExecutor
                 poo-flow-query-provider))

(export MrrQueryReceiptBindingExecutor
        MrrQueryReceiptBinder
        MrrGqlQueryProvider)

(def MrrQueryReceiptBindingExecutor
  (poo-clos-class
   'query/mrr-receipt-binding-executor
   direct-superclasses: (list QueryReceiptBindingExecutor)))

(def MrrQueryReceiptBinder
  (poo-clos-make-instance MrrQueryReceiptBindingExecutor))

(def MrrGqlQueryProvider
  (poo-flow-query-provider
   'mrr '(gql) 'mrr MrrQueryReceiptBinder))
