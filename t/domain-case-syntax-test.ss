;;; -*- Gerbil -*-
;;; Boundary: expansion and runtime checks for DomainCase authoring macros.

(import (only-in :std/test
                 check-equal?
                 check-eq?
                 test-case
                 test-suite)
        :clan/poo/object
        :poo-flow/src/core/object-syntax
        :poo-flow/src/module-system/domain-case
        :poo-flow/src/module-system/domain-case-syntax)

(export domain-case-syntax-test)

(def syntax-parent-role
  (poo-core-role-object
   (slots ((syntax/mode 'parent)))
   (supers)))

(def syntax-child-role
  (poo-core-role-object
   (slots ((syntax/mode 'child)))
   (supers)))

(def syntax-parent-type
  (poo-flow-case-type-contract
   'SyntaxParent '() (lambda (_value) #t)))

(def syntax-child-type
  (poo-flow-case-type-contract
   'SyntaxChild '(SyntaxParent) (lambda (_value) #t)))

(def syntax-runtime-projection
  (poo-flow-case-projection
   'runtime 'syntax-parent 'syntax.runtime.v1
   (lambda (value)
     (list (cons 'mode (.ref value 'syntax/mode))))))

(defpoo-case-component syntax-parent-component syntax-parent 1
  (role syntax-parent-role)
  (type syntax-parent-type)
  (slots)
  (contracts)
  (projections syntax-runtime-projection)
  (parents)
  (policy-algebra 'deny-overrides)
  (strategy-algebra 'route-first-match))

(defpoo-case-component syntax-child-component syntax-child 1
  (role syntax-child-role)
  (type syntax-child-type)
  (slots)
  (contracts)
  (projections)
  (parents syntax-parent)
  (policy-algebra 'deny-overrides)
  (strategy-algebra 'route-first-match))

(def syntax-domain-case-cache
  (poo-flow-domain-case-cache))

(defpoo-domain-case syntax-domain-case syntax-domain-case-closure
  (cache syntax-domain-case-cache)
  (schema syntax.case.v1 1)
  (components syntax-parent-component syntax-child-component)
  (local-overrides)
  (select-projections runtime))

(def syntax-instance-role
  (poo-core-role-object
   (slots ((syntax/instance? #t)))
   (supers)))

(def domain-case-syntax-test
  (test-suite "DomainCase hygienic authoring macros"
    (test-case "binds POO-native component descriptors"
      (check-equal?
       (.ref syntax-parent-component 'component-id)
       'syntax-parent)
      (check-equal?
       (.ref syntax-child-component 'parent-component-ids)
       '(syntax-parent))
      (check-eq?
       (.ref syntax-parent-component 'role-prototype)
       syntax-parent-role)
      (check-eq?
       (.ref syntax-child-component 'type-contract)
       syntax-child-type)
      (check-equal?
       (.ref syntax-parent-component 'projections)
       (list syntax-runtime-projection)))
    (test-case "closes a DomainCase and preserves child precedence"
      (let* ((instance-receipt
              (poo-flow-domain-case-instantiate
               syntax-domain-case syntax-instance-role))
             (instance (.ref instance-receipt 'instance))
             (projection
              (poo-flow-domain-case-project
               syntax-domain-case 'runtime instance)))
        (check-equal? (.ref syntax-domain-case-closure 'accepted?) #t)
        (check-equal? (poo-flow-domain-case? syntax-domain-case) #t)
        (check-equal? (.ref syntax-domain-case 'schema-id) 'syntax.case.v1)
        (check-equal?
         (.ref syntax-domain-case 'selected-projection-ids)
         '(runtime))
        (check-equal?
         (.ref syntax-domain-case 'policy-algebra)
         'deny-overrides)
        (check-equal?
         (.ref syntax-domain-case 'strategy-algebra)
         'route-first-match)
        (check-equal? (.ref instance-receipt 'accepted?) #t)
        (check-equal? (.ref instance 'syntax/mode) 'child)
        (check-equal? (.ref projection 'accepted?) #t)
        (check-equal? (.ref projection 'payload) '((mode . child)))))))
