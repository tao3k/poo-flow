;;; -*- Gerbil -*-
;;; Boundary: downstream live CI/CD cases loaded by custom/my-module/config.ss.
;;; Invariant: pure use-* declarations only; src/testing owns execution.

;;; This is a real downstream case, not a profile metadata extension. The user
;;; interface selects sandbox profile supers, then declares isolation
;;; policy, command fields, and runner-local options.
;; : POOObject
(use-module nono-sandbox  
  :inherits ci/build
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
