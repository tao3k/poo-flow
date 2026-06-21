;;; -*- Gerbil -*-
;;; Boundary: Gerbil language project harness policy owned by poo-flow.
;;; This file supplies package-specific thresholds; default harness policies
;;; remain enabled for every .ss file covered by gerbil.pkg source-scope.

(modularity-policy
 max-source-lines: 2300
 max-test-lines: 700
 explanation: "poo-flow keeps module-system facade owners consolidated while the POO module API is still settling; default harness policies still cover every package .ss file.")
