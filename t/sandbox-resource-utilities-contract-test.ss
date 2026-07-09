;;; -*- Gerbil -*-
;;; Contract: sandbox resources expose utilities-backed type contracts.

(eval '(import (only-in :clan/poo/object .o)))
(eval '(import "./src/modules/sandbox-core/resource-contract.ss"))

;; : (-> PooFlowSandboxResourceExpr PooFlowSandboxResourceValue)
(def (sandbox-resource-eval expr)
  (eval expr))

;; : (-> Alist Symbol Object Object)
(def (alist-ref/default entries key default-value)
  (let (entry (assoc key entries))
    (if entry (cdr entry) default-value)))

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

(def valid-validation
  (sandbox-resource-eval
   '(poo-flow-sandbox-resources-prototype-contract-validation
     poo-flow-runtime-volume-resources-prototype)))

(unless (sandbox-resource-eval
         `(poo-flow-sandbox-resources-prototype-contract-validation-valid?
           ',valid-validation))
  (error "runtime volume resources should satisfy utilities-backed validation"))

(def invalid-validation
  (sandbox-resource-eval
   '(poo-flow-sandbox-resources-prototype-contract-validation
     (.o filesystem: poo-flow-runtime-volume-filesystem-prototype
         cpu: "two"
         memory: "4Gi"))))

(when (sandbox-resource-eval
       `(poo-flow-sandbox-resources-prototype-contract-validation-valid?
         ',invalid-validation))
  (error "invalid cpu should fail utilities-backed validation"))
