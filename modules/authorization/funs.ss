;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Authorization has no in-process fallback evaluator. Provider execution is
;;; admitted only through its explicit runtime boundary.
(import (only-in :clan/poo/object .ref)
        (only-in :poo-flow/modules/authorization/types
                 poo-flow-authorization-provider?))

(export poo-flow-authorization-provider-engines)

(def (poo-flow-authorization-provider-engines provider)
  (unless (poo-flow-authorization-provider? provider)
    (error "invalid authorization Provider" provider))
  (.ref provider 'engines))
