#!/usr/bin/env gxi
(import (only-in :clan/poo/object .cc)
        (only-in :asp-gerbil-scheme/build-api
                 +asp-testing-interface+
                 +testing-discovery-profile+
                 testing-interface-add-profile
                 init-profiled-test-environment!))

(def +poo-flow-testing-interface+
  (testing-interface-add-profile
   +asp-testing-interface+
   (.cc +testing-discovery-profile+
        ignoreDirectories: '("lambda-episteme"))))

(init-profiled-test-environment! +poo-flow-testing-interface+)
