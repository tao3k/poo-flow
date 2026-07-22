(export feature-system-bundle-v1-lowering-test-suite)

(import :std/test
        :clan/poo/object
        :poo-flow/src/feature-system/bundle-v1-lowering)

(def (sample-component component-id composition-order)
  (feature-bundle-v1-component
   'case-a component-id
   (string->symbol (string-append (symbol->string component-id) "-object"))
   'agent-type 'agent-contract 'worker-role 'tool-capability
   'bounded-policy 'retry-strategy 'python-adapter 'runtime-projection
   composition-order))

(def (sample-symbol component-id label)
  (feature-bundle-v1-symbol 'component component-id label 1))

(def feature-system-bundle-v1-lowering-test-suite
  (test-suite
   "feature-system Bundle v1 lowering"

   (test-case
    "compact identities are deterministic and domain separated"
    (let ((first
           (feature-bundle-v1-lower-compact-id 'component 'agent-a))
          (second
           (feature-bundle-v1-lower-compact-id 'component 'agent-a))
          (other-domain
           (feature-bundle-v1-lower-compact-id 'role 'agent-a)))
      (check (feature-bundle-v1-compact-id? first) => #t)
      (check (feature-bundle-v1-compact-id=? first second) => #t)
      (check (feature-bundle-v1-compact-id=? first other-domain) => #f)))

   (test-case
    "compact identity segments retain the full SHA-256 prefix"
    (let ((zero
           (feature-bundle-v1-lower-compact-id 'obligation 0))
          (one
           (feature-bundle-v1-lower-compact-id 'obligation 1)))
      (check (> (.ref zero 'high) 4294967295) => #t)
      (check (> (.ref zero 'low) 4294967295) => #t)
      (check (.ref zero 'high) => 15650260190551699577)
      (check (.ref zero 'low) => 10580127755728368254)
      (check (feature-bundle-v1-compact-id=? zero one) => #f)))

   (test-case
    "POO-native values lower into the frozen C layout"
    (let* ((component-b (sample-component 'agent-b 1))
           (component-a (sample-component 'agent-a 0))
           (input-components (list component-b component-a))
           (edge
            (feature-bundle-v1-edge
             'case-a 'agent-a 'agent-b 'depends-on 0))
           (evidence
            (feature-bundle-v1-evidence
             'case-a 'proof-a 'agent-contract 'signed-receipt 'lean 0))
           (plan
            (feature-bundle-v1-lowering/with-symbols
             'bundle-a 7
             (list (sample-symbol 'agent-b "Agent B")
                   (sample-symbol 'agent-a "Agent A"))
             input-components (list edge) (list evidence)))
           (descriptor (.ref plan 'descriptor))
           (symbols (.ref descriptor 'symbols))
           (components (.ref descriptor 'components))
           (edges (.ref descriptor 'edges))
           (obligations (.ref descriptor 'evidence-obligations))
           (metadata (.ref descriptor 'metadata-bytes))
           (symbol-rows (.ref descriptor 'symbol-rows))
           (rows (.ref descriptor 'component-rows))
           (native-edges (.ref descriptor 'edge-rows))
           (native-evidence (.ref descriptor 'evidence-rows)))
      (check (feature-bundle-v1-lowering-plan? plan) => #t)
      (check (.ref plan 'accepted?) => #t)
      (check (.ref plan 'status) => 'ready)
      (check (eq? (require-feature-bundle-v1-lowering-plan plan) plan) => #t)
      (check (feature-bundle-v1-descriptor? descriptor) => #t)
      (check (.ref descriptor 'struct-size) => 256)
      (check (.ref descriptor 'flags) => 3)
      (check (.ref descriptor 'schema-major) => 1)
      (check (.ref descriptor 'schema-minor) => 0)
      (check (.ref descriptor 'reserved0) => 0)
      (check (.ref descriptor 'bundle-epoch) => 7)
      (check (.ref descriptor 'reserved) => '(0 0 0 0 0 0 0))
      (check (.ref descriptor 'arena-bytes) => 704)
      (check (.ref symbols 'offset) => 0)
      (check (.ref symbols 'length) => 64)
      (check (.ref symbols 'count) => 2)
      (check (.ref symbols 'stride) => 32)
      (check (.ref components 'offset) => 64)
      (check (.ref components 'length) => 400)
      (check (.ref components 'stride) => 200)
      (check (.ref edges 'offset) => 464)
      (check (.ref edges 'length) => 80)
      (check (.ref obligations 'offset) => 544)
      (check (.ref obligations 'length) => 96)
      (check (.ref metadata 'offset) => 640)
      (check (.ref metadata 'length) => 14)
      (check (u8vector-length (.ref descriptor 'metadata-image)) => 14)
      (check (u8vector-length (.ref descriptor 'digest)) => 32)
      (check (length symbol-rows) => 2)
      (check (feature-bundle-v1-native-symbol? (car symbol-rows)) => #t)
      (check (.ref (car symbol-rows) 'flags) => 0)
      (check (feature-bundle-v1-native-component? (car rows)) => #t)
      (check (.ref (car rows) 'flags) => 1)
      (check (.ref (car rows) 'reserved0) => 0)
      (check (.ref (car rows) 'reserved1) => 0)
      (check (feature-bundle-v1-native-edge? (car native-edges)) => #t)
      (check (.ref (car native-edges) 'reserved0) => 0)
      (check (feature-bundle-v1-native-evidence? (car native-evidence)) => #t)
      (check (.ref (car native-evidence) 'reserved0) => 0)
      (check (feature-bundle-v1-compact-id<?
              (.ref (car rows) 'component-id)
              (.ref (cadr rows) 'component-id))
             => #t)
      (check (eq? (car input-components) component-b) => #t)))

   (test-case
   "equivalent input produces an identical digest"
    (let* ((symbols
            (list (sample-symbol 'agent-b "Agent B")
                  (sample-symbol 'agent-a "Agent A")))
           (first
            (feature-bundle-v1-lowering/with-symbols
             'bundle-a 0 symbols
             (list (sample-component 'agent-b 1)
                   (sample-component 'agent-a 0))
             '() '()))
           (second
            (feature-bundle-v1-lowering/with-symbols
             'bundle-a 0 (reverse symbols)
             (list (sample-component 'agent-a 0)
                   (sample-component 'agent-b 1))
             '() '()))
           (renamed
            (feature-bundle-v1-lowering/with-symbols
             'bundle-a 0
             (list (sample-symbol 'agent-b "Renamed B")
                   (sample-symbol 'agent-a "Agent A"))
             (list (sample-component 'agent-a 0)
                   (sample-component 'agent-b 1))
             '() '())))
      (check (equal? (.ref (.ref first 'descriptor) 'digest)
                     (.ref (.ref second 'descriptor) 'digest))
             => #t)
      (check (equal? (.ref (.ref first 'descriptor) 'digest)
                     (.ref (.ref renamed 'descriptor) 'digest))
             => #f)))

   (test-case
   "duplicate and non-POO Bundle surfaces fail closed"
    (let* ((component (sample-component 'agent-a 0))
           (duplicate-symbol
            (feature-bundle-v1-lowering/with-symbols
             'bundle-a 0
             (list (sample-symbol 'agent-a "Agent A")
                   (sample-symbol 'agent-a "Agent A again"))
             (list component) '() '()))
           (invalid-symbol
            (feature-bundle-v1-lowering/with-symbols
             'bundle-a 0 '(not-a-symbol-row) (list component) '() '()))
           (duplicate
            (feature-bundle-v1-lowering
             'bundle-a 0 (list component component) '() '()))
           (raw
            (feature-bundle-v1-lowering
             'bundle-a 0 '((case-id . case-a)) '() '()))
           (invalid-order
            (feature-bundle-v1-lowering
             'bundle-a 0 (list (sample-component 'agent-a -1)) '() '()))
           (invalid-epoch
            (feature-bundle-v1-lowering
             'bundle-a -1 (list component) '() '())))
      (check (.ref duplicate-symbol 'accepted?) => #f)
      (check (.ref (car (.ref duplicate-symbol 'diagnostics)) 'code)
             => 'duplicate-symbol-key)
      (check (.ref invalid-symbol 'accepted?) => #f)
      (check (.ref (car (.ref invalid-symbol 'diagnostics)) 'code)
             => 'invalid-symbol)
      (check (.ref duplicate 'accepted?) => #f)
      (check (.ref (car (.ref duplicate 'diagnostics)) 'code)
             => 'duplicate-component-key)
      (check (.ref raw 'accepted?) => #f)
      (check (.ref (car (.ref raw 'diagnostics)) 'code)
             => 'invalid-component)
      (check (.ref invalid-order 'accepted?) => #f)
      (check (.ref (car (.ref invalid-order 'diagnostics)) 'code)
             => 'invalid-component)
      (check (.ref invalid-epoch 'accepted?) => #f)
      (check (.ref (car (.ref invalid-epoch 'diagnostics)) 'code)
             => 'invalid-bundle-epoch)))

   (test-case
    "an empty Bundle still receives one aligned arena page"
    (let* ((plan (feature-bundle-v1-lowering
                  'empty-bundle 0 '() '() '()))
           (descriptor (.ref plan 'descriptor)))
      (check (.ref plan 'accepted?) => #t)
      (check (.ref descriptor 'arena-bytes) => 64)
      (check (.ref (.ref descriptor 'components) 'count) => 0)
      (check (.ref (.ref descriptor 'edges) 'count) => 0)
      (check (.ref (.ref descriptor 'evidence-obligations) 'count) => 0)))))

(run-tests! feature-system-bundle-v1-lowering-test-suite)
