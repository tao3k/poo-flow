;;; -*- Gerbil -*-
;;; Boundary: scenario coverage for user-interface use-composition syntax.

(import (only-in :clan/poo/object .o .ref)
         (only-in :std/test check-equal? run-tests! test-case test-suite)
         :poo-flow/src/module-system/profile-composition)

;; : PooModule
(def session-module
  (.o (hardened (.o (name 'session-hardened)
                    (scope '(session))))))

;; : PooModule
(def sandbox-module
  (.o (restricted (.o (name 'sandbox-restricted)
                      (scope '(sandbox))))))

;; : PooFlowComposition
(def rag-agent
  (use-composition rag-agent
    (modules
     (use-module session-module #:as session)
     (use-module sandbox-module #:as sandbox))
    (stage production
      (compose
       (profile session hardened)
       (profile sandbox restricted))
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
    (check-equal? (length (poo-flow-composition-modules rag-agent)) 2))
  (test-case "selects exact POO module slot profiles"
    (let* ((production-stage (car (poo-flow-composition-stages rag-agent)))
           (profiles (stage-clause-payload production-stage 'compose)))
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
