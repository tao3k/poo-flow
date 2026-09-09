;;; -*- Gerbil -*-
;;; Boundary: tests verify strict module-system observability traces.
;;; Invariant: trace construction never dereferences POO slots.

(import :gerbil/gambit
        (only-in :clan/poo/object .ref object?)
        (only-in :std/srfi/13 string-suffix?)
        (only-in :std/test
                 check
                 check-eq?
                 check-equal?
                 check-false
                 check-not-equal?
                 check-output
                 check-true
                 run-tests!
                 test-case
                 test-error
                 test-suite)
        :poo-flow/src/module-system/observability/module-presentation
        :poo-flow/src/module-system/observability/module-source-observation
        :poo-flow/src/module-system/facade)

(export module-system-observability-test)

;; : (-> Symbol Alist Value)
(def (module-observability-test-alist-value key rows)
  (cdr (assoc key rows)))

;; Native Scheme owns the source gate as well as the observations.  The walk is
;; deliberately rooted at `src/` and reads `.ss` files without expanding them.
(def (module-observability-source-files directory)
  (apply append
         (map (lambda (name)
                (let (path (path-expand name directory))
                  (cond
                   ((eq? (file-info-type (file-info path)) 'directory)
                    (module-observability-source-files path))
                   ((string-suffix? ".ss" name) (list path))
                   (else '()))))
              (directory-files directory))))

(def (module-observability-source-observations path)
  (poo-flow-poo-slot-authoring-file-observations
   (string->symbol path)
   path))

;; : (-> PathString [Alist])
(def (module-observability-source-lexical-shadow-observations path)
  (poo-flow-scheme-lexical-call-shadow-file-observations
   (string->symbol path)
   path))

(def (module-observability-source-inline-prototype-observations path)
  (poo-flow-scheme-inline-prototype-file-observations
   (string->symbol path) path))

;; : (-> Unit TestSuite)
;;; This suite protects module observability receipts used to debug expansion
;;; and lazy-load decisions.
(def module-system-observability-test
  (test-suite "poo-flow module-system observability"
    (test-case "builds strict presentation trace rows"
      (let* ((native-observation
              (poo-flow-module-observation-stage/detail
               'test-presentation 'selected-modules 2 '() '()))
             (trace
              (poo-flow-module-presentation-trace
               'test-presentation
               (list (cons 'selected-modules 2)
                     (cons 'settings 1))))
             (first-step (car trace))
             (second-step (cadr trace)))
        (check-equal? (and (object? native-observation)
                           (poo-flow-module-observation? native-observation))
                      #t)
        (check-equal? (module-observability-test-alist-value 'kind first-step)
                      poo-flow-module-observation-kind)
        (check-equal? (module-observability-test-alist-value 'scope first-step)
                      'test-presentation)
        (check-equal? (module-observability-test-alist-value 'stage first-step)
                      'selected-modules)
        (check-equal? (module-observability-test-alist-value 'status first-step)
                      'ok)
        (check-equal? (module-observability-test-alist-value 'count first-step) 2)
        (check-equal? (module-observability-test-alist-value 'depth first-step) 0)
        (check-equal? (module-observability-test-alist-value 'path first-step)
                      '(selected-modules))
        (check-equal? (module-observability-test-alist-value
                       'runtime-executed
                       first-step)
                      #f)
        (check-equal? (module-observability-test-alist-value 'stage second-step)
                      'settings)
        (check-equal? (module-observability-test-alist-value 'path second-step)
                      '(selected-modules settings))))
    (test-case "marks repeated stages as recursive-stage"
      (let* ((trace
              (poo-flow-module-presentation-trace
               'test-presentation
               (list (cons 'selected-modules 2)
                     (cons 'selected-modules 2))))
             (repeat-step (cadr trace)))
        (check-equal? (module-observability-test-alist-value
                       'stage
                       repeat-step)
                      'selected-modules)
        (check-equal? (module-observability-test-alist-value
                       'status
                       repeat-step)
                      'recursive-stage)
        (check-equal? (module-observability-test-alist-value
                       'depth
                       repeat-step)
                      1)
        (check-equal? (module-observability-test-alist-value
                       'path
                       repeat-step)
                      '(selected-modules selected-modules))))
    (test-case "observes POO slot initializer self references"
      (let* ((native-observation
              (make-poo-flow-poo-slot-authoring-observation
               'poo-introspection-slot-receipt
               'safe
               'safe-value
               'ok
               '()
               #f
               #f))
             (observations
              (poo-flow-poo-slot-authoring-observations
               'poo-introspection-slot-receipt
               (list (cons 'slot 'slot)
                     (cons 'object? 'poo-object?)
                     (cons 'present? 'slot-present?)
                     (cons 'value 'slot-current-value))))
             (bad (car observations))
             (shadow (cadr observations))
             (good (caddr observations))
             (detail (module-observability-test-alist-value 'detail bad)))
        (check-equal?
         (and (object? native-observation)
              (poo-flow-poo-slot-authoring-observation? native-observation))
         #t)
        (check-equal? (module-observability-test-alist-value 'kind bad)
                      poo-flow-poo-slot-authoring-observation-kind)
        (check-equal? (module-observability-test-alist-value 'scope bad)
                      'poo-introspection-slot-receipt)
        (check-equal? (module-observability-test-alist-value 'slot bad)
                      'slot)
        (check-equal? (module-observability-test-alist-value 'initializer bad)
                      'slot)
        (check-equal? (module-observability-test-alist-value 'status bad)
                      'self-referential-slot-initializer)
        (check-equal? (module-observability-test-alist-value
                       'code
                       detail)
                      'poo-slot-initializer-shadows-slot)
        (check-equal? (module-observability-test-alist-value 'status shadow)
                      'primitive-shadow-slot)
        (check-equal? (module-observability-test-alist-value
                       'code
                       (module-observability-test-alist-value
                        'detail
                        shadow))
                      'poo-slot-shadows-poo-primitive)
        (check-equal? (module-observability-test-alist-value 'status good)
                      'ok)
        (check-equal? (module-observability-test-alist-value 'detail good)
                      '())
        (check-equal? (poo-flow-poo-slot-authoring-summary
                       'poo-introspection-slot-receipt
                       observations)
                      (list
                       (cons 'kind poo-flow-poo-slot-authoring-summary-kind)
                       (cons 'scope 'poo-introspection-slot-receipt)
                       (cons 'observation-count 4)
                       (cons 'statuses
                             '(self-referential-slot-initializer
                               primitive-shadow-slot
                               ok
                               ok))
                       (cons 'diagnostic-count 2)
                       (cons 'diagnostics
                             (list
                              (module-observability-test-alist-value
                               'detail
                               bad)
                              (module-observability-test-alist-value
                               'detail
                               shadow)))
                       (cons 'descriptor-realized? #f)
                       (cons 'runtime-executed #f)))
        (check-equal? (poo-flow-poo-slot-authoring-diagnostics
                       (list good))
                      '())))
    (test-case "reader-native source inspection catches both POO slot spellings"
      (let* ((source
              "(.o values: values safe: safe-value (before before) (after after-value) diagnostics: (reverse diagnostics))\n(.def Prototype policy: policy (result result-value))")
             (observations
              (poo-flow-poo-slot-authoring-port-observations
               'synthetic-source
               (open-input-string source))))
        (check-equal?
         (poo-flow-poo-slot-authoring-statuses observations)
         '(self-referential-slot-initializer
           ok
           self-referential-slot-initializer
           ok
           self-referential-slot-initializer
           self-referential-slot-initializer
           ok))
        (check-equal?
         (map (lambda (diagnostic)
                (module-observability-test-alist-value 'slot diagnostic))
              (poo-flow-poo-slot-authoring-diagnostics observations))
         '(values before diagnostics policy))))
    (test-case "reader-native source inspection catches lexical values calls"
      (let* ((source
              (string-append
               "(def (poo-flow-tool-unique-symbols/accumulate remaining seen values)\n"
               "  (if (null? remaining) (values remaining values) values))\n"
               "(def (safe values) (reverse values))\n"
               "(def (safe-loop values)\n"
               "  (let loop ((values values)) (if (null? values) '() (loop (cdr values)))))\n"
               "(.o (values values-vector-value))\n"
               "'(def (quoted values) (values values))\n"))
             (observations
              (poo-flow-scheme-lexical-call-shadow-port-observations
               'synthetic-source
               (open-input-string source)))
             (observation (car observations))
             (detail (module-observability-test-alist-value
                      'detail observation)))
        (check-equal? (length observations) 1)
        (check-equal?
         (module-observability-test-alist-value 'kind observation)
         poo-flow-scheme-lexical-call-shadow-observation-kind)
        (check-equal?
         (module-observability-test-alist-value 'definition observation)
         'poo-flow-tool-unique-symbols/accumulate)
        (check-equal?
         (module-observability-test-alist-value 'identifier observation)
         'values)
        (check-equal?
         (module-observability-test-alist-value 'status observation)
         'lexical-procedure-shadow)
        (check-equal?
         (module-observability-test-alist-value 'code detail)
         'scheme-lexical-binding-shadows-procedure)
        (check-equal?
         (module-observability-test-alist-value 'runtime-executed observation)
         #f)))
    (test-case "projects one inline prototype lookup as native authoring advice"
      (let* ((source
              (string-append
               "(.o (:: @ (.ref Contract 'proto)) value: 1)\n"
               "(.o (:: @ Contract.) value: 2)\n"
               "(.o . slots)\n"
               "'(.o (:: @ (.ref Quoted 'proto)))\n"))
             (observations
              (poo-flow-authoring-inline-prototype-port-observations
               'synthetic-source (open-input-string source)))
             (observation (car observations)))
        (check-equal? (length observations) 1)
        (check-equal? (.ref observation 'owner) 'Contract)
        (check-equal? (.ref observation 'code)
                      'poo-prototype-lookup-inside-composition)
        (check-equal? (.ref observation 'runtime-executed?) #f)))
    (test-case "default module-system facade exposes development quality and performance evidence"
      (let* ((policy
              (poo-flow-debug-memory-policy
               'native-module-system-test
               heap-limit-bytes: 4096
               live-growth-limit-bytes: 1024
               fail-closed?: #t))
             (before
              (poo-flow-debug-memory-sample
               'native-module-system-test 1024 512 256 128 128))
             (after
              (poo-flow-debug-memory-sample
               'native-module-system-test 2048 1024 768 384 384))
             (receipt
              (poo-flow-debug-memory-receipt policy before after))
             (observations
              (poo-flow-authoring-inline-prototype-datum-observations
               'native-module-system-test
               '(.o (:: @ (.ref Contract 'proto)) value: 1))))
        (check-equal? (.ref receipt 'accepted?) #t)
        (check-equal? (.ref receipt 'heap-growth-bytes) 1024)
        (check-equal? (.ref receipt 'live-growth-bytes) 512)
        (check-equal? (length observations) 1)
        (check-equal? (.ref (car observations) 'code)
                      'poo-prototype-lookup-inside-composition)))
    (test-case "all repository POO source slots pass the native authoring gate"
      (let* ((paths (module-observability-source-files "src"))
             (observations
              (apply append
                     (map module-observability-source-observations paths))))
        (check-equal? (pair? paths) #t)
        (check-equal?
         (poo-flow-poo-slot-authoring-diagnostics observations)
         '())))
    (test-case "all repository Scheme sources avoid lexical values calls"
      (let* ((paths (module-observability-source-files "src"))
             (observations
              (apply append
                     (map module-observability-source-lexical-shadow-observations
                          paths))))
        (check-equal? (pair? paths) #t)
        (check-equal? observations '())))
    (test-case "all repository constructors hoist stable prototype lookups"
      (let* ((paths (module-observability-source-files "src"))
             (observations
              (apply append
                     (map module-observability-source-inline-prototype-observations
                          paths))))
        (check-equal? (pair? paths) #t)
        (check-equal? observations '())))))
