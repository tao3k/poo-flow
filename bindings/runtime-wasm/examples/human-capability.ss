#!/usr/bin/env gxi

(import :std/format
        :clan/poo/object
        :poo-flow/src/core/plan
        :poo-flow/src/module-system/profile-composition
        :poo-flow/src/feature-system/bundle-v1-lowering
        :poo-flow/src/feature-system/bundle-v1-foreign-arena)

(export human-capability)

(def human-capability
  (use-composition human-capability
    (use-module human-ai-capability as capability
      (profile access
        :kind interface
        :scope knowledge
        :capabilities (discover retrieve attribute))
      (profile understand
        :kind human-ai
        :scope meaning
        :capabilities (contextualize inspect contest))
      (profile compose
        :kind human-ai
        :scope synthesis
        :capabilities (connect model frame))
      (profile qualify
        :kind authority
        :scope evidence
        :capabilities (verify constrain admit))
      (profile act
        :kind human-authority
        :scope execution
        :capabilities (decide execute pause stop))
      (profile learn
        :kind evidence-return
        :scope outcomes
        :capabilities (record correct reuse compound)))
    (compose
      (profile capability access)
      (profile capability understand)
      (profile capability compose)
      (profile capability qualify)
      (profile capability act)
      (profile capability learn))
    (stage knowledge
      (step access)
      (step understand)
      (step compose)
      (edges (access understand)
             (understand compose)))
    (stage governed-action
      (step qualify)
      (step act)
      (edges (qualify act)))
    (stage evidence-return
      (step learn))
    (stage human-capability-cycle
      (step knowledge)
      (step governed-action)
      (step evidence-return)
      (edges (knowledge governed-action)
             (governed-action evidence-return)))))

(def (required-output-path variable)
  (let (path (getenv variable))
    (unless (and path (> (string-length path) 0))
      (error "Human capability Bundle v1 output path is required" variable))
    path))

(def (write-u8vector-file! path bytes)
  (let (port (open-output-file (list path: path)))
    (unwind-protect
      (let (written
            (write-subu8vector bytes 0 (u8vector-length bytes) port))
        (unless (= written (u8vector-length bytes))
          (error "Incomplete human capability Bundle v1 write" path)))
      (close-output-port port))))

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
        'poo-flow.adapter.wasm
        'poo-flow.projection.react-flow
        (plan-node-ordinal node))))
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

(def (write-human-capability-bundle!)
  (let* ((descriptor-path
          (required-output-path "POO_FLOW_HUMAN_CAPABILITY_DESCRIPTOR_OUT"))
         (arena-path
          (required-output-path "POO_FLOW_HUMAN_CAPABILITY_ARENA_OUT"))
         (plan (poo-flow-composition->execution-plan human-capability))
         (lowering
          (require-feature-bundle-v1-lowering-plan
           (feature-bundle-v1-lowering
            'human-capability
            1
            (plan-components plan)
            (plan-edges plan)
            '())))
         (image
          (require-feature-bundle-v1-foreign-arena-image
           (feature-bundle-v1-write-foreign-arena lowering)))
         (descriptor-image (.ref image 'descriptor-image))
         (arena-image (.ref image 'arena-image)))
    (write-u8vector-file! descriptor-path descriptor-image)
    (write-u8vector-file! arena-path arena-image)
    (display "POO_FLOW_HUMAN_CAPABILITY_BUNDLE_RECEIPT nodes=")
    (display (length (execution-plan-nodes plan)))
    (display " edges=")
    (display (length (execution-plan-dependency-edges plan)))
    (newline)))

(write-human-capability-bundle!)
