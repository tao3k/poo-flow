;;; -*- Gerbil -*-
;;; Contract: sandbox resources expose native POO Type/Contract descriptors.

(import :std/test)

;; : (-> PooFlowSandboxResourceExpr PooFlowSandboxResourceValue)
(def (sandbox-resource-eval expr)
  (eval expr))

;; : (-> Alist Symbol Object Object)
(def (alist-ref/default entries key default-value)
  (let (entry (assoc key entries))
    (if entry (cdr entry) default-value)))

(export sandbox-resource-native-type-contract-test)

(def sandbox-resource-native-type-contract-test
  (test-suite "sandbox-resource-native-type-contract-test"
    (test-case "validates the native contract"
      (eval '(import (only-in :clan/poo/object .o)))
      (eval '(import (only-in :clan/poo/mop Type element?)))
      (eval '(import "./src/modules/sandbox-core/resource-contract.ss"))
      (let* ((row
        (sandbox-resource-eval
         '(poo-flow-sandbox-resources-prototype-type-contract->alist)))
       (slot-rows (alist-ref/default row 'slots '()))
       (slot-names
        (map (lambda (slot-row)
               (alist-ref/default slot-row 'slot #f))
             slot-rows)))
  (unless (and (eq? (alist-ref/default row 'object-kind #f)
                    'PooSandboxResourcesPrototype)
               (equal? slot-names
                       '(filesystem cpu ports memory timeout-ms)))
    (error "sandbox resource type contract should expose structured slot contracts")))

(unless (sandbox-resource-eval
         '(and (element? Type PooFlowSandboxResourcesPrototypeContract)
               (element? PooFlowSandboxResourcesPrototypeContract
                         poo-flow-runtime-volume-resources-prototype)))
  (error "sandbox resource contract should be native and admit valid resources"))

(when (sandbox-resource-eval
       '(element? PooFlowSandboxResourcesPrototypeContract
                  (.o filesystem: poo-flow-runtime-volume-filesystem-prototype
                      cpu: "two"
                      memory: "4Gi")))
  (error "native sandbox resource contract should reject an invalid cpu slot"))

(def valid-validation
  (sandbox-resource-eval
   '(poo-flow-sandbox-resources-prototype-contract-validation
     poo-flow-runtime-volume-resources-prototype)))

(unless (sandbox-resource-eval
         `(poo-flow-sandbox-resources-prototype-contract-validation-valid?
           ',valid-validation))
  (error "runtime volume resources should satisfy native validation"))

(def invalid-validation
  (sandbox-resource-eval
   '(poo-flow-sandbox-resources-prototype-contract-validation
     (.o filesystem: poo-flow-runtime-volume-filesystem-prototype
         cpu: "two"
         memory: "4Gi"))))

(when (sandbox-resource-eval
       `(poo-flow-sandbox-resources-prototype-contract-validation-valid?
         ',invalid-validation))
  (error "invalid cpu should fail native validation")))))
