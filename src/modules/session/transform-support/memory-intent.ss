(import :gerbil/gambit
        (only-in :clan/poo/object .ref object?)
        :poo-flow/src/modules/session/objects)

(export poo-flow-session-memory-intent-ref
        poo-flow-session-memory-intent?
        poo-flow-session-memory-intent-name
        poo-flow-session-memory-intent-store-ref
        poo-flow-session-memory-intent-scope
        poo-flow-session-memory-intent-recall
        poo-flow-session-memory-intent-commit-policy
        poo-flow-session-memory-intent-runtime-owner
        poo-flow-session-memory-intent-metadata
        poo-flow-session-memory-intent-handoff
        poo-flow-session-memory-intent-handoff-bundle/rev
        poo-flow-session-memory-intent-handoff-bundle
        poo-flow-session-memory-intent-count)

;; Boundary: memory-intent accessors and handoff rows are pure projections.
;; The declaration constructor stays in transform.ss where metadata validation lives.
(def (poo-flow-session-memory-intent-ref intent key default)
  (if (object? intent)
    (.ref intent key)
    (poo-flow-session-alist-ref intent key default)))

(def (poo-flow-session-memory-intent? value)
  (or (and (object? value)
           (eq? (.ref value 'kind) 'poo-flow.session.memory-intent))
      (and (list? value)
           (eq? (poo-flow-session-alist-ref value 'kind #f)
                'poo-flow.session.memory-intent))))

(def (poo-flow-session-memory-intent-name intent)
  (poo-flow-session-memory-intent-ref intent 'intent-name #f))

(def (poo-flow-session-memory-intent-store-ref intent)
  (poo-flow-session-memory-intent-ref intent 'store-ref #f))

(def (poo-flow-session-memory-intent-scope intent)
  (poo-flow-session-memory-intent-ref intent 'scope #f))

(def (poo-flow-session-memory-intent-recall intent)
  (poo-flow-session-memory-intent-ref intent 'recall '()))

(def (poo-flow-session-memory-intent-commit-policy intent)
  (poo-flow-session-memory-intent-ref intent 'commit-policy #f))

(def (poo-flow-session-memory-intent-runtime-owner intent)
  (poo-flow-session-memory-intent-ref intent 'runtime-owner "marlin-agent-core"))

(def (poo-flow-session-memory-intent-metadata intent)
  (poo-flow-session-memory-intent-ref intent 'metadata '()))

(def (poo-flow-session-memory-intent-handoff intent)
  (list
   (cons 'kind 'poo-flow.session.memory-intent.handoff)
   (cons 'schema 'poo-flow.modules.session.memory-intent.handoff.v1)
   (cons 'intent-name (poo-flow-session-memory-intent-name intent))
   (cons 'store-ref (poo-flow-session-memory-intent-store-ref intent))
   (cons 'scope (poo-flow-session-memory-intent-scope intent))
   (cons 'recall (poo-flow-session-memory-intent-recall intent))
   (cons 'commit-policy
         (poo-flow-session-memory-intent-commit-policy intent))
   (cons 'runtime-owner
         (poo-flow-session-memory-intent-runtime-owner intent))
   (cons 'handoff-required #t)
   (cons 'descriptor-realized? #f)
   (cons 'runtime-executed #f)))

(def (poo-flow-session-memory-intent-handoff-bundle/rev memory-intents
                                                        rows-rev
                                                        count)
  (if (null? memory-intents)
    (cons rows-rev count)
    (poo-flow-session-memory-intent-handoff-bundle/rev
     (cdr memory-intents)
     (cons (poo-flow-session-memory-intent-handoff (car memory-intents))
           rows-rev)
     (fx+ count 1))))

(def (poo-flow-session-memory-intent-handoff-bundle memory-intents)
  (let (bundle
        (poo-flow-session-memory-intent-handoff-bundle/rev
         memory-intents
         '()
         0))
    (cons (reverse (car bundle)) (cdr bundle))))

(def (poo-flow-session-memory-intent-count memory-intents)
  (length memory-intents))
