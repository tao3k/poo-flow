;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Explicit slot policies are pure values shared by Core and vertical modules.

(import (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :std/test check-equal? test-suite)
        :core/module-system/schema/interface)

(export module-schema-slot-policy-test)

(def module-schema-slot-policy-test
  (test-suite "module schema slot policy"
    (poo-flow-test-case "override does not normalize scalar values"
      (check-equal?
       (poo-flow-module-slot-apply-policy 'override '(old) 'new)
       'new))
    (poo-flow-test-case "ordered list policies deduplicate and remove"
      (check-equal?
       (poo-flow-module-slot-apply-policy 'append '(a b) '(b c))
       '(a b c))
      (check-equal?
       (poo-flow-module-slot-apply-policy 'prepend '(a b) '(b c))
       '(b c a))
      (check-equal?
       (poo-flow-module-slot-apply-policy 'remove '(a b c) '(b))
       '(a c)))))
