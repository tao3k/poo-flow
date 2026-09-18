;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: session-owned declaration and case syntax.
;;; Invariant: syntax lowers through session functions and the single module
;;; selection contract without importing the user-interface aggregate.

(import (only-in :clan/poo/object object<-alist)
        (only-in :poo-flow/src/module-system/declaration/contract
                 poo-flow-modules-system-use-module/contract)
        "funs.ss"
        :poo-flow/src/modules/memory-core/durable/policy
        :poo-flow/src/modules/session/agent
        :poo-flow/src/modules/session/agent-param
        :poo-flow/src/modules/session/communication
        :poo-flow/src/modules/session/materialization
        :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/policy
        :poo-flow/src/modules/session/policy-validation
        :poo-flow/src/modules/session/registry
        :poo-flow/src/modules/session/selector
        :poo-flow/src/modules/session/transform
        :poo-flow/src/modules/session/config-session-syntax
        :poo-flow/src/modules/session/config-policy-syntax)

(export (import: "funs.ss")
        (import: :poo-flow/src/modules/memory-core/durable/policy)
        (import: :poo-flow/src/modules/session/agent)
        (import: :poo-flow/src/modules/session/agent-param)
        (import: :poo-flow/src/modules/session/communication)
        (import: :poo-flow/src/modules/session/materialization)
        (import: :poo-flow/src/modules/session/objects)
        (import: :poo-flow/src/modules/session/policy)
        (import: :poo-flow/src/modules/session/policy-validation)
        (import: :poo-flow/src/modules/session/registry)
        (import: :poo-flow/src/modules/session/selector)
        (import: :poo-flow/src/modules/session/transform)
        (import: :poo-flow/src/modules/session/config-session-syntax)
        (import: :poo-flow/src/modules/session/config-policy-syntax)
        poo-flow-session-cases)

(defsyntax (poo-flow-session-cases stx)
  (syntax-case stx (session-case metadata objects rows row-groups)
    ((_ (session-case case-name
          (metadata metadata-entry ...)
          (objects (object-name object-expr) ...)
          (rows row-expr ...)
          (row-groups row-group-expr ...))
        ...)
     (syntax
      (let* ((case-name
              (let* ((object-name object-expr) ...)
                (object<-alist
                 (list
                  (cons 'rows
                        (append (list row-expr ...)
                                row-group-expr ...
                                '()))
                  (cons 'metadata '(metadata-entry ...)))
                 supers: session-config)))
             ...)
        (poo-flow-modules-system-use-module/contract
         'session-core
         (poo-flow-session-core-poo-config-flags
          (list case-name ...)
          '(:config
            (session-case case-name
              (metadata metadata-entry ...)
              (objects (object-name object-expr) ...)
              (rows row-expr ...)
              (row-groups row-group-expr ...))
            ...))))))
    ((_ (session-case case-name
          (metadata metadata-entry ...)
          (objects (object-name object-expr) ...)
          (rows row-expr ...))
        ...)
     (syntax
      (let* ((case-name
              (let* ((object-name object-expr) ...)
                (object<-alist
                 (list
                  (cons 'rows (list row-expr ...))
                  (cons 'metadata '(metadata-entry ...)))
                 supers: session-config)))
             ...)
        (poo-flow-modules-system-use-module/contract
         'session-core
         (poo-flow-session-core-poo-config-flags
          (list case-name ...)
          '(:config
            (session-case case-name
              (metadata metadata-entry ...)
              (objects (object-name object-expr) ...)
              (rows row-expr ...))
            ...))))))))
