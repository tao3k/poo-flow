;;; -*- Gerbil -*-
;;; Contract: JSON Schema emits and validates native POO Contracts directly.

(eval '(import "./src/contract/json-schema-receipt.ss"))
(eval '(import "./src/contract/json-schema-validate.ss"))
(eval '(import "./src/module-system/descriptor/contracts.ss"))
(eval '(import "./src/type-facts/objects.ss"))
(eval '(import :clan/poo/mop))

(def (json-schema-native-eval expr)
  (eval expr))

(json-schema-native-eval
 '(def +json-schema-native-artifact+
    (poo-flow-json-schema->contract-artifact
     '((type . "object")
       (required . ("name"))
       (properties . ((name . ((type . "string"))))))
     '((owner . contract-test)
       (object-kind . PooFlowJsonSchemaNativeFixture)
       (object-key . json-schema/native-fixture)))))

(unless
 (json-schema-native-eval
  '(let (contract
         (poo-flow-json-schema-contract-artifact-object-contract
          +json-schema-native-artifact+))
     (and (element? Type contract)
          (element? contract '((name . "flow")))
          (not (element? contract '((name . 42))))
          (= (length (poo-flow-native-contract->type-facts contract)) 1)
          (= (length (poo-flow-native-contract->lean-fact-contracts contract))
             1))))
 (error "JSON Schema should emit a native Contract with proof projections"))

(unless
 (json-schema-native-eval
  '(poo-flow-json-schema-object-contract-validation-valid?
    (poo-flow-json-schema-contract-artifact-validate
     +json-schema-native-artifact+
     '((name . "flow")))))
 (error "native JSON Schema validation should admit a valid candidate"))

(when
 (json-schema-native-eval
  '(poo-flow-json-schema-object-contract-validation-valid?
    (poo-flow-json-schema-contract-artifact-validate
     +json-schema-native-artifact+
     '((name . 42)))))
 (error "native JSON Schema validation should reject an invalid candidate"))
