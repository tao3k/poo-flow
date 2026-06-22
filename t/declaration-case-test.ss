;;; -*- Gerbil -*-
;;; Boundary: tests verify maintained root declaration cases.
;;; Invariant: cases are downstream declarations and report data, never runtime work.

(import (only-in :std/test
                 check
                 check-eq?
                 check-equal?
                 check-false
                 check-not-equal?
                 check-output
                 check-true
                 run-tests!
                 test-case
                 test-error
                 test-suite)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/facade
        (only-in :poo-flow/user-interface/init
                 poo-flow-user-module-bundles))

(export declaration-case-test)

;; : (-> UserInterfaceEntry Alist MaybeValue)
;; : (-> Unit POOObject)
(def (root-developer-case)
  (pooFlowRootDeveloperDeclarationCase
   (pooFlowRootConfig poo-flow-user-module-bundles)))

;; : (-> Unit TestSuite)
;;; This suite keeps downstream declaration cases declarative while the
;;; upstream module system owns validation.
(def declaration-case-test
  (test-suite "poo-flow declaration cases"
    (test-case "keeps developer case as an explicit root declaration contract"
      (let* ((case-object (root-developer-case))
             (presentation
              (poo-flow-declaration-case-presentation case-object)))
        (check-equal? (poo-flow-declaration-case? case-object) #t)
        (check-equal? (poo-flow-declaration-case-name case-object)
                      'developer)
        (check-equal? (poo-flow-declaration-case-case-file case-object)
                      "src/module-system/declaration-case.ss")
        (check-equal? (poo-flow-declaration-case-init-file case-object)
                      "user-interface/init.ss")
        (check-equal? (poo-flow-declaration-case-custom-module-file
                       case-object)
                      "user-interface/custom/my-module/config.ss")
        (check-equal? (.ref case-object 'declaration-owned?) #t)
        (check-equal? (.ref case-object 'declarative-only?) #t)
        (check-equal? (.ref case-object 'runtime-owner) "marlin-agent-core")
        (check-equal? (.ref case-object 'descriptor-realized?) #f)
        (check-equal? (.ref case-object 'runtime-executed) #f)
        (check-equal? (poo-flow-user-config?
                       (poo-flow-declaration-case-config case-object))
                      #t)
        (check-equal? (.ref presentation 'kind)
                      poo-flow-user-config-presentation-kind)))
    (test-case "presents selected modules and custom entrypoint from the case"
      (let* ((case-object (root-developer-case))
             (presentation
              (poo-flow-declaration-case-presentation case-object))
             (modules (.ref presentation 'modules))
             (custom-module (caddr (cddddr modules)))
             (feature-facts (.ref presentation 'feature-facts))
             (custom-fact (caddr (cddddr feature-facts)))
             (cicd-intent (car (.ref presentation 'cicd-intents))))
        (check-equal? (.ref presentation 'module-count) 7)
        (check-equal? (.ref presentation 'module-keys)
                      (poo-flow-declaration-case-expected-module-keys
                       case-object))
        (check-equal? (.ref presentation 'setting-keys)
                      (poo-flow-declaration-case-expected-setting-keys
                       case-object))
        (check-equal? (poo-flow-declaration-case-alist-value
                       'key
                       custom-module)
                      '(custom . my-module))
        (check-equal? (poo-flow-declaration-case-alist-value
                       'entrypoint
                       custom-module)
                      "./custom/my-module/config.ss")
        (check-equal? (poo-flow-declaration-case-alist-value
                       'flags
                       custom-module)
                      '(+private +doctor))
        (check-equal? (poo-flow-declaration-case-alist-value
                       'declaration-index
                       custom-fact)
                      6)
        (check-equal? (poo-flow-declaration-case-alist-value
                       'declaration-phase
                       custom-fact)
                      'init-selection)
        (check-equal? (poo-flow-declaration-case-alist-value
                       'package-management?
                       custom-fact)
                      #f)
        (check-equal? (poo-flow-declaration-case-alist-value
                       'dependency-installation?
                       custom-fact)
                      #f)
        (check-equal? (poo-flow-declaration-case-alist-value
                       'descriptor-realized?
                       custom-fact)
                      #f)
        (check-equal? (poo-flow-declaration-case-alist-value
                       'loader-executed?
                       custom-fact)
                      #f)
        (check-equal? (poo-flow-declaration-case-alist-value
                       'feature
                       cicd-intent)
                      '+cicd)
        (check-equal? (poo-flow-declaration-case-alist-value
                       'runtime-handoff
                       cicd-intent)
                      'runtime-command-manifest)
        (check-equal? (poo-flow-declaration-case-alist-value
                       'runtime-owner
                       cicd-intent)
                      "marlin-agent-core")
        (check-equal? (poo-flow-declaration-case-alist-value
                       'runtime-executed
                       cicd-intent)
                      #f)
        (check-equal? (.ref presentation 'loop-engine-intent-count) 0)
        (check-equal? (.ref presentation 'loop-engine-intents) '())))
    (test-case "exposes trace observability for the maintained case"
      (let* ((case-object (root-developer-case))
             (presentation
              (poo-flow-declaration-case-presentation case-object))
             (trace (.ref presentation 'presentation-trace)))
        (check-equal? (poo-flow-declaration-case-trace-stages trace)
                      (poo-flow-declaration-case-expected-trace-stages
                       case-object))
        (check-equal? (poo-flow-declaration-case-trace-safe? case-object)
                      #t)
        (check-equal? (poo-flow-declaration-case-presentation-matches?
                       case-object)
                      #t)
        (check-equal? (.ref presentation 'descriptor-realized?) #f)
        (check-equal? (.ref presentation 'runtime-executed) #f)))))

(run-tests! declaration-case-test)
