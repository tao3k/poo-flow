(export feature-system-bundle-v1-composition-writer-test-suite)

(import :std/test
        :clan/poo/object
        :poo-flow/src/core/plan
        :poo-flow/src/module-system/profile-composition
        :poo-flow/src/feature-system/bundle-v1-composition-writer)

(def writer-test-composition
  (use-composition writer-test-composition
    (use-module writer-test-module as writer
      (profile source :kind interface :scope evidence)
      (profile target :kind authority :scope action))
    (compose
      (profile writer source)
      (profile writer target))
    (stage writer-test-flow
      (step source)
      (step target)
      (edges (source target)))))

(def feature-system-bundle-v1-composition-writer-test-suite
  (test-suite
   "Bundle v1 composition writer"

   (test-case
    "arbitrary POO composition lowers with symbols and dependency edges"
    (let-values (((plan image)
                  (poo-flow-composition->bundle-v1-image
                   writer-test-composition 'writer-test-bundle 3)))
      (let (descriptor (.ref image 'descriptor))
        (check (.ref image 'accepted?) => #t)
        (check (length (execution-plan-nodes plan)) => 4)
        (check (length (.ref descriptor 'symbol-rows)) => 4)
        (check (length (.ref descriptor 'component-rows)) => 4)
        (check (length (.ref descriptor 'edge-rows)) => 4)
        (check (.ref descriptor 'bundle-epoch) => 3))))))

(run-tests! feature-system-bundle-v1-composition-writer-test-suite)
