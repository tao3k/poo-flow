;;; -*- Gerbil -*-
;;; Boundary: scenario coverage for POO-native composition user interface.

(import (only-in :clan/poo/object .o .ref)
        (only-in :std/test check-equal? test-case test-suite)
        :poo-flow/src/module-system/profile-composition-builders
        :poo-flow/src/module-system/profile-composition-accessors)

;; : PooModule
(def session-module
  (.o (dev (.o (name 'session-dev)
               (scope '(session))))
      (hardened (.o (name 'session-hardened)
                    (scope '(session))
                    (audit-required #t)))))

;; : PooModule
(def sandbox-module
  (.o (local (.o (name 'sandbox-local)
                 (scope '(sandbox))))
      (restricted (.o (name 'sandbox-restricted)
                      (scope '(sandbox))
                      (network #f)))))

;; : PooModule
(def retriever-module
  (.o (mock (.o (name 'retriever-mock)
                (tool 'mock)))
      (vector-store (.o (name 'retriever-vector-store)
                        (tool 'retriever)))))

;; : PooModule
(def llm-module
  (.o (debug (.o (name 'llm-debug)
                 (tool 'llm)))
      (chat (.o (name 'llm-chat)
                (tool 'llm)
                (streaming #t)))))

;; : PooFlowComposition
(def rag-composition
  (poo-flow-composition-object
   'rag-agent
   (list (poo-flow-composition-module-binding 'session session-module)
         (poo-flow-composition-module-binding 'sandbox sandbox-module)
         (poo-flow-composition-module-binding 'retriever retriever-module)
         (poo-flow-composition-module-binding 'llm llm-module))
   (list
    (poo-flow-composition-stage
     'develop
     (list (poo-flow-composition-clause
            'compose
            (list (poo-flow-profile-ref session-module 'dev)
                  (poo-flow-profile-ref sandbox-module 'local)
                  (poo-flow-profile-ref retriever-module 'mock)
                  (poo-flow-profile-ref llm-module 'debug)))))
    (poo-flow-composition-stage
     'production
     (list (poo-flow-composition-clause
            'compose
            (list (poo-flow-profile-ref session-module 'hardened)
                  (poo-flow-profile-ref sandbox-module 'restricted)
                  (poo-flow-profile-ref retriever-module 'vector-store)
                  (poo-flow-profile-ref llm-module 'chat)))
           (poo-flow-composition-clause 'graph '(guarded-rag-flow))
           (poo-flow-composition-clause
            'loop
            '(#:fuel 8 #:exit answer-ready))
           (poo-flow-composition-clause
            'prove
            '(scope-contained
              dependency-ready
              graph-reachable
              loop-progress)))))))

;; : (-> List Symbol Any)
(def (alist-value key alist)
  (cond
   ((null? alist) #f)
   ((eq? key (caar alist)) (cdar alist))
   (else (alist-value key (cdr alist)))))

;; : (-> PooFlowCompositionStage Symbol Any)
(def (stage-clause-payload composition-stage clause-kind)
  (let loop ((clauses (poo-flow-composition-stage-clauses composition-stage)))
    (cond
     ((null? clauses) #f)
     ((eq? (.ref (car clauses) 'clause-kind) clause-kind)
      (.ref (car clauses) 'payload))
     (else (loop (cdr clauses))))))

(test-suite "poo-flow POO-native composition interface"
  (test-case "builds staged composition from module profile slots"
    (check-equal? (poo-flow-composition? rag-composition) #t)
    (check-equal? (poo-flow-composition-name rag-composition) 'rag-agent)
    (check-equal? (map poo-flow-composition-stage-name
                       (poo-flow-composition-stages rag-composition))
                  '(develop production))
    (check-equal? (length (poo-flow-composition-modules rag-composition)) 4))
  (test-case "selects exact profile slots from POO module objects"
    (let* ((production-stage (cadr (poo-flow-composition-stages
                                    rag-composition)))
           (profiles (stage-clause-payload production-stage 'compose)))
      (check-equal? (map (lambda (profile) (.ref profile 'name)) profiles)
                    '(session-hardened
                      sandbox-restricted
                      retriever-vector-store
                      llm-chat))
      (check-equal? (.ref (car profiles) 'audit-required) #t)
      (check-equal? (.ref (cadr profiles) 'network) #f)))
  (test-case "keeps graph loop and proof clauses as stage metadata"
    (let ((production-stage (cadr (poo-flow-composition-stages
                                   rag-composition))))
      (check-equal? (stage-clause-payload production-stage 'graph)
                    '(guarded-rag-flow))
      (check-equal? (stage-clause-payload production-stage 'loop)
                    '(#:fuel 8 #:exit answer-ready))
      (check-equal? (stage-clause-payload production-stage 'prove)
                    '(scope-contained
                      dependency-ready
                      graph-reachable
                      loop-progress)))))
