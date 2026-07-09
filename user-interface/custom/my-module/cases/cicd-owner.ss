;;; -*- Gerbil -*-
;;; Boundary: focused custom CI/CD and introspection scenario owner.
;;; Invariant: scenario declarations stay separate from the full custom module
;;; facade so tests and imports do not compile every user-interface case.

(import :poo-flow/src/module-system/init-syntax
        :poo-flow/user-interface/custom/my-module/profiles/all)

(load! "cicd")
(load! "funflow-cicd")
(load! "poo-introspection")
