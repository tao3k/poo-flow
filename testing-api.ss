;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Public POO Flow testing policy interface.
;;; ASP owns native gxtest execution and generic profile algebra.  POO Flow
;;; extends that one interface once; downstream packages only refine the
;;; resulting POO value with package-local profiles and selectors.

(import "./src/module-system/observability/testing-extension")

(export (import: "./src/module-system/observability/testing-extension"))
