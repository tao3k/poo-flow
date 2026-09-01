(import (only-in :clan/poo/object object<-alist object?))

(export poo-flow-lineage-analysis-prototype
        poo-flow-lineage-cycle?
        poo-flow-productive-recursion?
        poo-flow-lineage-analysis
        poo-flow-lineage-analysis?)

(def poo-flow-lineage-analysis-prototype
  (object<-alist '((kind . lineage-analysis))))

(def (poo-flow-lineage-cycle? lineage)
  (let loop ((remaining lineage) (seen '()))
    (cond
     ((null? remaining) #f)
     ((member (car remaining) seen) #t)
     (else (loop (cdr remaining) (cons (car remaining) seen))))))

(def (poo-flow-productive-recursion? lineage productive-identities)
  (and (poo-flow-lineage-cycle? lineage)
       (let loop ((remaining lineage))
         (cond
          ((null? remaining) #f)
          ((member (car remaining) productive-identities) #t)
          (else (loop (cdr remaining)))))))

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
       (status . ,(cond
                   ((not cycle?) 'acyclic)
                   (productive? 'productive-recursion)
                   (else 'non-productive-cycle)))))))

(def (poo-flow-lineage-analysis? value)
  (object? value))
