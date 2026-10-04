;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; POO source-backed Orgize candidate identity for Memory policy.
;;; The runtime authenticates the Rust receipt before using these values.

(import (only-in :clan/poo/object .o .ref object?)
        :poo-flow/modules/session/objects)

(export poo-flow-memory-org-candidate
        poo-flow-memory-org-candidate?
        poo-flow-memory-org-load-receipt
        poo-flow-memory-org-load-receipt?)

(def (poo-flow-memory-org-nonempty-string? value)
  (and (string? value) (> (string-length value) 0)))

(def (poo-flow-memory-org-nonnegative-integer? value)
  (and (integer? value) (>= value 0)))

(def (poo-flow-memory-org-candidate record-id parent-id kind
                                    start-byte end-byte span-sha256)
  (poo-flow-session-require "Org candidate requires an Element record id"
                            (poo-flow-memory-org-nonnegative-integer? record-id)
                            record-id)
  (poo-flow-session-require "Org candidate parent must be an Element id or false"
                            (or (not parent-id)
                                (poo-flow-memory-org-nonnegative-integer? parent-id))
                            parent-id)
  (poo-flow-session-require "Org candidate requires kind and span digest"
                            (and (poo-flow-memory-org-nonempty-string? kind)
                                 (poo-flow-memory-org-nonempty-string? span-sha256))
                            (list kind span-sha256))
  (poo-flow-session-require "Org candidate requires ordered byte offsets"
                            (and (poo-flow-memory-org-nonnegative-integer? start-byte)
                                 (poo-flow-memory-org-nonnegative-integer? end-byte)
                                 (< start-byte end-byte))
                            (list start-byte end-byte))
  (let ((record-value record-id)
        (parent-value parent-id)
        (kind-value kind)
        (start-value start-byte)
        (end-value end-byte)
        (span-value span-sha256))
    (.o (kind 'poo-flow.memory-core.org-candidate)
        (record-id record-value)
        (parent-id parent-value)
        (element-kind kind-value)
        (start-byte start-value)
        (end-byte end-value)
        (span-sha256 span-value))))

(def (poo-flow-memory-org-candidate? value)
  (and (object? value)
       (eq? (.ref value 'kind) 'poo-flow.memory-core.org-candidate)))

;;; POO representation of the exact-byte Orgize candidate result. The
;;; constructor checks shape; the runtime authenticates origin and hashes.
(def (poo-flow-memory-org-load-receipt project-id
                                       worktree-id
                                       source-path
                                       source-cut-digest
                                       bytes-sha256
                                       orgize-revision
                                       parser-digest
                                       graph-digest
                                       query-id
                                       query-rule-sha256
                                       scope-record-id
                                       candidates)
  (poo-flow-session-require "Org load requires a project id"
                            (poo-flow-memory-org-nonempty-string? project-id)
                            project-id)
  (poo-flow-session-require "Org load requires a WorkTree id"
                            (poo-flow-memory-org-nonempty-string? worktree-id)
                            worktree-id)
  (poo-flow-session-require "Org load requires a source path"
                            (poo-flow-memory-org-nonempty-string? source-path)
                            source-path)
  (poo-flow-session-require "Org load requires a source cut"
                            (poo-flow-memory-org-nonempty-string? source-cut-digest)
                            source-cut-digest)
  (poo-flow-session-require "Org load requires source bytes digest"
                            (poo-flow-memory-org-nonempty-string? bytes-sha256)
                            bytes-sha256)
  (poo-flow-session-require "Org load requires an Orgize revision"
                            (poo-flow-memory-org-nonempty-string? orgize-revision)
                            orgize-revision)
  (poo-flow-session-require "Org load requires parser and graph digests"
                            (and (poo-flow-memory-org-nonempty-string? parser-digest)
                                 (poo-flow-memory-org-nonempty-string? graph-digest))
                            (list parser-digest graph-digest))
  (poo-flow-session-require "Org load requires a named query and rule digest"
                            (and (poo-flow-memory-org-nonempty-string? query-id)
                                 (poo-flow-memory-org-nonempty-string? query-rule-sha256))
                            (list query-id query-rule-sha256))
  (poo-flow-session-require "Org load requires a scope Element id"
                            (poo-flow-memory-org-nonnegative-integer? scope-record-id)
                            scope-record-id)
  (poo-flow-session-require "Org load candidates must be source-backed Elements"
                            (and (list? candidates)
                                 (poo-flow-session-every?
                                  poo-flow-memory-org-candidate?
                                  candidates))
                            candidates)
  (let ((project-value project-id)
        (worktree-value worktree-id)
        (path-value source-path)
        (cut-value source-cut-digest)
        (bytes-value bytes-sha256)
        (revision-value orgize-revision)
        (parser-value parser-digest)
        (graph-value graph-digest)
        (query-value query-id)
        (rule-value query-rule-sha256)
        (scope-value scope-record-id)
        (candidate-values candidates))
    (.o (kind 'poo-flow.memory-core.org-load-receipt)
        (schema 'poo-flow.modules.memory-core.org-load.v1)
        (project-id project-value)
        (worktree-id worktree-value)
        (source-path path-value)
        (source-cut-digest cut-value)
        (bytes-sha256 bytes-value)
        (orgize-revision revision-value)
        (parser-digest parser-value)
        (graph-digest graph-value)
        (query-id query-value)
        (query-rule-sha256 rule-value)
        (scope-record-id scope-value)
        (candidates candidate-values)
        (runtime-executed #f))))

(def (poo-flow-memory-org-load-receipt? value)
  (and (object? value)
       (eq? (.ref value 'kind) 'poo-flow.memory-core.org-load-receipt)))
