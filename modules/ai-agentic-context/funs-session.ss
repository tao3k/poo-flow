;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; Context produces the independent Session input proposal; Session never parses Org.
;;; The producer receipt reference must be resolved by a Host before publication.
(import (only-in :clan/poo/object .o .ref)
        (only-in :poo-flow/modules/session/objects-attempt SessionInputRef.)
        (only-in :poo-flow/modules/query/gql poo-flow-query->gql)
        "funs-scope.ss" "funs-projection.ss")
(export poo-flow-ai-agentic-context-session-input)
(def (poo-flow-ai-agentic-context-session-input source projection expected-scope receipt-reference)
  (unless (and (string? receipt-reference) (< 0 (string-length receipt-reference) 257))
    (error "Session input requires a producer receipt reference"))
  (let* ((verified (poo-flow-ai-agentic-context-org-replay source projection expected-scope))
         (scope-value (.ref verified 'scope))
         (identity-value (string-copy (.ref verified 'semantic-digest)))
         (scope-digest-value (string-copy (.ref scope-value 'semantic-digest)))
         (source-value (string-copy (.ref verified 'source-digest)))
         (query-value (poo-flow-ai-agentic-context-digest
                        (poo-flow-query->gql (.ref (.ref verified 'observation) 'query))))
         (restriction-value (string-copy (.ref (.ref verified 'restriction) 'semantic-digest)))
         (profile-value (poo-flow-ai-agentic-context-digest (.ref verified 'feature-ids)))
         (receipt-value (string-copy receipt-reference)))
    (unless (string? (.ref scope-value 'session))
      (error "Context Session input requires an exact Session and Turn scope"))
    (.o (:: @ SessionInputRef.) producer: "poo-flow/ai-agentic-context"
        contract: "org-projection-v1" identity: identity-value digest: identity-value
        scope-digest: scope-digest-value source-vector-digest: source-value
        query-digest: query-value restriction-digest: restriction-value
        profile-digest: profile-value receipt-ref: receipt-value
        consumer-session: (string-copy (.ref scope-value 'session))
        consumer-turn: (.ref scope-value 'turn) complete?: #t)))
