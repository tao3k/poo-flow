#!/usr/bin/env gxi
(import (only-in :clan/poo/object .cc)
        (only-in :asp-gerbil-scheme/testing-api
                 +asp-testing-interface+
                 +testing-discovery-profile+
                 +testing-serial-resource-profile+
                 testing-test-selector
                 testing-interface-add-profile
                 testing-interface-map-profile
                 init-profiled-test-environment!))

(def +poo-flow-serial-test-selectors+
  (map (lambda (fragment) (testing-test-selector 'contains fragment))
       '("module-object-practice-test.ss"
         "module-system-lazy-loader-test.ss"
         "module-system-observability-test.ss")))

(def +poo-flow-testing-interface+
  (foldl
    (lambda (selector testing)
      (testing-interface-map-profile
       testing selector +testing-serial-resource-profile+))
    (testing-interface-add-profile
     +asp-testing-interface+
     (.cc +testing-discovery-profile+
          ignoreDirectories: '("lambda-episteme"
                               "t/performance"
                               "t/module-system-poo-performance-test-support")))
    +poo-flow-serial-test-selectors+))

(init-profiled-test-environment! +poo-flow-testing-interface+)
