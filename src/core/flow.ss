;;; -*- Gerbil -*-
;;; Boundary: flows describe workflow composition and contract shape.
;;; Invariant: task execution is deferred to runner/runtime-adapter code.

(import (only-in :clan/poo/object .o .@ object?)
        :core/roles
        :core/task)

(export make-flow
        flow?
        flow-name
        flow-steps
        flow-input-contract
        flow-output-contract
        make-flow-declaration-descriptor
        flow-declaration-descriptor?
        make-flow-declaration-registry
        flow-declaration-registry?
        default-flow-declaration-registry
        flow-declaration-registry-name
        flow-declaration-registry-descriptors
        flow-declaration-registry-extend
        task-flow-descriptor
        sequential-flow-descriptor
        branch-flow-descriptor
        empty-flow-descriptor
        flow-declaration-descriptors
        flow-declaration-name
        flow-declaration-kind
        flow-declaration-planner
        flow-extension-policy
        flow-declaration-for-kind-in
        flow-declaration-descriptor-in
        flow-declaration-descriptor
        flow-branch-declaration?
        flow-task-declaration?
        flow-sequential-declaration?
        make-branch-step
        branch-step?
        branch-step-name
        branch-step-left
        branch-step-right
        branch-step-input-contract
        branch-step-output-contract
        flow-compose
        task-flow
        pure-flow
        scheme-flow
        store-flow
        external-flow
        return-flow
        flow-then
        flow-branch
        flow-empty?
        flow-step-count)

;;; Boundary: a flow stores ordered steps plus its input/output contract edge.
;;; Invariant: nested flows remain steps until a planner chooses lowering.
;; Flow <- Symbol [Step] Contract Contract
(defstruct flow
  (name
   steps
   input-contract
   output-contract)
  transparent: #t)

;;; Flow descriptors are POO declaration metadata: they select planning policy
;;; without changing the stable flow record or running any task.
;; FlowDeclarationDescriptor <- Symbol Symbol PlannerPolicy ExtensionPolicy
(def (make-flow-declaration-descriptor descriptor-name descriptor-kind descriptor-planner descriptor-extension-policy)
  (.o (:: @ flow-role)
      (name descriptor-name)
      (kind 'flow-declaration)
      (declaration-kind descriptor-kind)
      (planner descriptor-planner)
      (extension-policy descriptor-extension-policy)
      (responsibility (list 'flow-declaration descriptor-kind descriptor-planner))))

;; Boolean <- FlowDeclarationDescriptorCandidate
(def (flow-declaration-descriptor? descriptor)
  (and (object? descriptor)
       (eq? (.@ descriptor kind) 'flow-declaration)))

;;; Flow declaration registries are immutable extension bundles. Strategy code
;;; can consume a registry without knowing which module contributed descriptors.
;; FlowDeclarationRegistry <- Symbol [FlowDeclarationDescriptor]
(def (make-flow-declaration-registry registry-name registry-descriptors)
  (.o (:: @ flow-role)
      (name registry-name)
      (kind 'flow-declaration-registry)
      (descriptors registry-descriptors)
      (responsibility (list 'flow-declaration-registry registry-name))))

;; Boolean <- FlowDeclarationRegistryCandidate
(def (flow-declaration-registry? registry)
  (and (object? registry)
       (eq? (.@ registry kind) 'flow-declaration-registry)))

;; Symbol <- FlowDeclarationRegistry
(def (flow-declaration-registry-name registry)
  (.@ registry name))

;; [FlowDeclarationDescriptor] <- FlowDeclarationRegistry
(def (flow-declaration-registry-descriptors registry)
  (.@ registry descriptors))

;; FlowDeclarationRegistry <- FlowDeclarationRegistry FlowDeclarationDescriptor
(def (flow-declaration-registry-extend registry descriptor)
  (make-flow-declaration-registry
   (flow-declaration-registry-name registry)
   (append (flow-declaration-registry-descriptors registry)
           (list descriptor))))

;; FlowDeclarationDescriptor <- Unit
(def task-flow-descriptor
  (make-flow-declaration-descriptor 'task-flow 'task 'linear-dag 'closed))

;; FlowDeclarationDescriptor <- Unit
(def sequential-flow-descriptor
  (make-flow-declaration-descriptor 'sequential-flow 'sequential 'linear-dag 'composable))

;; FlowDeclarationDescriptor <- Unit
(def branch-flow-descriptor
  (make-flow-declaration-descriptor 'branch-flow 'branch 'linear-dag 'parallelizable))

;; FlowDeclarationDescriptor <- Unit
(def empty-flow-descriptor
  (make-flow-declaration-descriptor 'empty-flow 'empty 'linear-dag 'identity))

;; FlowDeclarationRegistry <- Unit
(def default-flow-declaration-registry
  (make-flow-declaration-registry
   'default-flow-declarations
   (list task-flow-descriptor
         sequential-flow-descriptor
         branch-flow-descriptor
         empty-flow-descriptor)))

;; [FlowDeclarationDescriptor] <- Unit
(def flow-declaration-descriptors
  (flow-declaration-registry-descriptors default-flow-declaration-registry))

;; Symbol <- FlowDeclarationDescriptor
(def (flow-declaration-name descriptor)
  (.@ descriptor name))

;; Symbol <- FlowDeclarationDescriptor
(def (flow-declaration-kind descriptor)
  (.@ descriptor declaration-kind))

;; PlannerPolicy <- FlowDeclarationDescriptor
(def (flow-declaration-planner descriptor)
  (.@ descriptor planner))

;; ExtensionPolicy <- FlowDeclarationDescriptor
(def (flow-extension-policy descriptor)
  (.@ descriptor extension-policy))

;; MaybeFlowDeclarationDescriptor <- Symbol [FlowDeclarationDescriptor]
(def (find-flow-declaration kind descriptors)
  (cond
   ((null? descriptors) #f)
   ((eq? kind (flow-declaration-kind (car descriptors))) (car descriptors))
   (else (find-flow-declaration kind (cdr descriptors)))))

;; FlowDeclarationDescriptor <- FlowDeclarationRegistry Symbol
(def (flow-declaration-for-kind-in registry kind)
  (let ((descriptor (find-flow-declaration
                     kind
                     (flow-declaration-registry-descriptors registry))))
    (if descriptor
      descriptor
      (error "unknown flow declaration kind" kind))))

;;; Branch steps keep the left and right flows as declarations so planning can
;;; expose a DAG before runner or adapter code chooses an execution strategy.
;; BranchStep <- Symbol Flow Flow Contract Contract
(defstruct branch-step
  (name
   left
   right
   input-contract
   output-contract)
  transparent: #t)

;; Flow <- Symbol [Step] Contract Contract
(def (flow-compose name steps input-contract output-contract)
  (make-flow name steps input-contract output-contract))

;; Flow <- Symbol Task
(def (task-flow name task)
  (flow-compose name
                (list task)
                (task-input-contract task)
                (task-output-contract task)))

;; Flow <- Symbol Procedure Contract Contract
(def (pure-flow name proc input-contract output-contract)
  (task-flow name (make-pure-task name proc input-contract output-contract)))

;; Flow <- Symbol Procedure Contract Contract
(def (scheme-flow name proc input-contract output-contract)
  (task-flow name (make-scheme-task name proc input-contract output-contract)))

;; Flow <- Symbol Symbol Payload Contract Contract
(def (store-flow name operation payload input-contract output-contract)
  (task-flow name (make-store-task name operation payload input-contract output-contract)))

;; Flow <- Symbol Symbol Payload Contract Contract
(def (external-flow name operation payload input-contract output-contract)
  (task-flow name (make-external-task name operation payload input-contract output-contract)))

;;; The identity lambda is the unit flow: it preserves value and contract while
;;; still presenting the same task-backed flow shape as non-trivial steps.
;; Flow <- Symbol Contract
(def (return-flow name contract)
  (pure-flow name (lambda (value) value) contract contract))

;;; Composition concatenates logical steps and keeps the left input/right output
;;; edge, matching pipeline composition without running either side.
;; Flow <- Symbol Flow Flow
(def (flow-then name left right)
  (flow-compose name
                (append (flow-steps left) (flow-steps right))
                (flow-input-contract left)
                (flow-output-contract right)))

;;; Branch composition applies two flows to the same input and joins their
;;; outputs as a pair-shaped value, leaving heavy parallelism to adapters.
;; Flow <- Symbol Flow Flow
(def (flow-branch name left right)
  (flow-compose name
                (list (make-branch-step name
                                        left
                                        right
                                        (flow-input-contract left)
                                        (list 'pair
                                              (flow-output-contract left)
                                              (flow-output-contract right))))
                (flow-input-contract left)
                (list 'pair
                      (flow-output-contract left)
                      (flow-output-contract right))))

;; Boolean <- Flow
(def (flow-empty? flow)
  (null? (flow-steps flow)))

;; Boolean <- Flow
(def (flow-branch-declaration? flow)
  (steps-contain-branch? (flow-steps flow)))

;; Boolean <- Flow
(def (flow-task-declaration? flow)
  (let ((steps (flow-steps flow)))
    (and (not (null? steps))
         (null? (cdr steps))
         (task? (car steps)))))

;; Boolean <- Flow
(def (flow-sequential-declaration? flow)
  (and (not (flow-empty? flow))
       (not (flow-branch-declaration? flow))
       (not (flow-task-declaration? flow))))

;; Boolean <- [Step]
(def (steps-contain-branch? steps)
  (cond
   ((null? steps) #f)
   ((branch-step? (car steps)) #t)
   (else (steps-contain-branch? (cdr steps)))))

;;; Descriptor selection is purely structural today; future extension flows can
;;; add new descriptors without changing the runner execution loop.
;; FlowDeclarationDescriptor <- FlowDeclarationRegistry Flow
(def (flow-declaration-descriptor-in registry flow)
  (cond
   ((flow-empty? flow) (flow-declaration-for-kind-in registry 'empty))
   ((flow-branch-declaration? flow) (flow-declaration-for-kind-in registry 'branch))
   ((flow-task-declaration? flow) (flow-declaration-for-kind-in registry 'task))
   (else (flow-declaration-for-kind-in registry 'sequential))))

;; FlowDeclarationDescriptor <- Flow
(def (flow-declaration-descriptor flow)
  (flow-declaration-descriptor-in default-flow-declaration-registry flow))

;; Nat <- Flow
(def (flow-step-count flow)
  (length (flow-steps flow)))
