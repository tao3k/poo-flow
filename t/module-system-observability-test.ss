;;; -*- Gerbil -*-
;;; Boundary: tests verify strict module-system observability traces.
;;; Invariant: trace construction never dereferences POO slots.

(import (only-in :std/test
                 check
                 check-eq?
                 check-equal?
                 check-false
                 check-not-equal?
                 check-output
                 check-true
                 run-tests!
                 test-case
                 test-error
                 test-suite)
        :poo-flow/src/module-system/facade)

(export module-system-observability-test)

;; : (-> Symbol Alist Value)
(def (module-observability-test-alist-value key rows)
  (cdr (assoc key rows)))

;; : (-> Unit TestSuite)
;;; This suite protects module observability receipts used to debug expansion
;;; and lazy-load decisions.
(def module-system-observability-test
  (test-suite "poo-flow module-system observability"
    (test-case "builds strict presentation trace rows"
      (let* ((trace
              (poo-flow-module-presentation-trace
               'test-presentation
               (list (cons 'selected-modules 2)
                     (cons 'settings 1))))
             (first-step (car trace))
             (second-step (cadr trace)))
        (check-equal? (module-observability-test-alist-value 'kind first-step)
                      poo-flow-module-observation-kind)
        (check-equal? (module-observability-test-alist-value 'scope first-step)
                      'test-presentation)
        (check-equal? (module-observability-test-alist-value 'stage first-step)
                      'selected-modules)
        (check-equal? (module-observability-test-alist-value 'status first-step)
                      'ok)
        (check-equal? (module-observability-test-alist-value 'count first-step) 2)
        (check-equal? (module-observability-test-alist-value 'depth first-step) 0)
        (check-equal? (module-observability-test-alist-value 'path first-step)
                      '(selected-modules))
        (check-equal? (module-observability-test-alist-value
                       'runtime-executed
                       first-step)
                      #f)
        (check-equal? (module-observability-test-alist-value 'stage second-step)
                      'settings)
        (check-equal? (module-observability-test-alist-value 'path second-step)
                      '(selected-modules settings))))
    (test-case "marks repeated stages as recursive-stage"
      (let* ((trace
              (poo-flow-module-presentation-trace
               'test-presentation
               (list (cons 'selected-modules 2)
                     (cons 'selected-modules 2))))
             (repeat-step (cadr trace)))
        (check-equal? (module-observability-test-alist-value
                       'stage
                       repeat-step)
                      'selected-modules)
        (check-equal? (module-observability-test-alist-value
                       'status
                       repeat-step)
                      'recursive-stage)
        (check-equal? (module-observability-test-alist-value
                       'depth
                       repeat-step)
                      1)
        (check-equal? (module-observability-test-alist-value
                       'path
                       repeat-step)
                      '(selected-modules selected-modules))))))

(run-tests! module-system-observability-test)
