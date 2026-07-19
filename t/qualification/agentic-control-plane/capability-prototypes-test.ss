(import :std/test
        :gslph/src/testing/memory-profile
        (only-in :clan/poo/object .ref)
        :poo-flow/src/core/object-syntax
        :poo-flow/src/qualification/capability-prototypes)

(declare-gxtest-memory-exception '((maxHeapMiB . 512)))

(def capability-prototypes-test
  (test-suite "qualification POO capability prototypes"
    (test-case "multiple parents preserve orthogonal inherited slots"
      (let (left
            (poo-core-role-object
             (slots ((kind 'left)))
             (supers (poo-flow-versioned-capability 'schema.v1 1)
                     (poo-flow-revision-bound-capability "revision")
                     (poo-flow-owner-bound-capability '(owner-a)))))
        (check (.ref left 'schema-id) => 'schema.v1)
        (check (.ref left 'schema-version) => 1)
        (check (.ref left 'source-revision) => "revision")
        (check (.ref left 'owner-artifacts) => '(owner-a))
        (check (poo-flow-qualification-capabilities-valid?
                left
                (list poo-flow-versioned-capability-valid?
                      poo-flow-revision-bound-capability-valid?
                      poo-flow-owner-bound-capability-valid?))
               => #t)))
    (test-case "orthogonal parent order does not change capability values"
      (let ((left
             (poo-core-role-object
              (slots ((kind 'left)))
              (supers (poo-flow-versioned-capability 'schema.v1 1)
                      (poo-flow-revision-bound-capability "revision"))))
            (right
             (poo-core-role-object
              (slots ((kind 'right)))
              (supers (poo-flow-revision-bound-capability "revision")
                      (poo-flow-versioned-capability 'schema.v1 1)))))
        (check (.ref left 'schema-id) => (.ref right 'schema-id))
        (check (.ref left 'source-revision) => (.ref right 'source-revision))))
    (test-case "local extension intentionally overrides inherited value"
      (let (extended
            (poo-core-role-object
             (slots ((schema-id 'schema.v2)))
             (supers (poo-flow-versioned-capability 'schema.v1 1))))
        (check (.ref extended 'schema-id) => 'schema.v2)
        (check (.ref extended 'schema-version) => 1)))
    (test-case "separate compositions remain isolated"
      (let ((first (poo-flow-owner-bound-capability '(owner-a)))
            (second (poo-flow-owner-bound-capability '(owner-b))))
        (check (.ref first 'owner-artifacts) => '(owner-a))
        (check (.ref second 'owner-artifacts) => '(owner-b))))
    (test-case "missing required capability slot fails validation"
      (check (poo-flow-versioned-capability-valid?
              (poo-flow-versioned-capability #f 1))
             => #f)
      (check (poo-flow-versioned-capability-valid?
              (poo-flow-owner-bound-capability '(owner-a)))
             => #f))
    (test-case "duplicate capability and slot ownership conflict fail closed"
      (check
       (poo-flow-qualification-capability-composition-diagnostics
        '((versioned schema-id schema-version)
          (versioned schema-id schema-version)))
       => '((slot-owner-conflict schema-version)
            (slot-owner-conflict schema-id)
            (duplicate-capability versioned)))
      (check
       (poo-flow-qualification-capability-composition-diagnostics
        '((left unique-a shared) (right unique-b shared)))
       => '((slot-owner-conflict shared))))))

(run-tests! capability-prototypes-test)
