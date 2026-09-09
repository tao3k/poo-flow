;;; -*- Gerbil -*-
;;; Boundary: modules enabled by the upstream kernel profile.
;;; Invariant: every module owns its default flags and bundle in config.ss;
;;; this profile only composes those module-owned values.

(import (only-in "../../modules/poo-method-combination/config.ss"
                 poo-method-combination-module-bundles)
        (only-in "../../modules/funflow/config.ss"
                 poo-flow-funflow-cicd-default-payload
                 poo-flow-funflow-module-bundles
                 poo-upstream-flow-funflow-module-bundles)
        (only-in "../../modules/session-core/config.ss"
                 +poo-flow-session-core-default-flags+
                 poo-flow-session-core-module-bundles)
        (only-in "../../modules/governor/config.ss"
                 poo-flow-loop-governor-module-bundles)
        (only-in "../../modules/nono-sandbox/config.ss"
                 poo-flow-nono-sandbox-module-bundles)
        (only-in "../../modules/cubeSandbox/config.ss"
                 poo-flow-cubeSandbox-module-bundles)
        (only-in "../../modules/docker-sandbox/config.ss"
                 poo-flow-docker-sandbox-module-bundles))

(export poo-flow-funflow-cicd-default-payload
        poo-method-combination-module-bundles
        poo-flow-kernel-module-bundles
        poo-flow-funflow-module-bundles
        poo-upstream-flow-funflow-module-bundles
        +poo-flow-session-core-default-flags+
        poo-flow-session-core-module-bundles
        poo-flow-loop-governor-module-bundles
        poo-flow-nono-sandbox-module-bundles
        poo-flow-cubeSandbox-module-bundles
        poo-flow-docker-sandbox-module-bundles)

(def poo-flow-kernel-module-bundles
  (append poo-method-combination-module-bundles
          poo-flow-funflow-module-bundles
          poo-flow-session-core-module-bundles
          poo-flow-loop-governor-module-bundles
          poo-flow-nono-sandbox-module-bundles
          poo-flow-cubeSandbox-module-bundles
          poo-flow-docker-sandbox-module-bundles))
