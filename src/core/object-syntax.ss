;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: hygienic macros for repeated core POO role objects.
;;; Invariant: generated code is ordinary role-backed POO object construction;
;;; public descriptor and registry APIs remain in their owner modules.

(import (only-in :clan/poo/object object<-alist))

(export poo-core-role-object)

;;; Role-object expansion is the public POO prototype construction boundary.
;; poo-core-role-object
;; : (-> Syntax Syntax Syntax Syntax Syntax)
;; | type RoleSlotRowsSyntax = Syntax
;; | type RoleSupersSyntax = Syntax
;; | type RoleObjectSyntax = Syntax
;; | contract: accepts literal slot rows or a row expression plus zero or more supers
;; | warning: inheritance remains owned by gerbil-poo `object<-alist`; this macro only prepares syntax
;; | doc m%
;;   Builds a POO role object from constant slots and parent prototypes.
;;   # Examples
;;   ```scheme
;;   (poo-core-role-object (slots ((kind 'worker))) (supers base-role))
;;   ;; => a POO object mixed from `base-role` with a `kind` slot
;;   ```
(defrules poo-core-role-object
  (slots slot-rows supers)
  ((_ (slots ((slot-key slot-value) ...))
      (supers super ...))
   (object<-alist (list (cons 'slot-key slot-value) ...)
                  supers: (list super ...)))
  ((_ (slot-rows slot-rows-expr)
      (supers super ...))
   (object<-alist slot-rows-expr supers: (list super ...))))
