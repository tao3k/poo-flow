;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Session-owned pure Memory selection over a source-bound Orgize receipt.
;;; The runtime must recheck current authority and head CAS before publication.

(import (only-in :clan/poo/object .o .ref object?)
        :poo-flow/modules/session/objects
        :poo-flow/modules/session/transform-support/memory-intent
        :poo-flow/modules/memory-core/objects-core
        :poo-flow/modules/memory-core/org-load)

(export poo-flow-session-org-memory-selection-context
        poo-flow-session-org-memory-selection-context?
        poo-flow-session-org-memory-selection-intent
        poo-flow-session-org-memory-selection-intent?
        poo-flow-session-org-memory-selection-intent-eligible?
        poo-flow-session-org-memory-selection-intent-diagnostics)

(def (poo-flow-session-org-nonempty-string? value)
  (and (string? value) (> (string-length value) 0)))

(def (poo-flow-session-org-nonnegative-integer? value)
  (and (integer? value) (>= value 0)))

;;; Host-current values are explicit premises. A caller must not derive the
;;; grant, Session state or source cut from the Org document being selected.
(def (poo-flow-session-org-memory-selection-context project-id
                                            worktree-id
                                            current-cut-digest
                                            current-bytes-sha256
                                            allowed-query-id
                                            current-orgize-revision
                                            current-parser-digest
                                            current-graph-digest
                                            current-query-rule-sha256
                                            expected-head-revision
                                            current-head-revision
                                            read-granted?
                                            session-active?)
  (poo-flow-session-require "selection context requires project and WorkTree ids"
                            (and (poo-flow-session-org-nonempty-string? project-id)
                                 (poo-flow-session-org-nonempty-string? worktree-id))
                            (list project-id worktree-id))
  (poo-flow-session-require "selection context requires source and query ids"
                            (and (poo-flow-session-org-nonempty-string? current-cut-digest)
                                 (poo-flow-session-org-nonempty-string? current-bytes-sha256)
                                 (poo-flow-session-org-nonempty-string? allowed-query-id))
                            (list current-cut-digest current-bytes-sha256
                                  allowed-query-id))
  (poo-flow-session-require "selection context requires current Orgize digests"
                            (and (poo-flow-session-org-nonempty-string?
                                  current-orgize-revision)
                                 (poo-flow-session-org-nonempty-string?
                                  current-parser-digest)
                                 (poo-flow-session-org-nonempty-string?
                                  current-graph-digest)
                                 (poo-flow-session-org-nonempty-string?
                                  current-query-rule-sha256))
                            (list current-orgize-revision
                                  current-parser-digest
                                  current-graph-digest
                                  current-query-rule-sha256))
  (poo-flow-session-require "head revisions must be nonnegative integers"
                            (and (integer? expected-head-revision)
                                 (>= expected-head-revision 0)
                                 (integer? current-head-revision)
                                 (>= current-head-revision 0))
                            (list expected-head-revision current-head-revision))
  (poo-flow-session-require "grant and Session state must be booleans"
                            (and (boolean? read-granted?) (boolean? session-active?))
                            (list read-granted? session-active?))
  (let ((project-value project-id)
        (worktree-value worktree-id)
        (cut-value current-cut-digest)
        (bytes-value current-bytes-sha256)
        (query-value allowed-query-id)
        (revision-value current-orgize-revision)
        (parser-value current-parser-digest)
        (graph-value current-graph-digest)
        (rule-value current-query-rule-sha256)
        (expected-value expected-head-revision)
        (current-value current-head-revision)
        (grant-value read-granted?)
        (active-value session-active?))
    (.o (kind 'poo-flow.session.org-memory-selection-context)
        (project-id project-value)
        (worktree-id worktree-value)
        (current-cut-digest cut-value)
        (current-bytes-sha256 bytes-value)
        (allowed-query-id query-value)
        (current-orgize-revision revision-value)
        (current-parser-digest parser-value)
        (current-graph-digest graph-value)
        (current-query-rule-sha256 rule-value)
        (expected-head-revision expected-value)
        (current-head-revision current-value)
        (read-granted? grant-value)
        (session-active? active-value))))

(def (poo-flow-session-org-memory-selection-context? value)
  (and (object? value)
       (eq? (.ref value 'kind) 'poo-flow.session.org-memory-selection-context)))

(def (poo-flow-session-org-memory-selection-diagnostics load intent store context)
  (filter
   (lambda (diagnostic) diagnostic)
   (list
    (and (not (and (equal? (.ref load 'project-id)
                           (.ref context 'project-id))
                   (equal? (.ref load 'worktree-id)
                           (.ref context 'worktree-id))))
         'foreign-scope)
    (and (not (equal? (.ref load 'source-cut-digest)
                      (.ref context 'current-cut-digest)))
         'stale-source-cut)
    (and (not (equal? (.ref load 'bytes-sha256)
                      (.ref context 'current-bytes-sha256)))
         'stale-org-bytes)
    (and (not (equal? (.ref load 'query-id)
                      (.ref context 'allowed-query-id)))
         'query-not-granted)
    (and (not (equal? (.ref load 'orgize-revision)
                      (.ref context 'current-orgize-revision)))
         'stale-orgize-revision)
    (and (not (equal? (.ref load 'parser-digest)
                      (.ref context 'current-parser-digest)))
         'stale-orgize-parser)
    (and (not (equal? (.ref load 'graph-digest)
                      (.ref context 'current-graph-digest)))
         'stale-orgize-graph)
    (and (not (equal? (.ref load 'query-rule-sha256)
                      (.ref context 'current-query-rule-sha256)))
         'stale-query-rule)
    (and (not (and (equal? (poo-flow-session-memory-intent-store-ref intent)
                           (poo-flow-memory-store-spec-ref store))
                   (member (poo-flow-session-memory-intent-scope intent)
                           (poo-flow-memory-store-spec-scopes store))
                   (member (poo-flow-session-memory-intent-commit-policy intent)
                           (poo-flow-memory-store-spec-commit-policies store))))
         'memory-policy-denied)
    (and (not (.ref context 'read-granted?)) 'read-not-granted)
    (and (not (.ref context 'session-active?)) 'session-inactive)
    (and (not (= (.ref context 'expected-head-revision)
                 (.ref context 'current-head-revision)))
         'stale-memory-head)
    (and (null? (.ref load 'candidates)) 'no-candidate))))

;;; A pure proposed selection. It is not semantic admission or a CAS commit.
(def (poo-flow-session-org-memory-selection-intent load intent store session context)
  (poo-flow-session-require "Org selection requires an Orgize load receipt"
                            (poo-flow-memory-org-load-receipt? load)
                            load)
  (poo-flow-session-require "Org selection requires a Session memory intent"
                            (poo-flow-session-memory-intent? intent)
                            intent)
  (poo-flow-session-require "Org selection requires a Memory store spec"
                            (poo-flow-memory-store-spec? store)
                            store)
  (poo-flow-session-require "Org selection requires a Session"
                            (poo-flow-session? session)
                            session)
  (poo-flow-session-require "Org selection requires current host context"
                            (poo-flow-session-org-memory-selection-context? context)
                            context)
  (let ((diagnostic-values
         (poo-flow-session-org-memory-selection-diagnostics load intent store context))
        (session-value (poo-flow-session-id session))
        (load-value load)
        (intent-value intent)
        (head-value (.ref context 'expected-head-revision)))
    (.o (kind 'poo-flow.session.org-memory-selection-intent)
        (schema 'poo-flow.modules.session.org-memory-selection.v1)
        (session-id session-value)
        (load load-value)
        (memory-intent intent-value)
        (expected-head-revision head-value)
        (eligible? (null? diagnostic-values))
        (diagnostics diagnostic-values)
        (semantic-admitted? #f)
        (runtime-executed #f))))

(def (poo-flow-session-org-memory-selection-intent? value)
  (and (object? value)
       (eq? (.ref value 'kind) 'poo-flow.session.org-memory-selection-intent)))

(def (poo-flow-session-org-memory-selection-intent-eligible? value)
  (.ref value 'eligible?))

(def (poo-flow-session-org-memory-selection-intent-diagnostics value)
  (.ref value 'diagnostics))
