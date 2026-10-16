;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: builtin memory stores and default catalog.

(import :poo-flow/modules/ai-agentic-context/features/memory/objects-core
        :poo-flow/modules/ai-agentic-context/features/memory/objects-catalog)

(export poo-flow-ai-agentic-context-memory-local-session-store
        poo-flow-ai-agentic-context-memory-durable-project-store
        poo-flow-ai-agentic-context-memory-default-catalog)

(def poo-flow-ai-agentic-context-memory-local-session-store
  (poo-flow-memory-store-spec
   'memory/local-session
   'local-session
   'session
   '(current-session parent-summary)
   '(read-latest read-summary)
   '(none ephemeral)
   "marlin-agent-core"
   'memory/local-session-handoff
   #f
   'marlin-memory-adapter
   '((builtin . #t))))

(def poo-flow-ai-agentic-context-memory-durable-project-store
  (poo-flow-memory-store-spec
   'memory/durable-project
   'durable-project
   'project
   '(current-session parent-summary project)
   '(semantic-search exact-key read-summary)
   '(append review-only)
   "marlin-agent-core"
   'memory/durable-project-handoff
   #t
   'marlin-memory-adapter
   '((builtin . #t))))

(def poo-flow-ai-agentic-context-memory-default-catalog
  (poo-flow-memory-catalog
   'memory-core/default
   (list poo-flow-ai-agentic-context-memory-local-session-store
         poo-flow-ai-agentic-context-memory-durable-project-store)
   '((source . poo-flow-memory-core)
     (runtime-executed . #f))))
