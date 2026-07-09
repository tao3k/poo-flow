;;; -*- Gerbil -*-
;;; Boundary: scenario test for structured type-fact validation receipts.

(import (only-in :clan/poo/object .o))

(eval '(import "./src/type-facts/objects.ss"))
(eval '(import "./src/modules/sandbox-core/resource-contract.ss"))

;; : (-> PooFlowTypeFactsSandboxScenarioExpr PooFlowTypeFactsSandboxScenarioValue)
(def (type-facts-sandbox-scenario-eval expr)
  (eval expr))

(unless
 (type-facts-sandbox-scenario-eval
  '(let (valid-validation
         (poo-flow-sandbox-resources-prototype-contract-validation
          poo-flow-runtime-volume-resources-prototype))
     (poo-flow-type-validation-receipt? valid-validation)))
  (error "sandbox resource validation should return a type validation receipt"))

(unless
 (type-facts-sandbox-scenario-eval
  '(let (valid-validation
         (poo-flow-sandbox-resources-prototype-contract-validation
          poo-flow-runtime-volume-resources-prototype))
     (poo-flow-sandbox-resources-prototype-contract-validation-valid?
      valid-validation)))
  (error "runtime volume resource prototype should pass typed validation"))

(unless
 (type-facts-sandbox-scenario-eval
  '(let* ((valid-validation
           (poo-flow-sandbox-resources-prototype-contract-validation
            poo-flow-runtime-volume-resources-prototype))
          (row
           (poo-flow-sandbox-resources-prototype-contract-validation->alist
            valid-validation)))
     (and (assq 'type-facts row)
          (assq 'lean-fact-contracts row)
          (eq? (cdr (assq 'runtime-executed row)) #f))))
 (error "typed validation projection should expose type and Lean facts"))

(when
 (type-facts-sandbox-scenario-eval
  '(let (invalid-validation
         (poo-flow-sandbox-resources-prototype-contract-validation
          (.o filesystem: poo-flow-runtime-volume-filesystem-prototype
              cpu: 2)))
     (poo-flow-sandbox-resources-prototype-contract-validation-valid?
      invalid-validation)))
  (error "resource prototype without memory should fail typed validation"))
