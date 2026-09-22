#!/usr/bin/env gxi
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(export main)

(import (only-in :clan/poo/object .cc)
        (only-in :std/cli/multicall call-entry-point)
        (only-in :asp-gerbil-scheme/testing-api
                 +asp-testing-interface+
                 +testing-discovery-profile+
                 +testing-memory-profile+
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

(def +poo-flow-testing-interface+
  (foldl
    (lambda (selector testing)
      (testing-interface-map-profile
       testing selector +testing-serial-resource-profile+))
    (testing-interface-add-profile
      (poo-flow-testing-observability-extension
       (testing-interface-add-profile
        +asp-testing-interface+
        (.cc +testing-memory-profile+ maxHeapMiB: 1024)))
      (.cc +testing-discovery-profile+
           ignoreDirectories: '("packages/lambda-episteme"
                                "packages/lambda-aitia"
                                "t/performance"
                                ;; This external qualification requires the
                                ;; explicitly pinned FHIR Validator JAR and is
                                ;; owned by `just check-healthcare-fhir-reference-validator`.
                                "t/qualification/healthcare-fhir-reference-validator"
                                ;; Healthcare parser and migration assurance
                                ;; qualifications inject their pinned
                                ;; gerbil-parser and Lambda Episteme loadpaths
                                ;; through dedicated Just gates.
                                "t/qualification/healthcare-fhirpath-syntax"
                                "t/qualification/healthcare-hl7v2-migration"
                                "t/qualification/healthcare-standard-migration-assurance"
                                "t/qualification/standards-multi-industry"
                                "t/module-system-poo-performance-test-support")))
    +poo-flow-serial-test-selectors+))

(init-profiled-test-environment! +poo-flow-testing-interface+)

;; The ASP declaration installs the selected entry point.  V19's script
;; launcher looks up a caller-visible `main`, so expose that trampoline here.
(def (main . args)
  (apply call-entry-point args))
