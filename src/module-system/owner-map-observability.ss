(import (only-in :clan/poo/object object<-alist object?))

(export poo-flow-owner-map-event-prototype
        poo-flow-detached-snapshot-prototype
        poo-flow-owner-map-event
        poo-flow-detached-snapshot
        poo-flow-bounded-event-append
        poo-flow-owner-map-observation-object?)

(def poo-flow-owner-map-event-prototype
  (object<-alist '((kind . owner-map-event))))

(def poo-flow-detached-snapshot-prototype
  (object<-alist '((kind . detached-snapshot))))

(def (poo-flow-owner-map-event row-identity stage status sequence)
  (object<-alist
   `((kind . owner-map-event)
     (row-identity . ,row-identity)
     (stage . ,stage)
     (status . ,status)
     (sequence . ,sequence))))

(def (poo-flow-detached-snapshot generation row-identities digest)
  (object<-alist
   `((kind . detached-snapshot)
     (generation . ,generation)
     (row-identities . ,row-identities)
     (digest . ,digest))))

(def (poo-flow-bounded-event-append events event limit)
  (let (next (append events (list event)))
    (let loop ((remaining next))
      (if (<= (length remaining) limit)
          remaining
          (loop (cdr remaining))))))

(def (poo-flow-owner-map-observation-object? value)
  (object? value))
