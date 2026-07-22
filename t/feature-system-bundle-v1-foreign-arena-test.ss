(import :std/test
        :clan/poo/object
        :poo-flow/src/utilities/functional
        :poo-flow/src/feature-system/bundle-v1-lowering
        :poo-flow/src/feature-system/bundle-v1-foreign-arena)

(export feature-system-bundle-v1-foreign-arena-test-suite)

(def +byte-offsets/u16+ '(0 1))
(def +byte-offsets/u32+ '(0 1 2 3))
(def +byte-offsets/u64+ '(0 1 2 3 4 5 6 7))

(def (read-unsigned-le bytes offset byte-offsets)
  (poo-flow-fold-left
   (lambda (byte-offset state)
     (+ state
        (* (u8vector-ref bytes (+ offset byte-offset))
           (expt 256 byte-offset))))
   0
   byte-offsets))

(def (read-u32 bytes offset)
  (read-unsigned-le bytes offset +byte-offsets/u32+))

(def (read-u16 bytes offset)
  (read-unsigned-le bytes offset +byte-offsets/u16+))

(def (read-u64 bytes offset)
  (read-unsigned-le bytes offset +byte-offsets/u64+))

(def (sample-lowering-plan)
  (feature-bundle-v1-lowering/with-symbols
   'bundle-v1-foreign-arena-test
   42
   (list
    (feature-bundle-v1-symbol 'component 'component-b "Component B" 1)
    (feature-bundle-v1-symbol 'component 'component-a "Component A" 1))
   (list
    (feature-bundle-v1-component
     'case-a 'component-b 'object-b 'type-a 'contract-a 'role-b
     'capability-a 'policy-a 'strategy-a 'adapter-a 'projection-a 1)
    (feature-bundle-v1-component
     'case-a 'component-a 'object-a 'type-a 'contract-a 'role-a
     'capability-a 'policy-a 'strategy-a 'adapter-a 'projection-a 0))
   (list
    (feature-bundle-v1-edge
     'case-a 'component-b 'component-a 'component-parent 1))
   (list
    (feature-bundle-v1-evidence
     'case-a 'obligation-a 'contract-a 'evidence-a 'lean-a 0))))

(def feature-system-bundle-v1-foreign-arena-test-suite
  (test-suite
   "feature system Bundle v1 foreign arena"

   (test-case
    "accepted lowering plan becomes a packed native arena image"
    (let* ((plan (sample-lowering-plan))
           (descriptor (.ref plan 'descriptor))
           (image (feature-bundle-v1-write-foreign-arena plan))
           (descriptor-image (.ref image 'descriptor-image))
           (arena-image (.ref image 'arena-image))
           (symbol-rows (.ref descriptor 'symbol-rows))
           (first-symbol (car symbol-rows))
           (component-rows (.ref descriptor 'component-rows))
           (first-component (car component-rows))
           (symbol-offset (read-u64 descriptor-image 80))
           (component-offset (read-u64 descriptor-image 104))
           (edge-offset (read-u64 descriptor-image 128))
           (evidence-offset (read-u64 descriptor-image 152))
           (metadata-offset (read-u64 descriptor-image 176)))
      (check (feature-bundle-v1-foreign-arena-image? image) => #t)
      (check (.ref image 'accepted?) => #t)
      (check (.ref image 'status) => 'ready)
      (check (u8vector-length descriptor-image) => 256)
      (check (u8vector-length arena-image) => 704)
      (check (.ref image 'arena-length) => 704)
      (check (read-u32 descriptor-image 0) => 256)
      (check (read-u32 descriptor-image 4) => 3)
      (check (read-u64 descriptor-image 64) => 42)
      (check (read-u64 descriptor-image 72) => 704)
      (check symbol-offset => 0)
      (check (read-u64 descriptor-image 88) => 64)
      (check (read-u32 descriptor-image 96) => 32)
      (check component-offset => 64)
      (check (read-u64 descriptor-image 112) => 400)
      (check (read-u32 descriptor-image 120) => 200)
      (check (read-u64 arena-image symbol-offset)
             => (.ref (.ref first-symbol 'id) 'high))
      (check (read-u64 arena-image (+ symbol-offset 8))
             => (.ref (.ref first-symbol 'id) 'low))
      (check (read-u64 arena-image (+ symbol-offset 16))
             => (.ref first-symbol 'byte-offset))
      (check (read-u32 arena-image (+ symbol-offset 24))
             => (.ref first-symbol 'byte-length))
      (check (read-u16 arena-image (+ symbol-offset 28)) => 1)
      (check (read-u16 arena-image (+ symbol-offset 30)) => 0)
      (check (u8vector-ref arena-image metadata-offset)
             => (u8vector-ref (.ref first-symbol 'value-bytes) 0))
      (check (read-u64 arena-image component-offset)
             => (.ref (.ref first-component 'case-id) 'high))
      (check (read-u64 arena-image (+ component-offset 8))
             => (.ref (.ref first-component 'case-id) 'low))
      (check (read-u64 arena-image (+ component-offset 176))
             => (.ref first-component 'composition-order))
      (check (read-u64 arena-image edge-offset)
             => (.ref (.ref (car (.ref descriptor 'edge-rows)) 'case-id)
                      'high))
      (check (read-u64 arena-image evidence-offset)
             => (.ref (.ref (car (.ref descriptor 'evidence-rows)) 'case-id)
                      'high))
      (check (.ref image 'diagnostics) => '())))

   (test-case
    "empty lowering plan still creates one aligned arena quantum"
    (let* ((plan (feature-bundle-v1-lowering 'empty-bundle 0 '() '() '()))
           (image (feature-bundle-v1-write-foreign-arena plan)))
      (check (.ref image 'accepted?) => #t)
      (check (.ref image 'arena-length) => 64)
      (check (u8vector-length (.ref image 'arena-image)) => 64)
      (check (read-u64 (.ref image 'descriptor-image) 72) => 64)))

   (test-case
    "invalid lowering owner fails closed with a POO diagnostic"
    (let* ((image (feature-bundle-v1-write-foreign-arena 'not-a-plan))
           (diagnostic (car (.ref image 'diagnostics))))
      (check (feature-bundle-v1-foreign-arena-image? image) => #t)
      (check (.ref image 'accepted?) => #f)
      (check (.ref image 'status) => 'rejected)
      (check (feature-bundle-v1-foreign-arena-diagnostic? diagnostic) => #t)
      (check (.ref diagnostic 'reason) => 'foreign-arena-write-failed)
      (check (u8vector-length (.ref image 'descriptor-image)) => 0)
      (check (u8vector-length (.ref image 'arena-image)) => 0)))))

(run-tests! feature-system-bundle-v1-foreign-arena-test-suite)
