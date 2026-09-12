;;; -*- Gerbil -*-
;;; Generic-function creation and binding-owned configuration evolution.

(import (only-in :clan/poo/object .ref .put!)
        (only-in :clan/poo/mop element?)
        "types.ss" "objects.ss")

(export poo-clos-ensure-generic-function
        poo-clos-reinitialize-generic-function!)

(def +poo-clos-unspecified-generic-option+
  (cons 'poo-clos 'unspecified-generic-option))

;; : (forall (a) (-> a a a))
(def (option-or-current option current)
  (if (eq? option +poo-clos-unspecified-generic-option+) current option))

;; : (-> ClosGenericFunction GenericFunctionOptions ClosGenericFunction)
(def (generic-configuration-template
      current-value required-value rest-value optional-value key-value key-values
      allow-other-keys-value precedence-value combination-value protocol-value)
  (let (lambda-list-value (.ref current-value 'lambda-list))
    (poo-clos-generic-function
     (.ref current-value 'identity)
     (option-or-current required-value (.ref current-value 'required))
     rest?: (option-or-current rest-value (.ref current-value 'rest?))
     optional:
     (option-or-current optional-value (.ref lambda-list-value 'optional))
     key?: (option-or-current key-value (.ref lambda-list-value 'key?))
     keys: (option-or-current key-values (.ref lambda-list-value 'keys))
     allow-other-keys?:
     (option-or-current allow-other-keys-value
                        (.ref lambda-list-value 'allow-other-keys?))
     argument-precedence-order:
     (option-or-current precedence-value
                        (.ref current-value 'argument-precedence-order))
     method-combination:
     (option-or-current combination-value
                        (.ref current-value 'method-combination))
     protocol: (option-or-current protocol-value
                                  (.ref current-value 'protocol)))))

;; : (-> ClosGenericFunction ClosGenericFunction ClosGenericFunction)
(def (admit-existing-methods current-value template-value)
  (for-each (lambda (method-value)
              ;; A detached projection exercises the complete method admission
              ;; contract without violating the original method's sole owner.
              (poo-clos-add-method
               template-value
               (poo-clos-method
                (.ref method-value 'identity)
                (.ref method-value 'specializers)
                (.ref method-value 'body)
                qualifier: (.ref method-value 'qualifier)
                lambda-list: (.ref method-value 'lambda-list))))
            (.ref current-value 'methods))
  (for-each (lambda (field)
              (.put! current-value field (.ref template-value field)))
            '(required rest? argument-precedence-order method-combination
              lambda-list protocol))
  (.put! current-value 'generation (+ 1 (.ref current-value 'generation)))
  current-value)

;; poo-clos-reinitialize-generic-function!
;;   : (-> ClosGenericBinding required: (Maybe Natural)
;;         rest?: (Maybe Boolean) optional: (Maybe Natural)
;;         key?: (Maybe Boolean) keys: (Maybe [InitargName])
;;         allow-other-keys?: (Maybe Boolean)
;;         argument-precedence-order: (Maybe [Natural])
;;         method-combination: (Maybe ClosMethodCombination)
;;         protocol: (Maybe ClosGenericProtocol) ClosGenericFunction)
;;   | contract: validates a complete configuration and every existing method
;;     before mutating the stable ANSI generic-function object.
;;   | doc m%
;;       `poo-clos-reinitialize-generic-function!` attributes mutation to one
;;       explicit generic binding.
;;
;;       # Examples
;;       ```scheme
;;       (poo-clos-reinitialize-generic-function! binding rest?: #t)
;;       ;; => successor-generic
;;       ```
;;
;;       result: the same generic-function identity at its next generation.
;;     %
(def (poo-clos-reinitialize-generic-function!
      binding-value
      required: (required-value +poo-clos-unspecified-generic-option+)
      rest?: (rest-value +poo-clos-unspecified-generic-option+)
      optional: (optional-value +poo-clos-unspecified-generic-option+)
      key?: (key-value +poo-clos-unspecified-generic-option+)
      keys: (key-values +poo-clos-unspecified-generic-option+)
      allow-other-keys?:
      (allow-other-keys-value +poo-clos-unspecified-generic-option+)
      argument-precedence-order:
      (precedence-value +poo-clos-unspecified-generic-option+)
      method-combination:
      (combination-value +poo-clos-unspecified-generic-option+)
      protocol: (protocol-value +poo-clos-unspecified-generic-option+))
  (unless (element? ClosGenericBinding binding-value)
    (clos-fail 'invalid-generic-binding))
  (let* ((current-value (poo-clos-generic-binding-current binding-value))
         (template-value
          (generic-configuration-template
           current-value required-value rest-value optional-value key-value
           key-values allow-other-keys-value precedence-value combination-value
           protocol-value))
         (next-value (admit-existing-methods current-value template-value)))
    (.put! binding-value 'current next-value)
    next-value))

;; : (-> Symbol GenericFunctionOptions ClosGenericFunction)
(def (initial-generic identity-value required-value rest-value optional-value
                      key-value key-values allow-other-keys-value
                      precedence-value combination-value protocol-value)
  (poo-clos-generic-function
   identity-value
   (option-or-current required-value 0)
   rest?: (option-or-current rest-value #f)
   optional: (option-or-current optional-value 0)
   key?: (option-or-current key-value #f)
   keys: (option-or-current key-values '())
   allow-other-keys?: (option-or-current allow-other-keys-value #f)
   argument-precedence-order:
   (if (eq? precedence-value +poo-clos-unspecified-generic-option+)
     #f precedence-value)
   method-combination: (option-or-current combination-value 'standard)
   protocol: (if (eq? protocol-value +poo-clos-unspecified-generic-option+)
               #f protocol-value)))

;; poo-clos-ensure-generic-function
;;   : (-> Symbol existing: (Maybe GenericSource)
;;         required: (Maybe Natural) GenericFunctionOptions ClosGenericBinding)
;;   | contract: creates a binding when absent or reconfigures an existing
;;     binding only through its checked immutable successor transition.
;;   | doc m%
;;       `poo-clos-ensure-generic-function` is the explicit Scheme adaptation of
;;       ANSI `ensure-generic-function`; it returns the POO mutation owner.
;;
;;       # Examples
;;       ```scheme
;;       (poo-clos-ensure-generic-function 'route required: 2)
;;       ;; => route-binding
;;       ```
;;
;;       result: a POO generic binding accepted by ordinary dispatch.
;;     %
(def (poo-clos-ensure-generic-function
      identity-value
      existing: (existing-value #f)
      required: (required-value +poo-clos-unspecified-generic-option+)
      rest?: (rest-value +poo-clos-unspecified-generic-option+)
      optional: (optional-value +poo-clos-unspecified-generic-option+)
      key?: (key-value +poo-clos-unspecified-generic-option+)
      keys: (key-values +poo-clos-unspecified-generic-option+)
      allow-other-keys?:
      (allow-other-keys-value +poo-clos-unspecified-generic-option+)
      argument-precedence-order:
      (precedence-value +poo-clos-unspecified-generic-option+)
      method-combination:
      (combination-value +poo-clos-unspecified-generic-option+)
      protocol: (protocol-value +poo-clos-unspecified-generic-option+))
  (unless (or (symbol? identity-value)
              (and (list? identity-value) (= (length identity-value) 2)
                   (eq? (car identity-value) 'setf)
                   (symbol? (cadr identity-value))))
    (clos-fail 'invalid-generic-name generic: identity-value))
  (if existing-value
    (let (binding-value
          (if (element? ClosGenericBinding existing-value)
            existing-value
            (poo-clos-generic-binding identity-value existing-value)))
      (unless (equal? identity-value (.ref binding-value 'identity))
        (clos-fail 'generic-binding-identity-mismatch
                   generic: identity-value))
      (poo-clos-reinitialize-generic-function!
       binding-value required: required-value rest?: rest-value
       optional: optional-value key?: key-value keys: key-values
       allow-other-keys?: allow-other-keys-value
       argument-precedence-order: precedence-value
       method-combination: combination-value protocol: protocol-value)
      binding-value)
    (poo-clos-generic-binding
     identity-value
     (initial-generic
      identity-value required-value rest-value optional-value key-value
      key-values allow-other-keys-value precedence-value combination-value
      protocol-value))))
