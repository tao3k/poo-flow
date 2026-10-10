;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; Public native Scope declaration; admission freezes its complete tuple.
(import (only-in :clan/poo/object .def .o .ref .slot? object?)
        (only-in :std/list/list every)
        (only-in :std/crypto/digest sha256)
        (only-in :std/encoding/hex hex-encode))
(export AiAgenticContextScope. poo-flow-ai-agentic-context-scope-admit
        poo-flow-ai-agentic-context-digest)
(.def AiAgenticContextScope.
  (kind 'poo-flow.ai-agentic-context.scope.v1)
  (bundle #f) (organization #f) (epoch #f) (project #f) (worktree #f)
  (source-cut #f) (actor #f) (task #f) (destination #f)
  (session #f) (turn #f))
(def (poo-flow-ai-agentic-context-digest x)
  (string-append "sha256:" (hex-encode (sha256 (string->utf8
    (call-with-output-string (lambda (port) (write x port))))))))
(def (name? x) (and (string? x) (< 0 (string-length x) 257)))
(def (poo-flow-ai-agentic-context-scope-admit spec)
  (unless (and (object? spec)
               (every (lambda (k) (and (.slot? spec k) (name? (.ref spec k))))
                 '(bundle organization project worktree source-cut actor task destination))
               (.slot? spec 'kind) (eq? (.ref spec 'kind) 'poo-flow.ai-agentic-context.scope.v1)
               (.slot? spec 'epoch) (exact-integer? (.ref spec 'epoch)) (>= (.ref spec 'epoch) 0)
               (.slot? spec 'session) (.slot? spec 'turn)
               (or (and (eq? (.ref spec 'session) #f) (eq? (.ref spec 'turn) #f))
                   (and (name? (.ref spec 'session)) (exact-integer? (.ref spec 'turn))
                        (>= (.ref spec 'turn) 0))))
    (error "invalid AI Agentic-context Scope"))
  (let* ((tuple (map (lambda (k) (let (v (.ref spec k)) (if (string? v) (string-copy v) v)))
                    '(bundle organization epoch project worktree source-cut actor task destination session turn)))
         (scope-value (.o (:: @ AiAgenticContextScope.)
            bundle: (list-ref tuple 0) organization: (list-ref tuple 1)
            epoch: (list-ref tuple 2) project: (list-ref tuple 3) worktree: (list-ref tuple 4)
            source-cut: (list-ref tuple 5) actor: (list-ref tuple 6) task: (list-ref tuple 7)
            destination: (list-ref tuple 8) session: (list-ref tuple 9) turn: (list-ref tuple 10)
            semantic-digest: (poo-flow-ai-agentic-context-digest (cons 'ai-agentic-context/scope-v1 tuple)))))
    scope-value))
