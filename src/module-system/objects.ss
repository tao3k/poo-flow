;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: shared module objects available to every module namespace.

(import :core/module-schema/interface)

(export (import: :core/module-schema/interface)
        poo-flow-shared-sandbox-object
        poo-flow-shared-module-objects)

(def poo-flow-shared-sandbox-object
  (poo-flow-module-object
   'objects.shared.sandbox
   '()
   (list
    (poo-flow-module-field-contract
     'backend PooFlowModuleSymbolType 'override 'sandbox '((scope . shared)))
    (poo-flow-module-field-contract
     'flags PooFlowModuleListType 'append '() '((scope . shared)))
    (poo-flow-module-field-contract
     'runtime-args PooFlowModuleListType 'append '() '((scope . shared))))
   '((namespace . objects.shared)
     (domain . sandbox))))

(def poo-flow-shared-module-objects
  (list poo-flow-shared-sandbox-object))
