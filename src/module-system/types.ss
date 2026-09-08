;;; -*- Gerbil -*-
;;; Boundary: POO Flow domain specialization of upstream gerbil-poo types.
;;; Invariant: upstream owns primitive Type validation and prototype dispatch;
;;; this module owns only evidence-bearing POO Flow classification/contracts.

(import (only-in :clan/poo/object
                 .cc
                 .all-slots
                 .o
                 .ref
                 .slot?
                 compute-precedence-list!
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
        PooFlowNativeObjectContract.
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

;; : (-> Object Symbol [Symbol] Boolean)
(def (poo-flow-evidence-object? value expected-kind required-slots)
  (and (object? value)
       (every (cut .slot? value <>) required-slots)
       (eq? (.ref value 'kind) expected-kind)
       (boolean? (.ref value 'accepted?))
       (list? (.ref value 'diagnostics))))

;; : (-> Object Boolean)
(def (poo-flow-type-identity? value)
  (or (symbol? value)
      (and (pair? value)
           (list? value)
           (every poo-flow-type-identity? value))))

;;; Evidence type: accepts only classification receipts with the required typed slots.
(define-type (PooFlowClassificationEvidence @ Type.)
  .element?:
  (lambda (value)
    (and (poo-flow-evidence-object?
          value 'poo-flow.type.classification-evidence
          '(kind type-identity candidate accepted? diagnostics context))
         (poo-flow-type-identity? (.ref value 'type-identity)))))

;;; Evidence type: accepts only validation receipts with the required typed slots.
(define-type (PooFlowValidationEvidence @ Type.)
  .element?:
  (lambda (value)
    (and (poo-flow-evidence-object?
          value 'poo-flow.contract.validation-evidence
          '(kind contract-identity candidate classification obligation-evidence
                 accepted? diagnostics context))
         (symbol? (.ref value 'contract-identity))
         (element? PooFlowClassificationEvidence (.ref value 'classification))
         (list? (.ref value 'obligation-evidence))
         (equal? (.ref value 'candidate)
                 (.ref (.ref value 'classification) 'candidate))
         (equal? (.ref value 'context)
                 (.ref (.ref value 'classification) 'context))
         (eq? (.ref value 'accepted?)
              (and (.ref (.ref value 'classification) 'accepted?)
                   (null? (.ref value 'obligation-evidence)))))))

;; : (-> Object Object Boolean [Alist] Object PooFlowClassificationEvidence)
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
         (_checked
          (unless (and (poo-flow-classification-evidence? classification)
                       (equal? candidate (.ref classification 'candidate))
                       (equal? context (.ref classification 'context)))
            (raise-type-error PooFlowClassificationEvidence classification)))
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
       'sexp identity))

;; : (-> Symbol Procedure Procedure PooFlowContract)
(def (poo-flow-predicate-contract identity predicate obligations)
  (.cc PooFlowContract.
       'identity identity
       '.classify (poo-flow-predicate-classifier identity predicate)
       '.obligations obligations
       'sexp identity))

;;; Object responsibility admission delegates every slot to its native Contract.
;;; The map is a POO value; inherited map slots follow upstream precedence.
(def (poo-flow-responsibility-evidence candidate context responsibilities slot)
  (if (.slot? candidate slot)
    (.cc (poo-flow-contract-admit (.ref responsibilities slot)
                                (.ref candidate slot) context)
         'responsibility slot)
    (let (classification
          (poo-flow-classification-evidence
           (.ref (.ref responsibilities slot) 'identity) #f #f
           (list (.o kind: 'missing-responsibility responsibility: slot)) context))
      (.cc (poo-flow-validation-evidence
            (.ref (.ref responsibilities slot) 'identity) #f classification '()
            #f (.ref classification 'diagnostics) context)
           'responsibility slot))))

(def (poo-flow-object-admit descriptor candidate context)
  (let* ((classification (poo-flow-type-classify descriptor candidate context))
         (_checked
          (unless (and (poo-flow-classification-evidence? classification)
                       (eq? (.ref descriptor 'identity)
                            (.ref classification 'type-identity))
                       (equal? candidate (.ref classification 'candidate))
                       (equal? context (.ref classification 'context)))
            (raise-type-error PooFlowClassificationEvidence classification)))
         (responsibilities (.ref descriptor 'responsibilities))
         (evidence
          (if (poo-flow-classification-evidence-accepted? classification)
            (map (cut poo-flow-responsibility-evidence
                      candidate context responsibilities <>)
                 (.all-slots responsibilities))
            '()))
         (rejections
          (filter (lambda (item)
                    (not (poo-flow-validation-evidence-accepted? item))) evidence))
         (obligations
          (if (and (poo-flow-classification-evidence-accepted? classification)
                   (null? rejections))
            (poo-flow-contract-obligations descriptor candidate context)
            '()))
         (failures (append rejections obligations)))
    (.cc (poo-flow-validation-evidence
          (.ref descriptor 'identity) candidate classification failures
          (and (poo-flow-classification-evidence-accepted? classification)
               (null? failures))
          (append (.ref classification 'diagnostics) failures) context)
         'responsibility-evidence evidence)))

;;; Protocol boundary: responsibility admission walks the descriptor-owned slot map.
(define-type (PooFlowResponsibilityContract. @ PooFlowContract. responsibilities)
  .admit: (cut poo-flow-object-admit @ <> <>))

;;; Domain declarations inherit this native prototype-aware responsibility contract.
(def (poo-flow-native-classify identity proto candidate context)
  (let (accepted?
        (and (object? candidate)
             (if (memq proto (compute-precedence-list! candidate)) #t #f)))
    (poo-flow-classification-evidence
     identity candidate accepted?
     (if accepted? '()
       (list (.o kind: 'prototype-mismatch type-identity: identity))) context)))

;;; Invariant: native objects must prove prototype ancestry before slot obligations run.
(define-type (PooFlowNativeObjectContract. @ PooFlowResponsibilityContract.
                                         identity proto)
  .classify: (cut poo-flow-native-classify identity proto <> <>))
