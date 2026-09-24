;;; Inert negative fixture: direct CLOS declarations are not root configuration.
(def UserGeneric
  (poo-clos-generic-function 'user-generic 1))
(user-composition direct-clos
  (compose profiles MaintainedHealthcareProfile))
