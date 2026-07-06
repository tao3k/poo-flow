;;; -*- Gerbil -*-
;;; Scenario: user-interface LangChain and LangGraph composition instances.

(import (only-in :clan/poo/object .o .ref)
        (only-in :std/test check-equal? run-tests! test-case test-suite)
        :poo-flow/src/graph/types
        :poo-flow/src/graph/algorithms
        :poo-flow/src/graph/control-analysis
        :poo-flow/src/graph/runtime-executor
        :poo-flow/src/module-system/init-syntax
        :poo-flow/src/module-system/profile-composition
        :poo-flow/src/module-system/profile-composition-accessors)

(load! "../user-interface/profiles/langchain")
(load! "../user-interface/profiles/langgraph")
(load! "../user-interface/cases/langchain-linear")
(load! "../user-interface/cases/langgraph-state")

(def langchain-linear-composition
  poo-flow-custom-module-langchain-linear-case)

(def langgraph-state-composition
  poo-flow-custom-module-langgraph-state-case)

(def audited-langchain-module
  (.o (:: self poo-flow-custom-module-langchain-module)
      (model (.o (name 'langchain-audited-chat-model)
                 (contract 'single-turn-input-output)
                 (policy 'audit-model-call-before-terminal)))))

(def audited-langchain-composition
  (use-composition audited-langchain-linear-composition
    (modules
     (use-module audited-langchain-module #:as chain))
    (stage production
      (compose
       (profile chain memory)
       (profile chain prompt)
       (profile chain model)
       (profile chain parser)
       (profile chain no-tool))
      (graph langchain-linear-chain)
      (loop #:fuel 1 #:exit parsed-output)
      (prove chain-order
             prompt-before-model
             parser-after-model
             no-implicit-tool-branch))))

(def langchain-linear-control-graph
  (poo-flow-graph
   'langchain-linear-chain
   (list (poo-flow-graph-node 'memory)
         (poo-flow-graph-node 'prompt)
         (poo-flow-graph-node 'model)
         (poo-flow-graph-node 'parser)
         (poo-flow-graph-node 'parsed-output))
   (list (poo-flow-graph-edge 'memory 'prompt)
         (poo-flow-graph-edge 'prompt 'model)
         (poo-flow-graph-edge 'model 'parser)
         (poo-flow-graph-edge 'parser 'parsed-output))
   (list (cons 'entry-ids '(memory))
         (cons 'finish-ids '(parsed-output)))))

(def langgraph-state-control-graph
  (poo-flow-graph
   'langgraph-state-graph
   (list (poo-flow-graph-node 'session)
         (poo-flow-graph-node 'state)
         (poo-flow-graph-node 'router)
         (poo-flow-graph-node 'agent-node)
         (poo-flow-graph-node 'tool-node)
         (poo-flow-graph-node 'terminal)
         (poo-flow-graph-node 'runtime-handoff))
   (list (poo-flow-graph-edge 'session 'state)
         (poo-flow-graph-edge 'state 'router)
         (poo-flow-graph-edge 'router 'agent-node 'conditional)
         (poo-flow-graph-edge 'agent-node 'router 'loop)
         (poo-flow-graph-edge 'router 'tool-node 'conditional)
         (poo-flow-graph-edge 'tool-node 'router 'loop)
         (poo-flow-graph-edge 'router 'terminal 'conditional)
         (poo-flow-graph-edge 'terminal 'runtime-handoff))
   (list (cons 'entry-ids '(session))
         (cons 'finish-ids '(runtime-handoff)))))

(def langgraph-broken-branch-graph
  (poo-flow-graph
   'langgraph-broken-branch
   (list (poo-flow-graph-node 'router)
         (poo-flow-graph-node 'terminal))
   (list (poo-flow-graph-edge 'router 'missing-node 'conditional))
   (list (cons 'entry-ids '(router))
         (cons 'finish-ids '(terminal)))))

(def langgraph-production-runtime-graph
  (poo-flow-graph
   'langgraph-production-runtime
   (list (poo-flow-graph-node 'session)
         (poo-flow-graph-node 'sandbox)
         (poo-flow-graph-node 'router)
         (poo-flow-graph-node 'retriever)
         (poo-flow-graph-node 'agent-node)
         (poo-flow-graph-node 'tool-node)
         (poo-flow-graph-node 'checkpoint)
         (poo-flow-graph-node 'human-approval)
         (poo-flow-graph-node 'runtime-handoff))
   (list (poo-flow-graph-edge 'session 'sandbox)
         (poo-flow-graph-edge 'sandbox 'router)
         (poo-flow-graph-edge 'router 'retriever 'conditional)
         (poo-flow-graph-edge 'retriever 'router 'loop)
         (poo-flow-graph-edge 'router 'agent-node 'conditional)
         (poo-flow-graph-edge 'agent-node 'tool-node)
         (poo-flow-graph-edge 'tool-node 'checkpoint)
         (poo-flow-graph-edge 'checkpoint 'human-approval)
         (poo-flow-graph-edge 'human-approval 'runtime-handoff))
   (list (cons 'entry-ids '(session))
         (cons 'finish-ids '(runtime-handoff)))))

(def langgraph-production-runtime-policy
  (poo-flow-graph-runtime-policy
   'langgraph-production-runtime
   'session
   'runtime-handoff
   (list (poo-flow-graph-branch-choice 'router 'retriever)
         (poo-flow-graph-branch-choice 'router 'agent-node))
   8
   #t
   #t
   #t
   #t
   #t
   #t
   #t))

(def langgraph-human-approval-missing-policy
  (poo-flow-graph-runtime-policy
   'langgraph-production-runtime
   'session
   'runtime-handoff
   (list (poo-flow-graph-branch-choice 'router 'retriever)
         (poo-flow-graph-branch-choice 'router 'agent-node))
   8
   #t
   #t
   #t
   #t
   #f
   #t
   #t))

(def (alist-value alist key)
  (let loop ((remaining alist))
    (cond
     ((null? remaining) #f)
     ((eq? (caar remaining) key) (cdar remaining))
     (else (loop (cdr remaining))))))

(def (string-contains? value needle)
  (let ((value-length (string-length value))
        (needle-length (string-length needle)))
    (let loop ((index 0))
      (cond
       ((= needle-length 0) #t)
       ((> (+ index needle-length) value-length) #f)
       ((string-prefix-at? value needle index 0 needle-length) #t)
       (else (loop (+ index 1)))))))

(def (string-prefix-at? value needle value-index needle-index needle-length)
  (cond
   ((= needle-index needle-length) #t)
   ((char=? (string-ref value (+ value-index needle-index))
            (string-ref needle needle-index))
    (string-prefix-at? value
                       needle
                       value-index
                       (+ needle-index 1)
                       needle-length))
   (else #f)))

(def (stage-clause-payload stage kind)
  (let loop ((clauses (poo-flow-composition-stage-clauses stage)))
    (cond
     ((null? clauses) (error "missing composition clause" kind))
     ((equal? (.ref (car clauses) 'clause-kind) kind)
      (.ref (car clauses) 'payload))
     (else (loop (cdr clauses))))))

(def (single-stage composition)
  (car (poo-flow-composition-stages composition)))

(run-tests!
 (test-suite "langchain and langgraph user compositions"
  (test-case "langchain linear chain declares one production stage"
    (let* ((stage (single-stage langchain-linear-composition))
           (compose-payload (stage-clause-payload stage 'compose))
           (graph-payload (stage-clause-payload stage 'graph))
           (loop-payload (stage-clause-payload stage 'loop))
           (prove-payload (stage-clause-payload stage 'prove)))
      (check-equal? (poo-flow-composition? langchain-linear-composition) #t)
      (check-equal? (poo-flow-composition-name langchain-linear-composition)
                    'langchain-linear-composition)
      (check-equal? (length (poo-flow-composition-modules
                             langchain-linear-composition))
                    1)
      (check-equal? (poo-flow-composition-stage-name stage) 'production)
      (check-equal? (length compose-payload) 5)
      (check-equal? graph-payload '(langchain-linear-chain))
      (check-equal? (length loop-payload) 4)
      (check-equal? (cadr loop-payload) 1)
      (check-equal? (cadddr loop-payload) 'parsed-output)
      (check-equal? prove-payload
                    '(chain-order
                      prompt-before-model
                      parser-after-model
                      no-implicit-tool-branch))))

  (test-case "graph core proves the LangChain case is a total linear chain"
    (let* ((analysis (poo-flow-graph-control-analysis-receipt
                      langchain-linear-control-graph))
           (metadata (.ref analysis 'metadata)))
      (check-equal? (alist-value metadata 'entry-ids)
                    '(memory))
      (check-equal? (alist-value metadata 'finish-ids)
                    '(parsed-output))
      (check-equal? (poo-flow-graph-acyclic? langchain-linear-control-graph)
                    #t)
      (check-equal? (.ref analysis 'topological-order)
                    '(memory prompt model parser parsed-output))
      (check-equal? (.ref analysis 'diagnostics) '())
      (check-equal? (alist-value metadata 'finish-total?) #t)
      (check-equal? (alist-value metadata 'conditional-edge-pairs) '())
      (check-equal? (alist-value metadata 'dead-end-ids) '())))

  (test-case "local override keeps the reusable case and replaces one profile"
    (let* ((stage (single-stage audited-langchain-composition))
           (compose-payload (stage-clause-payload stage 'compose)))
      (check-equal? (length compose-payload) 5)
      (check-equal? (map (lambda (profile) (.ref profile 'name))
                         compose-payload)
                    '(langchain-stateless-memory
                      langchain-prompt-template
                      langchain-audited-chat-model
                      langchain-output-parser
                      langchain-no-tool))))

  (test-case "langgraph state graph declares bounded loop and handoff"
    (let* ((stage (single-stage langgraph-state-composition))
           (compose-payload (stage-clause-payload stage 'compose))
           (graph-payload (stage-clause-payload stage 'graph))
           (loop-payload (stage-clause-payload stage 'loop))
           (prove-payload (stage-clause-payload stage 'prove))
           (handoff-payload (stage-clause-payload stage 'handoff)))
      (check-equal? (poo-flow-composition? langgraph-state-composition) #t)
      (check-equal? (poo-flow-composition-name langgraph-state-composition)
                    'langgraph-state-composition)
      (check-equal? (length (poo-flow-composition-modules
                             langgraph-state-composition))
                    1)
      (check-equal? (poo-flow-composition-stage-name stage) 'production)
      (check-equal? (length compose-payload) 7)
      (check-equal? graph-payload '(langgraph-state-graph))
      (check-equal? (length loop-payload) 4)
      (check-equal? (cadr loop-payload) 8)
      (check-equal? (cadddr loop-payload) 'terminal-edge)
      (check-equal? prove-payload
                    '(declared-branch-targets
                      typed-state-merge
                      bounded-loop-progress
                      explicit-runtime-handoff))
      (check-equal? handoff-payload '(marlin-control-plane))))

  (test-case "graph core accepts explicit LangGraph loop edges"
    (let* ((analysis (poo-flow-graph-control-analysis-receipt
                      langgraph-state-control-graph))
           (metadata (.ref analysis 'metadata)))
      (check-equal? (alist-value metadata 'entry-ids)
                    '(session))
      (check-equal? (alist-value metadata 'finish-ids)
                    '(runtime-handoff))
      (check-equal? (poo-flow-graph-acyclic? langgraph-state-control-graph)
                    #f)
      (check-equal? (.ref analysis 'topological-order) #f)
      (check-equal? (.ref analysis 'diagnostics) '())
      (check-equal? (alist-value metadata 'branch-targets-declared?) #t)
      (check-equal? (alist-value metadata 'finish-total?) #t)
      (check-equal? (alist-value metadata 'loop-edge-pairs)
                    '((agent-node router) (tool-node router)))))

  (test-case "graph core reports undeclared LangGraph branch targets"
    (let* ((analysis (poo-flow-graph-control-analysis-receipt
                      langgraph-broken-branch-graph))
           (metadata (.ref analysis 'metadata))
           (diagnostics (.ref analysis 'diagnostics)))
      (check-equal? (alist-value metadata 'branch-targets-declared?) #f)
      (check-equal? (alist-value metadata 'finish-total?) #f)
      (check-equal? (alist-value diagnostics 'undeclared-edge-pairs)
                    '((router missing-node)))
      (check-equal? (alist-value diagnostics 'undeclared-branch-targets)
                    '(missing-node))))

  (test-case "runtime executor records a production LangGraph path"
    (let* ((receipt
            (poo-flow-graph-runtime-execute
             langgraph-production-runtime-graph
             langgraph-production-runtime-policy))
           (facts (poo-flow-graph-runtime-receipt->lean-facts receipt))
           (lean-source
            (poo-flow-graph-runtime-receipt->lean-module receipt)))
      (check-equal? (.ref receipt 'runtime-executed) #t)
      (check-equal? (.ref receipt 'finished) #t)
      (check-equal? (.ref receipt 'trace)
                    '(session
                      sandbox
                      router
                      retriever
                      router
                      agent-node
                      tool-node
                      checkpoint
                      human-approval
                      runtime-handoff))
      (check-equal? (.ref receipt 'fuel-after) 7)
      (check-equal? (.ref receipt 'diagnostics) '())
      (check-equal? (alist-value facts 'graph.runtime/executed) #t)
      (check-equal? (alist-value facts 'graph.runtime/finished) #t)
      (check-equal? (alist-value facts 'graph.runtime/handoff-reached) #t)
      (check-equal? (alist-value facts 'graph.runtime/checkpoint-persisted)
                    #t)
      (check-equal? (alist-value facts 'graph.runtime/human-approval-sound)
                    #t)
      (check-equal? (alist-value facts
                                 'graph.runtime/reusable-production-case)
                    #t)
      (check-equal? (poo-flow-graph-runtime-lean-fact-contract-complete?
                     facts)
                    #t)
      (check-equal? (string-contains?
                     lean-source
                     "def generatedProductionRuntimeFacts")
                    #t)
      (check-equal? (string-contains?
                     lean-source
                     "theorem generatedProductionRuntimeReusable")
                    #t)))

  (test-case "runtime executor rejects missing human approval"
    (let* ((receipt
            (poo-flow-graph-runtime-execute
             langgraph-production-runtime-graph
             langgraph-human-approval-missing-policy))
           (facts (poo-flow-graph-runtime-receipt->lean-facts receipt)))
      (check-equal? (.ref receipt 'finished) #t)
      (check-equal? (alist-value (.ref receipt 'diagnostics)
                                 'human-approval-missing)
                    'langgraph-production-runtime)
      (check-equal? (alist-value facts 'graph.runtime/human-approval-sound)
                    #f)
      (check-equal? (alist-value facts
                                 'graph.runtime/reusable-production-case)
                    #f)
      (check-equal? (poo-flow-graph-runtime-lean-fact-contract-complete?
                     facts)
                    #t)))))
