;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .ref)
        (only-in :std/test check-equal? test-case test-suite)
        :poo-flow/src/module-system/profile-composition/interface
        :poo-flow/src/module-system/profile-composition/accessors
        :poo-flow/src/module-system/loader/collection
        (only-in :poo-flow/src/module-system/loader/source
                 poo-flow-module-source-ref-value)
        (only-in :poo-flow/user-interface/profiles/langchain langchain)
        (only-in :poo-flow/user-interface/scenarios/langchain/scenario
                 langchain-scenario)
        (only-in :poo-flow/user-interface/scenarios/tool-calling-agent-loop/scenario
                 tool-calling-agent-loop-scenario)
        :poo-flow/user-interface/config)

(export user-interface-doom-config-test)

(def user-interface-doom-config-test
  (test-suite
   "Doom-style User Interface roots"
   (test-case
    "config directly composes reusable Profiles across three stages"
    (check-equal?
     (poo-flow-scenario-case? default-agent-control-plane) #t)
    (check-equal?
     (poo-flow-scenario-case-name default-agent-control-plane)
     'default-agent-control-plane)
    (check-equal?
     (length (poo-flow-scenario-case-modules default-agent-control-plane)) 2)
    (check-equal?
     (length (poo-flow-scenario-case-profiles default-agent-control-plane)) 18)
    (check-equal?
     (map poo-flow-scenario-stage-name
          (poo-flow-scenario-case-stages default-agent-control-plane))
     '(development staging production)))
   (test-case
    "Profile and Scenario libraries retain explicit import paths"
    (check-equal? (.ref (.ref langchain 'memory) 'name)
                  'langchain-stateless-memory)
    (check-equal? (poo-flow-scenario-case? langchain-scenario) #t)
    (check-equal? (poo-flow-scenario-case? tool-calling-agent-loop-scenario)
                  #t))
   (test-case
    "custom modules expose one admitted interface entry"
    (let* ((collection
            (make-poo-flow-module-source-collection
             'user-custom 'user "user-interface" "custom"))
           (sources (poo-flow-load-modules collection)))
      (check-equal? (map poo-flow-module-source-ref-value sources)
                    '("user-interface/custom/my-module/interface.ss"))))))
