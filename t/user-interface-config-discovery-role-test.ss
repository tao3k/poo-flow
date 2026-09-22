;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :poo-flow/src/user-interface/config-discovery-funs
                 poo-flow-ui-scenario-declaration?))

(export user-interface-config-discovery-role-test)

(def user-interface-config-discovery-role-test
  (test-suite "User Interface config discovery role boundary"
    (test-case "Scenario declaration and Profiles are discoverable"
      (check-equal?
       (poo-flow-ui-scenario-declaration?
        "/user-interface/scenarios/software-delivery/scenario.ss") #t)
      (check-equal?
       (poo-flow-ui-scenario-declaration?
        "/user-interface/scenarios/software-delivery/profiles/base.ss") #t)
      (check-equal?
       (poo-flow-ui-scenario-declaration?
        "/user-interface/scenarios/software-delivery/profiles/releases/production.ss") #t))
    (test-case "Cases and support projections stay demand-loaded"
      (check-equal?
       (poo-flow-ui-scenario-declaration?
        "/user-interface/scenarios/software-delivery/cases/example/case.ss") #f)
      (check-equal?
       (poo-flow-ui-scenario-declaration?
        "/user-interface/scenarios/software-delivery/assurance.ss") #f)
      (check-equal?
       (poo-flow-ui-scenario-declaration?
        "/user-interface/scenarios/software-delivery/README.org") #f))))
