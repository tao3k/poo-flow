;;; -*- Gerbil -*-
;;; Multi-argument applicability, specificity and standard method combination.

(import (only-in :clan/poo/object
                 .ref .slot? object? compute-precedence-list!)
        (only-in :clan/poo/mop element?)
        (only-in :std/srfi/1 drop filter-map find iota list-index)
        "types.ss" "objects.ss" "classes.ss" "method-combination.ss")

(export poo-clos-compute-applicable-methods poo-clos-call
        poo-clos-compute-effective-method
        poo-clos-no-applicable-method poo-clos-no-next-method
        poo-clos-no-applicable-method-generic
        poo-clos-no-next-method-generic
        poo-clos-effective-method-group poo-clos-call-method
        poo-clos-make-method
        poo-clos-call-next-method poo-clos-next-method?
        poo-clos-funcall poo-clos-setf)

;;; Identity lookup deliberately uses SRFI list-index: class precedence is a
;;; finite native C3 value, not a custom recursive search owner.
;; : (forall (a) (-> a [a] (Maybe Natural)))
(def (identity-index target values)
  (list-index (lambda (value) (eq? target value)) values))

;; : (-> SchemeValue Boolean)
(def (clos-instance-state-bearing? value)
  (and (object? value)
       (.slot? value '%poo-clos-state)
       (element? ClosInstanceState (.ref value '%poo-clos-state))))

;;; Logical class precedence follows class-generation successors while native
;;; POO prototypes remain the sole source of each generation's C3 order.
;; : (-> SchemeValue (Maybe [ClosClass]))
(def (argument-class-precedence argument)
  (and (clos-instance-state-bearing? argument)
       (poo-clos-class-precedence-list
        (poo-clos-current-class
         (.ref (.ref argument '%poo-clos-state) 'class)))))

;; : (-> SchemeValue SchemeValue (Maybe Natural))
(def (class-target-distance target argument)
  (and (object? argument)
       (let* ((logical-cpl (argument-class-precedence argument))
              (values
               (if (element? ClosClass target)
                 logical-cpl (compute-precedence-list! argument)))
              (target-value
               (if (element? ClosClass target)
                 (poo-clos-current-class target) target))
              (index (and values (identity-index target-value values))))
         (and index (+ index 1)))))

;; : (-> SchemeValue Natural)
(def (universal-specializer-distance argument)
  (+ 2 (if (object? argument)
         (length (or (argument-class-precedence argument)
                     (compute-precedence-list! argument)))
         0)))

;;; Eql ranks before every class; a class rank is its native C3 distance; the
;;; universal specializer follows every applicable class.
;; : (-> ClosSpecializer SchemeValue (Maybe Natural))
(def (specializer-distance specializer argument)
  (case (.ref specializer 'kind)
    ((eql) (and (eqv? argument (.ref specializer 'target)) 0))
    ((class)
     (class-target-distance (.ref specializer 'target) argument))
    ((any) (universal-specializer-distance argument))
    (else #f)))

;; : (-> ClosMethod [SchemeValue] (Maybe [Natural]))
(def (method-distances method arguments)
  (let (distances
        (map specializer-distance
             (.ref method 'specializers)
             arguments))
    (and (andmap (lambda (distance) (if distance #t #f)) distances)
         distances)))

;;; Ranked method entries keep distances in required-argument order; lookup is
;;; bounded by the generic's admitted arity.
;; : (-> [Natural] Natural Natural)
(def (distance-at distances index)
  (list-ref distances index))

;;; Argument precedence is a generic-owned permutation.  The first unequal
;;; distance is the complete lexicographic method-order decision.
;; : (-> [Natural] [Natural] [Natural] Boolean)
(def (distances-before? left right precedence-order)
  (let loop ((remaining precedence-order))
    (and (pair? remaining)
         (let ((left-distance (distance-at left (car remaining)))
               (right-distance (distance-at right (car remaining))))
           (cond
            ((< left-distance right-distance) #t)
            ((> left-distance right-distance) #f)
            (else (loop (cdr remaining))))))))

;;; Stable insertion preserves the source generation's order only when two
;;; methods have indistinguishable specializer precedence.
;; : (forall (a) (-> (Pair a [Natural]) [(Pair a [Natural])]
;;        [Natural] [(Pair a [Natural])]))
(def (insert-ranked ranked sorted precedence-order)
  (cond
   ((null? sorted) (list ranked))
   ((distances-before? (cdr ranked) (cdar sorted) precedence-order)
    (cons ranked sorted))
   (else
    (cons (car sorted)
          (insert-ranked ranked (cdr sorted) precedence-order)))))

;;; The fold is intentionally stable and allocation-only; it never mutates the
;;; generic's source method list.
;; : (forall (a) (-> [(Pair a [Natural])] [Natural]
;;        [(Pair a [Natural])]))
(def (sort-ranked ranked precedence-order)
  (foldl (lambda (entry sorted)
           (insert-ranked entry sorted precedence-order))
         '() ranked))

;;; Applicability is a pure projection from one immutable generic generation;
;;; no cache or registry can change the method set during this computation.
;; : (-> ClosGenericFunction [SchemeValue] [(Pair ClosMethod [Natural])])
(def (applicable-ranked-methods generic arguments)
  (sort-ranked
   (filter-map
    (lambda (method)
      (let (distances (method-distances method arguments))
        (and distances (cons method distances))))
    (.ref generic 'methods))
   (.ref generic 'argument-precedence-order)))


;;; Arity admission precedes applicability and every method body, including an
;;; around method that would otherwise short circuit.
;; : (-> ClosGenericFunction [SchemeValue] Unit)
(def (arguments-valid! generic arguments)
  (let* ((count (length arguments))
         (required (.ref generic 'required))
         (lambda-list (.ref generic 'lambda-list))
         (optional (.ref lambda-list 'optional))
         (open-tail?
          (or (.ref lambda-list 'rest?) (.ref lambda-list 'key?))))
    (unless (and (>= count required)
                 (or open-tail? (<= count (+ required optional))))
      (clos-fail 'argument-count-mismatch
                 generic: (.ref generic 'identity)))))

;; : (-> SchemeValue Boolean)
(def (keyword-name? value)
  (or (symbol? value) (keyword? value)))

;; : (-> SchemeValue Boolean)
(def (allow-other-keys-name? value)
  (or (eq? value 'allow-other-keys)
      (and (keyword? value)
           (string=? (keyword->string value) "allow-other-keys"))))

;; : (-> [SchemeValue] Natural [SchemeValue])
(def (keyword-tail arguments start)
  (drop arguments (min start (length arguments))))

;; : (-> [SchemeValue] InitargName (Maybe SchemeValue))
(def (keyword-value arguments name)
  (let (position
        (list-index (lambda (index)
                      (eq? (list-ref arguments (* 2 index)) name))
                    (iota (quotient (length arguments) 2))))
    (and position (list-ref arguments (+ 1 (* 2 position))))))

;;; An explicit =allow-other-keys= argument admits unknown keys only when its
;;; leftmost value is true.  Absence and an explicit false value are both
;;; intentionally rejecting outcomes.
;; : (-> [SchemeValue] Boolean)
(def (call-allows-other-keys? arguments)
  (let ((symbol-value (keyword-value arguments 'allow-other-keys))
        (keyword-value* (keyword-value arguments allow-other-keys:)))
    (or (if symbol-value #t #f)
        (if keyword-value* #t #f))))

;; : (-> ClosGenericFunction [(Pair ClosMethod [Natural])]
;;        [SchemeValue] Unit)
(def (keyword-arguments-valid! generic ranked arguments)
  (let* ((lambda-list (.ref generic 'lambda-list))
         (method-lists
          (filter-map (lambda (entry) (.ref (car entry) 'lambda-list))
                      ranked)))
    (when (or (.ref lambda-list 'key?)
              (find (lambda (method-list) (.ref method-list 'key?))
                    method-lists))
      (let* ((start (+ (.ref lambda-list 'required)
                       (.ref lambda-list 'optional)))
             (tail (keyword-tail arguments start)))
        (unless (and (even? (length tail))
                     (andmap (lambda (index)
                               (keyword-name?
                                (list-ref tail (* 2 index))))
                             (iota (quotient (length tail) 2))))
          (clos-fail 'malformed-keyword-arguments
                     generic: (.ref generic 'identity)))
        (let* ((valid-keys
                (apply append
                       (cons (.ref lambda-list 'keys)
                             (map (lambda (method-list)
                                    (.ref method-list 'keys))
                                  method-lists))))
               (allow-other?
                (or (.ref lambda-list 'allow-other-keys?)
                    (call-allows-other-keys? tail)
                    (find (lambda (method-list)
                            (.ref method-list 'allow-other-keys?))
                          method-lists)))
               (invalid-key
                (find (lambda (index)
                        (let (name (list-ref tail (* 2 index)))
                          (and (not (allow-other-keys-name? name))
                               (not (memq name valid-keys)))))
                      (iota (quotient (length tail) 2)))))
          (when (and invalid-key (not allow-other?))
            (clos-fail 'invalid-keyword-argument
                       generic: (.ref generic 'identity))))))))

;;; Protocol customization may filter or reorder the default applicable set,
;;; but cannot inject a method outside the generic generation or one that is
;;; inapplicable to the current required arguments.
;; : (-> ClosGenericFunction [SchemeValue]
;;        [(Pair ClosMethod [Natural])])
(def (protocol-ranked-methods generic arguments)
  (let* ((ranked (applicable-ranked-methods generic arguments))
         (hook (.ref (.ref generic 'protocol) 'compute-applicable-methods)))
    (if (not hook)
      ranked
      (let (methods (hook generic arguments (map car ranked)))
        (unless (and (list? methods)
                     (andmap
                      (lambda (method)
                        (and (element? ClosMethod method)
                             (memq method (.ref generic 'methods))
                             (method-distances method arguments)))
                      methods))
          (clos-fail 'invalid-compute-applicable-methods-result
                     generic: (.ref generic 'identity)))
        (map (lambda (method)
               (cons method (method-distances method arguments)))
             methods)))))

;;; Standard and short combinations share the immutable effective-method carrier. A
;;; short combination uses the primary field for methods bearing its name.
;; : (-> ClosGenericFunction [SchemeValue]
;;        [(Pair ClosMethod [Natural])] ClosEffectiveMethod)
(def (default-effective-method generic arguments ranked)
  (let (combination (.ref generic 'method-combination))
    (case (.ref combination 'kind)
      ((standard)
       (make-effective-method
        generic arguments
        (poo-clos-methods-with-qualifier ranked 'around)
        (poo-clos-methods-with-qualifier ranked 'before)
        (poo-clos-methods-with-qualifier ranked 'primary)
        (poo-clos-methods-with-qualifier ranked 'after)))
      ((short)
       (make-effective-method
        generic arguments
        (poo-clos-methods-with-qualifier ranked 'around)
        '()
        (poo-clos-methods-with-qualifier ranked (.ref combination 'identity))
        '()))
      ((long)
       (let ((builder (.ref combination 'effective-builder))
             (groups (poo-clos-partition-long-methods generic ranked)))
         (unless builder
           (clos-fail 'missing-effective-method-builder
                      generic: (.ref generic 'identity)))
         (let (executor (builder generic arguments groups))
           (unless (procedure? executor)
             (clos-fail 'invalid-effective-method-result
                        generic: (.ref generic 'identity)))
           (make-effective-method generic arguments '() '() '() '()
                                groups: groups executor: executor))))
      (else
       (clos-fail 'unsupported-method-combination
                  generic: (.ref generic 'identity))))))

;;; One effective method captures both arguments and the immutable generic
;;; generation used to rank all qualifier groups.  The protocol hook receives
;;; the checked default effective method rather than a raw evaluator continuation.
;; : (-> ClosGenericFunction [SchemeValue] ClosEffectiveMethod)
(def (compute-effective-method generic arguments)
  (arguments-valid! generic arguments)
  (let (ranked (protocol-ranked-methods generic arguments))
    (if (null? ranked)
      ;; ANSI ordering invokes no-applicable-method before keyword rejection.
      (make-effective-method generic arguments '() '() '() '())
      (begin
        (keyword-arguments-valid! generic ranked arguments)
        (let* ((default-method (default-effective-method generic arguments ranked))
               (hook (.ref (.ref generic 'protocol) 'compute-effective-method))
               (effective-method
                (if hook
                  (hook generic arguments (map car ranked) default-method)
                  default-method)))
          (unless (and (element? ClosEffectiveMethod effective-method)
                       (eq? (.ref effective-method 'generic) generic))
            (clos-fail 'invalid-effective-method-result
                       generic: (.ref generic 'identity)))
          effective-method)))))

;;; Public reflection returns the shared specificity order before qualifier
;;; grouping; qualifiers do not create a second precedence system.
;; : (-> ClosGenericFunction SchemeValue... [ClosMethod])
(def (poo-clos-compute-applicable-methods generic-source . arguments)
  (let (generic-value (require-clos-generic generic-source))
    (arguments-valid! generic-value arguments)
    (map car (protocol-ranked-methods generic-value arguments))))

;; : (-> ClosGenericFunction SchemeValue... ClosEffectiveMethod)
(def (poo-clos-compute-effective-method generic-source . arguments)
  (let (generic-value (require-clos-generic generic-source))
    (compute-effective-method generic-value arguments)))

;;; Terminal protocol functions preserve the deprecated descriptor hook as a
;;; compatibility bridge.  The normal path is an ordinary, mutable CLOS
;;; generic function whose methods can specialize on the affected generic or
;;; method identity.
;; : (-> ClosGenericFunction [SchemeValue] SchemeValue)
(def (poo-clos-no-applicable-method generic arguments)
  (let (hook (.ref (.ref generic 'protocol) 'no-applicable-method))
    (if hook
      (hook generic arguments)
      (apply poo-clos-call poo-clos-no-applicable-method-generic
             (cons generic arguments)))))

;; : (-> ClosGenericFunction ClosMethod [SchemeValue] SchemeValue)
(def (poo-clos-no-next-method generic method arguments)
  (let (hook (.ref (.ref generic 'protocol) 'no-next-method))
    (if hook
      (hook generic method arguments)
      (apply poo-clos-call poo-clos-no-next-method-generic
             (cons generic (cons method arguments))))))

;; : ClosGenericFunction
(def poo-clos-no-applicable-method-generic
  (poo-clos-add-method
   (poo-clos-generic-function 'no-applicable-method 1 rest?: #t)
   (poo-clos-method
    'no-applicable-method/default
    (list (poo-clos-any-specializer))
    (lambda (_frame generic . _arguments)
      (clos-fail 'no-applicable-method
                 generic: (.ref generic 'identity)))
    lambda-list: (poo-clos-lambda-list 1 0 #t #f '() #f))))

;; : ClosGenericFunction
(def poo-clos-no-next-method-generic
  (poo-clos-add-method
   (poo-clos-generic-function 'no-next-method 2 rest?: #t)
   (poo-clos-method
    'no-next-method/default
    (list (poo-clos-any-specializer) (poo-clos-any-specializer))
    (lambda (_frame generic method . _arguments)
      (clos-fail 'no-next-method
                 generic: (.ref generic 'identity)
                 qualifier: (.ref method 'qualifier)
                 method: (.ref method 'identity)))
    lambda-list: (poo-clos-lambda-list 2 0 #t #f '() #f))))

;;; Method-list equivalence is identity based: equal-looking descriptors from
;;; different generations are not interchangeable continuation targets.
;; : (forall (a) (-> [a] [a] Boolean))
(def (same-methods? left right)
  (or (eq? left right)
      (and (pair? left) (pair? right)
           (eq? (car left) (car right))
           (same-methods? (cdr left) (cdr right)))))

;; : (-> [(Pair Symbol [ClosMethod])] [(Pair Symbol [ClosMethod])] Boolean)
(def (same-method-groups? left right)
  (or (eq? left right)
      (and (pair? left) (pair? right)
           (eq? (caar left) (caar right))
           (same-methods? (cdar left) (cdar right))
           (same-method-groups? (cdr left) (cdr right)))))

;;; Replacement applicability compares every qualifier chain, not merely the
;;; currently executing primary or around chain.
;; : (-> ClosEffectiveMethod ClosEffectiveMethod Boolean)
(def (same-effective-method? left right)
  (and (andmap (lambda (qualifier)
                 (same-methods? (.ref left qualifier) (.ref right qualifier)))
               '(around before primary after))
       (same-method-groups? (.ref left 'groups) (.ref right 'groups))))

;;; Frame admission prevents arbitrary lookalike POO objects from exercising a
;;; captured next-method continuation.
;; : (forall (a) (-> a ClosInvocationFrame))
(def (require-frame frame)
  (unless (element? ClosInvocationFrame frame)
    (clos-fail 'invalid-invocation-frame))
  frame)

;;; Invocation failures retain method and qualifier identity while omitting raw
;;; arguments from the raised POO value.
;; : (-> ClosInvocationFrame Symbol Bottom)
(def (frame-fail frame code)
  (clos-fail
   code
   generic: (.ref (.ref (.ref frame 'effective-method) 'generic) 'identity)
   qualifier: (.ref frame 'qualifier)
   method: (.ref (.ref frame 'method) 'identity)))

;;; Auxiliary frames never report a next method even if another auxiliary
;;; method follows in specificity order.
;; : (-> ClosInvocationFrame Boolean)
(def (poo-clos-next-method? frame)
  (require-frame frame)
  (and (if (memq (.ref frame 'qualifier) '(around primary long)) #t #f)
       (if (.ref frame 'next) #t #f)))

;;; Replacement arguments must preserve the complete ordered applicable method
;;; set before the captured continuation can be invoked.
;; : (-> ClosInvocationFrame SchemeValue... SchemeValue)
(def (poo-clos-call-next-method frame . replacement)
  (require-frame frame)
  (unless (memq (.ref frame 'qualifier) '(around primary long))
    (frame-fail frame 'next-forbidden-in-auxiliary))
  (let* ((effective-method (.ref frame 'effective-method))
         (generic (.ref effective-method 'generic))
         (arguments (if (null? replacement)
                      (.ref frame 'arguments)
                      replacement)))
    (arguments-valid! generic arguments)
    (unless (or (null? replacement)
                (same-effective-method?
                 effective-method (compute-effective-method generic arguments)))
      (frame-fail frame 'changed-applicable-methods))
    (if (.ref frame 'next)
      ((.ref frame 'next) arguments)
      (poo-clos-no-next-method generic (.ref frame 'method) arguments))))

;;; Long-form bodies receive named immutable method lists through the effective method,
;;; never through a mutable global method-group registry.
;; : (-> ClosEffectiveMethod Symbol [ClosMethod])
(def (poo-clos-effective-method-group effective-method name)
  (unless (element? ClosEffectiveMethod effective-method)
    (clos-fail 'invalid-effective-method))
  (let (entry (assq name (.ref effective-method 'groups)))
    (if entry (cdr entry)
        (clos-fail 'unknown-effective-method-group))))

;; : (-> Thunk ClosMethod)
(def (poo-clos-make-method thunk)
  (make-synthetic-effective-method thunk))

;; : (-> ClosEffectiveMethod ClosMethod Boolean)
(def (effective-method-member? effective-method method)
  (or (.ref method 'synthetic-effective-method?)
      (find (lambda (entry) (memq method (cdr entry)))
            (.ref effective-method 'groups))
      (find (lambda (qualifier)
              (memq method (.ref effective-method qualifier)))
            '(around before primary after))))

;;; =call-method= semantics invoke one explicit method and provide only the
;;; declared next-method list as its continuation chain.
;; : (-> ClosEffectiveMethod ClosMethod [ClosMethod] SchemeValue)
(def (poo-clos-call-method effective-method method next-methods)
  (unless (element? ClosEffectiveMethod effective-method)
    (clos-fail 'invalid-call-method operation: 'invalid-effective-method))
  (unless (element? ClosMethod method)
    (clos-fail 'invalid-call-method operation: 'invalid-method))
  (unless (list? next-methods)
    (clos-fail 'invalid-call-method operation: 'invalid-next-method-list))
  (unless (effective-method-member? effective-method method)
    (clos-fail 'invalid-call-method operation: 'method-not-applicable))
  (for-each
   (lambda (next)
     (unless (element? ClosMethod next)
       (clos-fail 'invalid-next-method operation: 'call-method))
     (unless (effective-method-member? effective-method next)
       (clos-fail 'next-method-not-applicable operation: 'call-method)))
   next-methods)
  (def (run current remaining arguments)
    (invoke current effective-method arguments
            (and (pair? remaining)
                 (lambda (replacement)
                   (run (car remaining) (cdr remaining) replacement)))
            'long))
  (run method next-methods (.ref effective-method 'arguments)))

;;; Invocation allocates one POO lexical frame and calls the already admitted
;;; method procedure; it does not repeat method selection.
;; : (-> ClosMethod ClosEffectiveMethod [SchemeValue] (Maybe Procedure)
;;        MethodQualifier SchemeValue)
(def (invoke method effective-method arguments next qualifier)
  (apply (.ref method 'body)
         (make-invocation-frame effective-method arguments next qualifier method)
         arguments))

;;; Auxiliary return values are discarded without collapsing or inspecting the
;;; number of Scheme values produced.
;; : (forall (a) (-> (-> a) Unit))
(def (ignore-values thunk)
  (call-with-values thunk (lambda _ (void))))

;;; Short combinations consume one primary value per method, matching Common
;;; Lisp value-context behavior; zero values adapt to Scheme =#f=.
;; : (-> Thunk SchemeValue)
(def (primary-value thunk)
  (call-with-values thunk
    (lambda results (if (pair? results) (car results) #f))))

;; : (-> ClosMethod ClosEffectiveMethod [SchemeValue] SchemeValue)
(def (invoke-short method effective-method arguments)
  (primary-value
   (lambda ()
     (invoke method effective-method arguments #f (.ref method 'qualifier)))))

;; : (-> ClosEffectiveMethod SchemeValue)
(def (execute-short-effective-method effective-method)
  (let* ((generic (.ref effective-method 'generic))
         (arguments (.ref effective-method 'arguments))
         (combination (.ref generic 'method-combination))
         (ordered (if (eq? (.ref combination 'order) 'most-specific-last)
                    (reverse (.ref effective-method 'primary))
                    (.ref effective-method 'primary))))
    (when (null? ordered)
      (clos-fail 'no-primary-method generic: (.ref generic 'identity)))
    (def (run-core args)
      (if (and (.ref combination 'identity-with-one-argument?)
               (null? (cdr ordered)))
        (invoke (car ordered) effective-method args #f
                (.ref (car ordered) 'qualifier))
        (poo-clos-execute-short-operator
         (.ref combination 'operator) ordered
         (lambda (method) (invoke-short method effective-method args)))))
    (def (run-around methods args)
      (if (null? methods)
        (run-core args)
        (invoke (car methods) effective-method args
                (lambda (new-arguments)
                  (run-around (cdr methods) new-arguments))
                'around)))
    (run-around (.ref effective-method 'around) arguments)))

;;; The specialized execution branch preserves Scheme multiple values.  Before
;;; is most-specific-first; after is reversed only after effective-method construction.
;; : (-> ClosEffectiveMethod SchemeValue)
(def (execute-standard-effective-method effective-method)
  (let ((arguments (.ref effective-method 'arguments))
        (around (.ref effective-method 'around))
        (before (.ref effective-method 'before))
        (primary (.ref effective-method 'primary))
        (after (reverse (.ref effective-method 'after)))
        (generic (.ref effective-method 'generic)))
    (when (null? primary)
      (clos-fail 'no-primary-method generic: (.ref generic 'identity)))
    (def (run-primary methods args)
      (invoke (car methods) effective-method args
              (and (pair? (cdr methods))
                   (lambda (new-arguments)
                     (run-primary (cdr methods) new-arguments)))
              'primary))
    (def (run-auxiliary methods args qualifier)
      (for-each
       (lambda (method)
         (ignore-values
          (lambda () (invoke method effective-method args #f qualifier))))
       methods))
    (def (run-core args)
      (run-auxiliary before args 'before)
      (call-with-values
       (lambda () (run-primary primary args))
       (lambda results
         (run-auxiliary after args 'after)
         (apply values results))))
    (def (run-around methods args)
      (if (null? methods)
        (run-core args)
        (invoke (car methods) effective-method args
                (lambda (new-arguments)
                  (run-around (cdr methods) new-arguments))
                'around)))
    (run-around around arguments)))

;;; The public call captures exactly one effective method from the supplied
;;; immutable generic generation.
;; : (-> ClosEffectiveMethod Boolean)
(def (effective-method-empty? effective-method)
  (and (not (.ref effective-method 'executor))
       (null? (.ref effective-method 'around))
       (null? (.ref effective-method 'before))
       (null? (.ref effective-method 'primary))
       (null? (.ref effective-method 'after))))

;; : (-> ClosGenericFunction SchemeValue... SchemeValue)
(def (poo-clos-call generic-source . arguments)
  (let (generic-value (require-clos-generic generic-source))
    (let (effective-method (compute-effective-method generic-value arguments))
      (if (effective-method-empty? effective-method)
        (poo-clos-no-applicable-method generic-value arguments)
        (if (.ref effective-method 'executor)
          ((.ref effective-method 'executor) effective-method)
          (case (.ref (.ref generic-value 'method-combination) 'kind)
            ((short) (execute-short-effective-method effective-method))
            (else (execute-standard-effective-method effective-method))))))))

;; : (-> FunctionName SchemeValue ... SchemeValue)
(def (poo-clos-funcall function-name . arguments)
  (apply poo-clos-call
         (poo-clos-find-generic-function function-name) arguments))

;; : (-> Symbol SchemeValue SchemeValue ... SchemeValue)
(def (poo-clos-setf accessor-name new-value . arguments)
  (apply poo-clos-funcall
         (cons (list 'setf accessor-name) (cons new-value arguments))))
