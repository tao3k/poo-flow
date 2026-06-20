;;; -*- Gerbil -*-
;;; Boundary: downstream live CI/CD cases loaded by custom/my-module/config.ss.
;;; Invariant: pure use-* declarations only; src/testing owns execution.

;;; This is a real downstream case, not a profile metadata extension. The user
;;; interface declares the sandbox profile, isolation policy, and build command;
;;; src/testing is responsible for interpreting those fields.
;; : POOObject
(use-live-case current-system-build
  :module poo-flow-custom-my-module-cicd-module
  :profile ci/build
  :isolation
  ((mode . project-copy)
   (project-mount . isolated-copy)
   (source . ".")
   (root-env . "TMPDIR")
   (root . "poo-flow-live-case/current-system-build")
   (workspace . "workspace")
   (home . ".home")
   (exclude . (".git" ".tmp" ".cache" "run")))
  :environment
  ((policy . whitelist)
   (enabled-env . "POO_FLOW_LIVE_CICD_BUILD")
   (clear-env . ("POO_FLOW_LIVE_CICD_BUILD")))
  :command
  ((program . "gxpkg")
   (args . ("build")))
  :nono
  ((network . blocked)
   (audit . disabled)))
