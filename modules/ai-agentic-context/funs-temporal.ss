;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; Pure Context lifecycle window policy over existing Temporal primitives.
(import (only-in :clan/poo/object .o .ref)
        (only-in :std/list/list every delete-duplicates/hash)
        (only-in :poo-flow/modules/temporal-causality/time/types poo-flow-temporal-interval?)
        (only-in :poo-flow/modules/temporal-causality/time/objects poo-flow-temporal-instant poo-flow-temporal-interval)
        (only-in :poo-flow/modules/temporal-causality/time/funs poo-flow-temporal-interval-contains?)
        (only-in :poo-flow/modules/temporal-causality/time/uncertainty-funs poo-flow-temporal-bounded-observation-replay)
        "types.ss" "objects.ss" "funs-scope.ss")
(export poo-flow-ai-agentic-context-temporal-policy
        poo-flow-ai-agentic-context-temporal-policy-replay
        poo-flow-ai-agentic-context-temporal-assess)
(def (instant-row value)
  (map (lambda (key) (.ref value key)) '(identity domain-identity coordinate provenance-identity modality)))
(def (copy-instant value)
  (apply poo-flow-temporal-instant
    (map (lambda (value) (if (string? value) (string-copy value) value)) (instant-row value))))
(def (poo-flow-ai-agentic-context-temporal-policy policy-id policy-revision interval-value role-value purpose-values)
  (unless (and (string? policy-id) (< 0 (string-length policy-id) 257)
               (exact-integer? policy-revision) (<= 0 policy-revision 65535)
               (poo-flow-temporal-interval? interval-value) (symbol? role-value)
               (list? purpose-values) (<= 1 (length purpose-values) 5)
               (every (lambda (purpose) (memq purpose '(prepare disclose accept-result publish-memory revisit))) purpose-values)) (error "Invalid Context temporal policy inputs"))
  (let* ((window-value (poo-flow-temporal-interval (string-copy (.ref interval-value 'identity))
               (copy-instant (.ref interval-value 'start)) (copy-instant (.ref interval-value 'end))
               (.ref interval-value 'start-closed?) (.ref interval-value 'end-closed?)))
         (purposes-value (list-sort (lambda (a b) (string<? (symbol->string a) (symbol->string b))) purpose-values))
         (digest-value (poo-flow-ai-agentic-context-digest
           (list 'context-temporal-policy-v1 policy-id policy-revision (.ref window-value 'identity)
                 (instant-row (.ref window-value 'start)) (instant-row (.ref window-value 'end))
                 (.ref window-value 'start-closed?) (.ref window-value 'end-closed?) role-value purposes-value)))
         (value (.o (:: @ AiAgenticContextTemporalPolicy.) identity: (string-copy policy-id)
              revision: policy-revision window: window-value clock-role: role-value purposes: purposes-value
              semantic-digest: digest-value)))
    (unless (and (poo-flow-ai-agentic-context-temporal-policy-shape? value)
                 (= (length purposes-value) (length (delete-duplicates/hash purposes-value))))
      (error "Invalid Context temporal policy")) value))
(def (poo-flow-ai-agentic-context-temporal-policy-replay policy)
  (unless (poo-flow-ai-agentic-context-temporal-policy-shape? policy) (error "Invalid Context temporal policy proposal"))
  (let (fresh (poo-flow-ai-agentic-context-temporal-policy (.ref policy 'identity) (.ref policy 'revision)
                 (.ref policy 'window) (.ref policy 'clock-role) (.ref policy 'purposes)))
    (unless (equal? (.ref fresh 'semantic-digest) (.ref policy 'semantic-digest))
      (error "Context temporal policy substitution")) fresh))
(def (poo-flow-ai-agentic-context-temporal-assess policy observation purpose-value)
  (let* ((policy-value (poo-flow-ai-agentic-context-temporal-policy-replay policy))
         (clock-value (poo-flow-temporal-bounded-observation-replay observation))
         (window-value (.ref policy-value 'window)) (earliest-value (.ref clock-value 'earliest))
         (latest-value (.ref clock-value 'latest))
         (left (poo-flow-temporal-interval-contains? window-value earliest-value))
         (right (poo-flow-temporal-interval-contains? window-value latest-value))
         (status-value
          (cond ((not (memq purpose-value (.ref policy-value 'purposes))) 'purpose-denied)
                ((not (eq? (.ref clock-value 'clock-role) (.ref policy-value 'clock-role))) 'unsupported-clock)
                ((or (eq? left 'incomparable) (eq? right 'incomparable)) 'incomparable)
                ((or (eq? left 'unknown) (eq? right 'unknown)) 'unknown)
                ((and (eq? left #t) (eq? right #t)) 'eligible)
                ((< (.ref latest-value 'coordinate) (.ref (.ref window-value 'start) 'coordinate)) 'not-yet-effective)
                ((>= (.ref earliest-value 'coordinate) (.ref (.ref window-value 'end) 'coordinate)) 'expired)
                (else 'uncertain)))
         (policy-digest-value (.ref policy-value 'semantic-digest))
         (clock-digest-value (string-copy (.ref clock-value 'semantic-digest)))
         (assessment-digest-value (poo-flow-ai-agentic-context-digest
                  (list 'context-temporal-assessment-v1 policy-digest-value clock-digest-value purpose-value status-value))))
    (.o kind: 'poo-flow.ai-agentic-context.temporal-assessment.v1 policy-digest: policy-digest-value
        clock-digest: clock-digest-value purpose: purpose-value status: status-value semantic-digest: assessment-digest-value
        source-authenticated?: #f action-authorized?: #f runtime-published?: #f durable?: #f)))
