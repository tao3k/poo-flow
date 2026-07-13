(import :std/test
        :clan/poo/object
        :poo-flow/src/feature-system/interface
        :poo-flow/src/utilities/functional)

(export feature-system-manifest-test)

(def manifest-option-a
  (feature-option-schema 'mode 'symbol 'safe #f))

(def manifest-option-a-duplicate
  (feature-option-schema 'mode 'symbol 'fast #f))

(defpoo-feature manifest-base-feature
  (feature-id 'manifest-base)
  (owner-module-id 'feature-system-manifest-test))

(defpoo-feature manifest-dependent-feature
  (feature-id 'manifest-dependent)
  (owner-module-id 'feature-system-manifest-test)
  (requires manifest-base-feature))

(defpoo-feature manifest-missing-requirement-feature
  (feature-id 'manifest-missing-requirement)
  (owner-module-id 'feature-system-manifest-test)
  (requires manifest-base-feature))

(defpoo-feature manifest-duplicate-feature
  (feature-id 'manifest-base)
  (owner-module-id 'feature-system-manifest-test-duplicate))

(defpoo-feature manifest-conflict-target-feature
  (feature-id 'manifest-conflict-target)
  (owner-module-id 'feature-system-manifest-test))

(defpoo-feature manifest-conflicting-feature
  (feature-id 'manifest-conflicting)
  (owner-module-id 'feature-system-manifest-test)
  (conflicts manifest-conflict-target-feature))

(defpoo-feature manifest-duplicate-option-feature
  (feature-id 'manifest-duplicate-option)
  (owner-module-id 'feature-system-manifest-test)
  (option-schemas manifest-option-a manifest-option-a-duplicate))

(defpoo-feature manifest-duplicate-option-second-feature
  (feature-id 'manifest-duplicate-option-second)
  (owner-module-id 'feature-system-manifest-test)
  (option-schemas manifest-option-a manifest-option-a-duplicate))

(defpoo-feature-manifest-bundle manifest-valid-bundle
  (bundle-id 'manifest-valid)
  (features manifest-base-feature manifest-dependent-feature))

(defpoo-feature-manifest-bundle manifest-empty-bundle
  (bundle-id 'manifest-empty)
  (features))

(defpoo-feature-manifest-bundle manifest-missing-requirement-bundle
  (bundle-id 'manifest-missing-requirement)
  (features manifest-missing-requirement-feature))

(defpoo-feature-manifest-bundle manifest-duplicate-id-bundle
  (bundle-id 'manifest-duplicate-id)
  (features manifest-base-feature manifest-duplicate-feature))

(defpoo-feature-manifest-bundle manifest-conflict-bundle
  (bundle-id 'manifest-conflict)
  (features manifest-conflict-target-feature manifest-conflicting-feature))

(defpoo-feature-manifest-bundle manifest-duplicate-option-bundle
  (bundle-id 'manifest-duplicate-option)
  (features manifest-duplicate-option-feature
            manifest-duplicate-option-second-feature))

(def (diagnostic-codes bundle)
  (poo-flow-map (lambda (diagnostic) (.ref diagnostic 'code))
                (.ref bundle 'diagnostics)))

(def (diagnostic-feature-ids bundle)
  (poo-flow-map (lambda (diagnostic) (.ref diagnostic 'feature-id))
                (.ref bundle 'diagnostics)))

(def (manifest-stress-feature-id index)
  (string->symbol
   (string-append "manifest-stress-" (number->string index))))

(def (manifest-linear-feature-descriptors count)
  (let loop ((index 0)
             (previous #f)
             (descriptors []))
    (if (= index count)
      (reverse descriptors)
      (let* ((base
              (feature-descriptor-base
               (manifest-stress-feature-id index)
               'feature-system-manifest-stress))
             (spec
              (if previous
                (feature-spec-compose
                 base
                 (feature-required-features previous))
                base))
             (descriptor (feature-descriptor spec)))
        (loop (+ index 1)
              descriptor
              (cons descriptor descriptors))))))

(def (manifest-index-hit-count bundle feature-ids rounds)
  (let outer ((round rounds)
              (hits 0))
    (if (zero? round)
      hits
      (let inner ((feature-ids feature-ids)
                  (hits hits))
        (match feature-ids
          ([feature-id . rest]
           (inner rest
                  (if (feature-manifest-bundle-ref bundle feature-id)
                    (+ hits 1)
                    hits)))
          ([] (outer (- round 1) hits)))))))

(def feature-system-manifest-test
  (test-suite "feature system immutable manifests"
    (test-case "descriptor projects to an immutable POO manifest"
      (let ((manifest (feature-manifest manifest-dependent-feature)))
        (check (.ref manifest 'kind) => 'feature-manifest)
        (check (.ref manifest 'schema-version) => 1)
        (check (.ref manifest 'feature-id) => 'manifest-dependent)
        (check (.ref manifest 'owner-module-id)
               => 'feature-system-manifest-test)
        (check (.ref manifest 'requires) => '(manifest-base))))

    (test-case "explicit bundle reuses the resolver activation plan"
      (let ((index (.ref manifest-valid-bundle 'manifest-index))
            (base-manifest (car (.ref manifest-valid-bundle 'manifests))))
        (check (.ref manifest-valid-bundle 'kind)
               => 'feature-manifest-bundle)
        (check (.ref manifest-valid-bundle 'status) => 'ready)
        (check (.ref manifest-valid-bundle 'accepted?) => #t)
        (check (.ref manifest-valid-bundle 'feature-ids)
               => '(manifest-base manifest-dependent))
        (check (.ref index 'kind) => 'feature-manifest-index)
        (check (.ref index 'size) => 2)
        (check (eq? (feature-manifest-bundle-ref
                     manifest-valid-bundle 'manifest-base)
                    base-manifest)
               => #t)
        (check (eq? (require-feature-manifest-bundle-ref
                     manifest-valid-bundle 'manifest-base)
                    base-manifest)
               => #t)
        (check (feature-manifest-bundle-ref
                manifest-valid-bundle 'manifest-absent)
               => #f)
        (check (eq? (require-valid-feature-manifest-bundle
                     manifest-valid-bundle)
                    manifest-valid-bundle)
               => #t)))

    (test-case "empty explicit bundle is a valid identity plan"
      (check (.ref manifest-empty-bundle 'status) => 'ready)
      (check (.ref manifest-empty-bundle 'feature-ids) => '())
      (check (.ref manifest-empty-bundle 'diagnostics) => '()))

    (test-case "missing requirements reject the explicit build bundle"
      (check (.ref manifest-missing-requirement-bundle 'status)
             => 'rejected)
      (check (.ref manifest-missing-requirement-bundle 'accepted?) => #f)
      (check (memq 'missing-dependency
                   (diagnostic-codes manifest-missing-requirement-bundle))
             ? values))

    (test-case "duplicate feature identities reject the bundle"
      (check (.ref manifest-duplicate-id-bundle 'status) => 'rejected)
      (check (.ref manifest-duplicate-id-bundle 'manifest-index) => #f)
      (check (memq 'duplicate-selection
                   (diagnostic-codes manifest-duplicate-id-bundle))
             ? values))

    (test-case "conflicting features reject the bundle"
      (check (.ref manifest-conflict-bundle 'status) => 'rejected)
      (check (memq 'feature-conflict
                   (diagnostic-codes manifest-conflict-bundle))
             ? values))

    (test-case "duplicate option identities reject the bundle"
      (check (.ref manifest-duplicate-option-bundle 'status) => 'rejected)
      (check (diagnostic-codes manifest-duplicate-option-bundle)
             => '(duplicate-option-schema duplicate-option-schema))
      (check (diagnostic-feature-ids manifest-duplicate-option-bundle)
             => '(manifest-duplicate-option
                  manifest-duplicate-option-second)))

    (test-case "1024-Feature bundle keeps one linear manifest pass"
      (let* ((descriptors (manifest-linear-feature-descriptors 1024))
             (bundle (feature-manifest-bundle
                      'manifest-linear-stress descriptors))
             (feature-ids (.ref bundle 'feature-ids)))
        (check (.ref bundle 'status) => 'ready)
        (check (length (.ref bundle 'manifests)) => 1024)
        (check (.ref (.ref bundle 'manifest-index) 'size) => 1024)
        (check (length feature-ids) => 1024)
        (check (car feature-ids) => 'manifest-stress-0)
        (check (car (reverse feature-ids))
               => 'manifest-stress-1023)
        (check (manifest-index-hit-count bundle feature-ids 64)
               => 65536)
        (check (feature-manifest-bundle-ref
                bundle 'manifest-stress-absent)
               => #f)))))
