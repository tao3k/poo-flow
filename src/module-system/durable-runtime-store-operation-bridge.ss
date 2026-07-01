;;; -*- Gerbil -*-
;;; Boundary: bridge durable rows into runtime-store operation receipts.
;;; Invariant: this is a functional projection layer only; Scheme does not
;;; append logs, claim leases, retain artifacts, or attach sandbox handles.

(import :poo-flow/src/module-system/durable-runtime-store-operation)

(export poo-flow-durable-runtime-store-operations-from-rows
        poo-flow-durable-runtime-store-rows->marlin-handoff)

(def (bridge-ref row key default-value)
  (if (list? row)
    (let (entry (assoc key row))
      (if entry (cdr entry) default-value))
    default-value))

(def (bridge-symbols value)
  (cond
   ((symbol? value) (list value))
   ((pair? value)
    (append (bridge-symbols (car value))
            (bridge-symbols (cdr value))))
   (else '())))

(def (bridge-unique symbols seen)
  (cond
   ((null? symbols) '())
   ((member (car symbols) seen)
    (bridge-unique (cdr symbols) seen))
   (else
    (cons (car symbols)
          (bridge-unique (cdr symbols)
                         (cons (car symbols) seen))))))

(def (bridge-symbol-refs value)
  (bridge-unique (bridge-symbols value) '()))

(def (bridge-options target-ref causal-refs)
  (append
   (if target-ref
     (list (cons 'target-ref target-ref))
     '())
   (list (cons 'causal-refs (bridge-symbol-refs causal-refs)))))

(def (bridge-operation negotiation
                       operation-id
                       operation-kind
                       source-kind
                       row
                       target-ref
                       causal-refs)
  (poo-flow-durable-runtime-store-operation
   operation-id
   operation-kind
   negotiation
   (list (cons 'source-kind source-kind)
         (cons 'source-row row))
   (bridge-options target-ref causal-refs)))

(def (bridge-session-graph-operation negotiation row)
  (and row
       (bridge-operation
        negotiation
        (bridge-ref row 'root-session-ref
                    (bridge-ref row 'project-id 'session-graph))
        'append-fact
        'session-graph
        row
        #f
        (list (bridge-ref row 'root-session-ref #f)
              (bridge-ref row 'session-ids '())))))

(def (bridge-communication-operation negotiation row)
  (bridge-operation
   negotiation
   (bridge-ref row 'channel-id 'communication-event)
   'append-communication-event
   'session-communication
   row
   (bridge-ref row 'communication-ledger-ref #f)
   (list (bridge-ref row 'source-session-id #f)
         (bridge-ref row 'target-session-id #f)
         (bridge-ref row 'channel-id #f))))

(def (bridge-memory-job-operation negotiation row)
  (bridge-operation
   negotiation
   (bridge-ref row 'job-id 'memory-job)
   'claim-job-lease
   'memory-durable-job
   row
   (bridge-ref row 'job-store-ref #f)
   (list (bridge-ref row 'job-id #f)
         (bridge-ref row 'session-id #f)
         (bridge-ref row 'source-ref #f))))

(def (bridge-workflow-task-operation negotiation row)
  (bridge-operation
   negotiation
   (bridge-ref row 'durable-task-id
               (bridge-ref row 'check 'workflow-task))
   'append-fact
   'workflow-task
   row
   #f
   (list (bridge-ref row 'durable-task-id #f)
         (bridge-ref row 'checkpoint-ref #f)
         (bridge-ref row 'sandbox-refs '()))))

(def (bridge-artifact-operation negotiation artifact-ref)
  (bridge-operation
   negotiation
   artifact-ref
   'retain-artifact
   'workflow-artifact
   (list (cons 'artifact-ref artifact-ref))
   #f
   (list artifact-ref)))

(def (bridge-sandbox-operation negotiation sandbox-ref)
  (bridge-operation
   negotiation
   sandbox-ref
   'attach-sandbox-handle
   'sandbox-handle
   (list (cons 'sandbox-ref sandbox-ref))
   #f
   (list sandbox-ref)))

(def (bridge-row-symbol-refs rows key)
  (if (pair? rows)
    (append (bridge-symbol-refs (bridge-ref (car rows) key '()))
            (bridge-row-symbol-refs (cdr rows) key))
    '()))

(def (poo-flow-durable-runtime-store-operations-from-rows negotiation
                                                          session-graph-row
                                                          communication-rows
                                                          memory-job-rows
                                                          workflow-task-rows
                                                          sandbox-refs)
  (let* ((session-graph-operation
          (bridge-session-graph-operation negotiation session-graph-row))
         (artifact-refs
          (bridge-unique (bridge-row-symbol-refs workflow-task-rows
                                                 'artifact-refs)
                         '()))
         (all-sandbox-refs
          (bridge-unique
           (append (bridge-symbol-refs sandbox-refs)
                   (bridge-row-symbol-refs workflow-task-rows 'sandbox-refs))
           '())))
    (append
     (if session-graph-operation (list session-graph-operation) '())
     (map (lambda (row)
            (bridge-communication-operation negotiation row))
          communication-rows)
     (map (lambda (row)
            (bridge-memory-job-operation negotiation row))
          memory-job-rows)
     (map (lambda (row)
            (bridge-workflow-task-operation negotiation row))
          workflow-task-rows)
     (map (lambda (artifact-ref)
            (bridge-artifact-operation negotiation artifact-ref))
          artifact-refs)
     (map (lambda (sandbox-ref)
            (bridge-sandbox-operation negotiation sandbox-ref))
          all-sandbox-refs))))

(def (poo-flow-durable-runtime-store-rows->marlin-handoff negotiation
                                                          session-graph-row
                                                          communication-rows
                                                          memory-job-rows
                                                          workflow-task-rows
                                                          sandbox-refs)
  (poo-flow-durable-runtime-store-operations->marlin-handoff
   negotiation
   (poo-flow-durable-runtime-store-operations-from-rows
    negotiation
    session-graph-row
    communication-rows
    memory-job-rows
    workflow-task-rows
    sandbox-refs)))
