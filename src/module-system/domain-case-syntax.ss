;;; -*- Gerbil -*-
;;; Boundary: internal hygienic authoring forms for CaseComponent/DomainCase.
;;; Invariant: expansion produces ordinary POO objects and functional closure.

(import :clan/poo/object
        :poo-flow/src/module-system/domain-case)

(export defpoo-case-component
        defpoo-domain-case)

;; defpoo-case-component
;;   : (-> Identifier Identifier VersionExpr Clauses CaseComponentBinding)
;;   | doc m%
;;       Bind one module-owned CaseComponent without exposing constructor
;;       argument order as the ordinary authoring surface.  Clause order is
;;       fixed deliberately so malformed or incomplete declarations fail at
;;       macro expansion.  Every referenced role, type, slot contract, method
;;       contract, and projection remains an ordinary POO object.
;;     %
(defrules defpoo-case-component
  (role type slots contracts projections parents policy-algebra
        strategy-algebra)
  ((_ binding component-id component-version
      (role role-prototype)
      (type type-contract)
      (slots slot-contract ...)
      (contracts method-contract ...)
      (projections projection ...)
      (parents parent-component-id ...)
      (policy-algebra policy-algebra-value)
      (strategy-algebra strategy-algebra-value))
   (def binding
     (poo-flow-case-component
      'component-id
      component-version
      role-prototype
      type-contract
      (list slot-contract ...)
      (list method-contract ...)
      (list projection ...)
      (list 'parent-component-id ...)
      policy-algebra-value
      strategy-algebra-value))))

;; defpoo-domain-case
;;   : (-> Identifier Identifier Clauses DomainCaseBindings)
;;   | doc m%
;;       Close already-built CaseComponents at module instantiation and bind
;;       both the resulting DomainCase and its fail-closed receipt.  The macro
;;       owns declaration shape only; closure, diagnostics, caching, and POO
;;       composition remain runtime functions.
;;     %
(defrules defpoo-domain-case
  (cache schema components local-overrides select-projections)
  ((_ case-binding closure-receipt-binding
      (cache cache-value)
      (schema schema-id schema-version)
      (components component ...)
      (local-overrides local-override ...)
      (select-projections projection-id ...))
   (begin
     (def closure-receipt-binding
       (poo-flow-domain-case-close
        cache-value
        'schema-id
        schema-version
        (list component ...)
        (list local-override ...)
        (list 'projection-id ...)))
     (def case-binding
       (.ref closure-receipt-binding 'domain-case)))))
