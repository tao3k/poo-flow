;;; -*- Gerbil -*-
;;; Boundary: reusable workloads for recursive JSON Schema contract gates.
;;; Invariant: workloads measure Scheme-side contract validation only.

(import (only-in :std/srfi/1
                 fold
                 iota)
        (only-in :clan/poo/object
                 object<-alist)
        (only-in "./performance.ss"
                 poo-flow-performance-build-list)
        (only-in "../../src/contract/json-schema-ir.ss"
                 poo-flow-json-schema-normalization-schema)
        (only-in "../../src/contract/json-schema-receipt.ss"
                 poo-flow-json-schema-contract-artifact-normalization)
        (only-in "../../src/contract/json-schema-valid.ss"
                 poo-flow-json-schema-node-valid?)
        (only-in "../../src/modules/funflow/github-ci-contract.ss"
                 poo-flow-funflow-github-ci-contract-artifact
                 poo-flow-funflow-github-ci-validate-workflow->alist))

(export json-schema-contract-performance-ref
        json-schema-contract-performance-step
        json-schema-contract-performance-job
        json-schema-contract-performance-workflow
        json-schema-contract-performance-poo-workflow
        json-schema-contract-performance-valid-receipt?
        json-schema-contract-performance-repeat
        json-schema-contract-performance-fast-validate-rounds
        json-schema-contract-performance-validate-rounds)

;; : (-> Alist Symbol Object)
(def (json-schema-contract-performance-ref rows key)
  (let (entry (assoc key rows))
    (if entry (cdr entry) #f)))

;; : (-> Integer Alist)
(def (json-schema-contract-performance-step index)
  (list
   (cons 'id
         (string-append "step_" (number->string index)))
   (cons 'run "echo poo-flow-json-schema-contract")))

;; : (-> Integer Integer Pair)
(def (json-schema-contract-performance-job index step-count)
  (cons
   (string->symbol
    (string-append "job_" (number->string index)))
   (list
    (cons 'runs-on "ubuntu-latest")
    (cons 'steps
          (poo-flow-performance-build-list
           step-count
           json-schema-contract-performance-step)))))

;; : (-> Integer Integer Alist)
(def (json-schema-contract-performance-workflow job-count step-count)
  (list
   (cons 'name "POO Flow recursive contract benchmark")
   (cons 'on "push")
   (cons 'jobs
         (poo-flow-performance-build-list
          job-count
          (lambda (index)
            (json-schema-contract-performance-job index step-count))))))

;; : (-> Integer Integer PooFlowObject)
(def (json-schema-contract-performance-poo-workflow job-count step-count)
  (object<-alist
   (json-schema-contract-performance-workflow job-count step-count)))

;; : (-> Alist Boolean)
(def (json-schema-contract-performance-valid-receipt? receipt)
  (and (eq? (json-schema-contract-performance-ref receipt 'valid?) #t)
       (= (json-schema-contract-performance-ref receipt 'diagnostic-count) 0)))

;; : (-> Integer (-> Integer) Integer)
(def (json-schema-contract-performance-repeat rounds workload)
  (if (<= rounds 0)
    0
    (fold (lambda (_round total)
            (+ total (workload)))
          0
          (iota rounds))))

;; : (-> Object Integer Integer)
(def (json-schema-contract-performance-validate-rounds workflow rounds)
  (json-schema-contract-performance-repeat
   rounds
   (lambda ()
     (if (json-schema-contract-performance-valid-receipt?
          (poo-flow-funflow-github-ci-validate-workflow->alist workflow))
       1
       0))))

;; : (-> Object Integer Integer)
(def (json-schema-contract-performance-fast-validate-rounds workflow rounds)
  (let (root-node
        (poo-flow-json-schema-normalization-schema
         (poo-flow-json-schema-contract-artifact-normalization
          poo-flow-funflow-github-ci-contract-artifact)))
    (json-schema-contract-performance-repeat
     rounds
     (lambda ()
       (if (poo-flow-json-schema-node-valid? root-node workflow)
         1
         0)))))
