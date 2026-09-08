;;; Boundary: models runtime context demand cells and recovery decisions as POO values.
;;; Invariant: recovery transitions preserve context identity and explicit evidence state.
(import (only-in :clan/poo/object .ref object<-alist object?))

(export poo-flow-runtime-context-prototype
        poo-flow-demand-cell-prototype
        poo-flow-recovery-decision-prototype
        poo-flow-runtime-context
        poo-flow-demand-cell-transition
        poo-flow-recovery-decision
        poo-flow-runtime-control-object?)

(def poo-flow-runtime-context-prototype
  (object<-alist '((kind . runtime-context))))

(def poo-flow-demand-cell-prototype
  (object<-alist '((kind . demand-cell))))

(def poo-flow-recovery-decision-prototype
  (object<-alist '((kind . recovery-decision))))

;; : (-> PooFlowRuntimeIdentity Symbol Natural PooFlowRuntimeContext)
(def (poo-flow-runtime-context identity phase generation)
  (object<-alist
   `((kind . runtime-context)
     (identity . ,identity)
     (phase . ,phase)
     (generation . ,generation))))

;; : (-> PooFlowDemandCellState PooFlowDemandCellState PooFlowDemandCellState)
(def (poo-flow-demand-cell-transition current requested)
  (cond
   ((eq? current requested) current)
   ((and (eq? current 'pending) (eq? requested 'realizing)) 'realizing)
   ((and (eq? current 'realizing) (eq? requested 'realized)) 'realized)
   ((and (eq? current 'realizing) (eq? requested 'failed)) 'failed)
   (else 'invalid-transition)))

;; : (-> Condition Boolean Natural PooFlowRecoveryDecision)
(def (poo-flow-recovery-decision condition continuable? retry-budget)
  (object<-alist
   `((kind . recovery-decision)
     (condition . ,condition)
     (continuable? . ,continuable?)
     (retry-budget . ,retry-budget)
     (action . ,(match (cons continuable? (> retry-budget 0))
                  ([#t . #t] 'resume)
                  ([#t . #f] 'defer)
                  (else 'abort))))))

;; : (-> Object Boolean)
(def (poo-flow-runtime-control-object? value)
  (and (object? value)
       (with-catch
        (lambda (_failure) #f)
        (lambda ()
          (case (.ref value 'kind)
            ((runtime-context demand-cell recovery-decision) #t)
            (else #f))))))
