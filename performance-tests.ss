#!/usr/bin/env gxi
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Native performance entrypoint using the same ASP scheduler as unit tests.

(import (only-in :clan/testing find-test-files)
        (only-in :asp-gerbil-scheme/testing-api
                 +asp-testing-interface+
                 +testing-serial-resource-profile+
                 testing-test-selector
                 testing-interface-map-profile
                 testing-interface-run-test-files!)
        (only-in :std/srfi/1 filter foldl)
        (only-in :std/srfi/13 string-prefix?)
        (only-in "src/module-system/observability/testing-extension.ss"
                 poo-flow-testing-observability-extension))

;;; Scenario end-to-end benchmarks admit on wall-clock p95, so every file in
;;; the performance lane needs an uncontended process.  This is a test-owned
;;; POO declaration; non-benchmark support files still use ASP's native core
;;; capacity, while CPU-time micro-kernels can later opt out through a distinct
;;; lane.
(def +poo-flow-performance-serial-test-fragments+
  '("./t/performance/"
    "module-system-poo-performance-test-support/objects-test.ss"))

(def +poo-flow-performance-testing-interface+
  (foldl
   (lambda (fragment testing)
     (testing-interface-map-profile
      testing
      (testing-test-selector 'contains fragment)
      +testing-serial-resource-profile+))
   (poo-flow-testing-observability-extension +asp-testing-interface+)
   +poo-flow-performance-serial-test-fragments+))

(def +poo-flow-performance-test-files+
  (filter
   (lambda (path)
     (or (string-prefix? "./t/performance/" path)
         (string-prefix?
          "./t/module-system-poo-performance-test-support/"
          path)))
   (find-test-files "." "-test.ss$")))

(displayln "[poo-performance-testing] phase=entry-ready")
(force-output)
(testing-interface-run-test-files!
 +poo-flow-performance-testing-interface+
 +poo-flow-performance-test-files+)
