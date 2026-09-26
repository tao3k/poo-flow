;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Minimal native gxtest fixture for the POO Flow operation-observation lane.

(import (only-in :poo-flow/src/module-system/observability/testing-case poo-flow-test-case)
         :std/test)

(export native-batch-test)

(def native-batch-test
  (test-suite "POO Flow observed native batch fixture"
    (poo-flow-test-case "runs through the upstream Gerbil test executor"
      (check #t => #t))))
