(export poo-flow-composition->bundle-v1-image
        poo-flow-write-composition-bundle-v1!
        poo-flow-write-composition-bundle-v1/from-environment!)

(import :std/format
        :clan/poo/object
        :poo-flow/src/core/plan
        :poo-flow/src/module-system/profile-composition
        :poo-flow/src/feature-system/bundle-v1-lowering
        :poo-flow/src/feature-system/bundle-v1-foreign-arena)

(def (plan-node-semantic-id node)
  (format "~s" (plan-node-id node)))

(def (plan-components plan)
  (map
   (lambda (node)
     (let (semantic-id (plan-node-semantic-id node))
       (feature-bundle-v1-component
        (execution-plan-flow-name plan)
        semantic-id
        semantic-id
        (plan-node-kind node)
        'poo-flow.contract.none
        (plan-node-kind node)
        (plan-node-name node)
        'poo-flow.policy.none
        'poo-flow.strategy.none
        +feature-bundle-v1-no-adapter-id+
        +feature-bundle-v1-no-projection-id+
        (plan-node-ordinal node))))
   (execution-plan-nodes plan)))

(def (plan-symbols plan)
  (map
   (lambda (node)
     (feature-bundle-v1-symbol
      'component
      (plan-node-semantic-id node)
      (symbol->string (plan-node-name node))
      1))
   (execution-plan-nodes plan)))

(def (plan-edges plan)
  (let loop
      ((rest (execution-plan-dependency-edges plan))
       (order 0)
       (out '()))
    (if (null? rest)
      (reverse out)
      (let (edge (car rest))
        (loop
         (cdr rest)
         (+ order 1)
         (cons
          (feature-bundle-v1-edge
           (execution-plan-flow-name plan)
           (format "~s" (car edge))
           (format "~s" (cadr edge))
           'poo-flow.bundle-v1.plan-dependency
           order)
          out))))))

(def (poo-flow-composition->bundle-v1-image composition bundle-id bundle-epoch)
  (let* ((plan (poo-flow-composition->execution-plan composition))
         (lowering
          (require-feature-bundle-v1-lowering-plan
           (feature-bundle-v1-lowering/with-symbols
            bundle-id
            bundle-epoch
            (plan-symbols plan)
            (plan-components plan)
            (plan-edges plan)
            '())))
         (image
          (require-feature-bundle-v1-foreign-arena-image
           (feature-bundle-v1-write-foreign-arena lowering))))
    (values plan image)))

(def (write-u8vector-file! path bytes)
  (let (port (open-output-file (list path: path)))
    (unwind-protect
      (let (written
            (write-subu8vector bytes 0 (u8vector-length bytes) port))
        (unless (= written (u8vector-length bytes))
          (error "Incomplete Bundle v1 composition write"
                 path written (u8vector-length bytes))))
      (close-output-port port))))

(def (poo-flow-write-composition-bundle-v1!
      composition bundle-id bundle-epoch descriptor-path arena-path)
  (let-values (((plan image)
                (poo-flow-composition->bundle-v1-image
                 composition bundle-id bundle-epoch)))
    (write-u8vector-file! descriptor-path (.ref image 'descriptor-image))
    (write-u8vector-file! arena-path (.ref image 'arena-image))
    plan))

(def (required-environment-value name)
  (let (value (getenv name))
    (unless (and value (> (string-length value) 0))
      (error "Bundle v1 composition environment value is required" name))
    value))

(def (poo-flow-write-composition-bundle-v1/from-environment! composition)
  (let* ((bundle-id
          (string->symbol
           (required-environment-value "POO_FLOW_BUNDLE_V1_ID")))
         (bundle-epoch-text
          (required-environment-value "POO_FLOW_BUNDLE_V1_EPOCH"))
         (bundle-epoch (string->number bundle-epoch-text))
         (descriptor-path
          (required-environment-value "POO_FLOW_BUNDLE_V1_DESCRIPTOR_OUT"))
         (arena-path
          (required-environment-value "POO_FLOW_BUNDLE_V1_ARENA_OUT")))
    (unless (and bundle-epoch
                 (integer? bundle-epoch)
                 (>= bundle-epoch 0))
      (error "Bundle v1 epoch must be a non-negative integer"
             bundle-epoch-text))
    (let (plan
          (poo-flow-write-composition-bundle-v1!
           composition bundle-id bundle-epoch descriptor-path arena-path))
      (display "POO_FLOW_BUNDLE_V1_RECEIPT bundle=")
      (display bundle-id)
      (display " nodes=")
      (display (length (execution-plan-nodes plan)))
      (display " edges=")
      (display (length (execution-plan-dependency-edges plan)))
      (display " symbols=")
      (display (length (execution-plan-nodes plan)))
      (newline)
      plan)))
