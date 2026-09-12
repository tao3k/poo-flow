;;; -*- Gerbil -*-
;;; Shared grammar, immutable IR types, and callable declaration parsing.

(import :gerbil/expander
        (only-in :std/srfi/1 find filter-map foldl iota))

(export parse-poo-clos-generic-declaration-ir
        parse-poo-clos-method-declaration-ir
        clos-class-declaration-ir-name clos-class-declaration-ir-supers
        clos-class-declaration-ir-slots clos-class-declaration-ir-default-initargs
        clos-class-declaration-ir-slot-missing
        clos-class-declaration-ir-slot-unbound
        clos-class-declaration-ir-documentation
        clos-class-declaration-ir-metaclass
        clos-slot-declaration-ir-name clos-slot-declaration-ir-allocation
        clos-slot-declaration-ir-initargs clos-slot-declaration-ir-initform
        clos-slot-declaration-ir-readers clos-slot-declaration-ir-writers
        clos-slot-declaration-ir-type-predicate
        clos-slot-declaration-ir-documentation
        clos-generic-declaration-ir-name clos-generic-declaration-ir-lambda-list
        clos-generic-declaration-ir-argument-precedence-order
        clos-generic-declaration-ir-method-combination
        clos-generic-declaration-ir-documentation
        clos-generic-declaration-ir-generic-function-class
        clos-generic-declaration-ir-method-class
        clos-generic-declaration-ir-declarations
        clos-generic-declaration-ir-methods
        clos-method-combination-reference-declaration-ir-name
        clos-method-combination-reference-declaration-ir-arguments
        clos-method-declaration-ir-name clos-method-declaration-ir-qualifier
        clos-method-declaration-ir-lambda-list clos-method-declaration-ir-body
        clos-method-combination-declaration-ir-name
        clos-method-combination-declaration-ir-operator
        clos-method-combination-declaration-ir-order
        clos-method-combination-declaration-ir-identity-with-one-argument
        clos-method-combination-declaration-ir-documentation
        clos-long-method-combination-declaration-ir-name
        clos-long-method-combination-declaration-ir-lambda-list
        clos-long-method-combination-declaration-ir-groups
        clos-long-method-combination-declaration-ir-arguments
        clos-long-method-combination-declaration-ir-arguments-whole
        clos-long-method-combination-declaration-ir-generic-function
        clos-long-method-combination-declaration-ir-declarations
        clos-long-method-combination-declaration-ir-documentation
        clos-long-method-combination-declaration-ir-body
        clos-method-group-declaration-ir-name
        clos-method-group-declaration-ir-matchers
        clos-method-group-declaration-ir-order
        clos-method-group-declaration-ir-required
        clos-method-group-declaration-ir-description
        clos-lambda-declaration-ir-required clos-lambda-declaration-ir-optional
        clos-lambda-declaration-ir-rest clos-lambda-declaration-ir-keys
        clos-lambda-declaration-ir-allow-other-keys
        clos-lambda-declaration-ir-aux
        clos-parameter-declaration-ir-variable clos-parameter-declaration-ir-kind
        clos-parameter-declaration-ir-target
        clos-optional-declaration-ir-variable clos-optional-declaration-ir-initform
        clos-optional-declaration-ir-supplied
        clos-key-declaration-ir-name clos-key-declaration-ir-variable
        clos-key-declaration-ir-initform clos-key-declaration-ir-supplied
        clos-aux-declaration-ir-variable clos-aux-declaration-ir-initform
        clos-class-declaration-ir clos-slot-declaration-ir
        clos-method-combination-declaration-ir
        clos-long-method-combination-declaration-ir
        clos-method-group-declaration-ir
        clos-syntax-error clos-syntax-list clos-identifier clos-function-name
        clos-literal=? clos-identifier-symbols clos-require-unique-identifiers
        parse-clos-lambda-list)

;;; Class IRs own declaration order and the two class-level slot hooks.
(defclass clos-class-declaration-ir
  (name supers slots default-initargs slot-missing slot-unbound documentation
        metaclass source))
;;; Slot IRs preserve repeatable accessor options separately from singular
;;; allocation, initform, type, and documentation options.
(defclass clos-slot-declaration-ir
  (name allocation initargs initform readers writers type-predicate
        documentation source))
;;; Generic IRs separate lambda-list shape from dispatch precedence and
;;; method-combination selection.
(defclass clos-generic-declaration-ir
  (name lambda-list argument-precedence-order method-combination documentation
        generic-function-class method-class declarations methods source))
;;; A generic's method-combination reference retains its hygienic descriptor
;;; name separately from the option forms supplied to that combination type.
(defclass clos-method-combination-reference-declaration-ir
  (name arguments source))
;;; Method IRs retain the original body syntax for hygienic lexical lowering.
(defclass clos-method-declaration-ir
  (name qualifier lambda-list body source))
;;; Short method-combination IRs retain the operator as syntax while order
;;; and identity policy become closed expansion-time data.
(defclass clos-method-combination-declaration-ir
  (name operator order identity-with-one-argument documentation source))
;;; Long-form IRs separate declarative qualifier groups from the hygienic
;;; Scheme body that executes the effective method.
(defclass clos-long-method-combination-declaration-ir
  (name lambda-list groups arguments arguments-whole generic-function
        declarations documentation body source))
;;; Group IRs preserve matcher syntax because predicate identifiers must
;;; resolve in the declaration's lexical context.
(defclass clos-method-group-declaration-ir
  (name matchers order required description source))
;;; Lambda-list IRs keep parameter families distinct so congruence can be
;;; computed without reparsing source forms.
(defclass clos-lambda-declaration-ir
  (required optional rest keys allow-other-keys aux source))
;;; Required parameter IRs distinguish universal, class, and eql dispatch.
(defclass clos-parameter-declaration-ir (variable kind target source))
;;; Optional parameter IRs preserve default and supplied-p ownership.
(defclass clos-optional-declaration-ir (variable initform supplied source))
;;; Key parameter IRs separate the external key name from its lexical name.
(defclass clos-key-declaration-ir (name variable initform supplied source))
;;; Aux IRs remain execution-only and do not enter dispatch metadata.
(defclass clos-aux-declaration-ir (variable initform source))

;;; Every grammar failure carries a stable category in the expansion message,
;;; while the original syntax object retains source location and lexical scope.
;; : (-> Symbol String Syntax Bottom)
(def (clos-syntax-error category message source)
  (raise-syntax-error
   #f (string-append (symbol->string category) ": " message) source))

;;; Proper-list admission is centralized so no downstream parser silently
;;; accepts dotted declaration syntax.
;; : (-> Syntax String [Syntax])
(def (clos-syntax-list source message)
  (or (syntax->list source)
      (clos-syntax-error 'poo-clos-invalid-syntax message source)))

;;; Identifier admission returns the same syntax object, preserving bindings
;;; for hygienic comparison and lowering.
;; : (-> Syntax String Syntax)
(def (clos-identifier source message)
  (if (identifier? source)
    source
    (clos-syntax-error 'poo-clos-invalid-identifier message source)))

;; : (-> Syntax String Syntax)
(def (clos-function-name source message)
  (if (identifier? source)
    source
    (let (items (syntax->list source))
      (if (and items (= (length items) 2)
               (clos-literal=? (car items) #'setf)
               (identifier? (cadr items)))
        source
        (clos-syntax-error 'poo-clos-invalid-function-name message source)))))

;;; Grammar markers are binding-aware; a locally shadowed =&key= is data, not
;;; a phase transition token.
;; : (-> Syntax Syntax Boolean)
(def (clos-literal=? candidate literal)
  (and (identifier? candidate) (free-identifier=? candidate literal)))

;;; Symbol projection is delayed until binding identity is no longer needed.
;; : (-> [Syntax] [Symbol])
(def (clos-identifier-symbols values)
  (map (lambda (value) (syntax->datum value)) values))

;;; A hash-owned membership pass keeps duplicate checks linear in declaration
;;; size and reports the second occurrence at its own source location.
;; : (-> [Syntax] Symbol Syntax Unit)
(def (clos-require-unique-identifiers values category source)
  (let ((seen (make-hash-table-eq)))
    (let loop ((rest values))
    (when (pair? rest)
      (let (name (syntax->datum (car rest)))
        (when (hash-key? seen name)
          (clos-syntax-error category "declaration names must be unique"
                             (car rest)))
        (hash-put! seen name #t)
        (loop (cdr rest)))))))

;;; Required method parameters alone may carry class or eql specializers;
;;; generic declarations retain unspecialized identifiers.
;; : (-> Syntax (values Syntax Symbol (Maybe Syntax)))
(def (parse-required-parameter source specialized?)
  (cond
   ((identifier? source)
    (values source 'any #f))
   (specialized?
    (let (items (clos-syntax-list
                 source "specialized parameter must be (variable class)"))
      (unless (= (length items) 2)
        (clos-syntax-error 'poo-clos-invalid-specializer
                           "specialized parameter expects two forms" source))
      (let ((variable (clos-identifier
                       (car items) "parameter must be an identifier"))
            (specializer (cadr items)))
        (let (specializer-items
              (and (pair? (syntax-e specializer))
                   (syntax->list specializer)))
          (if (and specializer-items
                   (= (length specializer-items) 2)
                   (clos-literal=? (car specializer-items) #'eql))
            (values variable 'eql (cadr specializer-items))
            (values variable 'class specializer))))))
   (else
    (clos-syntax-error 'poo-clos-invalid-generic-lambda-list
                       "generic required parameters must be identifiers"
                       source))))

;;; Optional method defaults remain syntax for later lexical lowering; generic
;;; lambda lists record shape only.
;; : (-> Syntax ClosOptionalDeclarationIR)
(def (parse-optional-parameter source generic?)
  (if (identifier? source)
    (clos-optional-declaration-ir variable: source initform: #'#f supplied: #f
                          source: source)
    (let (items (clos-syntax-list source "invalid optional parameter"))
      (when generic?
        (clos-syntax-error 'poo-clos-invalid-generic-lambda-list
                           "generic optional parameters cannot have defaults"
                           source))
      (unless (and (<= 1 (length items) 3)
                   (identifier? (car items)))
        (clos-syntax-error 'poo-clos-invalid-method-lambda-list
                           "optional parameter is var or (var init supplied)"
                           source))
      (clos-optional-declaration-ir
       variable: (car items)
       initform: (if (pair? (cdr items)) (cadr items) #'#f)
       supplied: (and (= (length items) 3)
                      (clos-identifier (caddr items)
                                       "supplied-p must be an identifier"))
       source: source))))

;;; A key head parser isolates the two admitted name forms and gives the main
;;; parameter parser a single, source-aware fallback boundary.
;; : (-> Syntax (values SchemeValue Syntax))
(def (parse-key-head head source)
  (cond
   ((identifier? head)
    (values (syntax->datum head) head))
   (else
    (let (explicit
          (and head (pair? (syntax-e head)) (syntax->list head)))
      (unless (and explicit (= (length explicit) 2)
                   (identifier? (cadr explicit)))
        (clos-syntax-error 'poo-clos-invalid-key-parameter
                           "key parameter has an invalid name" source))
      (values (syntax->datum (car explicit)) (cadr explicit))))))

;; : (-> Syntax ClosKeyDeclarationIR)
(def (parse-key-parameter source generic?)
  (cond
   ((identifier? source)
    (clos-key-declaration-ir name: (syntax->datum source) variable: source
                     initform: #'#f supplied: #f source: source))
   (else
    (let* ((items (clos-syntax-list source "invalid key parameter"))
           (head (and (pair? items) (car items))))
      (when (and generic? (> (length items) 1))
        (clos-syntax-error 'poo-clos-invalid-generic-lambda-list
                           "generic key parameters cannot have defaults"
                           source))
      (unless (and (<= 1 (length items) 3)
                   head)
        (clos-syntax-error 'poo-clos-invalid-key-parameter
                           "key parameter has an invalid shape" source))
      (let-values (((name variable) (parse-key-head head source)))
        (clos-key-declaration-ir
         name: name variable: variable
         initform: (if (pair? (cdr items)) (cadr items) #'#f)
         supplied: (and (= (length items) 3)
                        (clos-identifier (caddr items)
                                         "supplied-p must be an identifier"))
         source: source))))))

;;; Aux bindings are method-local sequential bindings and never contribute to
;;; generic congruence or dispatch arity.
;; : (-> Syntax ClosAuxDeclarationIR)
(def (parse-aux-parameter source)
  (if (identifier? source)
    (clos-aux-declaration-ir variable: source initform: #'#f source: source)
    (let (items (clos-syntax-list source "invalid aux parameter"))
      (unless (and (<= 1 (length items) 2) (identifier? (car items)))
        (clos-syntax-error 'poo-clos-invalid-aux-parameter
                           "aux parameter is var or (var initform)" source))
      (clos-aux-declaration-ir variable: (car items)
                       initform: (if (= (length items) 2)
                                   (cadr items) #'#f)
                       source: source))))

;;; Lambda-list variables are flattened without growing an accumulator through
;;; append; order is immaterial for the uniqueness-only consumer.
;; : (-> [ClosParameterDeclarationIR] [ClosOptionalDeclarationIR] (Maybe Syntax)
;;        [ClosKeyDeclarationIR] [ClosAuxDeclarationIR] [Syntax])
(def (lambda-ir-variables required optional rest-variable keys aux)
  (foldl (lambda (group out) (foldl cons out group))
         '()
         (list (map clos-parameter-declaration-ir-variable required)
               (map clos-optional-declaration-ir-variable optional)
               (if rest-variable (list rest-variable) '())
               (map clos-key-declaration-ir-variable keys)
               (map clos-aux-declaration-ir-variable aux))))

;;; The state machine admits each marker only from its legal predecessor and
;;; accumulates each parameter family in reverse for one final normalization.
;; : (-> Syntax Boolean ClosLambdaDeclarationIR)
(def (parse-clos-lambda-list source specialized?)
  (let item-loop
      ((rest (clos-syntax-list source "lambda list must be a proper list"))
       (phase 'required) (required '()) (optional '()) (rest-variable #f)
       (keys '()) (allow-other? #f) (aux '()))
    (if (null? rest)
      (begin
        (clos-require-unique-identifiers
         (lambda-ir-variables required optional rest-variable keys aux)
         'poo-clos-duplicate-lambda-variable source)
        (clos-lambda-declaration-ir
         required: (reverse required) optional: (reverse optional)
         rest: rest-variable keys: (reverse keys)
         allow-other-keys: allow-other? aux: (reverse aux) source: source))
      (let (item (car rest))
        (cond
         ((clos-literal=? item #'&optional)
          (unless (eq? phase 'required)
            (clos-syntax-error 'poo-clos-invalid-lambda-list-order
                               "&optional is out of order" item))
          (item-loop (cdr rest) 'optional required optional rest-variable
                     keys allow-other? aux))
         ((clos-literal=? item #'&rest)
          (unless (and (memq phase '(required optional))
                       (pair? (cdr rest)))
            (clos-syntax-error 'poo-clos-invalid-lambda-list-order
                               "&rest requires one following variable" item))
          (let (variable
                (clos-identifier (cadr rest)
                                 "&rest requires an identifier"))
            (item-loop (cddr rest) 'post-rest required optional variable
                       keys allow-other? aux)))
         ((clos-literal=? item #'&key)
          (unless (memq phase '(required optional post-rest))
            (clos-syntax-error 'poo-clos-invalid-lambda-list-order
                               "&key is out of order" item))
          (item-loop (cdr rest) 'key required optional rest-variable
                     keys allow-other? aux))
         ((clos-literal=? item #'&allow-other-keys)
          (unless (eq? phase 'key)
            (clos-syntax-error 'poo-clos-invalid-lambda-list-order
                               "&allow-other-keys requires &key" item))
          (item-loop (cdr rest) 'post-key required optional rest-variable
                     keys #t aux))
         ((clos-literal=? item #'&aux)
          (when (not specialized?)
            (clos-syntax-error 'poo-clos-invalid-generic-lambda-list
                               "generic lambda lists cannot contain &aux" item))
          (item-loop (cdr rest) 'aux required optional rest-variable
                     keys allow-other? aux))
         ((eq? phase 'required)
          (let-values (((variable kind target)
                        (parse-required-parameter item specialized?)))
            (item-loop
             (cdr rest) phase
             (cons (clos-parameter-declaration-ir
                    variable: variable kind: kind target: target source: item)
                   required)
             optional rest-variable keys allow-other? aux)))
         ((eq? phase 'optional)
          (item-loop (cdr rest) phase required
                     (cons (parse-optional-parameter item (not specialized?))
                           optional)
                     rest-variable keys allow-other? aux))
         ((eq? phase 'key)
          (item-loop (cdr rest) phase required optional rest-variable
                     (cons (parse-key-parameter item (not specialized?)) keys)
                     allow-other? aux))
         ((eq? phase 'aux)
          (item-loop (cdr rest) phase required optional rest-variable keys
                     allow-other? (cons (parse-aux-parameter item) aux)))
         (else
          (clos-syntax-error 'poo-clos-invalid-lambda-list-order
                             "parameter follows a closed lambda-list section"
                             item)))))))

;;; APO lookup indexes required names once, then maps the declared permutation
;;; while detecting unknown and repeated entries at their precise syntax.
;; : (-> [Syntax] [Syntax] [Natural])
(def (parse-argument-precedence-order required options)
  (let (option
        (find (lambda (candidate)
                (let (items (syntax->list candidate))
                  (and items (pair? items)
                       (clos-literal=? (car items)
                                       #'argument-precedence-order))))
              options))
    (if (not option)
      (iota (length required))
      (let* ((items (syntax->list option))
             (names (cdr items))
             (required-names
              (map clos-parameter-declaration-ir-variable required))
             (positions (make-hash-table-eq)))
        (unless (= (length names) (length required-names))
          (clos-syntax-error 'poo-clos-invalid-argument-precedence-order
                             "precedence order must name every required parameter"
                             option))
        (for-each
         (lambda (required-name index)
           (hash-put! positions (syntax->datum required-name) index))
         required-names (iota (length required-names)))
        (let ((seen (make-hash-table-eq)))
          (map
           (lambda (name)
             (let (key (syntax->datum name))
               (unless (hash-key? positions key)
                 (clos-syntax-error
                  'poo-clos-invalid-argument-precedence-order
                  "precedence order contains an unknown parameter" name))
               (when (hash-key? seen key)
                 (clos-syntax-error
                  'poo-clos-invalid-argument-precedence-order
                  "precedence order repeats a parameter" name))
               (hash-put! seen key #t)
               (hash-ref positions key)))
           names))))))

;;; Standard is the explicit default.  Names remain hygienic descriptor
;;; references while option forms are evaluated only by the generated generic
;;; declaration, never by this phase parser.
;; : (-> [Syntax] ClosMethodCombinationReferenceDeclarationIR)
(def (parse-method-combination options)
  (let (option
        (find (lambda (candidate)
                (let (items (syntax->list candidate))
                  (and items (pair? items)
                       (clos-literal=? (car items) #'method-combination))))
              options))
    (if option
      (let (items (syntax->list option))
        (unless (>= (length items) 2)
          (clos-syntax-error 'poo-clos-invalid-generic-option
                             "method-combination requires a name" option))
        (clos-identifier
         (cadr items) "method-combination name must be an identifier")
        (clos-method-combination-reference-declaration-ir
         name: (cadr items) arguments: (cddr items) source: option))
      (clos-method-combination-reference-declaration-ir
       name: #'standard arguments: '() source: #f))))

;;; Generic options have a closed, single-occurrence vocabulary before either
;;; option-specific projection runs.
;; : (-> [Syntax] Syntax Unit)
(def (validate-generic-options options source)
  (let (seen (make-hash-table-eq))
    (for-each
     (lambda (candidate)
       (let* ((items (syntax->list candidate))
              (head (and items (pair? items) (car items)))
              (kind
               (cond
                ((and head
                      (clos-literal=? head #'argument-precedence-order))
                 'argument-precedence-order)
                ((and head (clos-literal=? head #'method-combination))
                 'method-combination)
                ((and head (clos-literal=? head #'documentation))
                 'documentation)
                ((and head (clos-literal=? head #'generic-function-class))
                 'generic-function-class)
                ((and head (clos-literal=? head #'method-class))
                 'method-class)
                ((and head (clos-literal=? head #'declare)) 'declare)
                ((and head (clos-literal=? head #'method)) 'method)
                (else #f))))
         (unless kind
           (clos-syntax-error 'poo-clos-unknown-generic-option
                              "unknown generic function option" candidate))
         (when (and (not (memq kind '(declare method)))
                    (hash-key? seen kind))
           (clos-syntax-error 'poo-clos-duplicate-generic-option
                              "generic option can appear only once" candidate))
         (hash-put! seen kind #t)))
     options)))

;; : (-> Syntax Syntax ClosMethodDeclarationIR)
(def (parse-inline-generic-method name option)
  (let (items (cdr (clos-syntax-list
                    option "inline method option must be a list")))
    (let loop ((rest items) (qualifiers '()))
      (when (null? rest)
        (clos-syntax-error 'poo-clos-invalid-inline-method
                           "inline method requires a specialized lambda list"
                           option))
      (if (syntax->list (car rest))
        (let* ((ordered-qualifiers (reverse qualifiers))
               (qualifier-value
               (cond
                ((null? ordered-qualifiers) 'primary)
                ((null? (cdr ordered-qualifiers))
                 (syntax->datum (car ordered-qualifiers)))
                (else (map syntax->datum ordered-qualifiers)))))
          (parse-poo-clos-method-declaration-ir
           name (datum->syntax name qualifier-value) (car rest)
           (cdr rest) option))
        (begin
          (clos-identifier (car rest)
                           "inline method qualifiers must be identifiers")
          (loop (cdr rest) (cons (car rest) qualifiers)))))))

;; : (-> Syntax [Syntax] [ClosMethodDeclarationIR])
(def (parse-inline-generic-methods name options)
  (filter-map
   (lambda (option)
     (let (items (syntax->list option))
       (and items (pair? items)
            (clos-literal=? (car items) #'method)
            (parse-inline-generic-method name option))))
   options))

;; : (-> [Syntax] (values (Maybe Syntax) (Maybe Syntax) (Maybe Syntax) [Syntax]))
(def (parse-generic-metadata options)
  (let loop ((rest options) (documentation #f) (generic-class #f)
             (method-class #f) (declarations '()))
    (if (null? rest)
      (values documentation generic-class method-class
              (reverse declarations))
      (let* ((option (car rest))
             (items (syntax->list option))
             (head (car items))
             (arguments (cdr items)))
        (cond
         ((clos-literal=? head #'documentation)
          (unless (= (length arguments) 1)
            (clos-syntax-error 'poo-clos-invalid-generic-option
                               "documentation expects one expression" option))
          (loop (cdr rest) (car arguments) generic-class method-class
                declarations))
         ((clos-literal=? head #'generic-function-class)
          (unless (and (= (length arguments) 1)
                       (identifier? (car arguments)))
            (clos-syntax-error 'poo-clos-invalid-generic-option
                               "generic-function-class expects one class name"
                               option))
          (loop (cdr rest) documentation (car arguments) method-class
                declarations))
         ((clos-literal=? head #'method-class)
          (unless (and (= (length arguments) 1)
                       (identifier? (car arguments)))
            (clos-syntax-error 'poo-clos-invalid-generic-option
                               "method-class expects one class name" option))
          (loop (cdr rest) documentation generic-class (car arguments)
                declarations))
         ((clos-literal=? head #'declare)
          (loop (cdr rest) documentation generic-class method-class
                (foldl cons declarations arguments)))
         (else
          (loop (cdr rest) documentation generic-class method-class
                declarations)))))))

;;; Generic IR construction joins independently validated lambda-list, APO, and
;;; combination values without evaluating user forms.
;; : (-> Syntax Syntax [Syntax] Syntax ClosGenericDeclarationIR)
(def (parse-poo-clos-generic-declaration-ir name lambda-list options source)
  (clos-function-name name
                      "generic function name must be an identifier or (setf name)")
  (validate-generic-options options source)
  (let (lambda-ir (parse-clos-lambda-list lambda-list #f))
    (let-values (((documentation generic-class method-class declarations)
                  (parse-generic-metadata options)))
      (clos-generic-declaration-ir
       name: name lambda-list: lambda-ir
       argument-precedence-order:
       (parse-argument-precedence-order
        (clos-lambda-declaration-ir-required lambda-ir) options)
       method-combination: (parse-method-combination options)
       documentation: documentation generic-function-class: generic-class
       method-class: method-class declarations: declarations
       methods: (parse-inline-generic-methods name options)
       source: source))))

;;; Method IR construction closes the standard qualifier set and retains specialized
;;; parameters for the lowering phase.
;; : (-> Syntax Syntax Syntax [Syntax] Syntax ClosMethodDeclarationIR)
(def (parse-poo-clos-method-declaration-ir name qualifier lambda-list body source)
  (clos-function-name name
                      "method generic name must be an identifier or (setf name)")
  (let (qualifier-value (syntax->datum qualifier))
    (unless (or (symbol? qualifier-value)
                (and (pair? qualifier-value)
                     (andmap symbol? qualifier-value)))
      (clos-syntax-error 'poo-clos-invalid-method-qualifier
                         "method qualifier must be a symbol or symbol list"
                         qualifier))
    (clos-method-declaration-ir
     name: name qualifier: qualifier-value
     lambda-list: (parse-clos-lambda-list lambda-list #t)
     body: body source: source)))

