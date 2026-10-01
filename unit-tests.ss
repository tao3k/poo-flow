#!/usr/bin/env gxi
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(export main)

(import (only-in :clan/poo/object .cc)
        (only-in :std/cli/multicall call-entry-point)
        (only-in :asp-gerbil-scheme/testing-api
                 +testing-discovery-profile+
                 +testing-process-isolation-profile+
                 +testing-serial-resource-profile+
                 testing-test-selector
                 testing-interface-add-profile
                 testing-interface-map-profile)
        (only-in :asp-gerbil-scheme/testing-runner-api
                 init-profiled-test-environment!)
        (only-in :poo-flow/testing-api
                 +poo-flow-testing-interface+))

(def +poo-flow-serial-test-selectors+
  (map (lambda (fragment) (testing-test-selector 'contains fragment))
       '("module-object-practice-test.ss"
         "module-system-lazy-loader-test.ss"
         "module-system-observability-test.ss")))

;; This suite deliberately drives a non-returning lazy POO slot and a bounded
;; retained-allocation Case. Its heap budget must be independent of earlier
;; files, while ordinary tests still share their native worker processes.
(def +poo-flow-isolated-test-selectors+
  (list (testing-test-selector 'contains "observability-framework-test.ss")))

(def +poo-flow-serial-testing-interface+
  (foldl
    (lambda (selector testing)
      (testing-interface-map-profile
       testing selector +testing-serial-resource-profile+))
    (testing-interface-add-profile
      +poo-flow-testing-interface+
      (.cc +testing-discovery-profile+
           ignoreDirectories: '("packages/lambda-episteme"
                                "packages/lambda-aitia"
                                "core"
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

(def +poo-flow-project-testing-interface+
  (foldl
   (lambda (selector testing)
     (testing-interface-map-profile
      testing selector +testing-process-isolation-profile+))
   +poo-flow-serial-testing-interface+
   +poo-flow-isolated-test-selectors+))

(init-profiled-test-environment! +poo-flow-project-testing-interface+)

;; The ASP declaration installs the selected entry point.  V19's script
;; launcher looks up a caller-visible `main`, so expose that trampoline here.
(def (main . args)
  (apply call-entry-point args))
