;;; -*- Gerbil -*-
;;; Boundary: builtin memory stores and default catalog.

(import :poo-flow/src/modules/memory-core/objects-core
        :poo-flow/src/modules/memory-core/objects-catalog)

(export poo-flow-memory-core-local-session-store
        poo-flow-memory-core-durable-project-store
        poo-flow-memory-core-default-catalog)

(def poo-flow-memory-core-local-session-store
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

(def poo-flow-memory-core-durable-project-store
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

(def poo-flow-memory-core-default-catalog
  (poo-flow-memory-catalog
   'memory-core/default
   (list poo-flow-memory-core-local-session-store
         poo-flow-memory-core-durable-project-store)
   '((source . poo-flow-memory-core)
     (runtime-executed . #f))))
