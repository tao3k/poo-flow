;;; -*- Gerbil -*-
;;; Boundary: report-only project/root/child session registry receipts.
;;; Invariant: the registry is a projection, not a live runtime store.

(import (only-in :clan/poo/object .o .ref object?)
        :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/policy)

(export poo-flow-session-registry-entry
        poo-flow-session-registry-entry?
        poo-flow-session-registry-entry-session-id
        poo-flow-session-registry-entry-agent-id
        poo-flow-session-registry-entry-parent-session-ids
        poo-flow-session-registry-receipt
        poo-flow-session-registry-receipt?
        poo-flow-session-registry-receipt-project-id
        poo-flow-session-registry-receipt-session-ids
        poo-flow-session-registry-receipt-entries
        poo-flow-session-registry-receipt->alist)

;; : (-> Alist Symbol Value Value)
(def (poo-flow-session-registry-policy-ref summaries key default)
  (let (entry (assoc key summaries))
    (if entry (cdr entry) default)))

;; : (-> Alist Symbol Value Value)
(def (poo-flow-session-registry-alist-ref row key default)
  (let (entry (and (list? row) (assoc key row)))
    (if entry (cdr entry) default)))

;;; Boundary: registry callers construct explicit field pairs; this function
;;; preserves their order without introducing a syntax-only row language.
;; : (-> (List (Pair Symbol Object)) (List (Pair Symbol Object)))
(def (poo-flow-session-registry-field-rows . rows)
  rows)

;; : (-> Alist MaybeSymbol)
(def (poo-flow-session-registry-durable-policy-ref policy-summaries)
  (let (durable-summary
        (poo-flow-session-registry-policy-ref
         policy-summaries
         'durable
         '()))
    (poo-flow-session-registry-alist-ref
     durable-summary
     'policy-id
     #f)))

;; : (-> [PooSessionRegistryEntry] SessionRegistryEntrySummary)
(def (poo-flow-session-registry-entry-summary entries)
  (list
   (map poo-flow-session-registry-entry-session-id entries)
   (filter-map
    (lambda (entry)
      (poo-flow-session-alist-ref entry 'durable-policy-ref #f))
    entries)))

;;; Boundary: registry entries preserve parent/child session identity and
;;; allowed communication refs for later lookup policy.
;; : (-> PooSession Symbol [Symbol] Alist [Alist] PooSessionRegistryEntry)
(def (poo-flow-session-registry-entry session
                                      agent-id
                                      communication-channels
                                      policy-summaries
                                      . maybe-metadata)
  (poo-flow-session-require "session registry entry requires a session"
                            (poo-flow-session? session)
                            session)
  (poo-flow-session-require "session registry agent id must be a symbol"
                            (symbol? agent-id)
                            agent-id)
  (poo-flow-session-require "session registry channels must be symbols"
                            (poo-flow-session-every?
                             symbol?
                             communication-channels)
                            communication-channels)
  (poo-flow-session-require "session registry policies must be an alist"
                            (list? policy-summaries)
                            policy-summaries)
  (let* ((session-id-value (poo-flow-session-id session))
         (lineage-value (poo-flow-session-value-lineage session))
         (placement-value (poo-flow-session-value-placement session)))
    (poo-flow-session-registry-field-rows
     (cons 'kind 'poo-flow.session.registry-entry)
     (cons 'schema 'poo-flow.modules.session.registry-entry.v1)
     (cons 'session-id session-id-value)
     (cons 'parent-session-ids
      (poo-flow-session-lineage-parent-session-ids lineage-value))
     (cons 'agent-id agent-id)
     (cons 'placement-profile-ref
      (poo-flow-session-placement-profile-ref placement-value))
     (cons 'placement-resolved?
      (poo-flow-session-placement-resolved? placement-value))
     (cons 'communication-channels communication-channels)
     (cons 'isolation-policy-summary
      (poo-flow-session-registry-policy-ref
       policy-summaries
       'isolation
       '()))
     (cons 'sandbox-policy-summary
      (poo-flow-session-registry-policy-ref
       policy-summaries
       'sandbox
       '()))
     (cons 'context-policy-summary
      (poo-flow-session-registry-policy-ref
       policy-summaries
       'context
       '()))
     (cons 'history-policy-summary
      (poo-flow-session-registry-policy-ref
       policy-summaries
       'history
       '()))
     (cons 'sharing-policy-summary
      (poo-flow-session-registry-policy-ref
       policy-summaries
       'sharing
       '()))
     (cons 'resource-policy-summary
      (poo-flow-session-registry-policy-ref
       policy-summaries
       'resource
       '()))
     (cons 'durable-policy-summary
      (poo-flow-session-registry-policy-ref
       policy-summaries
       'durable
       '()))
     (cons 'durable-policy-ref
      (poo-flow-session-registry-durable-policy-ref policy-summaries))
     (cons 'materialization-state 'declared)
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'runtime-executed #f)
     (cons 'metadata (if (null? maybe-metadata)
                 '()
                 (car maybe-metadata))))))

;; : (-> Datum Boolean)
(def (poo-flow-session-registry-entry? value)
  (and (list? value)
       (eq? (poo-flow-session-alist-ref value 'kind #f)
            'poo-flow.session.registry-entry)))

;; : (-> PooSessionRegistryEntry Symbol)
(def (poo-flow-session-registry-entry-session-id entry)
  (poo-flow-session-alist-ref entry 'session-id #f))

;; : (-> PooSessionRegistryEntry Symbol)
(def (poo-flow-session-registry-entry-agent-id entry)
  (poo-flow-session-alist-ref entry 'agent-id #f))

;; : (-> PooSessionRegistryEntry [Symbol])
(def (poo-flow-session-registry-entry-parent-session-ids entry)
  (poo-flow-session-alist-ref entry 'parent-session-ids '()))

;; : (-> Symbol [Symbol] [Symbol] Symbol [PooSessionRegistryEntry] [Alist] PooSessionRegistryReceipt)
(def (poo-flow-session-registry-receipt project-id
                                        root-session-ids
                                        child-session-ids
                                        active-session-ref
                                        entries
                                        . maybe-metadata)
  (poo-flow-session-require "session registry project id must be a symbol"
                            (symbol? project-id)
                            project-id)
  (poo-flow-session-require "session registry roots must be symbols"
                            (poo-flow-session-every?
                             symbol?
                             root-session-ids)
                            root-session-ids)
  (poo-flow-session-require "session registry children must be symbols"
                            (poo-flow-session-every?
                             symbol?
                             child-session-ids)
                            child-session-ids)
  (poo-flow-session-require "session registry active ref must be a symbol"
                            (symbol? active-session-ref)
                            active-session-ref)
  (poo-flow-session-require "session registry entries must be entries"
                            (poo-flow-session-every?
                             poo-flow-session-registry-entry?
                             entries)
                            entries)
  ;; `.o` slot bodies treat a bare identifier matching the slot name as
  ;; self-dispatch. Capture constructor inputs under distinct lexical names so
  ;; receipt reads cannot turn into recursive project-id/session-id lookups.
  (let* ((project-id-value project-id)
         (root-session-id-values root-session-ids)
         (child-session-id-values child-session-ids)
         (active-session-ref-value active-session-ref)
         (entry-values entries)
         (metadata-value
          (if (null? maybe-metadata) '() (car maybe-metadata)))
         (entry-summary
          (poo-flow-session-registry-entry-summary entry-values))
         (session-id-values (car entry-summary))
         (durable-policy-ref-values (cadr entry-summary)))
    (.o (kind 'poo-flow.session.registry-receipt)
        (schema 'poo-flow.modules.session.registry-receipt.v1)
        (project-id project-id-value)
        (root-session-ids root-session-id-values)
        (child-session-ids child-session-id-values)
        (session-ids session-id-values)
        (active-session-ref active-session-ref-value)
        (durable-policy-refs durable-policy-ref-values)
        (entry-count (length entry-values))
        (entries entry-values)
        (runtime-owner "marlin-agent-core")
        (runtime-executed #f)
        (metadata metadata-value))))

;; : (-> POOObject Boolean)
(def (poo-flow-session-registry-receipt? value)
  (and (object? value)
       (eq? (.ref value 'kind)
            'poo-flow.session.registry-receipt)))

;; : (-> PooSessionRegistryReceipt Symbol)
(def (poo-flow-session-registry-receipt-project-id receipt)
  (.ref receipt 'project-id))

;; : (-> PooSessionRegistryReceipt [Symbol])
(def (poo-flow-session-registry-receipt-session-ids receipt)
  (.ref receipt 'session-ids))

;; : (-> PooSessionRegistryReceipt [PooSessionRegistryEntry])
(def (poo-flow-session-registry-receipt-entries receipt)
  (.ref receipt 'entries))

;; : (-> PooSessionRegistryReceipt Alist)
(def (poo-flow-session-registry-receipt->alist receipt)
  (poo-flow-session-require
   "session registry projection requires a receipt"
   (poo-flow-session-registry-receipt? receipt)
   receipt)
  (list
   (cons 'kind (.ref receipt 'kind))
   (cons 'schema (.ref receipt 'schema))
   (cons 'project-id (.ref receipt 'project-id))
   (cons 'root-session-ids (.ref receipt 'root-session-ids))
   (cons 'child-session-ids (.ref receipt 'child-session-ids))
   (cons 'session-ids (.ref receipt 'session-ids))
   (cons 'active-session-ref (.ref receipt 'active-session-ref))
   (cons 'durable-policy-refs (.ref receipt 'durable-policy-refs))
   (cons 'entry-count (.ref receipt 'entry-count))
   (cons 'entries (.ref receipt 'entries))
   (cons 'runtime-owner (.ref receipt 'runtime-owner))
   (cons 'runtime-executed (.ref receipt 'runtime-executed))
   (cons 'metadata (.ref receipt 'metadata))))
