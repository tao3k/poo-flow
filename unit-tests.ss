#!/usr/bin/env gxi
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .cc)
        (only-in :asp-gerbil-scheme/testing-api
                 +asp-testing-interface+
                 +testing-discovery-profile+
                 +testing-process-isolation-profile+
                 +testing-serial-resource-profile+
                 testing-test-selector
                 testing-interface-add-profile
                 testing-interface-map-profile)
        (only-in :asp-gerbil-scheme/testing-runner-api
                 init-profiled-test-environment!)
        (only-in "src/module-system/observability/testing-extension.ss"
                 poo-flow-testing-observability-extension))

(def +poo-flow-serial-test-selectors+
  (map (lambda (fragment) (testing-test-selector 'contains fragment))
       '("module-object-practice-test.ss"
         "module-system-lazy-loader-test.ss"
         "module-system-observability-test.ss"
         ;; This suite deliberately drives a non-returning lazy POO slot until
         ;; the memory monitor contains it.  Give it a fresh native process so
         ;; its heap budget is independent of earlier batch allocations.
         "observability-framework-test.ss")))

;; Each discovered unit is atomic: Gerbil expands and runs it in a fresh
;; process.  This prevents unrelated module families from accumulating syntax
;; and MOP state in one managed heap while ASP still derives concurrency from
;; GERBIL_BUILD_CORES.
(def +poo-flow-atomic-test-selector+
  (testing-test-selector 'contains "-test.ss"))

(def +poo-flow-testing-interface+
  (foldl
    (lambda (selector testing)
      (testing-interface-map-profile
       testing selector +testing-serial-resource-profile+))
    (testing-interface-map-profile
     (testing-interface-add-profile
      (poo-flow-testing-observability-extension +asp-testing-interface+)
      (.cc +testing-discovery-profile+
           ignoreDirectories: '("lambda-episteme"
                                "t/performance"
                                "t/module-system-poo-performance-test-support")))
     +poo-flow-atomic-test-selector+
     +testing-process-isolation-profile+)
    +poo-flow-serial-test-selectors+))

(init-profiled-test-environment! +poo-flow-testing-interface+)
