;;; -*- Gerbil -*-
;;; Boundary: tests verify maintained root user-interface cases.
;;; Invariant: cases are downstream declarations and report data, never runtime work.

(import :std/test
        (only-in :clan/poo/object .ref)
        :modules/module-system
        (only-in :poo-flow/user-interface/init
                 poo-flow-user-module-bundles))

(export user-interface-case-test)

;; : (-> UserInterfaceEntry Alist MaybeValue)
;; : (-> Unit POOObject)
(def (root-developer-case)
  (pooFlowRootUserInterfaceDeveloperCase
   (pooFlowUserInterfaceConfig poo-flow-user-module-bundles)))

;; : (-> Unit TestSuite)
(def user-interface-case-test
  (test-suite "poo-flow user interface cases"
    (test-case "keeps developer case as an explicit root user-interface contract"
      (let* ((case-object (root-developer-case))
             (presentation
              (poo-flow-user-interface-case-presentation case-object)))
        (check-equal? (poo-flow-user-interface-case? case-object) #t)
        (check-equal? (poo-flow-user-interface-case-name case-object)
                      'developer)
        (check-equal? (poo-flow-user-interface-case-case-file case-object)
                      "src/modules/user-interface-case.ss")
        (check-equal? (poo-flow-user-interface-case-init-file case-object)
                      "user-interface/init.ss")
        (check-equal? (poo-flow-user-interface-case-custom-module-file
                       case-object)
                      "user-interface/custom/my-module/config.ss")
        (check-equal? (.ref case-object 'user-interface-owned?) #t)
        (check-equal? (.ref case-object 'declarative-only?) #t)
        (check-equal? (.ref case-object 'runtime-owner) "marlin-agent-core")
        (check-equal? (.ref case-object 'descriptor-realized?) #f)
        (check-equal? (.ref case-object 'runtime-executed) #f)
        (check-equal? (poo-flow-user-config?
                       (poo-flow-user-interface-case-config case-object))
                      #t)
        (check-equal? (.ref presentation 'kind)
                      poo-flow-user-config-presentation-kind)))
    (test-case "presents selected modules and custom entrypoint from the case"
      (let* ((case-object (root-developer-case))
             (presentation
              (poo-flow-user-interface-case-presentation case-object))
             (modules (.ref presentation 'modules))
             (custom-module (car (cddddr modules)))
             (feature-facts (.ref presentation 'feature-facts))
             (custom-fact (car (cddddr feature-facts)))
             (cicd-intent (car (.ref presentation 'cicd-intents))))
        (check-equal? (.ref presentation 'module-count) 5)
        (check-equal? (.ref presentation 'module-keys)
                      (poo-flow-user-interface-case-expected-module-keys
                       case-object))
        (check-equal? (.ref presentation 'setting-keys)
                      (poo-flow-user-interface-case-expected-setting-keys
                       case-object))
        (check-equal? (poo-flow-user-interface-case-alist-value
                       'key
                       custom-module)
                      '(custom . my-module))
        (check-equal? (poo-flow-user-interface-case-alist-value
                       'entrypoint
                       custom-module)
                      "./custom/my-module/config.ss")
        (check-equal? (poo-flow-user-interface-case-alist-value
                       'flags
                       custom-module)
                      '(+private +doctor))
        (check-equal? (poo-flow-user-interface-case-alist-value
                       'declaration-index
                       custom-fact)
                      4)
        (check-equal? (poo-flow-user-interface-case-alist-value
                       'declaration-phase
                       custom-fact)
                      'init-selection)
        (check-equal? (poo-flow-user-interface-case-alist-value
                       'package-management?
                       custom-fact)
                      #f)
        (check-equal? (poo-flow-user-interface-case-alist-value
                       'dependency-installation?
                       custom-fact)
                      #f)
        (check-equal? (poo-flow-user-interface-case-alist-value
                       'descriptor-realized?
                       custom-fact)
                      #f)
        (check-equal? (poo-flow-user-interface-case-alist-value
                       'loader-executed?
                       custom-fact)
                      #f)
        (check-equal? (poo-flow-user-interface-case-alist-value
                       'feature
                       cicd-intent)
                      '+cicd)
        (check-equal? (poo-flow-user-interface-case-alist-value
                       'runtime-handoff
                       cicd-intent)
                      'runtime-command-manifest)
        (check-equal? (poo-flow-user-interface-case-alist-value
                       'runtime-owner
                       cicd-intent)
                      "marlin-agent-core")
        (check-equal? (poo-flow-user-interface-case-alist-value
                       'runtime-executed
                       cicd-intent)
                      #f)))
    (test-case "exposes trace observability for the maintained case"
      (let* ((case-object (root-developer-case))
             (presentation
              (poo-flow-user-interface-case-presentation case-object))
             (trace (.ref presentation 'presentation-trace)))
        (check-equal? (poo-flow-user-interface-case-trace-stages trace)
                      (poo-flow-user-interface-case-expected-trace-stages
                       case-object))
        (check-equal? (poo-flow-user-interface-case-trace-safe? case-object)
                      #t)
        (check-equal? (poo-flow-user-interface-case-presentation-matches?
                       case-object)
                      #t)
        (check-equal? (.ref presentation 'descriptor-realized?) #f)
        (check-equal? (.ref presentation 'runtime-executed) #f)))))

(run-tests! user-interface-case-test)
