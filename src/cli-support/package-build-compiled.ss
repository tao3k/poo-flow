;;; -*- Gerbil -*-
;;; Warm package build facade loaded after package-build-support modules compile.

(import (only-in :poo-flow/src/cli-support/package-build-support/options
                 poo-flow-entry-options)
        (only-in :poo-flow/src/cli-support/package-build-support/engine
                 poo-flow-clean
                 poo-flow-compile-build-spec
                 poo-flow-gxc-stage
                 poo-flow-gxc-stage/force-on-cache-miss!
                 poo-flow-package-compile)
        (only-in :poo-flow/src/cli-support/package-build-support/specs
                 +poo-flow-testing-bootstrap-build-spec+
                 +poo-flow-testing-project-build-spec+))

;; : (-> Void)
(import :poo-flow/src/cli-support/package-building)

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
