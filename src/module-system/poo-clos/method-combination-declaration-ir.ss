;;; -*- Gerbil -*-
;;; Expansion-time short and long method-combination declaration parsing.

(import :gerbil/expander
        (only-in :std/srfi/1 foldl)
        "declaration-ir-core.ss")

(export parse-poo-clos-method-combination-declaration-ir
        parse-poo-clos-long-method-combination-declaration-ir)

;;; Combination options are a closed single-occurrence set.  Operator syntax
;;; remains hygienic and is never resolved through a runtime name registry.
;; parse-poo-clos-method-combination-declaration-ir
;;   : (-> Syntax Syntax [Syntax] Syntax ClosMethodCombinationDeclarationIR)
;;   | contract: validates a short combination without evaluating its operator.
;;   | doc m%
;;       `parse-poo-clos-method-combination-declaration-ir` returns immutable phase data.
;;
;;       # Examples
;;
;;       ```scheme
;;       (parse-poo-clos-method-combination-declaration-ir name operator options source)
;;       ;; => ClosMethodCombinationDeclarationIR
;;       ```
;;     %
(def (parse-poo-clos-method-combination-declaration-ir
      name operator options source)
  (clos-identifier name "method combination name must be an identifier")
  (let option-loop ((rest options) (order 'most-specific-first)
                    (order-source #f) (identity-with-one? #f)
                    (identity-source #f) (documentation #f))
    (if (null? rest)
      (clos-method-combination-declaration-ir
       name: name operator: operator order: order
       identity-with-one-argument: identity-with-one?
       documentation: documentation source: source)
      (let* ((option (car rest))
             (items (clos-syntax-list
                     option "method combination option must be a list"))
             (head (and (pair? items) (car items)))
             (arguments (and (pair? items) (cdr items))))
        (cond
         ((and head (clos-literal=? head #'order))
          (unless (and (= (length arguments) 1) (not order-source)
                       (identifier? (car arguments))
                       (memq (syntax->datum (car arguments))
                             '(most-specific-first most-specific-last)))
            (clos-syntax-error 'poo-clos-invalid-method-combination-option
                               "order expects one unique admitted name" option))
          (option-loop (cdr rest) (syntax->datum (car arguments)) option
                       identity-with-one? identity-source documentation))
         ((and head
               (clos-literal=? head #'identity-with-one-argument))
          (unless (and (= (length arguments) 1) (not identity-source)
                       (boolean? (syntax->datum (car arguments))))
            (clos-syntax-error 'poo-clos-invalid-method-combination-option
                               "identity option expects one unique boolean"
                               option))
          (option-loop (cdr rest) order order-source
                       (syntax->datum (car arguments)) option documentation))
         ((and head (clos-literal=? head #'documentation))
          (unless (and (= (length arguments) 1) (not documentation))
            (clos-syntax-error 'poo-clos-invalid-method-combination-option
                               "documentation expects one unique expression"
                               option))
          (option-loop (cdr rest) order order-source identity-with-one?
                       identity-source (car arguments)))
         (else
          (clos-syntax-error 'poo-clos-unknown-method-combination-option
                             "unknown short method combination option"
                             option)))))))

;;; Group option recognition is binding-aware and deliberately distinct from
;;; list-valued qualifier patterns.
;; : (-> Syntax Boolean)
(def (method-group-option? source)
  (let (items (syntax->list source))
    (and items (pair? items)
         (or (clos-literal=? (car items) #'order)
             (clos-literal=? (car items) #'required)
             (clos-literal=? (car items) #'description)))))

;; : (-> Syntax ClosMethodGroupDeclarationIR)
(def (parse-method-group-declaration-ir source)
  (let* ((items (clos-syntax-list source "method group must be a list"))
         (name (and (pair? items) (car items))))
    (clos-identifier name "method group name must be an identifier")
    (let item-loop ((rest (cdr items)) (matchers '()) (options-started? #f)
                    (order #'(quote most-specific-first)) (order-source #f)
                    (required? #'#f) (required-source #f) (description #f))
      (if (null? rest)
        (begin
          (when (null? matchers)
            (clos-syntax-error 'poo-clos-missing-method-group-matcher
                               "method group requires a matcher" source))
          (clos-method-group-declaration-ir
           name: name matchers: (reverse matchers) order: order
           required: required? description: description source: source))
        (let (item (car rest))
          (if (method-group-option? item)
            (let* ((option-items (syntax->list item))
                   (head (car option-items))
                   (arguments (cdr option-items)))
              (cond
               ((clos-literal=? head #'order)
                (unless (and (= (length arguments) 1) (not order-source))
                  (clos-syntax-error
                   'poo-clos-invalid-method-group-option
                   "group order expects one unique expression" item))
                (item-loop (cdr rest) matchers #t
                           (car arguments) item
                           required? required-source description))
               ((clos-literal=? head #'required)
                (unless (and (= (length arguments) 1) (not required-source))
                  (clos-syntax-error
                   'poo-clos-invalid-method-group-option
                   "group required expects one unique expression" item))
                (item-loop (cdr rest) matchers #t order order-source
                           (car arguments) item description))
               (else
                (unless (and (= (length arguments) 1) (not description))
                  (clos-syntax-error
                   'poo-clos-invalid-method-group-option
                   "group description expects one unique expression" item))
                (item-loop (cdr rest) matchers #t order order-source
                           required? required-source (car arguments)))))
            (begin
              (when options-started?
                (clos-syntax-error 'poo-clos-invalid-method-group-option-order
                                   "matcher cannot follow a group option" item))
              (unless (or (identifier? item) (syntax->list item)
                          (pair? (syntax-e item)))
                (clos-syntax-error 'poo-clos-invalid-method-group-matcher
                                   "matcher must be *, a pattern, or predicate"
                                   item))
              (item-loop (cdr rest) (cons item matchers) #f order order-source
                         required? required-source description))))))))

;; : (-> ClosLambdaDeclarationIR Syntax Unit)
(def (require-ordinary-required-parameters ir source)
  (for-each
   (lambda (parameter)
     (unless (eq? (clos-parameter-declaration-ir-kind parameter) 'any)
       (clos-syntax-error
        'poo-clos-invalid-method-combination-lambda-list
        "required combination parameters cannot be specialized" source)))
   (clos-lambda-declaration-ir-required ir)))

;; : (-> Syntax (values ClosLambdaDeclarationIR (Maybe Syntax)))
(def (parse-combination-arguments-lambda-list source)
  (let* ((items (clos-syntax-list source
                                  "arguments lambda list must be proper"))
         (whole? (and (pair? items)
                      (clos-literal=? (car items) #'&whole)))
         (whole
          (and whole?
               (pair? (cdr items))
               (clos-identifier (cadr items)
                                "&whole requires one identifier")))
         (remaining (if whole? (cddr items) items)))
    (when (and whole? (not whole))
      (clos-syntax-error
       'poo-clos-invalid-method-combination-arguments
       "&whole requires one identifier" source))
    (let (ir
          (parse-clos-lambda-list
           (with-syntax (((item ...) remaining)) #'(item ...)) #t))
      (require-ordinary-required-parameters ir source)
      (values ir whole))))

;;; Leading long-form clauses are phase syntax, never runtime list data.
;; : (-> [Syntax] Syntax
;;        (values (Maybe ClosLambdaDeclarationIR) (Maybe Syntax) Syntax
;;                [Syntax] (Maybe Syntax) [Syntax]))
(def (parse-long-method-combination-preamble body source)
  (let loop ((rest body) (arguments #f) (whole #f)
             (generic-function #'generic-function)
             (declarations '()) (documentation #f))
    (if (null? rest)
      (values arguments whole generic-function (reverse declarations)
              documentation '())
      (let* ((form (car rest))
             (items (syntax->list form))
             (head (and items (pair? items) (car items))))
        (cond
         ((and head (clos-literal=? head #'arguments))
          (when arguments
            (clos-syntax-error
             'poo-clos-duplicate-method-combination-option
             "arguments clause can appear only once" form))
          (unless (= (length items) 2)
            (clos-syntax-error
             'poo-clos-invalid-method-combination-arguments
             "arguments expects one lambda list" form))
          (let-values (((ir whole-name)
                        (parse-combination-arguments-lambda-list (cadr items))))
            (loop (cdr rest) ir whole-name generic-function
                  declarations documentation)))
         ((and head (clos-literal=? head #'generic-function))
          (unless (and (= (length items) 2)
                       (identifier? (cadr items)))
            (clos-syntax-error
             'poo-clos-invalid-method-combination-generic-function
             "generic-function expects one identifier" form))
          (loop (cdr rest) arguments whole (cadr items)
                declarations documentation))
         ((and head (clos-literal=? head #'declare))
          (loop (cdr rest) arguments whole generic-function
                (foldl cons declarations (cdr items)) documentation))
         ((and (not documentation) (string? (syntax->datum form)))
          (loop (cdr rest) arguments whole generic-function
                declarations form))
         (else
          (values arguments whole generic-function (reverse declarations)
                  documentation rest)))))))

;;; Long declarations have no runtime syntax parser: every lambda list, group,
;;; binding clause, and duplicate name is admitted once during expansion.
;; parse-poo-clos-long-method-combination-declaration-ir
;;   : (-> Syntax Syntax [Syntax] Syntax ClosLongMethodCombinationDeclarationIR)
;;   | contract: validates long-form groups and preserves a hygienic body.
;;   | doc m%
;;       `parse-poo-clos-long-method-combination-declaration-ir` owns group admission.
;;
;;       # Examples
;;
;;       ```scheme
;;       (parse-poo-clos-long-method-combination-declaration-ir name groups body source)
;;       ;; => ClosLongMethodCombinationDeclarationIR
;;       ```
;;     %
(def (parse-poo-clos-long-method-combination-declaration-ir
      name lambda-list groups body source)
  (clos-identifier name "method combination name must be an identifier")
  (let ((lambda-ir (parse-clos-lambda-list lambda-list #t))
        (group-irs
         (map parse-method-group-declaration-ir
              (clos-syntax-list groups "method groups must be a list"))))
    (require-ordinary-required-parameters lambda-ir lambda-list)
    (clos-require-unique-identifiers
     (map clos-method-group-declaration-ir-name group-irs)
     'poo-clos-duplicate-method-group groups)
    (let-values (((arguments whole generic-function declarations documentation
                            executable-body)
                  (parse-long-method-combination-preamble body source)))
      (when (null? executable-body)
        (clos-syntax-error 'poo-clos-missing-method-combination-body
                           "long method combination requires an execution body"
                           source))
      (clos-long-method-combination-declaration-ir
       name: name lambda-list: lambda-ir groups: group-irs
       arguments: arguments arguments-whole: whole
       generic-function: generic-function declarations: declarations
       documentation: documentation body: executable-body source: source))))
