;;; -*- Gerbil -*-
;;; Boundary: hygienic macros for repeated core POO role objects.
;;; Invariant: generated code is ordinary role-backed POO object construction;
;;; public descriptor and registry APIs remain in their owner modules.

(import (only-in :clan/poo/object .mix)
        :poo-flow/src/core/roles)

(export poo-core-role-object)

;; poo-core-role-object
;;   : internal expression macro for fixed role-backed POO object frames.
;;     The call site owns the domain binding, constructor parameters, slots,
;;     and supers. This macro removes only the repeated `.mix` /
;;     `role-constant-slots` / alist-slot boilerplate.
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
