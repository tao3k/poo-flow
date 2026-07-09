(export +poo-object-family-syntax-expected-kind+
        poo-object-family-syntax-expected-sample
        poo-object-family-syntax-expected?
        poo-object-family-syntax-expected-ref
        poo-object-family-syntax-expected-provider
        poo-object-family-syntax-expected-capabilities
        poo-object-family-syntax-expected->alist)

(import (only-in :clan/poo/object object<-alist)
        :poo-flow/src/module-system/object-family-syntax)

(def +poo-object-family-syntax-expected-kind+
  'poo-object-family-syntax-scenario)

(def poo-object-family-syntax-expected-sample
  (object<-alist
   (list
    (cons 'kind +poo-object-family-syntax-expected-kind+)
    (cons 'ref 'scenario-model)
    (cons 'provider 'runtime-local)
    (cons 'capabilities '(chat text json))
    (cons 'runtime-executed #f))))

(defpoo-object-family +poo-object-family-syntax-expected-kind+
  poo-object-family-syntax-expected?
  (accessors
   (poo-object-family-syntax-expected-ref ref)
   (poo-object-family-syntax-expected-provider provider)
   (poo-object-family-syntax-expected-capabilities capabilities))
  (projections
   (poo-object-family-syntax-expected->alist
    (ref ref)
    (provider provider)
    (capabilities capabilities)
    (runtime-executed runtime-executed))))
