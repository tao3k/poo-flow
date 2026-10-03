;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; Independently authored vertical fixtures; neither contributes core code.
(import :poo-flow/modules/temporal-causality/behavior/interface)
(export medication-model software-release-model)
(def (medication-model interventions)
  (poo-flow-temporal-behavior-model
   "medication"
   (list (poo-flow-temporal-state-variable "prescription" '("none" "issued") "none")
         (poo-flow-temporal-state-variable "administration" '("none" "given") "none")
         (poo-flow-temporal-state-variable "control-measurement" '("baseline" "changed") "baseline"))
   (list (poo-flow-temporal-mechanism
          "prescribe" '() (list (poo-flow-temporal-assignment "order" "prescription" "issued")) "scenario-order-assumption")
         (poo-flow-temporal-mechanism
          "administer" (list (poo-flow-temporal-condition "order-required" "prescription" "issued"))
          (list (poo-flow-temporal-assignment "dose" "administration" "given")) "scenario-administration-assumption"))
   interventions 2))
(def (software-release-model interventions)
  (poo-flow-temporal-behavior-model
   "software-release"
   (list (poo-flow-temporal-state-variable "commit" '("absent" "built") "absent")
         (poo-flow-temporal-state-variable "canary" '("unverified" "verified") "unverified")
         (poo-flow-temporal-state-variable "deployment" '("old" "new") "old")
         (poo-flow-temporal-state-variable "protected-service" '("stable" "changed") "stable"))
   (list (poo-flow-temporal-mechanism
          "build" '() (list (poo-flow-temporal-assignment "build-write" "commit" "built")) "build-assumption")
         (poo-flow-temporal-mechanism
          "verify-canary" (list (poo-flow-temporal-condition "build-required" "commit" "built"))
          (list (poo-flow-temporal-assignment "canary-write" "canary" "verified")) "verification-assumption")
         (poo-flow-temporal-mechanism
          "deploy" (list (poo-flow-temporal-condition "canary-required" "canary" "verified"))
          (list (poo-flow-temporal-assignment "deployment-write" "deployment" "new")) "deployment-assumption"))
   interventions 3))
