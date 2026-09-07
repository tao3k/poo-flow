;;; -*- Gerbil -*-
;;; Boundary: POO Flow domain specialization of upstream gerbil-poo types.
;;; Invariant: upstream owns primitive Type validation and prototype dispatch;
;;; this module owns only evidence-bearing POO Flow classification/contracts.

(import (only-in :clan/poo/object
                 .cc
                 .o
                 .ref
                 .slot?
                 object?)
        (only-in :clan/poo/mop
                 .defgeneric
                 define-type
                 Type
                 Type.
                 element?
                 raise-type-error)
        (only-in :std/srfi/1 every)
        (only-in :std/sugar cut))

(export PooFlowType.
        PooFlowContract.
        PooFlowClassificationEvidence
        PooFlowValidationEvidence
        poo-flow-predicate-type
        poo-flow-predicate-contract
        poo-flow-type-classify
        poo-flow-contract-obligations
        poo-flow-contract-admit
        poo-flow-classification-evidence
        poo-flow-classification-evidence?
        poo-flow-classification-evidence-accepted?
        poo-flow-classification-evidence->alist
        poo-flow-validation-evidence
        poo-flow-validation-evidence?
        poo-flow-validation-evidence-accepted?
        poo-flow-validation-evidence->alist)

;; Open POO protocols dispatch through descriptor slots.  They are intentionally
;; sparse: fixed accessors and final receipt encoders remain ordinary functions.
(.defgeneric (poo-flow-type-classify type candidate context)
  slot: .classify)

;;; Protocol boundary: obligation dispatch stays on the contract descriptor.
(.defgeneric (poo-flow-contract-obligations contract candidate context)
  slot: .obligations)

;;; Protocol boundary: admission returns evidence rather than a bare boolean.
(.defgeneric (poo-flow-contract-admit contract candidate context)
  slot: .admit)

;; : (-> Object Symbol Boolean)
(def (poo-flow-evidence-object? value expected-kind)
  (and (object? value)
       (every (cut .slot? value <>) '(kind accepted? diagnostics))
       (eq? (.ref value 'kind) expected-kind)
       (boolean? (.ref value 'accepted?))
       (list? (.ref value 'diagnostics))))

;;; Evidence type: accepts only classification receipts with the required typed slots.
(define-type (PooFlowClassificationEvidence @ Type.)
  .element?:
  (cut poo-flow-evidence-object?
       <>
       'poo-flow.type.classification-evidence))

;;; Evidence type: accepts only validation receipts with the required typed slots.
(define-type (PooFlowValidationEvidence @ Type.)
  .element?:
  (cut poo-flow-evidence-object?
       <>
       'poo-flow.contract.validation-evidence))

;; : (-> Symbol Object Boolean [Alist] Object PooFlowClassificationEvidence)
(def (poo-flow-classification-evidence type-identity-value candidate-value
                                        accepted-value diagnostics-value
                                        context-value)
  (.o kind: 'poo-flow.type.classification-evidence
      type-identity: type-identity-value
      candidate: candidate-value
      accepted?: (if accepted-value #t #f)
      diagnostics: diagnostics-value
      context: context-value))

;; : (-> Object Boolean)
(def (poo-flow-classification-evidence? value)
  (element? PooFlowClassificationEvidence value))

;; : (-> PooFlowClassificationEvidence Boolean)
(def (poo-flow-classification-evidence-accepted? evidence)
  (and (poo-flow-classification-evidence? evidence)
       (.ref evidence 'accepted?)))

;; : (-> PooFlowClassificationEvidence Alist)
(def (poo-flow-classification-evidence->alist evidence)
  (unless (poo-flow-classification-evidence? evidence)
    (raise-type-error PooFlowClassificationEvidence evidence))
  (list (cons 'kind (.ref evidence 'kind))
        (cons 'type-identity (.ref evidence 'type-identity))
        (cons 'accepted? (.ref evidence 'accepted?))
        (cons 'diagnostics (.ref evidence 'diagnostics))
        (cons 'context (.ref evidence 'context))))

;; : (-> Symbol Object PooFlowClassificationEvidence [Alist] Boolean [Alist] Object PooFlowValidationEvidence)
(def (poo-flow-validation-evidence contract-identity-value candidate-value
                                    classification-value obligation-evidence-value
                                    accepted-value diagnostics-value context-value)
  (.o kind: 'poo-flow.contract.validation-evidence
      contract-identity: contract-identity-value
      candidate: candidate-value
      classification: classification-value
      obligation-evidence: obligation-evidence-value
      accepted?: (if accepted-value #t #f)
      diagnostics: diagnostics-value
      context: context-value))

;; : (-> Object Boolean)
(def (poo-flow-validation-evidence? value)
  (element? PooFlowValidationEvidence value))

;; : (-> PooFlowValidationEvidence Boolean)
(def (poo-flow-validation-evidence-accepted? evidence)
  (and (poo-flow-validation-evidence? evidence)
       (.ref evidence 'accepted?)))

;; : (-> PooFlowValidationEvidence Alist)
(def (poo-flow-validation-evidence->alist evidence)
  (unless (poo-flow-validation-evidence? evidence)
    (raise-type-error PooFlowValidationEvidence evidence))
  (list (cons 'kind (.ref evidence 'kind))
        (cons 'contract-identity (.ref evidence 'contract-identity))
        (cons 'accepted? (.ref evidence 'accepted?))
        (cons 'classification
              (poo-flow-classification-evidence->alist
               (.ref evidence 'classification)))
        (cons 'obligation-evidence (.ref evidence 'obligation-evidence))
        (cons 'diagnostics (.ref evidence 'diagnostics))
        (cons 'context (.ref evidence 'context))))

;; PooFlowType. makes classification the primary operation.  element? and
;; validate remain the upstream Type protocol and are derived from one
;; evidence-bearing classification decision.
;; : (-> PooFlowType Object Boolean)
(def (poo-flow-type-element? type candidate)
  (poo-flow-classification-evidence-accepted?
   (poo-flow-type-classify type candidate #f)))

;; : (-> PooFlowType Object Object)
(def (poo-flow-type-validate type candidate)
  (let (evidence (poo-flow-type-classify type candidate #f))
    (if (poo-flow-classification-evidence-accepted? evidence)
      candidate
      (raise-type-error type candidate (.ref evidence 'diagnostics)))))

;;; Typeclass boundary: derive element and validation behavior from one classification protocol.
(define-type (PooFlowType. @ Type. identity .classify)
  .element?: (cut poo-flow-type-element? @ <>)
  .validate: (cut poo-flow-type-validate @ <>))

;; A Contract is a Type refinement.  Domain values are validated by a Contract;
;; they never inherit from it.  Obligations are pure and return a list of
;; diagnostic facts; an empty list means that every obligation was discharged.
;; : (-> Object Object [Alist])
(def (poo-flow-contract-empty-obligations _candidate _context)
  '())

;; : (-> PooFlowContract Symbol Object Object PooFlowValidationEvidence)
(def (poo-flow-contract-admit-evidence contract identity candidate context)
  (let* ((classification
          (poo-flow-type-classify contract candidate context))
         (classification-ok?
          (poo-flow-classification-evidence-accepted? classification))
         (obligation-evidence
          (if classification-ok?
            (poo-flow-contract-obligations contract candidate context)
            '()))
         (obligations-ok? (null? obligation-evidence))
         (diagnostics
          (append (.ref classification 'diagnostics)
                  obligation-evidence)))
    (poo-flow-validation-evidence
     identity
     candidate
     classification
     obligation-evidence
     (and classification-ok? obligations-ok?)
     diagnostics
     context)))

;; : (-> PooFlowContract Object Boolean)
(def (poo-flow-contract-element? contract candidate)
  (poo-flow-validation-evidence-accepted?
   (poo-flow-contract-admit contract candidate #f)))

;; : (-> PooFlowContract Object Object)
(def (poo-flow-contract-validate contract candidate)
  (let (evidence (poo-flow-contract-admit contract candidate #f))
    (if (poo-flow-validation-evidence-accepted? evidence)
      candidate
      (raise-type-error contract candidate (.ref evidence 'diagnostics)))))

;;; Contract algebra: combine classification with pure obligations into one admission receipt.
(define-type (PooFlowContract. @ PooFlowType.
                               identity .classify .obligations .admit)
  .obligations: poo-flow-contract-empty-obligations
  .admit: (cut poo-flow-contract-admit-evidence @ identity <> <>)
  .element?: (cut poo-flow-contract-element? @ <>)
  .validate: (cut poo-flow-contract-validate @ <>))

;; : (-> Symbol Procedure Procedure)
(def (poo-flow-predicate-classifier identity predicate)
  (lambda (candidate context)
    (let (accepted? (predicate candidate))
      (poo-flow-classification-evidence
       identity
       candidate
       accepted?
       (if accepted?
         '()
         (list
          (.o kind: 'poo-flow.type.classification-failure
              type-identity: identity
              reason: 'predicate-rejected)))
       context))))

;; : (-> Symbol Procedure PooFlowType)
(def (poo-flow-predicate-type identity predicate)
  (.cc PooFlowType.
       'identity identity
       '.classify (poo-flow-predicate-classifier identity predicate)
       '.element? predicate
       '.validate
       (lambda (candidate)
         (if (predicate candidate)
           candidate
           (raise-type-error identity candidate)))
       'sexp identity))

;; : (-> Symbol Procedure Procedure PooFlowContract)
(def (poo-flow-predicate-contract identity predicate obligations)
  (.cc PooFlowContract.
       'identity identity
       '.classify (poo-flow-predicate-classifier identity predicate)
       '.obligations obligations
       'sexp identity))
