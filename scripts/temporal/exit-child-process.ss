;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; Owned single-job child-process boundary. Invoke only after a pure native
;;; evaluation or test harness returns. The host owns persistent resources;
;;; flush the completed result and propagate status without dyld unload latency.
(import :std/ffi)
(export temporal-child-process-exit!)
(C-ffi-macrology)
(C-include "<stdlib.h>")
(def-C-lambda _Exit (int) void)
(def (temporal-child-process-exit! status)
  (unless (and (exact-integer? status) (<= 0 status 255))
    (error "invalid native child exit status" status))
  (force-output (current-output-port))
  (force-output (current-error-port))
  (_Exit status))
