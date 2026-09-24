;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; MRR-owned method bundle for Provider x Query receipt binding.
(import :poo-flow/src/module-system/poo-clos/interface
        (only-in :poo-flow/src/modules/query/objects PooFlowQuery.)
        (only-in :poo-flow/src/modules/query/contracts
                 QueryReceiptBindingProtocol
                 QueryReceiptBindingGeneric
                 poo-flow-query-bind-execution-receipt/default)
        (only-in "config.ss"
                 MrrQueryReceiptBindingExecutor
                 MrrGqlQueryProvider))

(export MrrQueryReceiptBindingMethods)

(def MrrQueryReceiptBindingMethod
  (poo-clos-method
   'query/mrr-gql-receipt-binding
   (list
    (poo-clos-class-specializer MrrQueryReceiptBindingExecutor)
    (poo-clos-eql-specializer MrrGqlQueryProvider)
    (poo-clos-prototype-specializer PooFlowQuery.)
    (poo-clos-any-specializer)
    (poo-clos-any-specializer))
   (lambda (_frame _executor provider query admission candidate)
     (poo-flow-query-bind-execution-receipt/default
      provider query admission candidate))))

(.defmethod-bundle MrrQueryReceiptBindingMethods
  QueryReceiptBindingProtocol
  MrrQueryReceiptBindingMethod)

(poo-clos-compose-method-bundle
 QueryReceiptBindingGeneric
 MrrQueryReceiptBindingMethods)
