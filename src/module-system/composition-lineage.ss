;;; Boundary: analyzes composition lineage for cycles and productive recursion.
;;; Invariant: analysis reports lineage facts without mutating the composed objects.
(import (only-in :clan/poo/object object<-alist object?))

(export poo-flow-lineage-analysis-prototype
        poo-flow-lineage-cycle?
        poo-flow-productive-recursion?
        poo-flow-lineage-analysis
        poo-flow-lineage-analysis?)

(def poo-flow-lineage-analysis-prototype
  (object<-alist '((kind . lineage-analysis))))

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
                (member identity productive-identities))
              lineage)))

;; : (-> [PooFlowLineageIdentity] [PooFlowLineageIdentity] PooFlowLineageAnalysis)
(def (poo-flow-lineage-analysis lineage productive-identities)
  (let* ((cycle? (poo-flow-lineage-cycle? lineage))
         (productive? (poo-flow-productive-recursion?
                       lineage
                       productive-identities)))
    (object<-alist
     `((kind . lineage-analysis)
       (lineage . ,lineage)
       (cycle? . ,cycle?)
       (productive? . ,productive?)
       (status . ,(match (cons cycle? productive?)
                    ([#f . _] 'acyclic)
                    ([#t . #t] 'productive-recursion)
                    (else 'non-productive-cycle)))))))

;; : (-> Object Boolean)
(def (poo-flow-lineage-analysis? value)
  (object? value))
