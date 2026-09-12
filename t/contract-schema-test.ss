;;; -*- Gerbil -*-
;;; Contract: shared slot schemas and Contracts are native POO Type values.

(import :std/test)

(def (contract-schema-eval expr)
  (eval expr))

(def (contract-schema-test-ref row key)
  (cdr (assq key row)))

(export contract-schema-test)

(def contract-schema-test
  (test-suite "contract-schema-test"
    (test-case "validates the native contract"
      (eval '(import "./src/module-system/descriptor/contracts.ss"))
      (eval '(import :clan/poo/object :clan/poo/mop))
      (contract-schema-eval
 '(begin
    (def +contract-schema-fixture-slot+
      (poo-flow-contract-slot
       'contract-schema.fixture/schema
       'schema
       (poo-flow-contract-value-type 'String string? 'String 'string?)
       #t
       '((boundary . contract-schema))))
    (def +contract-schema-fixture-contract+
      (poo-flow-native-contract
       'contract-schema/fixture
       'module-system
       'PooFlowContractSchemaFixture
       object?
       (list +contract-schema-fixture-slot+)
       (lambda (candidate slot) (.slot? candidate slot))
       (lambda (candidate slot) (.ref candidate slot))
       '((projection . test))))))

(unless
 (contract-schema-eval
  '(and (element? Type
                  (poo-flow-contract-slot-type
                   +contract-schema-fixture-slot+))
        (element? Type +contract-schema-fixture-contract+)
        (element? +contract-schema-fixture-contract+
                  (.o schema: "schema/v1"))))
 (error "contract schema should construct native Type and Contract values"))

(let (row
      (contract-schema-eval
       '(poo-flow-native-contract->alist
         +contract-schema-fixture-contract+)))
  (unless (and (eq? (contract-schema-test-ref row 'object-kind)
                    'PooFlowContractSchemaFixture)
               (pair? (contract-schema-test-ref row 'slots))
               (eq? (contract-schema-test-ref
                     (car (contract-schema-test-ref row 'slots))
                     'predicate)
                    'string?))
    (error "contract projection should preserve bounded report metadata")))

(when
 (contract-schema-eval
  '(element? +contract-schema-fixture-contract+ (.o schema: 42)))
 (error "native Contract should reject invalid slot values"))

(unless
 (equal?
  (contract-schema-eval
   '(poo-flow-contract-check-slot!
     +contract-schema-fixture-slot+
     "schema/v1"))
  "schema/v1")
 (error "native slot gate should return valid values unchanged")))))
