;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal? check-exception)
        (only-in :clan/poo/object .o .mix .ref .cc)
        (only-in :clan/poo/mop element? validate TypeError?)
        (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :core/module-system/schema/relations
                 poo-flow-semantic-identity poo-flow-module-imports)
        :core/module-system/types
        :core/module-system/objects)

(export module-system-semantic-test)

(def role
  (validate ModuleSourceRoleContract
    (.o (:: @ ModuleSourceRole.) identity: 'test
        recommended-forms: '()
        forbidden-slot-verbs: '()
        forbidden-root-forms: '()
        recursive-root-forms?: #f
        forbidden-imports: '()
        forbidden-forms: '()
        forbid-raw-behavior-hooks?: #f
        forbid-raw-query-initializers?: #f
        repair-operators: '()
        freedom: 'open)))

(def authoring
  (validate ModuleAuthoringProfileContract
    (.o (:: @ ModuleAuthoringProfile.) executor: (.o)
        types: role objects: role funs: role
        config: role interface: role)))

(def module-system-semantic-test
  (test-suite "Core semantic Module owner"
    (poo-flow-test-case "generic constructor requires an admitted authoring Profile"
      (let* ((identity (poo-flow-semantic-identity 'core 'test))
             (left (make-semantic-module identity authoring))
             (right (make-semantic-module identity authoring)))
        (check-equal? (element? SemanticModuleContract left) #t)
        (check-equal? (.ref left 'authoring) authoring)
        (check-equal? (eq? (.ref left 'imports) (.ref right 'imports)) #f)
        (check-equal? (eq? (.ref left 'profiles) (.ref right 'profiles)) #f)
        (check-exception
         (make-semantic-module identity '()) TypeError?)
        (check-exception
         (validate SemanticModuleContract (.cc left 'identity 'invalid))
         TypeError?)))
    (poo-flow-test-case "leaf imports keep identity and C4 composes inherited imports"
      (let* ((identity (poo-flow-semantic-identity 'core 'test))
             (base-imports (poo-flow-module-imports 'base))
             (left-imports (poo-flow-module-imports 'left))
             (right-imports (poo-flow-module-imports 'right))
             (base (make-semantic-module identity authoring
                                         imports: base-imports))
             (left (.mix (make-semantic-module identity authoring
                                               imports: left-imports)
                         base))
             (right (.mix (make-semantic-module identity authoring
                                                imports: right-imports)
                          base))
             (combined (.mix left right)))
        (check-equal? (eq? (.ref base 'imports) base-imports) #t)
        (check-equal? (.ref (.ref combined 'imports) 'contributions)
                      '(left right base))))))
