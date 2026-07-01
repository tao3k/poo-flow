;;; -*- Gerbil -*-
;;; Boundary: user-interface presentation hot path stays bounded.
;;; Invariant: public authoring remains POO-native; generated runtime receipts
;;; are fixed structs until Marlin ABI handoff serialization.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-contract-pass?
                 benchmark-receipt-pass?
                 benchmark-run/result)
        (only-in :clan/poo/object .ref .slot? object?)
        :poo-flow/t/support/performance
        (only-in :poo-flow/src/module-system/base
                 poo-flow-settings
                 poo-flow-user-module-bundles->modules
                 pooFlowUserConfig)
        (only-in :poo-flow/src/module-system/presentation-config
                 pooFlowUserConfigPresentation)
        (only-in :poo-flow/src/module-system/loop-engine-runtime
                 loop-engine-capability-receipt?)
        (only-in :poo-flow/user-interface/custom/my-module/cases/loop-engine-owner
                 poo-flow-custom-my-module-loop-engine-case))

(export user-interface-presentation-performance-test)

;; : String
(def user-interface-presentation-fixture-path
  "t/scenarios/performance/user-interface-presentation-batch-projection/benchmark.ss")

;; : Alist
(def user-interface-presentation-fixture
  (call-with-input-file user-interface-presentation-fixture-path read))

;; : Integer
(def user-interface-presentation-module-count 8)

;; : (-> Value Symbol Value)
(def (user-interface-presentation-ref value key)
  (cond
   ((and (object? value) (.slot? value key))
    (.ref value key))
   ((pair? value)
    (let (entry (assoc key value))
      (and entry (cdr entry))))
   (else #f)))

;; : (-> [Value] Boolean)
(def (user-interface-presentation-all-capability-receipts? values)
  (cond
   ((null? values) #t)
   ((loop-engine-capability-receipt? (car values))
    (user-interface-presentation-all-capability-receipts? (cdr values)))
   (else #f)))

;; : (-> [Value] Boolean)
(def (user-interface-presentation-all-alists? values)
  (cond
   ((null? values) #t)
   ((and (pair? (car values))
         (not (object? (car values))))
    (user-interface-presentation-all-alists? (cdr values)))
   (else #f)))

;; : (-> Integer [[PooUserModuleSelection]])
(def (user-interface-presentation-module-bundles count)
  (poo-flow-performance-build-list
   count
   (lambda (_index)
     poo-flow-custom-my-module-loop-engine-case)))

;; : (-> Integer POOObject)
(def (user-interface-presentation-build count)
  (pooFlowUserConfigPresentation
   (pooFlowUserConfig
    (poo-flow-user-module-bundles->modules
     (user-interface-presentation-module-bundles count))
    (poo-flow-settings))))

;; : (-> Integer Alist)
(def (user-interface-presentation-summary count)
  (let* ((presentation
          (user-interface-presentation-build count))
         (capability-receipts
          (.ref presentation 'loop-engine-capability-receipts))
         (runtime-handoffs
          (.ref presentation 'loop-engine-runtime-handoffs))
         (runtime-handoff-capability-receipts
          (map (lambda (handoff)
                 (user-interface-presentation-ref
                  handoff
                  'capability-receipt))
               runtime-handoffs)))
    (list
     (cons 'module-count (.ref presentation 'module-count))
     (cons 'loop-engine-intent-count
           (.ref presentation 'loop-engine-intent-count))
     (cons 'loop-engine-runtime-handoff-count
           (.ref presentation 'loop-engine-runtime-handoff-count))
     (cons 'capability-receipt-count (length capability-receipts))
     (cons 'struct-capability-receipts?
           (user-interface-presentation-all-capability-receipts?
            capability-receipts))
     (cons 'runtime-handoff-capability-receipts-serialized?
           (user-interface-presentation-all-alists?
            runtime-handoff-capability-receipts))
     (cons 'presentation-trace-kind
           (user-interface-presentation-ref
            (.ref presentation 'presentation-trace)
            'kind))
     (cons 'runtime-executed (.ref presentation 'runtime-executed)))))

;; : (-> Alist Void)
(def (user-interface-presentation-display-receipt receipt)
  (display "[poo-flow-benchmark] user-interface-presentation-batch-projection ")
  (write receipt)
  (newline)
  (force-output))

;; : TestSuite
(def user-interface-presentation-performance-test
  (test-suite "user-interface presentation performance"
    (test-case "keeps batch presentation projection inside benchmark contract"
      (let-values (((receipt summary)
                    (benchmark-run/result
                     user-interface-presentation-fixture
                     (lambda ()
                       (user-interface-presentation-summary
                        user-interface-presentation-module-count)))))
        (check-equal?
         (benchmark-fixture-contract-pass? user-interface-presentation-fixture)
         #t)
        (check-equal?
         (user-interface-presentation-ref summary 'module-count)
         user-interface-presentation-module-count)
        (check-equal?
         (user-interface-presentation-ref summary 'loop-engine-intent-count)
         user-interface-presentation-module-count)
        (check-equal?
         (user-interface-presentation-ref
          summary
          'loop-engine-runtime-handoff-count)
         user-interface-presentation-module-count)
        (check-equal?
         (user-interface-presentation-ref summary 'capability-receipt-count)
         user-interface-presentation-module-count)
        (check-equal?
         (user-interface-presentation-ref summary 'struct-capability-receipts?)
         #t)
        (check-equal?
         (user-interface-presentation-ref
          summary
          'runtime-handoff-capability-receipts-serialized?)
         #t)
        (check-equal?
         (user-interface-presentation-ref summary 'runtime-executed)
         #f)
        (user-interface-presentation-display-receipt receipt)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
