#!/usr/bin/env gxi
;; -*- Gerbil -*-
;;; Build file for the POO Flow Gerbil runtime package.
;;; The runtime package root is the repository root, matching imports such as :poo-flow/src/core/roles.

(import :clan/building)

;;; clan/building owns package build-environment initialization and compilation.
;;; Non-module practice fragments stay out of the package build and are loaded
;;; through the user-interface macros that own them.
(def (spec)
  (append
   (all-gerbil-modules
    exclude: [default-exclude ...
              "src/cli.ss"
              "version.ss"
              "user-interface/custom/my-module/profiles/cicd.ss"
              "user-interface/custom/my-module/profiles/object-extension.ss"
              "user-interface/custom/my-module/profiles/session.ss"
              "user-interface/custom/my-module/profiles/task.ss"]
    exclude-dirs: ["run"
                   ".git"
                   "_darcs"
                   ".gerbil"
                   ".data"
                   "docs"
                   "harness-policy"])
   '((exe: "src/cli" bin: "poo-flow"))))

(init-build-environment!
 deps: '("gerbil-poo"
         "gerbil-scheme-language-project-harness")
 spec: spec)
