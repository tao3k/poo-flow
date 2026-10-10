;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; Boundary shapes and invariants; no construction or runtime effects.
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop Type. define-type)
        (only-in :std/list/list every))
(export AiAgenticContextScopeType poo-flow-ai-agentic-context-scope-shape?)
(def (name? x) (and (string? x) (< 0 (string-length x) 257)))
(def (poo-flow-ai-agentic-context-scope-shape? spec)
  (and (object? spec)
       (every (lambda (k) (and (.slot? spec k) (name? (.ref spec k))))
              '(bundle organization project worktree source-cut actor task destination))
       (.slot? spec 'kind)
       (eq? (.ref spec 'kind) 'poo-flow.ai-agentic-context.scope.v1)
       (.slot? spec 'epoch)
       (exact-integer? (.ref spec 'epoch)) (>= (.ref spec 'epoch) 0)
       (.slot? spec 'session) (.slot? spec 'turn)
       (or (and (eq? (.ref spec 'session) #f) (eq? (.ref spec 'turn) #f))
           (and (name? (.ref spec 'session))
                (exact-integer? (.ref spec 'turn)) (>= (.ref spec 'turn) 0)))))
(define-type (AiAgenticContextScopeType @ Type.)
  .element?: poo-flow-ai-agentic-context-scope-shape?)
