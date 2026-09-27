;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Profile selection and lexical binding values used by composition.

(import (only-in :clan/poo/object .o .ref))

(export poo-flow-profile-ref
        poo-flow-scenario-module-binding
        poo-flow-scenario-profile-binding)

(def (poo-flow-profile-ref module slot)
  (.ref module slot))

(def (poo-flow-scenario-module-binding alias module)
  (let ((alias-value alias)
        (module-value module))
    (.o (kind 'poo-flow.scenario.module-binding.v1)
        (alias alias-value)
        (module module-value))))

(def (poo-flow-scenario-profile-binding alias slot)
  (let ((alias-value alias)
        (slot-value slot))
    (.o (kind 'poo-flow.scenario.profile-binding.v1)
        (alias alias-value)
        (slot slot-value))))
