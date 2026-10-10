;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :clan/poo/object .o .mix .ref)
        (only-in :clan/poo/mop element? validate TypeError?)
        (only-in :std/test test-suite check-equal? check-exception)
        :core/module-system/schema/relations)
(export module-schema-relations-test)

(def module-schema-relations-test
  (test-suite "Core module relations"
    (poo-flow-test-case "identity and directional relations are POO values"
      (let* ((identity (poo-flow-semantic-identity 'test 'module))
             (imports (poo-flow-empty-imports))
             (profiles (poo-flow-empty-profiles))
             (capabilities (poo-flow-empty-capabilities)))
        (check-equal? (element? ModuleIdentityContract identity) #t)
        (check-equal? (element? ModuleImportsContract imports) #t)
        (check-equal? (element? ModuleProfilesContract profiles) #t)
        (check-equal? (element? ModuleImportsContract profiles) #f)
        (check-equal? (element? ModuleCapabilitiesContract capabilities) #t)
        (check-equal? (eq? imports (poo-flow-empty-imports)) #f)
        (check-exception
         (validate ModuleIdentityContract (.o namespace: 'test name: 42))
         TypeError?)))
    (poo-flow-test-case "contributions retain identity hops and lazy targets"
      (let* ((identity (poo-flow-semantic-identity 'test 'module))
             (target (lambda () (error "target was forced")))
             (contribution
              (poo-flow-import-contribution
               identity identity identity identity 'rev target))
             (imports (poo-flow-module-imports contribution)))
        (check-equal? (element? ImportContributionContract contribution) #t)
        (check-equal? (eq? (.ref contribution 'target) target) #t)
        (check-equal? (element? ModuleImportsContract imports) #t)
        (check-equal? (.ref imports 'contributions) (list contribution))))
    (poo-flow-test-case "C4 imports retain every distinct prototype contribution"
      (let* ((base (poo-flow-module-imports 'base))
             (left (.mix (poo-flow-module-imports 'left) base))
             (right (.mix (poo-flow-module-imports 'right) base))
             (combined (.mix left right)))
        (check-equal? (.ref combined 'contributions) '(left right base))))))
