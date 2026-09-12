;;; -*- Gerbil -*-
;;; Expansion-time class and slot declaration parsing.

(import :gerbil/expander
        (only-in :std/srfi/1 foldl)
        "declaration-ir-core.ss")

(export parse-poo-clos-class-declaration-ir)

;;; Slot options accumulate repeatable initarg/reader/writer clauses while
;;; singular options retain the syntax object that established ownership.
;; : (-> Syntax (values Symbol (Maybe Syntax) [Syntax] [Syntax] (Maybe Syntax)
;;        (Maybe Syntax)))
(def (parse-clos-slot-options source)
  (let option-loop
      ((rest (cdr (clos-syntax-list source "slot declaration must be a list")))
       (allocation 'instance) (allocation-source #f)
       (initargs '()) (initform #f) (readers '()) (writers '())
       (type-predicate #f) (documentation #f))
    (if (null? rest)
      (values allocation initform (reverse initargs) (reverse readers)
              (reverse writers) type-predicate documentation)
      (let* ((option (car rest))
             (items (clos-syntax-list option "slot option must be a list"))
             (head (and (pair? items) (car items)))
             (arguments (and (pair? items) (cdr items))))
        (cond
         ((and head (clos-literal=? head #'allocation))
          (unless (and (= (length arguments) 1)
                       (identifier? (car arguments))
                       (memq (syntax->datum (car arguments))
                             '(instance class)))
            (clos-syntax-error 'poo-clos-invalid-slot-option
                               "allocation expects instance or class" option))
          (when allocation-source
            (clos-syntax-error 'poo-clos-duplicate-slot-option
                               "allocation can appear only once" option))
          (option-loop (cdr rest) (syntax->datum (car arguments)) option
                       initargs initform readers writers type-predicate
                       documentation))
         ((and head (clos-literal=? head #'initarg))
          (unless (= (length arguments) 1)
            (clos-syntax-error 'poo-clos-invalid-slot-option
                               "initarg expects one name" option))
          (option-loop (cdr rest) allocation allocation-source
                       (cons (car arguments) initargs) initform readers writers
                       type-predicate documentation))
         ((and head (clos-literal=? head #'initform))
          (unless (= (length arguments) 1)
            (clos-syntax-error 'poo-clos-invalid-slot-option
                               "initform expects one expression" option))
          (when initform
            (clos-syntax-error 'poo-clos-duplicate-slot-option
                               "initform can appear only once" option))
          (option-loop (cdr rest) allocation allocation-source initargs
                       (car arguments) readers writers type-predicate
                       documentation))
         ((and head (clos-literal=? head #'reader))
          (unless (and (= (length arguments) 1)
                       (identifier? (car arguments)))
            (clos-syntax-error 'poo-clos-invalid-slot-option
                               "reader expects one generic name" option))
          (option-loop (cdr rest) allocation allocation-source initargs
                       initform (cons (car arguments) readers) writers
                       type-predicate documentation))
         ((and head (clos-literal=? head #'writer))
          (unless (and (= (length arguments) 1)
                       (identifier? (car arguments)))
            (clos-syntax-error 'poo-clos-invalid-slot-option
                               "writer expects one generic name" option))
          (option-loop (cdr rest) allocation allocation-source initargs
                       initform readers (cons (car arguments) writers)
                       type-predicate documentation))
         ((and head (clos-literal=? head #'accessor))
          (unless (and (memv (length arguments) '(1 2))
                       (identifier? (car arguments))
                       (or (= (length arguments) 1)
                           (identifier? (cadr arguments))))
            (clos-syntax-error 'poo-clos-invalid-slot-option
                               "accessor expects one ANSI name or reader and writer names"
                               option))
          (let ((reader (car arguments))
                (writer
                 (if (= (length arguments) 1)
                   (datum->syntax
                    (car arguments)
                    (list 'setf (syntax->datum (car arguments))))
                   (cadr arguments))))
            (option-loop (cdr rest) allocation allocation-source initargs
                         initform (cons reader readers)
                         (cons writer writers)
                         type-predicate documentation)))
         ((and head (clos-literal=? head #'type))
          (unless (= (length arguments) 1)
            (clos-syntax-error 'poo-clos-invalid-slot-option
                               "type expects one predicate" option))
          (when type-predicate
            (clos-syntax-error 'poo-clos-duplicate-slot-option
                               "type can appear only once" option))
          (option-loop (cdr rest) allocation allocation-source initargs
                       initform readers writers (car arguments) documentation))
         ((and head (clos-literal=? head #'documentation))
          (unless (= (length arguments) 1)
            (clos-syntax-error 'poo-clos-invalid-slot-option
                               "documentation expects one expression" option))
          (when documentation
            (clos-syntax-error 'poo-clos-duplicate-slot-option
                               "documentation can appear only once" option))
          (option-loop (cdr rest) allocation allocation-source initargs
                       initform readers writers type-predicate (car arguments)))
         (else
          (clos-syntax-error 'poo-clos-unknown-slot-option
                             "unknown CLOS slot option" option)))))))

;;; One slot declaration becomes immutable phase data before any runtime
;;; constructor expression is emitted.
;; : (-> Syntax ClosSlotDeclarationIR)
(def (parse-clos-slot source)
  (let* ((items (clos-syntax-list source "slot declaration must be a list"))
         (name (and (pair? items) (car items))))
    (unless name
      (clos-syntax-error 'poo-clos-invalid-slot "slot name is required" source))
    (clos-identifier name "slot names must be identifiers")
    (let-values (((allocation initform initargs readers writers type-predicate
                              documentation)
                  (parse-clos-slot-options source)))
      (clos-slot-declaration-ir
       name: name allocation: allocation initargs: initargs initform: initform
       readers: readers writers: writers type-predicate: type-predicate
       documentation: documentation source: source))))

;;; Default-initarg entries are a pure ordered projection; handler clauses are
;;; single-owner class options.
;; : (-> Syntax (Pair Syntax Syntax))
(def (parse-default-initarg entry)
  (let (items
        (clos-syntax-list
         entry "default-initargs entries must be (name expression)"))
    (unless (= (length items) 2)
      (clos-syntax-error 'poo-clos-invalid-class-option
                         "default initarg expects name and expression" entry))
    (cons (car items) (cadr items))))

;; : (-> [Syntax]
;;        (values [Pair] (Maybe Syntax) (Maybe Syntax) (Maybe Syntax)
;;                (Maybe Syntax)))
(def (parse-clos-class-options options)
  (let option-loop
      ((rest options) (default-initargs '())
       (slot-missing #f) (slot-unbound #f)
       (documentation #f) (metaclass #f))
    (if (null? rest)
      (values (reverse default-initargs) slot-missing slot-unbound
              documentation metaclass)
      (let* ((option (car rest))
             (items (clos-syntax-list option "class option must be a list"))
             (head (and (pair? items) (car items)))
             (arguments (and (pair? items) (cdr items))))
        (cond
         ((and head (clos-literal=? head #'default-initargs))
          (option-loop
           (cdr rest)
           (foldl (lambda (entry out)
                    (cons (parse-default-initarg entry) out))
                  default-initargs arguments)
           slot-missing slot-unbound documentation metaclass))
         ((and head (clos-literal=? head #'slot-missing))
          (unless (and (= (length arguments) 1) (not slot-missing))
            (clos-syntax-error 'poo-clos-duplicate-class-option
                               "slot-missing expects one unique handler" option))
          (option-loop (cdr rest) default-initargs (car arguments)
                       slot-unbound documentation metaclass))
         ((and head (clos-literal=? head #'slot-unbound))
          (unless (and (= (length arguments) 1) (not slot-unbound))
            (clos-syntax-error 'poo-clos-duplicate-class-option
                               "slot-unbound expects one unique handler" option))
          (option-loop (cdr rest) default-initargs slot-missing
                       (car arguments) documentation metaclass))
         ((and head (clos-literal=? head #'documentation))
          (unless (and (= (length arguments) 1) (not documentation))
            (clos-syntax-error 'poo-clos-duplicate-class-option
                               "documentation expects one unique expression"
                               option))
          (option-loop (cdr rest) default-initargs slot-missing slot-unbound
                       (car arguments) metaclass))
         ((and head (clos-literal=? head #'metaclass))
          (unless (and (= (length arguments) 1) (not metaclass))
            (clos-syntax-error 'poo-clos-duplicate-class-option
                               "metaclass expects one unique expression"
                               option))
          (option-loop (cdr rest) default-initargs slot-missing slot-unbound
                       documentation (car arguments)))
         (else
          (clos-syntax-error 'poo-clos-unknown-class-option
                             "unknown CLOS class option" option)))))))

;;; Class IR construction validates inheritance and slot-name uniqueness before
;;; evaluating any declaration expression.
;; : (-> Syntax Syntax Syntax [Syntax] Syntax ClosClassDeclarationIR)
(def (parse-poo-clos-class-declaration-ir name supers slots options source)
  (clos-identifier name "class name must be an identifier")
  (let* ((super-values
          (clos-syntax-list supers "direct superclasses must be a list"))
         (slot-values (clos-syntax-list slots "direct slots must be a list")))
    (for-each (lambda (superclass)
                (clos-identifier superclass
                                 "superclass names must be identifiers"))
              super-values)
    (clos-require-unique-identifiers
     super-values 'poo-clos-duplicate-superclass supers)
    (let (slot-irs (map parse-clos-slot slot-values))
      (clos-require-unique-identifiers
       (map clos-slot-declaration-ir-name slot-irs)
       'poo-clos-duplicate-slot slots)
      (let-values (((default-initargs slot-missing slot-unbound
                                      documentation metaclass)
                    (parse-clos-class-options options)))
        (clos-require-unique-identifiers
         (map car default-initargs) 'poo-clos-duplicate-default-initarg source)
        (clos-class-declaration-ir
         name: name supers: super-values slots: slot-irs
         default-initargs: default-initargs slot-missing: slot-missing
         slot-unbound: slot-unbound documentation: documentation
         metaclass: metaclass source: source)))))


