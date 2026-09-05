(import (only-in :clan/poo/object object<-alist object?))

(export poo-flow-g0-requirement-prototype
        poo-flow-g0-observation-prototype
        poo-flow-g0-policy-prototype
        poo-flow-g0-decision-prototype
        poo-flow-g0-resolve
        poo-flow-g0-decision?)

(def poo-flow-g0-requirement-prototype
  (object<-alist '((kind . g0-requirement))))

(def poo-flow-g0-observation-prototype
  (object<-alist '((kind . g0-observation))))

(def poo-flow-g0-policy-prototype
  (object<-alist '((kind . g0-policy))))

(def poo-flow-g0-decision-prototype
  (object<-alist '((kind . g0-decision))))

(def (poo-flow-g0-resolve requirement-id observed? authorized?)
  (object<-alist
   `((kind . g0-decision)
     (requirement-id . ,requirement-id)
     (observed? . ,observed?)
     (authorized? . ,authorized?)
     (admitted? . ,(and observed? authorized?))
     (reason . ,(cond
                 ((not observed?) 'missing-observation)
                 ((not authorized?) 'policy-denied)
                 (else 'admitted))))))

(def (poo-flow-g0-decision? value)
  (object? value))
