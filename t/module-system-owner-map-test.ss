(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        :poo-flow/src/module-system/g0-qualification
        :poo-flow/src/module-system/runtime-context-recovery
        :poo-flow/src/module-system/owner-map-observability
        :poo-flow/src/module-system/composition-lineage
        :poo-flow/src/module-system/gerbil-poo-consumption
        :poo-flow/src/module-system/owner-map-contract)

(export module-system-owner-map-tests)

(def (owner-map-test-row row-identity)
  `((row-identity . ,row-identity)
    (source-path . "src/module-system/owner-map-contract.ss")
    (source-symbol . poo-flow-module-system-owner-map-valid?)
    (test-path . "t/module-system-owner-map-test.ss")
    (test-symbol . module-system-owner-map-tests)
    (build-target . "//owner-map:module_system_sources")
    (implementation-state . implemented)))

(def module-system-owner-map-tests
  (test-suite
   "module-system owner-map contract"
   (test-case
    "G0 decisions are POO-native and fail closed"
    (check-equal? (poo-flow-g0-decision?
                   (poo-flow-g0-resolve 'requirement-1 #t #t))
                  #t)
    (check-equal? (poo-flow-g0-decision?
                   (poo-flow-g0-resolve 'requirement-1 #f #t))
                  #t))
   (test-case
    "runtime cells reject invalid transitions"
    (check-equal? (poo-flow-demand-cell-transition 'pending 'realizing)
                  'realizing)
    (check-equal? (poo-flow-demand-cell-transition 'pending 'realized)
                  'invalid-transition)
    (check-equal? (poo-flow-runtime-control-object?
                   (poo-flow-recovery-decision 'transient #t 1))
                  #t))
   (test-case
    "observability buffers are bounded and snapshots are detached objects"
    (check-equal? (poo-flow-bounded-event-append '(a b) 'c 2)
                  '(b c))
    (check-equal? (poo-flow-owner-map-observation-object?
                   (poo-flow-detached-snapshot 1 '(a b) "digest"))
                  #t))
   (test-case
    "lineage distinguishes productive recursion from invalid cycles"
    (check-equal? (poo-flow-lineage-cycle? '(a b a)) #t)
    (check-equal? (poo-flow-lineage-cycle? '(a b c)) #f)
    (check-equal? (poo-flow-productive-recursion? '(a b a) '(b)) #t)
    (check-equal? (poo-flow-productive-recursion? '(a b a) '()) #f))
   (test-case
    "gerbil-poo consumption is bound to the pinned API surface"
    (check-equal? (poo-flow-gerbil-poo-api-closed?
                   +poo-flow-gerbil-poo-required-api+)
                  #t)
    (check-equal? (poo-flow-gerbil-poo-api-closed? '(.o .@ .ref))
                  #f))
   (test-case
    "owner-map row identity is complete and deterministic"
    (let (rows (map owner-map-test-row
                    +poo-flow-module-system-owner-map-required-row-identities+))
      (check-equal? (poo-flow-module-system-owner-map-valid? rows) #t)
      (check-equal? (poo-flow-module-system-owner-map-valid? (cdr rows)) #f)))))

(run-tests! module-system-owner-map-tests)
