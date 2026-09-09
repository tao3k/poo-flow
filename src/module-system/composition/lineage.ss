;;; Boundary: analyzes composition lineage for cycles and productive recursion.
;;; Invariant: analysis reports lineage facts without mutating the composed objects.
(import (only-in :poo-flow/src/module-system/object-family/syntax
                 defpoo-object-family))

(export poo-flow-lineage-analysis-prototype
        poo-flow-lineage-cycle?
        poo-flow-productive-recursion?
        poo-flow-lineage-analysis
        poo-flow-lineage-analysis?)

;; : (-> [PooFlowLineageIdentity] Boolean)
(def (poo-flow-lineage-cycle? lineage)
  (car
   (foldl (lambda (identity state)
            (cons (or (car state)
                      (and (member identity (cdr state)) #t))
                  (cons identity (cdr state))))
          (cons #f '())
          lineage)))

;; : (-> [PooFlowLineageIdentity] [PooFlowLineageIdentity] Boolean)
(def (poo-flow-productive-recursion? lineage productive-identities)
  (and (poo-flow-lineage-cycle? lineage)
       (ormap (lambda (identity)
                (if (member identity productive-identities) #t #f))
              lineage)))

;; : (-> [PooFlowLineageIdentity] [PooFlowLineageIdentity] PooFlowLineageAnalysis)
(def (poo-flow-lineage-analysis-values lineage-value productive-identities)
  (let* ((cycle-value (poo-flow-lineage-cycle? lineage-value))
         (productive-value
          (poo-flow-productive-recursion?
           lineage-value productive-identities))
         (status-value
          (match (cons cycle-value productive-value)
            ([#f . _] 'acyclic)
            ([#t . #t] 'productive-recursion)
            (else 'non-productive-cycle))))
    (values lineage-value cycle-value productive-value status-value)))

(defpoo-object-family
  (prototype poo-flow-lineage-analysis-prototype
             lineage-analysis?
             poo-flow-lineage-analysis?
             (kind 'lineage-analysis))
  (constructor make-poo-flow-lineage-analysis
               (lineage-value lineage)
               (cycle-value cycle?)
               (productive-value productive?)
               (status-value status))
  (accessors)
  (projections))

;; : (-> [PooFlowLineageIdentity] [PooFlowLineageIdentity] PooFlowLineageAnalysis)
(def (poo-flow-lineage-analysis lineage-value productive-identities)
  (call-with-values
   (lambda ()
     (poo-flow-lineage-analysis-values lineage-value productive-identities))
   make-poo-flow-lineage-analysis))
