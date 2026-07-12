;;; -*- Gerbil -*-
;;; Boundary: scenario coverage for user-interface use-composition syntax.

(import (only-in :clan/poo/object .o .ref)
         (only-in :std/test check-equal? run-tests! test-case test-suite)
         :gslph/src/testing/memory-profile
         :poo-flow/src/module-system/profile-composition)

(declare-gxtest-memory-exception '((maxHeapMiB . 512)))

;; : PooFlowComposition
(def rag-agent
  (use-composition rag-agent
    (use-module agent as agent
      (profile session-hardened
        :scope (session))
      (profile sandbox-restricted
        :scope (sandbox)))
    (compose
     (profile agent session-hardened)
     (profile agent sandbox-restricted))
    (stage production
      (graph guarded-flow)
      (loop #:fuel 4 #:exit done)
      (prove scope-contained graph-reachable loop-progress))))

;; : (-> PooFlowCompositionStage Symbol Any)
(def (stage-clause-payload composition-stage clause-kind)
  (let loop ((clauses (poo-flow-composition-stage-clauses composition-stage)))
    (cond
     ((null? clauses) #f)
     ((eq? (.ref (car clauses) 'clause-kind) clause-kind)
      (.ref (car clauses) 'payload))
     (else (loop (cdr clauses))))))

(run-tests!
 (test-suite "poo-flow user-interface composition macro"
  (test-case "defines a named composition from module profile slots"
    (check-equal? (poo-flow-composition? rag-agent) #t)
    (check-equal? (poo-flow-composition-name rag-agent) 'rag-agent)
    (check-equal? (length (poo-flow-composition-modules rag-agent)) 1))
  (test-case "selects exact POO module slot profiles"
    (let ((profiles (poo-flow-composition-profiles rag-agent)))
      (check-equal? (map (lambda (profile) (.ref profile 'name)) profiles)
                    '(session-hardened sandbox-restricted))))
  (test-case "keeps graph loop and proof metadata on the stage"
    (let ((production-stage (car (poo-flow-composition-stages rag-agent))))
      (check-equal? (stage-clause-payload production-stage 'graph)
                    '(guarded-flow))
      (let ((loop-payload (stage-clause-payload production-stage 'loop)))
        (check-equal? (length loop-payload) 4)
        (check-equal? (cadr loop-payload) 4)
        (check-equal? (cadddr loop-payload) 'done))
      (check-equal? (stage-clause-payload production-stage 'prove)
                    '(scope-contained graph-reachable loop-progress))))))
