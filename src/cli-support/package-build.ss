;;; -*- Gerbil -*-
;;; Package build facade used by the thin build.ss entrypoints.

(import (only-in "./package-build-support/options.ss"
                 poo-flow-entry-options)
        (only-in "./package-build-support/engine.ss"
                 poo-flow-clean
                 poo-flow-compile-build-spec
                 poo-flow-gxc-stage
                 poo-flow-gxc-stage/force-on-cache-miss!
                 poo-flow-package-compile)
        (only-in "./package-build-support/specs.ss"
                 +poo-flow-testing-bootstrap-build-spec+
                 +poo-flow-testing-project-build-spec+))

;; : (-> Void)
(import "./package-building.ss")

(def (poo-flow-package-build-testing-project!)
  (poo-flow-package-building-testing-project!))

;; : (-> Void)
(def (poo-flow-package-build-testing-bootstrap!)
  (poo-flow-package-building-testing-bootstrap!))

(def (poo-flow-package-compile options)
  (poo-flow-package-build-run! options))

(export poo-flow-clean
        poo-flow-compile-build-spec
        poo-flow-entry-options
        poo-flow-package-build-testing-bootstrap!
        poo-flow-package-build-testing-project!
        poo-flow-package-compile)
