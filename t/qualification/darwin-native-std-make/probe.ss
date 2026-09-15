;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; std/interface supplies a stable, nontrivial precompiled import closure.

(import :std/interface)
(export std-make-one-target-probe)

(def (std-make-one-target-probe)
  'ready)
