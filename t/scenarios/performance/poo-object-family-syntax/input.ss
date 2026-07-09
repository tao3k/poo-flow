(export +poo-object-family-syntax-scenario-kind+
        poo-object-family-syntax-input-sample
        poo-object-family-syntax-input?
        poo-object-family-syntax-input-ref
        poo-object-family-syntax-input-provider
        poo-object-family-syntax-input-capabilities
        poo-object-family-syntax-input->alist)

(import (only-in :clan/poo/object .ref object<-alist))

(def +poo-object-family-syntax-scenario-kind+
  'poo-object-family-syntax-scenario)

(def poo-object-family-syntax-input-sample
  (object<-alist
   (list
    (cons 'kind +poo-object-family-syntax-scenario-kind+)
    (cons 'ref 'scenario-model)
    (cons 'provider 'runtime-local)
    (cons 'capabilities '(chat text json))
    (cons 'runtime-executed #f))))

(def (poo-object-family-syntax-input? value)
  (eq? (.ref value 'kind) +poo-object-family-syntax-scenario-kind+))

(def (poo-object-family-syntax-input-ref value)
  (.ref value 'ref))

(def (poo-object-family-syntax-input-provider value)
  (.ref value 'provider))

(def (poo-object-family-syntax-input-capabilities value)
  (.ref value 'capabilities))

(def (poo-object-family-syntax-input->alist value)
  (list
   (cons 'ref (.ref value 'ref))
   (cons 'provider (.ref value 'provider))
   (cons 'capabilities (.ref value 'capabilities))
   (cons 'runtime-executed (.ref value 'runtime-executed))))
