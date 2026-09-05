(import (only-in :clan/poo/object object<-alist object?))

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

(def (poo-flow-runtime-context identity phase generation)
  (object<-alist
   `((kind . runtime-context)
     (identity . ,identity)
     (phase . ,phase)
     (generation . ,generation))))

(def (poo-flow-demand-cell-transition current requested)
  (cond
   ((and (eq? current 'pending) (eq? requested 'realizing)) 'realizing)
   ((and (eq? current 'realizing) (eq? requested 'realized)) 'realized)
   ((and (eq? current 'realizing) (eq? requested 'failed)) 'failed)
   ((eq? current requested) current)
   (else 'invalid-transition)))

(def (poo-flow-recovery-decision condition continuable? retry-budget)
  (object<-alist
   `((kind . recovery-decision)
     (condition . ,condition)
     (continuable? . ,continuable?)
     (retry-budget . ,retry-budget)
     (action . ,(cond
                 ((and continuable? (> retry-budget 0)) 'resume)
                 (continuable? 'defer)
                 (else 'abort))))))

(def (poo-flow-runtime-control-object? value)
  (object? value))
