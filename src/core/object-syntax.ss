;;; -*- Gerbil -*-
;;; Boundary: hygienic macros for repeated core POO role objects.
;;; Invariant: generated code is ordinary role-backed POO object construction;
;;; public descriptor and registry APIs remain in their owner modules.

(import (only-in :clan/poo/object .mix)
        :poo-flow/src/core/roles)

(export poo-core-role-object)

;;; Role-object expansion is the public POO prototype construction boundary.
;; poo-core-role-object
;; : (-> Syntax Syntax Syntax Syntax Syntax)
;; | type RoleSlotRowsSyntax = Syntax
;; | type RoleSupersSyntax = Syntax
;; | type RoleObjectSyntax = Syntax
;; | contract: accepts literal slot rows or a row expression plus zero or more supers
;; | warning: keep inheritance semantics in `.mix`; this macro only prepares slots
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
   (.mix slots: (role-constant-slots
                 (list (cons 'slot-key slot-value) ...))
         super ...))
  ((_ (slot-rows slot-rows-expr)
      (supers super ...))
   (.mix slots: (role-constant-slots slot-rows-expr)
         super ...)))
