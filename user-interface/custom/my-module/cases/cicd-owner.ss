;;; -*- Gerbil -*-
;;; Boundary: focused custom CI/CD and introspection scenario owner.
;;; Invariant: scenario declarations stay separate from the full custom module
;;; facade so tests and imports do not compile every user-interface case.

(import :poo-flow/src/user-interface/init-syntax
        :poo-flow/user-interface/custom/my-module/profiles/all)

(export poo-flow-custom-my-module-cicd-case
        poo-flow-custom-my-module-cicd-module
        poo-flow-custom-my-module-funflow-cicd-case)

(load! "cicd")
(load! "funflow-cicd")
(load! "poo-introspection")
