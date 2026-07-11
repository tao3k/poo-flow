(import :std/test
        (only-in :clan/poo/object object<-alist)
        :poo-flow/src/module-system/object-family-syntax)

(def +poo-object-family-syntax-test-kind+
  'poo-object-family-syntax-test)

(def poo-object-family-syntax-test-object
  (object<-alist
   (list
    (cons 'kind +poo-object-family-syntax-test-kind+)
    (cons 'ref 'scenario-model)
    (cons 'provider 'runtime-local)
    (cons 'capabilities '(chat text json))
    (cons 'runtime-executed #f))))

(defpoo-object-family +poo-object-family-syntax-test-kind+
  poo-object-family-syntax-test?
  (accessors
   (poo-object-family-syntax-test-ref ref)
   (poo-object-family-syntax-test-provider provider)
   (poo-object-family-syntax-test-capabilities capabilities))
  (projections
   (poo-object-family-syntax-test->alist
    (ref ref)
    (provider provider)
    (capabilities capabilities)
    (runtime-executed runtime-executed))))

(def object-family-syntax-suite
  (test-suite "object family syntax"
    (test-case "generates POO-native predicates, accessors, and projections"
      (check-equal? (poo-object-family-syntax-test?
                     poo-object-family-syntax-test-object)
                    #t)
      (check-equal? (poo-object-family-syntax-test? 'not-a-poo-object) #f)
      (check-equal?
       (poo-object-family-syntax-test?
        (object<-alist (list (cons 'ref 'missing-kind))))
       #f)
      (check-equal? (poo-object-family-syntax-test-ref
                     poo-object-family-syntax-test-object)
                    'scenario-model)
      (check-equal? (poo-object-family-syntax-test-provider
                     poo-object-family-syntax-test-object)
                    'runtime-local)
      (check-equal? (poo-object-family-syntax-test-capabilities
                     poo-object-family-syntax-test-object)
                    '(chat text json))
      (check-equal? (poo-object-family-syntax-test->alist
                     poo-object-family-syntax-test-object)
                    '((ref . scenario-model)
                      (provider . runtime-local)
                      (capabilities chat text json)
                      (runtime-executed . #f))))))

(run-tests! object-family-syntax-suite)
