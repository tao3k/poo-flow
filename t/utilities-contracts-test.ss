;;; -*- Gerbil -*-
;;; Contract: scenario test for shared utilities contract records.

(eval '(import "./src/utilities/contracts.ss"))
(eval '(import "./src/utilities/contract-syntax.ss"))

;; : (-> PooFlowUtilitiesExpr PooFlowUtilitiesValue)
(def (utilities-eval expr)
  (eval expr))

;; : (-> Alist Symbol PooFlowAlistValue)
(def (utilities-test-ref row key)
  (cdr (assq key row)))

(def schema-slot
  (utilities-eval
   '(poo-flow-slot-contract-record
     'utilities.receipt/schema
     'PooFlowUtilitiesReceipt
     'schema
     'String
     'string?
     string?
     #t
     '((boundary . utilities)))))

(unless (utilities-eval
         `(poo-flow-slot-contract? ',schema-slot))
  (error "slot contract should be structured data"))

(let (row
      (utilities-eval
       `(poo-flow-slot-contract->alist ',schema-slot)))
  (unless (and (eq? (utilities-test-ref row 'key)
                    'utilities.receipt/schema)
               (eq? (utilities-test-ref row 'predicate)
                    'string?))
    (error "slot contract projection should preserve key and predicate-key")))

(def receipt-contract
  (utilities-eval
   `(poo-flow-object-type-contract-record
     'utilities/receipt
     'utilities
     'PooFlowUtilitiesReceipt
     (list ',schema-slot)
     '((projection . test)))))

(unless (utilities-eval
         `(poo-flow-object-type-contract? ',receipt-contract))
  (error "object type contract should be structured data"))

(let (row
      (utilities-eval
       `(poo-flow-object-type-contract->alist ',receipt-contract)))
  (unless (and (eq? (utilities-test-ref row 'object-kind)
                    'PooFlowUtilitiesReceipt)
               (pair? (utilities-test-ref row 'slots)))
    (error "object type contract projection should include slots")))

(unless (utilities-eval
         '(and (poo-flow-contract-alist? '((a . 1) (b . 2)))
               (poo-flow-contract-list-of? symbol? '(a b c))))
  (error "shared functional contract helpers should accept valid shapes"))

(when (utilities-eval
       `(with-catch
         (lambda (_failure) #f)
         (lambda ()
           (poo-flow-contract-check-slot! ',schema-slot 42)
           #t)))
  (error "slot contract should reject invalid values"))

(unless (equal? (utilities-eval
                 `(poo-flow-contract-check-slot! ',schema-slot "schema/v1"))
                "schema/v1")
  (error "slot contract should return valid values unchanged"))

(utilities-eval
 '(defcontract-family
    +utilities-macro-slots+
    +utilities-macro-type-contract+
    'utilities/macro
    'utilities
    'PooFlowUtilitiesMacro
    '((projection . test))
    ((+utilities-macro-name-slot+
      'utilities.macro/name
      'name
      'Symbol
      'symbol?
      symbol?
      #t
      '()))))

(unless (utilities-eval
         '(and (pair? +utilities-macro-slots+)
               (poo-flow-object-type-contract?
                +utilities-macro-type-contract+)))
  (error "defcontract-family should generate slot list and object contract"))
