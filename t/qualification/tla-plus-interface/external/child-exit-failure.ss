;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; Deliberate failure: only the child-exit qualification recipe runs this.
(import :std/test)
(export temporal-child-exit-failure-test)
(def temporal-child-exit-failure-test
  (test-suite "child process failure status control"
    (test-case "deliberate assertion failure" (check 0 => 1))))
