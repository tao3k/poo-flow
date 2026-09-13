;;; -*- Gerbil -*-
;;; Thin hygienic declaration surface for the POO-native CLOS kernel.

(import "objects.ss" "classes.ss" "lifecycle.ss" "dispatch.ss"
        "lambda-list.ss"
        (for-syntax :gerbil/expander
                    "declaration-ir.ss"
                    (only-in :std/srfi/1 filter-map find iota)))

(export .defclass .defgeneric .defmethod .define-method-combination
        .with-slots .with-accessors)

(begin-syntax
  ;; : (-> Syntax Syntax)
  (def (clos-generic-binding-identifier name)
    (let* ((datum (syntax->datum name))
           (base
            (if (symbol? datum)
              (symbol->string datum)
              (string-append "setf-" (symbol->string (cadr datum))))))
      (datum->syntax
       (if (identifier? name) name (cadr (syntax->list name)))
       (string->symbol (string-append base "$poo-clos-generic")))))

  ;;; Built-in combination names are symbolic kernel identities.  Every other
  ;;; identifier remains a hygienic lexical reference to a POO descriptor.
  ;;; Combination arguments configure a fresh inert descriptor at declaration
  ;;; evaluation time, leaving the named combination type unchanged.
  ;; : (-> ClosMethodCombinationReferenceDeclarationIR Syntax)
  (def (lower-method-combination-reference reference)
    (let* ((name
            (clos-method-combination-reference-declaration-ir-name reference))
           (arguments
            (clos-method-combination-reference-declaration-ir-arguments
             reference))
           (base
            (if (memq (syntax->datum name)
                      '(standard + and append list max min nconc or progn))
              (with-syntax ((identity (syntax->datum name))) #'(quote identity))
              name)))
      (if (null? arguments)
        base
        (with-syntax ((base base) ((argument ...) arguments))
          #'(poo-clos-configure-method-combination
             (poo-clos-resolve-method-combination base) argument ...)))))

  ;; : (-> ClosSlotDeclarationIR Syntax)
  (def (lower-clos-slot slot)
    (let ((name (clos-slot-declaration-ir-name slot))
          (allocation (clos-slot-declaration-ir-allocation slot))
          (initargs (clos-slot-declaration-ir-initargs slot))
          (initform (clos-slot-declaration-ir-initform slot))
          (readers (clos-slot-declaration-ir-readers slot))
          (writers (clos-slot-declaration-ir-writers slot))
          (type-predicate (clos-slot-declaration-ir-type-predicate slot))
          (documentation (clos-slot-declaration-ir-documentation slot)))
      (with-syntax
          ((name name)
           (allocation allocation)
           ((initarg ...) (map syntax->datum initargs))
           ((reader ...) (map syntax->datum readers))
           ((writer ...) (map syntax->datum writers))
           (type-predicate (or type-predicate #'#f))
           (documentation (or documentation #'#f)))
        (if initform
          (with-syntax ((initform initform))
            #'(poo-clos-direct-slot-definition
               'name allocation: 'allocation
               initargs: (list 'initarg ...) initform: (lambda () initform)
               readers: (list 'reader ...) writers: (list 'writer ...)
               type-predicate: type-predicate
               documentation: documentation))
          #'(poo-clos-direct-slot-definition
             'name allocation: 'allocation
             initargs: (list 'initarg ...)
             readers: (list 'reader ...) writers: (list 'writer ...)
             type-predicate: type-predicate documentation: documentation)))))

  ;; : (-> ClosSlotDeclarationIR [Syntax])
  (def (lower-standard-accessor-definitions slot)
    (let (writers (clos-slot-declaration-ir-writers slot))
      (filter-map
       (lambda (reader)
         (let* ((reader-name (syntax->datum reader))
                (writer
                 (find (lambda (candidate)
                         (equal? (syntax->datum candidate)
                                 (list 'setf reader-name)))
                       writers)))
           (and writer
                (let ((reader-binding
                       (clos-generic-binding-identifier reader))
                      (writer-binding
                       (clos-generic-binding-identifier writer))
                      (object (datum->syntax reader (gensym 'object)))
                      (arguments (datum->syntax reader (gensym 'arguments))))
                  (with-syntax
                      ((reader reader) (reader-binding reader-binding)
                       (writer-binding writer-binding)
                       (object object) (arguments arguments)
                       (reader-name reader-name))
                    #'(begin
                        (def reader-binding
                          (or (poo-clos-find-generic-function
                               'reader-name error?: #f)
                              (poo-clos-generic-binding
                               'reader-name
                               (poo-clos-generic-function 'reader-name 1))))
                        (def (reader object)
                          (poo-clos-call reader-binding object))
                        (def writer-binding
                          (or (poo-clos-find-generic-function
                               '(setf reader-name) error?: #f)
                              (poo-clos-generic-binding
                               '(setf reader-name)
                               (poo-clos-generic-function
                                '(setf reader-name) 2))))))))))
       (clos-slot-declaration-ir-readers slot))))

  ;; : (-> Syntax ClosSlotDeclarationIR Syntax)
  (def (lower-clos-slot-accessors class-name slot)
    (let* ((slot-name (clos-slot-declaration-ir-name slot))
           (readers (clos-slot-declaration-ir-readers slot))
           (writers (clos-slot-declaration-ir-writers slot))
           (reader-effects
            (map
             (lambda (reader)
               (with-syntax
                   ((binding (clos-generic-binding-identifier reader))
                    (reader reader) (class-name class-name)
                    (slot-name slot-name))
                 #'(poo-clos-generic-binding-add-method!
                    binding
                    (poo-clos-slot-reader-method
                     class-name 'slot-name 'reader))))
             readers))
           (writer-effects
            (map
             (lambda (writer)
               (with-syntax
                   ((binding (clos-generic-binding-identifier writer))
                    (writer writer) (class-name class-name)
                    (slot-name slot-name))
                 #'(poo-clos-generic-binding-add-method!
                    binding
                    (poo-clos-slot-writer-method
                     class-name 'slot-name 'writer))))
             writers)))
      (with-syntax (((effect ...) (append reader-effects writer-effects)))
        #'(begin effect ...))))

  ;; : (-> ClosClassDeclarationIR Syntax Syntax)
  (def (lower-poo-clos-class ir source)
    (let ((name (clos-class-declaration-ir-name ir))
          (supers (clos-class-declaration-ir-supers ir))
          (slots (clos-class-declaration-ir-slots ir))
          (defaults (clos-class-declaration-ir-default-initargs ir))
          (slot-missing (clos-class-declaration-ir-slot-missing ir))
          (slot-unbound (clos-class-declaration-ir-slot-unbound ir))
          (documentation (clos-class-declaration-ir-documentation ir))
          (metaclass (clos-class-declaration-ir-metaclass ir)))
      (with-syntax
          ((name name)
           ((super ...) supers)
           ((slot-expression ...) (map lower-clos-slot slots))
           (((default-name . default-expression) ...) defaults)
           (slot-missing (or slot-missing #'#f))
           (slot-unbound (or slot-unbound #'#f))
           (documentation (or documentation #'#f))
           (metaclass (or metaclass #'(quote standard-class)))
           ((accessor-definition ...)
            (apply append (map lower-standard-accessor-definitions slots)))
           ((accessor-effect ...)
            (map (lambda (slot) (lower-clos-slot-accessors name slot)) slots)))
        (syntax/loc source
          (begin
            (def name
              (poo-clos-class
               'name
               direct-superclasses:
               (if (null? (list super ...)) #f (list super ...))
               direct-slots: (list slot-expression ...)
               default-initargs:
               (list (cons 'default-name
                           (lambda () default-expression)) ...)
               slot-missing-handler: slot-missing
               slot-unbound-handler: slot-unbound
               documentation: documentation metaclass: metaclass))
            accessor-definition ...
            accessor-effect ...
            name)))))

  ;; : (-> ClosGenericDeclarationIR Syntax Syntax)
  (def (lower-poo-clos-generic ir source)
    (let* ((name (clos-generic-declaration-ir-name ir))
           (binding (clos-generic-binding-identifier name))
           (lambda-ir (clos-generic-declaration-ir-lambda-list ir))
           (required (clos-lambda-declaration-ir-required lambda-ir))
           (optional (clos-lambda-declaration-ir-optional lambda-ir))
           (rest? (if (clos-lambda-declaration-ir-rest lambda-ir) #t #f))
           (keys (clos-lambda-declaration-ir-keys lambda-ir))
           (key? (if (or (pair? keys)
                         (clos-lambda-declaration-ir-allow-other-keys lambda-ir))
                   #t #f))
           (allow-other?
            (if (clos-lambda-declaration-ir-allow-other-keys lambda-ir) #t #f))
           (precedence
            (clos-generic-declaration-ir-argument-precedence-order ir))
           (combination
            (lower-method-combination-reference
             (clos-generic-declaration-ir-method-combination ir)))
           (documentation (clos-generic-declaration-ir-documentation ir))
           (generic-class
            (clos-generic-declaration-ir-generic-function-class ir))
           (method-class (clos-generic-declaration-ir-method-class ir))
           (declarations (clos-generic-declaration-ir-declarations ir))
           (methods (clos-generic-declaration-ir-methods ir))
           (arguments (datum->syntax
                       (if (identifier? name) name (cadr (syntax->list name)))
                       (gensym 'arguments)))
           (callable-definition
            (if (identifier? name)
              (with-syntax ((name name) (binding binding)
                            (arguments arguments))
                #'(def (name . arguments)
                    (apply poo-clos-call binding arguments)))
              #'(begin))))
      (with-syntax
          ((name name) (binding binding) (arguments arguments)
           (required-count (length required))
           (optional-count (length optional))
           (rest? rest?) (key? key?) (allow-other? allow-other?)
           ((key-name ...) (map clos-key-declaration-ir-name keys))
           ((precedence-index ...) precedence)
           (combination combination)
           (documentation (or documentation #'#f))
           (generic-class
            (if generic-class (syntax->datum generic-class)
                'standard-generic-function))
           (method-class
            (if method-class (syntax->datum method-class) 'standard-method))
           ((declaration ...) (map syntax->datum declarations))
           ((method-effect ...)
            (map (lambda (method-ir)
                   (lower-poo-clos-method method-ir source))
                 methods))
           (callable-definition callable-definition))
        (syntax/loc source
          (begin
            (def binding
              (poo-clos-generic-binding
               'name
               (poo-clos-generic-function
                'name required-count rest?: rest?
                optional: optional-count key?: key?
                keys: (list 'key-name ...)
                allow-other-keys?: allow-other?
                argument-precedence-order: (list precedence-index ...)
                method-combination: combination
                documentation: documentation
                generic-function-class: 'generic-class
                method-class: 'method-class
                declarations: '(declaration ...))))
            callable-definition
            method-effect ...
            binding)))))

  ;; : (-> ClosParameterDeclarationIR Syntax)
  (def (lower-method-specializer parameter)
    (case (clos-parameter-declaration-ir-kind parameter)
      ((any) #'(poo-clos-any-specializer))
      ((class)
       (with-syntax ((target (clos-parameter-declaration-ir-target parameter)))
         #'(poo-clos-class-specializer target)))
      ((eql)
       (with-syntax ((target (clos-parameter-declaration-ir-target parameter)))
         #'(poo-clos-eql-specializer target)))
      (else (error "unknown CLOS specializer IR"))))

  ;; : (-> ClosOptionalDeclarationIR Natural Syntax [Syntax])
  (def (lower-optional-bindings optional index arguments)
    (let ((variable (clos-optional-declaration-ir-variable optional))
          (initform (clos-optional-declaration-ir-initform optional))
          (supplied (clos-optional-declaration-ir-supplied optional)))
      (with-syntax ((variable variable) (initform initform)
                    (index index) (arguments arguments))
        (let (value-binding
              #'(variable
                 (poo-clos-positional-argument
                  arguments index (lambda () initform))))
          (if supplied
            (with-syntax ((supplied supplied))
              (list
               #'(supplied
                  (poo-clos-positional-supplied? arguments index))
               value-binding))
            (list value-binding))))))

  ;; : (-> ClosKeyDeclarationIR Natural Syntax [Syntax])
  (def (lower-key-bindings key start arguments)
    (let ((name (clos-key-declaration-ir-name key))
          (variable (clos-key-declaration-ir-variable key))
          (initform (clos-key-declaration-ir-initform key))
          (supplied (clos-key-declaration-ir-supplied key)))
      (with-syntax ((name name) (variable variable) (initform initform)
                    (start start) (arguments arguments))
        (let (value-binding
              #'(variable
                 (let (entry
                       (poo-clos-key-argument arguments start 'name))
                   (if (car entry) (cdr entry) initform))))
          (if supplied
            (with-syntax ((supplied supplied))
              (list
               value-binding
               #'(supplied
                  (car (poo-clos-key-argument arguments start 'name)))))
            (list value-binding))))))

  ;; : (-> ClosMethodDeclarationIR Syntax Syntax)
  (def (lower-poo-clos-method ir source)
    (let* ((name (clos-method-declaration-ir-name ir))
           (binding (clos-generic-binding-identifier name))
           (qualifier (clos-method-declaration-ir-qualifier ir))
           (lambda-ir (clos-method-declaration-ir-lambda-list ir))
           (required (clos-lambda-declaration-ir-required lambda-ir))
           (optional (clos-lambda-declaration-ir-optional lambda-ir))
           (rest-variable (clos-lambda-declaration-ir-rest lambda-ir))
           (keys (clos-lambda-declaration-ir-keys lambda-ir))
           (allow-other?
            (if (clos-lambda-declaration-ir-allow-other-keys lambda-ir) #t #f))
           (aux (clos-lambda-declaration-ir-aux lambda-ir))
           (body (clos-method-declaration-ir-body ir))
           (name-template
            (if (identifier? name) name (cadr (syntax->list name))))
           (frame (datum->syntax name-template (gensym 'frame)))
           (arguments (datum->syntax name-template (gensym 'arguments)))
           (call-next (datum->syntax name-template 'call-next-method))
           (next-method-p (datum->syntax name-template 'next-method-p))
           (required-bindings
            (map (lambda (parameter index)
                   (with-syntax
                       ((variable (clos-parameter-declaration-ir-variable parameter))
                        (arguments arguments) (index index))
                     #'(variable (list-ref arguments index))))
                 required (iota (length required))))
           (optional-bindings
            (apply append
                   (map (lambda (optional-value index)
                          (lower-optional-bindings
                           optional-value (+ (length required) index)
                           arguments))
                        optional (iota (length optional)))))
           (tail-start (+ (length required) (length optional)))
           (rest-bindings
            (if rest-variable
              (with-syntax ((variable rest-variable) (arguments arguments)
                            (tail-start tail-start))
                (list #'(variable
                         (poo-clos-rest-arguments arguments tail-start))))
              '()))
           (key-bindings
            (apply append
                   (map (lambda (key)
                          (lower-key-bindings key tail-start arguments))
                        keys)))
           (aux-bindings
            (map (lambda (entry)
                   (with-syntax
                       ((variable (clos-aux-declaration-ir-variable entry))
                        (initform (clos-aux-declaration-ir-initform entry)))
                     #'(variable initform)))
                 aux))
           (specializers (map lower-method-specializer required)))
      (with-syntax
          ((name name) (binding binding) (qualifier qualifier)
           (frame frame) (arguments arguments)
           (call-next call-next) (next-method-p next-method-p)
           ((parameter-binding ...)
            (append required-bindings optional-bindings rest-bindings
                    key-bindings aux-bindings))
           ((specializer ...) specializers)
           ((body ...) body)
           (required-count (length required))
           (optional-count (length optional))
           (rest? (if rest-variable #t #f))
           (key? (if (or (pair? keys) allow-other?) #t #f))
           ((key-name ...) (map clos-key-declaration-ir-name keys))
           (allow-other? allow-other?))
        (syntax/loc source
          (poo-clos-generic-binding-add-method!
           binding
           (poo-clos-method
            'name (list specializer ...)
            (lambda (frame . arguments)
              (let* (parameter-binding ...)
                (let ((call-next
                       (lambda replacement-arguments
                         (apply poo-clos-call-next-method
                                frame replacement-arguments)))
                      (next-method-p
                       (lambda () (poo-clos-next-method? frame))))
                  body ...)))
            qualifier: 'qualifier
            lambda-list:
            (poo-clos-lambda-list
             required-count optional-count rest? key?
             (list 'key-name ...) allow-other?)))))))

  ;;; The short-form declaration emits one POO descriptor binding; invocation
  ;;; remains in the shared dispatch factor and never in macro-generated DSL data.
  ;; : (-> ClosMethodCombinationDeclarationIR Syntax Syntax)
  (def (lower-poo-clos-method-combination ir source)
    (let ((name (clos-method-combination-declaration-ir-name ir))
          (operator (clos-method-combination-declaration-ir-operator ir))
          (order (clos-method-combination-declaration-ir-order ir))
          (identity-with-one?
           (clos-method-combination-declaration-ir-identity-with-one-argument ir))
          (documentation
           (clos-method-combination-declaration-ir-documentation ir)))
      (with-syntax ((name name) (operator operator) (order order)
                    (identity-with-one? identity-with-one?)
                    (documentation (or documentation #'#f)))
        (syntax/loc source
          (def name
            (poo-clos-short-method-combination
             'name operator order: 'order
             identity-with-one-argument?: identity-with-one?
             documentation: documentation))))))

  ;;; Pattern data is quoted, while a predicate identifier remains a lexical
  ;;; procedure reference and =*= remains the declarative wildcard symbol.
  ;; : (-> Syntax Syntax)
  (def (lower-method-group-matcher matcher)
    (cond
     ((and (identifier? matcher) (eq? (syntax->datum matcher) '*)) #'(quote *))
     ((identifier? matcher) matcher)
     (else
      (with-syntax ((pattern (syntax->datum matcher))) #'(quote pattern)))))

  ;; : (-> ClosMethodGroupDeclarationIR Syntax)
  (def (lower-method-group group)
    (let ((name (clos-method-group-declaration-ir-name group))
          (matchers (clos-method-group-declaration-ir-matchers group))
          (order (clos-method-group-declaration-ir-order group))
          (required? (clos-method-group-declaration-ir-required group))
          (description (clos-method-group-declaration-ir-description group)))
      (with-syntax
          ((name name)
           ((matcher ...) (map lower-method-group-matcher matchers))
           (order order) (required? required?)
           (description (or description #'#f)))
        #'(poo-clos-method-group
           'name (list matcher ...) order: order required?: required?
           description: description))))

  ;; : (-> ClosLambdaDeclarationIR Syntax [Syntax])
  (def (lower-combination-configuration-bindings lambda-ir arguments)
    (let* ((required (clos-lambda-declaration-ir-required lambda-ir))
           (optional (clos-lambda-declaration-ir-optional lambda-ir))
           (rest-variable (clos-lambda-declaration-ir-rest lambda-ir))
           (keys (clos-lambda-declaration-ir-keys lambda-ir))
           (aux (clos-lambda-declaration-ir-aux lambda-ir))
           (required-bindings
            (map (lambda (parameter index)
                   (with-syntax
                       ((variable (clos-parameter-declaration-ir-variable parameter))
                        (arguments arguments) (index index))
                     #'(variable (list-ref arguments index))))
                 required (iota (length required))))
           (optional-bindings
            (apply append
                   (map (lambda (optional-value index)
                          (lower-optional-bindings
                           optional-value (+ (length required) index)
                           arguments))
                        optional (iota (length optional)))))
           (tail-start (+ (length required) (length optional)))
           (rest-bindings
            (if rest-variable
              (with-syntax ((variable rest-variable) (arguments arguments)
                            (tail-start tail-start))
                (list #'(variable
                         (poo-clos-rest-arguments arguments tail-start))))
              '()))
           (key-bindings
            (apply append
                   (map (lambda (key)
                          (lower-key-bindings key tail-start arguments))
                        keys)))
           (aux-bindings
            (map (lambda (entry)
                   (with-syntax
                       ((variable (clos-aux-declaration-ir-variable entry))
                        (initform (clos-aux-declaration-ir-initform entry)))
                     #'(variable initform)))
                 aux)))
      (append required-bindings optional-bindings rest-bindings
              key-bindings aux-bindings)))

  ;; : (-> ClosOptionalDeclarationIR Natural Syntax Syntax [Syntax])
  (def (lower-combination-argument-optional-bindings optional index generic args)
    (let ((variable (clos-optional-declaration-ir-variable optional))
          (initform (clos-optional-declaration-ir-initform optional))
          (supplied (clos-optional-declaration-ir-supplied optional)))
      (with-syntax ((variable variable) (initform initform) (index index)
                    (generic generic) (args args))
        (let (value-binding
              #'(variable
                 (poo-clos-combination-optional-argument
                  generic args index (lambda () initform))))
          (if supplied
            (with-syntax ((supplied supplied))
              (list
               #'(supplied
                  (poo-clos-combination-optional-supplied?
                   generic args index))
               value-binding))
            (list value-binding))))))

  ;; : (-> ClosKeyDeclarationIR Syntax Syntax [Syntax])
  (def (lower-combination-argument-key-bindings key generic args)
    (let ((name (clos-key-declaration-ir-name key))
          (variable (clos-key-declaration-ir-variable key))
          (initform (clos-key-declaration-ir-initform key))
          (supplied (clos-key-declaration-ir-supplied key)))
      (with-syntax ((name name) (variable variable) (initform initform)
                    (generic generic) (args args))
        (let (value-binding
              #'(variable
                 (let (entry
                       (poo-clos-combination-key-argument generic args 'name))
                   (if (car entry) (cdr entry) initform))))
          (if supplied
            (with-syntax ((supplied supplied))
              (list
               value-binding
               #'(supplied
                  (car (poo-clos-combination-key-argument
                        generic args 'name)))))
            (list value-binding))))))

  ;; : (-> (Maybe ClosLambdaDeclarationIR) (Maybe Syntax) Syntax Syntax [Syntax])
  (def (lower-combination-argument-bindings ir whole generic args)
    (if (not ir)
      '()
      (let* ((required (clos-lambda-declaration-ir-required ir))
             (optional (clos-lambda-declaration-ir-optional ir))
             (rest-variable (clos-lambda-declaration-ir-rest ir))
             (keys (clos-lambda-declaration-ir-keys ir))
             (aux (clos-lambda-declaration-ir-aux ir))
             (whole-binding
              (if whole
                (with-syntax ((whole whole) (args args))
                  (list #'(whole args)))
                '()))
             (required-bindings
              (map (lambda (parameter index)
                     (with-syntax
                         ((variable (clos-parameter-declaration-ir-variable parameter))
                          (generic generic) (args args) (index index))
                       #'(variable
                          (poo-clos-combination-required-argument
                           generic args index))))
                   required (iota (length required))))
             (optional-bindings
              (apply append
                     (map (lambda (optional-value index)
                            (lower-combination-argument-optional-bindings
                             optional-value index generic args))
                          optional (iota (length optional)))))
             (rest-bindings
              (if rest-variable
                (with-syntax ((variable rest-variable) (generic generic)
                              (args args))
                  (list #'(variable
                           (poo-clos-combination-rest-arguments
                            generic args))))
                '()))
             (key-bindings
              (apply append
                     (map (lambda (key)
                            (lower-combination-argument-key-bindings
                             key generic args))
                          keys)))
             (aux-bindings
              (map (lambda (entry)
                     (with-syntax
                         ((variable (clos-aux-declaration-ir-variable entry))
                          (initform (clos-aux-declaration-ir-initform entry)))
                       #'(variable initform)))
                   aux)))
        (append whole-binding required-bindings optional-bindings
                rest-bindings key-bindings aux-bindings))))

  ;;; A long-form body executes as hygienic functional Scheme with admitted
  ;;; configuration and invocation lambda lists, group variables, and lexical
  ;;; CALL-METHOD/MAKE-METHOD operators over one checked effective method.
  ;; : (-> ClosLongMethodCombinationDeclarationIR Syntax Syntax)
  (def (lower-poo-clos-long-method-combination ir source)
    (let* ((name (clos-long-method-combination-declaration-ir-name ir))
           (lambda-ir
            (clos-long-method-combination-declaration-ir-lambda-list ir))
           (groups (clos-long-method-combination-declaration-ir-groups ir))
           (argument-ir
            (clos-long-method-combination-declaration-ir-arguments ir))
           (argument-whole
            (clos-long-method-combination-declaration-ir-arguments-whole ir))
           (generic-function
            (clos-long-method-combination-declaration-ir-generic-function ir))
           (documentation
            (clos-long-method-combination-declaration-ir-documentation ir))
           (body (clos-long-method-combination-declaration-ir-body ir))
           (configurer
            (datum->syntax name
                           (string->symbol
                            (string-append (symbol->string (syntax->datum name))
                                           "$poo-clos-configurer"))))
           (options (datum->syntax name (gensym 'combination-options)))
           (generic-value (datum->syntax name (gensym 'generic-function)))
           (arguments (datum->syntax name (gensym 'arguments)))
           (grouped (datum->syntax name (gensym 'groups)))
           (effective-method (datum->syntax name (gensym 'effective-method)))
           (call-method (datum->syntax name 'call-method))
           (make-method (datum->syntax name 'make-method))
           (required (clos-lambda-declaration-ir-required lambda-ir))
           (optional (clos-lambda-declaration-ir-optional lambda-ir))
           (rest? (if (clos-lambda-declaration-ir-rest lambda-ir) #t #f))
           (keys (clos-lambda-declaration-ir-keys lambda-ir))
           (key? (if (or (pair? keys)
                         (clos-lambda-declaration-ir-allow-other-keys lambda-ir))
                   #t #f))
           (allow-other?
            (if (clos-lambda-declaration-ir-allow-other-keys lambda-ir) #t #f))
           (configuration-bindings
            (lower-combination-configuration-bindings lambda-ir options))
           (argument-bindings
            (lower-combination-argument-bindings
             argument-ir argument-whole generic-value arguments)))
      (with-syntax
          ((name name) (configurer configurer) (options options)
           ((group-expression ...) (map lower-method-group groups))
           (((group-name group-key) ...)
            (map (lambda (group)
                   (let (group-name (clos-method-group-declaration-ir-name group))
                     (list group-name (syntax->datum group-name))))
                 groups))
           ((body ...) body)
           (generic-function generic-function)
           (generic-value generic-value) (arguments arguments)
           (grouped grouped) (effective-method effective-method)
           (call-method call-method) (make-method make-method)
           (((configuration-variable configuration-expression) ...)
            configuration-bindings)
           (((argument-variable argument-expression) ...)
            argument-bindings)
           (required-count (length required))
           (optional-count (length optional))
           (rest? rest?) (key? key?)
           ((key-name ...) (map clos-key-declaration-ir-name keys))
           (allow-other? allow-other?)
           (documentation (or documentation #'#f)))
        (syntax/loc source
          (begin
            (def (configurer . options)
              (unless
                  (poo-clos-method-combination-options-valid?
                   options required-count optional-count rest? key?
                   (list 'key-name ...) allow-other?)
                (clos-fail 'invalid-method-combination-options method: 'name))
              (let* ((configuration-variable configuration-expression) ...)
                (poo-clos-long-method-combination
                 'name (list group-expression ...)
                 (lambda (generic-value arguments grouped)
                   (lambda (effective-method)
                     (let* ((generic-function generic-value)
                            (group-name (cdr (assq 'group-key grouped))) ...
                            (argument-variable argument-expression) ...)
                       (let (call-method
                             (lambda (method . next-method-lists)
                               (unless (<= (length next-method-lists) 1)
                                 (clos-fail 'invalid-call-method))
                               (poo-clos-call-method
                                effective-method method
                                (if (null? next-method-lists)
                                  '()
                                  (car next-method-lists)))))
                         (let-syntax
                             ((make-method
                               (syntax-rules ()
                                 ((_ form)
                                  (poo-clos-make-method
                                   (lambda () form))))))
                           body ...)))))
                 configurer: configurer configuration: options
                 documentation: documentation)))
            (def name (configurer)))))))
  )

;;; Boundary: each identifier transformer owns both its live read and `set!`
;;; place expansion.  No value is snapshotted and the instance form is still
;;; evaluated exactly once by the public wrapper.
;; | SchemeValue = SchemeValue
;; %poo-clos-with-slots
;;   : (-> (SlotBinding ...) ClosInstance Body ... SchemeValue)
;;   | contract: recursively lowers hygienic slot aliases to live POO slot reads.
;;   | doc m%
;;       =%poo-clos-with-slots= is the private expansion worker for
;;       =.with-slots=; an empty binding list evaluates the body directly.
;;
;;       # Examples
;;       ```scheme
;;       (%poo-clos-with-slots () point (poo-clos-slot-value point 'x))
;;       ;; => slot-value
;;       ```
;;     %
(defrules %poo-clos-with-slots ()
  ((_ () object body ...) (begin body ...))
  ((_ ((variable slot-name) entry ...) object body ...)
   (let-syntax
       ((variable
         (identifier-rules (set!)
           ((set! id new-value)
            (poo-clos-set-slot-value! object 'slot-name new-value))
           (id (identifier? #'id)
               (poo-clos-slot-value object 'slot-name)))))
     (%poo-clos-with-slots (entry ...) object body ...)))
  ((_ (slot-name entry ...) object body ...)
   (let-syntax
       ((slot-name
         (identifier-rules (set!)
           ((set! id new-value)
            (poo-clos-set-slot-value! object 'slot-name new-value))
           (id (identifier? #'id)
               (poo-clos-slot-value object 'slot-name)))))
     (%poo-clos-with-slots (entry ...) object body ...))))

;; | SchemeValue = SchemeValue
;; .with-slots
;;   : (-> (SlotBinding ...) ClosInstance Body ... SchemeValue)
;;   | contract: binds hygienic generalized variables whose reads and `set!`
;;     writes use the standard CLOS slot protocol.
;;   | doc m%
;;       `.with-slots` is the functional Scheme projection of ANSI `with-slots`.
;;
;;       # Examples
;;       ```scheme
;;       (.with-slots (x) point x)
;;       ;; => slot-value
;;       ```
;;     %
(defrules .with-slots ()
  ((_ entries instance body ...)
   (let (object instance)
     (%poo-clos-with-slots entries object body ...))))

;;; Boundary: accessor aliases remain ordinary generic calls at every use.
;;; Keeping recursion entirely in hygienic syntax prevents this helper from
;;; becoming an alternate accessor cache or dispatch path.
;; | SchemeValue = SchemeValue
;; %poo-clos-with-accessors
;;   : (-> (AccessorBinding ...) ClosInstance Body ... SchemeValue)
;;   | contract: recursively lowers hygienic aliases to live generic dispatch.
;;   | doc m%
;;       =%poo-clos-with-accessors= is the private expansion worker for
;;       =.with-accessors= and preserves the ordinary generic-function owner.
;;
;;       # Examples
;;       ```scheme
;;       (%poo-clos-with-accessors () point (point-x point))
;;       ;; => accessor-value
;;       ```
;;     %
(defrules %poo-clos-with-accessors ()
  ((_ () object body ...) (begin body ...))
  ((_ ((variable accessor) entry ...) object body ...)
   (let-syntax
       ((variable
         (identifier-rules (set!)
           ((set! id new-value)
            (poo-clos-setf 'accessor new-value object))
           (id (identifier? #'id) (accessor object)))))
     (%poo-clos-with-accessors (entry ...) object body ...))))

;; | SchemeValue = SchemeValue
;; .with-accessors
;;   : (-> (AccessorBinding ...) ClosInstance Body ... SchemeValue)
;;   | contract: binds hygienic generalized variables whose reads call the
;;     accessor generic and whose `set!` writes call its SETF generic.
;;   | doc m%
;;       `.with-accessors` preserves accessor dispatch at every lexical read.
;;
;;       # Examples
;;       ```scheme
;;       (.with-accessors ((x-value point-x)) point x-value)
;;       ;; => accessor-value
;;       ```
;;     %
(defrules .with-accessors ()
  ((_ entries instance body ...)
   (let (object instance)
     (%poo-clos-with-accessors entries object body ...))))

;; | ClosClass = POOObject
;; .defclass
;;   : (-> Identifier (Identifier ...) (SlotDeclaration ...) ClassOption ...)
;;   | contract: parses once at expansion and lowers to POO class and slot constructors.
;;   | doc m%
;;       `.defclass` binds one native POO-backed CLOS class descriptor.
;;
;;       # Examples
;;
;;       ```scheme
;;       (.defclass Point () ((x (initarg x:))))
;;       ;; => Point
;;       ```
;;     %
(defsyntax (.defclass stx)
  (syntax-case stx ()
    ((_ name supers slots option ...)
     (lower-poo-clos-class
      (parse-poo-clos-class-declaration-ir
       #'name #'supers #'slots (syntax->list #'(option ...)) stx)
      stx))))

;; | ClosGenericBinding = POOObject
;; .defgeneric
;;   : (-> Identifier LambdaList GenericOption ...)
;;   | contract: lowers one generic declaration to an explicit mutable binding owner.
;;   | doc m%
;;       `.defgeneric` binds a callable generic and its generation owner.
;;
;;       # Examples
;;
;;       ```scheme
;;       (.defgeneric render (object &key format))
;;       ;; => render$poo-clos-generic
;;       ```
;;     %
(defsyntax (.defgeneric stx)
  (syntax-case stx ()
    ((_ name lambda-list option ...)
     (lower-poo-clos-generic
      (parse-poo-clos-generic-declaration-ir
       #'name #'lambda-list (syntax->list #'(option ...)) stx)
      stx))))

;; | ClosMethod = POOObject
;; .defmethod
;;   : (-> (Identifier SpecializedParameter ...) Body ...)
;;   | contract: lowers lexical next-method bindings and installs one method generation.
;;   | doc m%
;;       `.defmethod` admits one method into the named generic binding.
;;
;;       # Examples
;;
;;       ```scheme
;;       (.defmethod (render (object Point) &key format) object)
;;       ;; => ClosMethod
;;       ```
;;     %
(defsyntax (.defmethod stx)
  (syntax-case stx (qualifier)
    ((_ (name parameter ...) (qualifier method-qualifier) body ...)
     (lower-poo-clos-method
      (parse-poo-clos-method-declaration-ir
       #'name #'method-qualifier #'(parameter ...)
       (syntax->list #'(body ...)) stx)
      stx))
    ((_ (name parameter ...) body ...)
     (lower-poo-clos-method
      (parse-poo-clos-method-declaration-ir
       #'name #'primary #'(parameter ...) (syntax->list #'(body ...)) stx)
      stx))
    ((_ name (parameter ...) body ...)
     (lower-poo-clos-method
      (parse-poo-clos-method-declaration-ir
       #'name #'primary #'(parameter ...) (syntax->list #'(body ...)) stx)
      stx))
    ((_ name qualifier lambda-list body ...)
     (lower-poo-clos-method
      (parse-poo-clos-method-declaration-ir
       #'name #'qualifier #'lambda-list (syntax->list #'(body ...)) stx)
      stx))))

;; .define-method-combination
;;   : (-> Identifier (short Operator) MethodCombinationOption ...)
;;   | contract: lowers one hygienic short-form combination to a POO descriptor.
;;   | doc m%
;;       `.define-method-combination` binds declarative combination policy.
;;
;;       # Examples
;;
;;       ```scheme
;;       (.define-method-combination collect
;;         (short list)
;;         (order most-specific-last))
;;       ;; => collect
;;       ```
;;     %
(defsyntax (.define-method-combination stx)
  (syntax-case stx (short long)
    ((_ name (short operator) option ...)
     (lower-poo-clos-method-combination
      (parse-poo-clos-method-combination-declaration-ir
       #'name #'operator (syntax->list #'(option ...)) stx)
      stx))
    ((_ name (long) groups body ...)
     (lower-poo-clos-long-method-combination
      (parse-poo-clos-long-method-combination-declaration-ir
       #'name #'() #'groups (syntax->list #'(body ...)) stx)
      stx))
    ((_ name (long lambda-list) groups body ...)
     (lower-poo-clos-long-method-combination
      (parse-poo-clos-long-method-combination-declaration-ir
       #'name #'lambda-list #'groups (syntax->list #'(body ...)) stx)
      stx))
    (_
     (raise-syntax-error
      #f "poo-clos-invalid-method-combination-declaration" stx))))
