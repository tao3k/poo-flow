;;; -*- Gerbil -*-
;;; Boundary: session graph predicates and presentation receipts.
;;; Invariant: graph helpers inspect report-only session objects.

(import (only-in :clan/poo/object object<-alist)
        :poo-flow/src/modules/session/objects-core)

(export poo-flow-session-by-id
        poo-flow-session-lineage-edge-pairs
        poo-flow-session-graph-edge-pairs
        poo-flow-session-graph-acyclic?
        pooFlowSessionGraphPresentation)

;;; Boundary: session by id is the policy-visible edge for object behavior,
;;; keeping validation, lookup, or projection responsibilities centralized for
;;; callers.
;; : (-> [PooSession] Symbol MaybePooSession)
(def (poo-flow-session-by-id sessions session-id)
  (cond
   ((null? sessions) #f)
   ((eq? (poo-flow-session-id (car sessions)) session-id) (car sessions))
   (else
    (poo-flow-session-by-id (cdr sessions) session-id))))

;;; Boundary: session lineage edge pairs is the policy-visible edge for object
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> PooSession [Pair])
(def (poo-flow-session-lineage-edge-pairs session)
  (reverse (poo-flow-session-lineage-edge-pairs/rev session '())))

;; : (-> PooSession [Pair] [Pair])
(def (poo-flow-session-lineage-edge-pairs/rev session edge-pairs)
  (let ((session-id (poo-flow-session-id session))
        (parent-session-ids
         (poo-flow-session-lineage-parent-session-ids
          (poo-flow-session-value-lineage session))))
    (foldl (lambda (parent-session-id edge-pair-values)
             (cons (cons parent-session-id session-id) edge-pair-values))
           edge-pairs
           parent-session-ids)))

;;; Boundary: session graph edge pairs is the policy-visible edge for object
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> [PooSession] [Pair])
(def (poo-flow-session-graph-edge-pairs sessions)
  (reverse
   (foldl (lambda (session edge-pair-values)
            (poo-flow-session-lineage-edge-pairs/rev
             session
             edge-pair-values))
          '()
          sessions)))

;;; Boundary: session index is the policy-visible edge for object behavior,
;;; keeping validation, lookup, or projection responsibilities centralized for
;;; callers.
;; : (-> [PooSession] HashTable)
(def (poo-flow-session-index sessions)
  (let (index (make-hash-table))
    (for-each
     (lambda (session)
       (hash-put! index (poo-flow-session-id session) session))
     sessions)
    index))

;;; Cycle detection walks parent links by session id only. Missing parents are
;;; treated as external roots so partial user-interface cases remain inspectable.
;; : (-> [PooSession] Symbol [Symbol] Boolean)
(def (poo-flow-session-graph-acyclic-from? sessions session-id path)
  (cond
   ((memq session-id path) #f)
   (else
    (let (session (poo-flow-session-by-id sessions session-id))
      (if session
        (poo-flow-session-every?
         (lambda (parent-id)
           (poo-flow-session-graph-acyclic-from?
            sessions
            parent-id
            (cons session-id path)))
          (poo-flow-session-lineage-parent-session-ids
           (poo-flow-session-value-lineage session)))
        #t)))))

;;; Boundary: session graph acyclic from index predicate is the policy-visible
;;; edge for object behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> HashTable HashTable Symbol Boolean)
(def (poo-flow-session-graph-acyclic-from-index? session-index visit-states session-id)
  (let (state (hash-get visit-states session-id))
    (cond
     ((eq? state 'visiting) #f)
     ((eq? state 'done) #t)
     (else
      (let (session (hash-get session-index session-id))
        (if session
          (begin
            (hash-put! visit-states session-id 'visiting)
            (let (acyclic?
                  (poo-flow-session-every?
                   (lambda (parent-id)
                     (poo-flow-session-graph-acyclic-from-index?
                      session-index
                      visit-states
                      parent-id))
                   (poo-flow-session-lineage-parent-session-ids
                    (poo-flow-session-value-lineage session))))
              (if acyclic?
                (hash-put! visit-states session-id 'done)
                #f)
              acyclic?))
          #t))))))

;;; Boundary: session graph acyclic predicate is the policy-visible edge for
;;; object behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> [PooSession] Boolean)
(def (poo-flow-session-graph-acyclic? sessions)
  (let ((session-index (poo-flow-session-index sessions))
        (visit-states (make-hash-table)))
    (poo-flow-session-every?
     (lambda (session)
       (poo-flow-session-graph-acyclic-from-index?
        session-index
        visit-states
        (poo-flow-session-id session)))
     sessions)))

;;; The graph presentation is intentionally compact. It exposes ids, edges,
;;; placement refs, and runtime flags without embedding the full session object
;;; graph in downstream receipts.
;; : (-> [PooSession] List)
(def (poo-flow-session-graph-presentation-summary sessions)
  (foldl (lambda (session summary)
           (let* ((session-count-value (car summary))
                  (session-id-values (cadr summary))
                  (chunk-count-value (caddr summary))
                  (lineage-edge-pair-values (cadddr summary))
                  (placement-summary-values (cddddr summary))
                  (placement-profile-ref-values (car placement-summary-values))
                  (placement-resolved-values (cadr placement-summary-values))
                  (placement-diagnostic-values (caddr placement-summary-values))
                  (placement (poo-flow-session-value-placement session)))
             (list
              (+ session-count-value 1)
              (cons (poo-flow-session-id session) session-id-values)
              (+ chunk-count-value (length (poo-flow-session-chunks session)))
              (poo-flow-session-lineage-edge-pairs/rev
               session
               lineage-edge-pair-values)
              (cons (poo-flow-session-placement-profile-ref placement)
                    placement-profile-ref-values)
              (cons (poo-flow-session-placement-resolved? placement)
                    placement-resolved-values)
              (cons (poo-flow-session-placement-diagnostics placement)
                    placement-diagnostic-values))))
         '(0 () 0 () () () ())
         sessions))

;; : (-> [PooSession] PooSessionGraphPresentation)
(def (pooFlowSessionGraphPresentation sessions)
  (poo-flow-session-require "session graph presentation requires sessions"
                            (list? sessions)
                            sessions)
  (poo-flow-session-require
   "session graph presentation entries must be sessions"
   (poo-flow-session-every? poo-flow-session? sessions)
   sessions)
  (let* ((summary (poo-flow-session-graph-presentation-summary sessions))
         (session-count-value (car summary))
         (session-id-values (reverse (cadr summary)))
         (chunk-count-value (caddr summary))
         (lineage-edge-pair-values (reverse (cadddr summary)))
         (placement-summary-values (cddddr summary))
         (placement-profile-ref-values (reverse (car placement-summary-values)))
         (placement-resolved-values (reverse (cadr placement-summary-values)))
         (placement-diagnostic-values (reverse (caddr placement-summary-values))))
    (object<-alist
     (list
      (cons 'kind 'poo-flow.session.graph.presentation)
      (cons 'schema 'poo-flow.modules.session.graph-presentation.v1)
      (cons 'session-count session-count-value)
      (cons 'session-ids session-id-values)
      (cons 'chunk-count chunk-count-value)
      (cons 'lineage-edge-pairs lineage-edge-pair-values)
      (cons 'acyclic? (poo-flow-session-graph-acyclic? sessions))
      (cons 'placement-profile-refs placement-profile-ref-values)
      (cons 'placement-resolved? placement-resolved-values)
      (cons 'placement-diagnostics placement-diagnostic-values)
      (cons 'runtime-owner "marlin-agent-core")
      (cons 'runtime-executed #f)
      (cons 'descriptor-realized? #f)
      (cons 'replayable #t)))))
