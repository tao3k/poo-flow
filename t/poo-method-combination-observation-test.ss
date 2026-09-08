;;; -*- Gerbil -*-
(import (only-in :std/test test-suite test-case check-equal?)
        (only-in :clan/poo/object .ref .slot?)
        "../src/research/poo-method-combination/observation.ss"
        "../src/observability/interface.ss"
        "scenarios/research/poo-method-combination/observation.ss")
(export poo-method-combination-observation-test)
(def poo-method-combination-observation-test
  (test-suite "research: method-combined real observation"
    (test-case "extension retains base decision and source-owned explanation"
      (let-values (((base detailed) (combination-observation-scenario)))
        (check-equal? (.ref base 'accepted?) #f)
        (check-equal? (.ref detailed 'accepted?) (.ref base 'accepted?))
        (check-equal? (.ref detailed 'failure-count) 1)
        (check-equal? (.slot? base 'explanation) #f)
        (check-equal? (.slot? detailed 'candidate) #f)
        (let (failure (car (.ref (.ref detailed 'explanation) 'failures)))
          (check-equal? (.ref failure 'path) '(imports))
          (check-equal? (.ref failure 'code) 'prototype-mismatch))))
    (test-case "one opt-in renderer reuses its plan across independent admissions"
      (let* ((renderer (poo-observation-combination-renderer explanation?: #t))
             (plan (.ref renderer 'research/summary-plan))
             (rejected (combination-observation-event))
             (accepted (combination-observation-event #t))
             (before (poo-flow-observation-summary rejected))
             (port (open-output-string))
             (results
              (parameterize ((current-output-port port) (current-error-port port))
                (map (lambda (event) (poo-observation-combination-summary renderer event))
                     (list rejected accepted rejected)))))
        (check-equal? (map (lambda (result) (.ref result 'accepted?)) results) '(#f #t #f))
        (check-equal? (map (lambda (result) (.ref result 'failure-count)) results) '(1 0 1))
        (check-equal? (eq? plan (.ref renderer 'research/summary-plan)) #t)
        (check-equal? (eq? (car results) (caddr results)) #f)
        (check-equal? (get-output-string port) "")
        (check-equal? (.slot? before 'explanation) #f)
        (check-equal? (.slot? (poo-flow-observation-summary rejected) 'explanation) #f)
        (check-equal? (.slot? (car results) 'candidate) #f)))))
