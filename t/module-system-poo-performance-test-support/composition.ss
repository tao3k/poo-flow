;;; -*- Gerbil -*-
;;; Boundary: POO composition macro and native extension performance gates.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :gslph/src/benchmark/gate
                 benchmark-receipt-pass?)
        :poo-flow/t/module-system-poo-performance-test-support/composition-scenarios)

(export module-system-poo-performance-composition-test)

;; : (-> (-> Integer Alist) Pair)
(def (poo-performance-composition-run-observed-gate gate)
  (poo-performance-composition-reset-construction-count!)
  (let (receipt (gate 1000))
    (list receipt
          (poo-performance-composition-construction-count))))

;; : TestCase
(def module-system-poo-performance-profile-declaration-case
  (test-case "gates inline profile declarations as native POO objects"
    (let* ((observed
            (poo-performance-composition-run-observed-gate
             poo-performance-composition-profile-declaration-gate-receipt))
           (receipt (car observed))
           (construction-count (cadr observed)))
      (check-equal?
       (poo-performance-composition-profile-declaration-valid-count 1)
       1)
      (check-equal? construction-count 1)
      (check-equal? (benchmark-receipt-pass? receipt) #t))))

;; : TestCase
(def module-system-poo-performance-profiles-bulk-case
  (test-case "gates grouped profiles import and compose syntax"
    (let* ((observed
            (poo-performance-composition-run-observed-gate
             poo-performance-composition-profiles-bulk-gate-receipt))
           (receipt (car observed))
           (construction-count (cadr observed)))
      (check-equal? (poo-performance-composition-profiles-bulk-valid-count 1)
                    1)
      (check-equal? construction-count 1)
      (check-equal? (benchmark-receipt-pass? receipt) #t))))

;; : TestCase
(def module-system-poo-performance-local-override-case
  (test-case "gates local native POO override profiles"
    (let* ((observed
            (poo-performance-composition-run-observed-gate
             poo-performance-composition-local-override-gate-receipt))
           (receipt (car observed))
           (construction-count (cadr observed)))
      (check-equal? (poo-performance-composition-local-override-valid-count 1)
                    1)
      (check-equal? construction-count 1)
      (check-equal? (benchmark-receipt-pass? receipt) #t))))

;; : TestCase
(def module-system-poo-performance-hook-override-case
  (test-case "gates reusable profile hook overrides"
    (let* ((observed
            (poo-performance-composition-run-observed-gate
             poo-performance-composition-hook-override-gate-receipt))
           (receipt (car observed))
           (construction-count (cadr observed)))
      (check-equal? (poo-performance-composition-hook-override-valid-count 1)
                    1)
      (check-equal? construction-count 1)
      (check-equal? (benchmark-receipt-pass? receipt) #t))))

;; : TestCase
(def module-system-poo-performance-native-object-reuse-case
  (test-case "gates direct native POO object reuse"
    (let* ((observed
            (poo-performance-composition-run-observed-gate
             poo-performance-composition-native-object-reuse-gate-receipt))
           (receipt (car observed))
           (construction-count (cadr observed)))
      (check-equal?
       (poo-performance-composition-native-object-reuse-valid-count 1)
       1)
      (check-equal? construction-count 1)
      (check-equal? (benchmark-receipt-pass? receipt) #t))))

;; : TestCase
(def module-system-poo-performance-native-object-reuse-large-library-case
  (test-case "gates 2048 native POO profiles plus hook variants"
    (let* ((observed
            (poo-performance-composition-run-observed-gate
             poo-performance-composition-native-object-reuse-large-library-gate-receipt))
           (receipt (car observed))
           (construction-count (cadr observed)))
      (check-equal?
       (poo-performance-composition-native-object-reuse-large-library-valid-count
        1)
       1)
      (check-equal? construction-count 1)
      (check-equal? (benchmark-receipt-pass? receipt) #t))))

(def module-system-poo-performance-composition-lazy-demand-case
  (test-case "gates POO composition lazy demand object reuse"
    (let* ((observed
            (poo-performance-composition-run-observed-gate
             poo-performance-composition-lazy-demand-gate-receipt))
           (receipt (car observed))
           (construction-count (cadr observed)))
      (check-equal?
       (poo-performance-composition-lazy-demand-valid-count 1)
       1)
      (check-equal? construction-count 0)
      (check-equal? (benchmark-receipt-pass? receipt) #t))))

;; : TestCase
(def module-system-poo-performance-native-object-list-indexed-family-case
  (test-case "gates Project Harness-style POO object-list indexed family"
    (let* ((observed
            (poo-performance-composition-run-observed-gate
             poo-performance-native-object-list-indexed-family-gate-receipt))
           (receipt (car observed))
           (construction-count (cadr observed)))
      (check-equal?
       (poo-performance-native-object-list-indexed-family-valid-count 1)
       1)
      (check-equal? construction-count 1)
      (check-equal? (benchmark-receipt-pass? receipt) #t))))

;; : TestCase
(def module-system-poo-performance-macro-style-matrix-case
  (test-case "gates high-performance composition macro styles"
    (let* ((observed
            (poo-performance-composition-run-observed-gate
             poo-performance-composition-macro-style-matrix-gate-receipt))
           (receipt (car observed))
           (construction-count (cadr observed)))
      (check-equal?
       (poo-performance-composition-macro-style-matrix-valid-count 1)
       1)
      (check-equal? construction-count 1)
      (check-equal? (benchmark-receipt-pass? receipt) #t))))

;; : TestSuite
(def module-system-poo-performance-composition-test
  (test-suite "poo-flow composition macro POO performance"
    module-system-poo-performance-profile-declaration-case
    module-system-poo-performance-profiles-bulk-case
    module-system-poo-performance-local-override-case
    module-system-poo-performance-hook-override-case
    module-system-poo-performance-native-object-reuse-case
    module-system-poo-performance-native-object-reuse-large-library-case
    module-system-poo-performance-composition-lazy-demand-case
    module-system-poo-performance-native-object-list-indexed-family-case
    module-system-poo-performance-macro-style-matrix-case))
