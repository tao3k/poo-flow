;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Preserve the POO Flow module path while Foundation owns the Case profile.
(import :core/observability/testing-case)
(export (import: :core/observability/testing-case))
