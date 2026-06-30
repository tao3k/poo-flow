;;; -*- Gerbil -*-
;;; Boundary: hygienic macros for repeated session policy object families.
;;; Invariant: macros expand to ordinary public constructors over POO-native
;;; session policy objects. They are internal generation helpers, not a user DSL.

(import :poo-flow/src/modules/session/objects)

(export defpoo-session-policy-family)

;; defpoo-session-policy-family
;;   : internal syntax generator for a session policy constructor family.
;;     The call site supplies the base constructor, contract symbols, parameter
;;     names, slot projection keys, and runtime validations. Expansion remains
;;     plain Scheme code that calls =poo-flow-session-policy-object=.
(defrules defpoo-session-policy-family
  (kind schema default-action scope-ref parameters slots validate)
  ((_ constructor policy-object
      (kind kind-expr)
      (schema schema-expr)
      (default-action default-action-expr)
      (scope-ref scope-ref-expr)
      (parameters (policy-name arg ... . maybe-metadata))
      (slots ((slot-key slot-value) ...))
      (validate validation ...))
   (def (constructor policy-name arg ... . maybe-metadata)
     validation ...
     (apply policy-object
            kind-expr
            schema-expr
            policy-name
            scope-ref-expr
            default-action-expr
            (list (cons slot-key slot-value) ...)
            maybe-metadata)))
  ((_ constructor policy-object
      (kind kind-expr)
      (schema schema-expr)
      (default-action default-action-expr)
      (parameters (policy-name scope-ref-param arg ... . maybe-metadata))
      (slots ((slot-key slot-value) ...))
      (validate validation ...))
   (def (constructor policy-name scope-ref-param arg ... . maybe-metadata)
     validation ...
     (apply policy-object
            kind-expr
            schema-expr
            policy-name
            scope-ref-param
            default-action-expr
            (list (cons slot-key slot-value) ...)
            maybe-metadata))))
