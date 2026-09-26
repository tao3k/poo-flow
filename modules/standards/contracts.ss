;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: open Standard validation Provider protocol.
;;; Invariant: the abstract Provider fails closed and selects no industry.
(import (only-in :clan/poo/object .o .ref)
        (only-in :clan/poo/mop .defgeneric)
        "types.ss")

(export PooFlowStandardValidationProvider.
        poo-flow-standard-validate)

(.defgeneric (poo-flow-standard-validate provider validation-closure subject)
  slot: .validate-standard)

(def PooFlowStandardValidationProvider.
  (.o kind: +poo-flow-standard-validation-provider-kind+
      identity: #f
      supported-families: '()
      .validate-standard:
      (lambda (validation-closure subject)
        (error "abstract Standard validation Provider cannot execute"
               validation-closure subject))))
