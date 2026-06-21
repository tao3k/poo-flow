;;; -*- Gerbil -*-
;;; Boundary: report-only session dataflow objects.
;;; Invariant: sessions describe chunks, lineage, placement, and handoff intent;
;;; they never execute runtime work in Scheme.

(import (only-in :clan/poo/object .o .ref object?)
        (only-in :poo-flow/src/modules/agent-sandbox/config
                 poo-flow-sandbox-profile-by-name
                 poo-flow-sandbox-profile-handoff-summary
                 poo-flow-sandbox-profile-runtime-summary))

(export poo-flow-session-require
        poo-flow-session-every?
        poo-flow-session-alist-ref
        poo-flow-session-chunk
        poo-flow-session-chunk?
        poo-flow-session-chunk-id
        poo-flow-session-chunk-role
        poo-flow-session-chunk-content
        poo-flow-session-lineage
        poo-flow-session-lineage?
        poo-flow-session-lineage-session-id
        poo-flow-session-lineage-parent-session-ids
        poo-flow-session-placement
        poo-flow-session-placement?
        poo-flow-session-placement-profile-ref
        poo-flow-session-placement-resolved?
        poo-flow-session-placement-diagnostics
        poo-flow-session-placement-runtime-summary
        poo-flow-session-placement-handoff-summary
        poo-flow-session-placement-resolve
        poo-flow-session-value
        poo-flow-session?
        poo-flow-session-id
        poo-flow-session-chunks
        poo-flow-session-value-lineage
        poo-flow-session-value-placement
        poo-flow-session-metadata
        poo-flow-session-handoff
        poo-flow-session-handoff?
        poo-flow-session-by-id
        poo-flow-session-lineage-edge-pairs
        poo-flow-session-graph-edge-pairs
        poo-flow-session-graph-acyclic?
        pooFlowSessionGraphPresentation)

;;; Validation returns the original value so constructors can keep compact
;;; sequential guard clauses before building report-only session rows.
;; : (-> String Boolean Value Value)
(def (poo-flow-session-require message condition value)
  (if condition
    value
    (error message value)))

;;; Local list validation avoids bringing a heavier contract layer into the
;;; user-interface session declaration path.
;; : (-> Procedure List Boolean)
(def (poo-flow-session-every? predicate values)
  (cond
   ((null? values) #t)
   ((predicate (car values))
    (poo-flow-session-every? predicate (cdr values)))
   (else #f)))

;;; Alist lookup is shared by chunk rows and tests because chunks remain simple
;;; wire data while session values are POO objects.
;; : (-> Symbol Alist Value Value)
(def (poo-flow-session-alist-ref entries key default)
  (let (entry (assoc key entries))
    (if entry (cdr entry) default)))

;;; Compact optional diagnostic rows without depending on a broader list
;;; library in this low-level user-interface module.
;; : (-> [MaybeValue] [Value])
(def (poo-flow-session-compact values)
  (cond
   ((null? values) '())
   ((car values)
    (cons (car values) (poo-flow-session-compact (cdr values))))
   (else
    (poo-flow-session-compact (cdr values)))))

;;; Chunks are receipt rows, not extension surfaces. Keeping them as primitive
;;; rows prevents presentation code from repeatedly instantiating child POO
;;; objects while still preserving typed user-visible data.
;; : (-> Symbol Symbol String [Alist] PooSessionChunk)
(def (poo-flow-session-chunk chunk-id role content . maybe-metadata)
  (poo-flow-session-require "session chunk id must be a symbol"
                            (symbol? chunk-id)
                            chunk-id)
  (poo-flow-session-require "session chunk role must be a symbol"
                            (symbol? role)
                            role)
  (poo-flow-session-require "session chunk content must be a string"
                            (string? content)
                            content)
  (list (cons 'kind 'poo-flow.session.chunk)
        (cons 'schema 'poo-flow.modules.session.chunk.v1)
        (cons 'chunk-id chunk-id)
        (cons 'role role)
        (cons 'content content)
        (cons 'visibility 'public)
        (cons 'metadata (if (null? maybe-metadata) '() (car maybe-metadata)))
        (cons 'runtime-executed #f)))

;;; Chunk predicates stay alist-based by design: a session may contain many
;;; chunks, so each row must be cheap to validate inside graph traversals.
;; : (-> Value Boolean)
(def (poo-flow-session-chunk? value)
  (and (list? value)
       (eq? (poo-flow-session-alist-ref value 'kind #f)
            'poo-flow.session.chunk)))

;; : (-> PooSessionChunk Symbol)
(def (poo-flow-session-chunk-id chunk)
  (poo-flow-session-alist-ref chunk 'chunk-id #f))

;; : (-> PooSessionChunk Symbol)
(def (poo-flow-session-chunk-role chunk)
  (poo-flow-session-alist-ref chunk 'role #f))

;; : (-> PooSessionChunk String)
(def (poo-flow-session-chunk-content chunk)
  (poo-flow-session-alist-ref chunk 'content #f))

;;; Lineage is a mixin prototype. Its slots are inherited by the final session
;;; object, so callers inspect direct session slots instead of a nested lineage
;;; child object.
;; : (-> Symbol [Symbol] Symbol [Alist] PooSessionLineage)
(def (poo-flow-session-lineage session-id parent-session-ids branch-kind
                               . maybe-metadata)
  (poo-flow-session-require "session lineage id must be a symbol"
                            (symbol? session-id)
                            session-id)
  (poo-flow-session-require "session lineage parents must be a list"
                            (list? parent-session-ids)
                            parent-session-ids)
  (poo-flow-session-require
   "session lineage parents must contain only symbols"
   (poo-flow-session-every? symbol? parent-session-ids)
   parent-session-ids)
  (poo-flow-session-require "session lineage branch kind must be a symbol"
                            (symbol? branch-kind)
                            branch-kind)
  (let ((lineage-session-id-value session-id)
        (lineage-parent-session-ids-value parent-session-ids)
        (lineage-branch-kind-value branch-kind)
        (lineage-metadata-value
         (if (null? maybe-metadata) '() (car maybe-metadata))))
    (.o lineage-kind: 'poo-flow.session.lineage
        lineage-schema: 'poo-flow.modules.session.lineage.v1
        lineage-session-id: lineage-session-id-value
        parent-session-ids: lineage-parent-session-ids-value
        branch-kind: lineage-branch-kind-value
        lineage-metadata: lineage-metadata-value
        lineage-runtime-executed: #f)))

;; : (-> Value Boolean)
(def (poo-flow-session-lineage? value)
  (and (object? value)
       (eq? (.ref value 'lineage-kind)
            'poo-flow.session.lineage)))

;;; The lineage id accessor is used before composition to prove the mixin
;;; belongs to the session being built.
;; : (-> PooSessionLineage Symbol)
(def (poo-flow-session-lineage-session-id lineage)
  (.ref lineage 'lineage-session-id))

;; : (-> PooSessionLineage [Symbol])
(def (poo-flow-session-lineage-parent-session-ids lineage)
  (.ref lineage 'parent-session-ids))

;;; Placement is also a mixin prototype. Backend resolution remains report-only
;;; here; real sandbox execution is owned by Marlin or a backend runtime.
;; : (-> Symbol [Alist] PooSessionPlacement)
(def (poo-flow-session-placement profile-ref . maybe-metadata)
  (poo-flow-session-require "session placement profile ref must be a symbol"
                            (symbol? profile-ref)
                            profile-ref)
  (let ((placement-profile-ref-value profile-ref)
        (placement-metadata-value
         (if (null? maybe-metadata) '() (car maybe-metadata))))
    (.o placement-kind: 'poo-flow.session.placement
        placement-schema: 'poo-flow.modules.session.placement.v1
        placement-profile-ref: placement-profile-ref-value
        placement-resolved?: #f
        placement-diagnostics: '()
        placement-runtime-summary: '()
        placement-handoff-summary: '()
        placement-metadata: placement-metadata-value
        placement-runtime-executed: #f)))

;; : (-> Value Boolean)
(def (poo-flow-session-placement? value)
  (and (object? value)
       (eq? (.ref value 'placement-kind)
            'poo-flow.session.placement)))

;; : (-> PooSessionPlacement Symbol)
(def (poo-flow-session-placement-profile-ref placement)
  (.ref placement 'placement-profile-ref))

;; : (-> PooSessionPlacement Boolean)
(def (poo-flow-session-placement-resolved? placement)
  (.ref placement 'placement-resolved?))

;; : (-> PooSessionPlacement [Alist])
(def (poo-flow-session-placement-diagnostics placement)
  (.ref placement 'placement-diagnostics))

;; : (-> PooSessionPlacement Alist)
(def (poo-flow-session-placement-runtime-summary placement)
  (.ref placement 'placement-runtime-summary))

;; : (-> PooSessionPlacement Alist)
(def (poo-flow-session-placement-handoff-summary placement)
  (.ref placement 'placement-handoff-summary))

;; : (-> Symbol Symbol Any Alist)
(def (poo-flow-session-placement-summary-failure profile-ref phase failure)
  (list (cons 'kind 'poo-flow.session.placement.diagnostic)
        (cons 'status 'summary-failed)
        (cons 'profile-ref profile-ref)
        (cons 'phase phase)
        (cons 'message (object->string failure))))

;; : (-> Symbol Alist)
(def (poo-flow-session-placement-missing-diagnostic profile-ref)
  (list (cons 'kind 'poo-flow.session.placement.diagnostic)
        (cons 'status 'missing-profile)
        (cons 'profile-ref profile-ref)
        (cons 'message "placement profile was not found in the catalog")))

;;; Summary projection is report-only. A malformed sandbox profile becomes a
;;; diagnostic row instead of aborting session graph construction.
;; : (-> Symbol Symbol Procedure PooSandboxProfile Pair)
(def (poo-flow-session-placement-summary profile-ref phase summarizer profile)
  (with-catch
   (lambda (failure)
     (cons '()
           (poo-flow-session-placement-summary-failure
            profile-ref
            phase
            failure)))
   (lambda ()
     (cons (summarizer profile) #f))))

;;; Resolve a placement ref against an existing sandbox profile catalog. The
;;; returned value is still a placement mixin prototype; it records validation
;;; receipts but never realizes or executes a sandbox runtime.
;; : (-> Symbol [PooSandboxProfile] [Alist] PooSessionPlacement)
(def (poo-flow-session-placement-resolve profile-ref profiles . maybe-metadata)
  (poo-flow-session-require "session placement profile ref must be a symbol"
                            (symbol? profile-ref)
                            profile-ref)
  (poo-flow-session-require "session placement catalog must be a list"
                            (list? profiles)
                            profiles)
  (let* ((profile-ref-value profile-ref)
         (profile (poo-flow-sandbox-profile-by-name profiles profile-ref-value))
         (placement-metadata-value
          (if (null? maybe-metadata) '() (car maybe-metadata))))
    (if profile
      (let* ((runtime-result
              (poo-flow-session-placement-summary
               profile-ref-value
               'runtime-summary
               poo-flow-sandbox-profile-runtime-summary
               profile))
             (handoff-result
              (poo-flow-session-placement-summary
               profile-ref-value
               'handoff-summary
               poo-flow-sandbox-profile-handoff-summary
               profile))
             (runtime-summary-value (car runtime-result))
             (handoff-summary-value (car handoff-result))
             (diagnostics-value
              (poo-flow-session-compact
               (list (cdr runtime-result) (cdr handoff-result))))
             (resolved-value
              (and runtime-summary-value
                   handoff-summary-value
                   (null? diagnostics-value))))
        (.o placement-kind: 'poo-flow.session.placement
            placement-schema: 'poo-flow.modules.session.placement.v1
            placement-profile-ref: profile-ref-value
            placement-resolved?: resolved-value
            placement-diagnostics: diagnostics-value
            placement-runtime-summary: runtime-summary-value
            placement-handoff-summary: handoff-summary-value
            placement-metadata: placement-metadata-value
            placement-runtime-executed: #f))
      (.o placement-kind: 'poo-flow.session.placement
          placement-schema: 'poo-flow.modules.session.placement.v1
          placement-profile-ref: profile-ref-value
          placement-resolved?: #f
          placement-diagnostics:
          (list (poo-flow-session-placement-missing-diagnostic
                 profile-ref-value))
          placement-runtime-summary: '()
          placement-handoff-summary: '()
          placement-metadata: placement-metadata-value
          placement-runtime-executed: #f))))

;;; Compose lineage and placement with C3 POO inheritance. Local variable names
;;; intentionally differ from slot names to avoid fixed-point self-reference
;;; such as `chunks: chunks`.
;; : (-> Symbol [PooSessionChunk] PooSessionLineage PooSessionPlacement [Alist] PooSession)
(def (poo-flow-session-value session-id chunks lineage placement . maybe-metadata)
  (poo-flow-session-require "session id must be a symbol"
                            (symbol? session-id)
                            session-id)
  (poo-flow-session-require "session chunks must be a list"
                            (list? chunks)
                            chunks)
  (poo-flow-session-require "session chunks must contain only session chunks"
                            (poo-flow-session-every?
                             poo-flow-session-chunk?
                             chunks)
                            chunks)
  (poo-flow-session-require "session lineage must match the session id"
                            (and (poo-flow-session-lineage? lineage)
                                 (eq? (poo-flow-session-lineage-session-id
                                       lineage)
                                      session-id))
                            lineage)
  (poo-flow-session-require "session placement must be a session placement"
                            (poo-flow-session-placement? placement)
                            placement)
  (let ((session-id-value session-id)
        (chunk-values chunks)
        (lineage-prototype lineage)
        (placement-prototype placement)
        (session-metadata-value
         (append '((declared-by . poo-flow-session-module)
                   (runtime-executed . #f))
                 (if (null? maybe-metadata) '() (car maybe-metadata)))))
    (.o (:: @ [lineage-prototype placement-prototype])
        kind: 'poo-flow.session.value
        schema: 'poo-flow.modules.session.value.v1
        session-id: session-id-value
        chunks: chunk-values
        metadata: session-metadata-value
        runtime-executed: #f)))

;; : (-> Value Boolean)
(def (poo-flow-session? value)
  (and (object? value)
       (eq? (.ref value 'kind) 'poo-flow.session.value)))

;; : (-> PooSession Symbol)
(def (poo-flow-session-id session)
  (.ref session 'session-id))

;; : (-> PooSession [PooSessionChunk])
(def (poo-flow-session-chunks session)
  (.ref session 'chunks))

;; : (-> PooSession PooSessionLineage)
(def (poo-flow-session-value-lineage session)
  session)

;; : (-> PooSession PooSessionPlacement)
(def (poo-flow-session-value-placement session)
  session)

;; : (-> PooSession Alist)
(def (poo-flow-session-metadata session)
  (.ref session 'metadata))

;;; Handoff receipts summarize the session for runtime owners. They keep the
;;; heavy execution boundary explicit and never claim Scheme executed work.
;; : (-> PooSession [Alist] PooSessionHandoff)
(def (poo-flow-session-handoff session . maybe-metadata)
  (poo-flow-session-require "session handoff requires a session"
                            (poo-flow-session? session)
                            session)
  (.o kind: 'poo-flow.session.handoff
      schema: 'poo-flow.modules.session.handoff.v1
      source: 'poo-flow-session-presentation
      session-id: (poo-flow-session-id session)
      chunk-count: (length (poo-flow-session-chunks session))
      placement-profile-ref:
      (poo-flow-session-placement-profile-ref
       (poo-flow-session-value-placement session))
      placement-resolved?:
      (poo-flow-session-placement-resolved?
       (poo-flow-session-value-placement session))
      placement-diagnostics:
      (poo-flow-session-placement-diagnostics
       (poo-flow-session-value-placement session))
      runtime-owner: "marlin-agent-core"
      handoff-required: #t
      runtime-executed: #f
      runtime-parses-scheme-source: #f
      scheme-manufactures-runtime-handlers: #f
      metadata: (if (null? maybe-metadata) '() (car maybe-metadata))))

;; : (-> Value Boolean)
(def (poo-flow-session-handoff? value)
  (and (object? value)
       (eq? (.ref value 'kind) 'poo-flow.session.handoff)))

;; : (-> [PooSession] Symbol MaybePooSession)
(def (poo-flow-session-by-id sessions session-id)
  (cond
   ((null? sessions) #f)
   ((eq? (poo-flow-session-id (car sessions)) session-id) (car sessions))
   (else
    (poo-flow-session-by-id (cdr sessions) session-id))))

;; : (-> PooSession [Pair])
(def (poo-flow-session-lineage-edge-pairs session)
  (map (lambda (parent-id)
         (cons parent-id (poo-flow-session-id session)))
       (poo-flow-session-lineage-parent-session-ids
        (poo-flow-session-value-lineage session))))

;; : (-> [PooSession] [Pair])
(def (poo-flow-session-graph-edge-pairs sessions)
  (apply append (map poo-flow-session-lineage-edge-pairs sessions)))

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

;; : (-> [PooSession] Boolean)
(def (poo-flow-session-graph-acyclic? sessions)
  (poo-flow-session-every?
   (lambda (session)
     (poo-flow-session-graph-acyclic-from?
      sessions
      (poo-flow-session-id session)
      '()))
   sessions))

;;; The graph presentation is intentionally compact. It exposes ids, edges,
;;; placement refs, and runtime flags without embedding the full session object
;;; graph in downstream receipts.
;; : (-> [PooSession] PooSessionGraphPresentation)
(def (pooFlowSessionGraphPresentation sessions)
  (poo-flow-session-require "session graph presentation requires sessions"
                            (list? sessions)
                            sessions)
  (poo-flow-session-require
   "session graph presentation entries must be sessions"
   (poo-flow-session-every? poo-flow-session? sessions)
   sessions)
  (.o kind: 'poo-flow.session.graph.presentation
      schema: 'poo-flow.modules.session.graph-presentation.v1
      session-count: (length sessions)
      session-ids: (map poo-flow-session-id sessions)
      chunk-count:
      (apply + (map (lambda (session)
                      (length (poo-flow-session-chunks session)))
                    sessions))
      lineage-edge-pairs: (poo-flow-session-graph-edge-pairs sessions)
      acyclic?: (poo-flow-session-graph-acyclic? sessions)
      placement-profile-refs:
      (map (lambda (session)
             (poo-flow-session-placement-profile-ref
              (poo-flow-session-value-placement session)))
           sessions)
      placement-resolved?:
      (map (lambda (session)
             (poo-flow-session-placement-resolved?
              (poo-flow-session-value-placement session)))
           sessions)
      placement-diagnostics:
      (map (lambda (session)
             (poo-flow-session-placement-diagnostics
              (poo-flow-session-value-placement session)))
           sessions)
      runtime-owner: "marlin-agent-core"
      runtime-executed: #f
      descriptor-realized?: #f
      replayable: #t))
