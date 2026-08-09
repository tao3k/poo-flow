(export feature-system-bundle-v1-composition-writer-test-suite
        feature-system-bundle-v1-composition-writer-test)

(import :std/test
        :clan/poo/object
        :poo-flow/src/core/plan
        :poo-flow/src/module-system/profile-composition
        :poo-flow/src/module-system/profile-composition-builders
        :poo-flow/src/feature-system/bundle-v1-composition-writer
        :poo-flow/src/feature-system/bundle-v1-lowering)

(def writer-test-composition
  (use-composition writer-test-composition
    (use-module writer-test-module as writer
      (profile source :kind interface :scope evidence
        :guard (all provenance attribution))
      (profile target :kind authority :scope action
        :guard (all verified authority)))
    (compose
      (profile writer source)
      (profile writer target))
    (stage writer-test-flow
      (guard (all (receipt source) (authority human)))
      (step source)
      (step target)
      (edges (source target)))))

;;; Native POO profiles can be selected through a composition binding without
;;; carrying a presentation `name` slot.  The binding slot is the plan identity.
(def writer-native-profile
  (.o (kind 'native-profile)
      (guard '(all native receipt))))

(def writer-binding-only-composition
  (poo-flow-composition-object/profile-bindings
   'writer-binding-only
   '()
   (list writer-native-profile)
   (list
    (poo-flow-composition-stage
     'native-flow
     (list (poo-flow-composition-clause 'step '(native)))))
   (list (poo-flow-composition-profile-binding 'native-module 'native))))

(def feature-system-bundle-v1-composition-writer-test-suite
  (test-suite
   "Bundle v1 composition writer"

   (test-case
    "profile guards resolve through composition bindings without a name slot"
    (let-values (((plan image)
                  (poo-flow-composition->bundle-v1-image
                   writer-binding-only-composition 'writer-binding-only-bundle 1)))
      (let ((descriptor (.ref image 'descriptor)))
        (check (.ref image 'accepted?) => #t)
        (check (length (execution-plan-nodes plan)) => 3)
        (check
         (length
          (filter (lambda (symbol) (= (.ref symbol 'symbol-kind) 2))
                  (.ref descriptor 'symbol-rows)))
         => 1))))

   (test-case
    "arbitrary POO composition lowers with symbols and dependency edges"
    (let-values (((plan image)
                  (poo-flow-composition->bundle-v1-image
                   writer-test-composition 'writer-test-bundle 3)))
      (let* ((descriptor (.ref image 'descriptor))
             (no-adapter (feature-bundle-v1-lower-compact-id
                          'adapter +feature-bundle-v1-no-adapter-id+))
             (no-projection (feature-bundle-v1-lower-compact-id
                             'projection +feature-bundle-v1-no-projection-id+))
             (no-policy (feature-bundle-v1-lower-compact-id
                         'policy +feature-bundle-v1-no-policy-id+)))
        (check (.ref image 'accepted?) => #t)
        (check (length (execution-plan-nodes plan)) => 4)
        (check (length (.ref descriptor 'symbol-rows)) => 7)
        (check
         (length
          (filter (lambda (symbol)
                    (= (.ref symbol 'symbol-kind) 2))
                  (.ref descriptor 'symbol-rows)))
         => 3)
        (check (length (.ref descriptor 'component-rows)) => 4)
        (check (length (.ref descriptor 'edge-rows)) => 4)
        (check
         (length
          (filter (lambda (component)
                    (not (feature-bundle-v1-compact-id=?
                          (.ref component 'policy-id)
                          no-policy)))
                  (.ref descriptor 'component-rows)))
         => 3)
        (for-each
         (lambda (component)
           (check
            (feature-bundle-v1-compact-id=?
             (.ref component 'adapter-id)
             no-adapter)
            => #t)
           (check
            (feature-bundle-v1-compact-id=?
             (.ref component 'projection-id)
             no-projection)
            => #t))
         (.ref descriptor 'component-rows))
        (check (.ref descriptor 'bundle-epoch) => 3))))))

(def feature-system-bundle-v1-composition-writer-test
  feature-system-bundle-v1-composition-writer-test-suite)
