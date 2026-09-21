;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import "types.ss")
(export poo-flow-custom-my-module-identity?)

(def (poo-flow-custom-my-module-identity? value)
  (eq? value +poo-flow-custom-my-module-identity+))
