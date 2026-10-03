;;; file: program/scheme-language.ss
;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import "objects.ss" "scheme-checked.ss" "scheme-admission.ss"
        (only-in :clan/poo/object .ref))

(export relational-program relational-fragment
        relational-lattice-fragment relational-finite-view
        relational-export relational-compose relational-admit
        relational-admit/report
        relational-admission-report? relational-admission-report-admission
        relational-admission-report-diagnostic
        relational-diagnostic? relational-diagnostic-code
        relational-diagnostic-path relational-diagnostic-detail
        relational-solve relational-query relational-query-name
        relational-open-session relational-session-append-source!
        relational-session-replace-source!
        relational-session-replace-sources!
        relational-session-transaction!
        relational-session-run relational-open-program-session
        relational-program-append-source!
        relational-program-replace-source!
        relational-program-transaction!
        relational-program-session-run relational-program-query)

;;; A rule term is syntax, not a call to an arbitrary Scheme expression.
;;; Explicit (value ...) captures one checked scalar at construction time;
;;; ?variables remain in the rule plan, so later lexical mutation cannot
;;; silently change a dependency during fixed-point evaluation.
(defsyntax (relational-term stx)
  (syntax-case stx (value)
    ((_ (value expression))
     (syntax (relational-captured-value expression)))
    ((_ term)
     (identifier? (syntax term))
     (let* ((datum (syntax->datum (syntax term)))
            (spelling (symbol->string datum)))
       (cond
        ((eq? datum '?_)
         (syntax (gerbil-ascent-wildcard)))
        ((and (> (string-length spelling) 1)
              (char=? (string-ref spelling 0) #\?))
         (syntax (gerbil-ascent-variable 'term)))
        (else
         (raise-syntax-error
          #f "relational term must be a ?variable or scalar literal"
          (syntax term))))))
    ((_ term)
     (let (datum (syntax->datum (syntax term)))
       (if (or (exact-integer? datum) (boolean? datum)
               (char? datum))
         (syntax (gerbil-ascent-literal term))
         (raise-syntax-error
          #f "relational term must be an immutable scalar literal"
          (syntax term)))))))

;;; Boundary: A program-level atom names a relation in the assembled graph.
;;; Invariant: Its terms are lowered through the restricted scalar grammar.
(defsyntax (relational-atom stx)
  (syntax-case stx ()
    ((_ (name term ...))
     (identifier? (syntax name))
     (syntax (gerbil-ascent-atom 'name
                               (list (relational-term term) ...))))
    ((_ bad)
     (raise-syntax-error #f "expected a relational atom" (syntax bad)))))

;;; Fragment atoms resolve a lexical handle after the builder allocates fresh
;;; private relation names. Reusing the same builder therefore cannot alias
;;; two fragment instances merely because their source spelling is the same.
(defsyntax (relational-atom/lexical stx)
  (syntax-case stx ()
    ((_ (name term ...))
     (identifier? (syntax name))
     (syntax (gerbil-ascent-atom name
                               (list (relational-term term) ...))))
    ((_ bad)
     (raise-syntax-error #f "expected a relational atom" (syntax bad)))))

;;; Negation lowers to an inspectable relation reference. The planner checks
;;; binding order and stratification across the whole assembled program.
(defsyntax (relational-negation stx)
  (syntax-case stx ()
    ((_ (name term ...))
     (identifier? (syntax name))
     (syntax (gerbil-ascent-negation
              'name (list (relational-term term) ...))))
    ((_ bad)
     (raise-syntax-error #f "expected a relational negation atom"
                         (syntax bad)))))

;;; The lexical variant preserves the imported handle rather than quoting a
;;; spelling; dependency analysis still sees the same negative clause kind.
(defsyntax (relational-negation/lexical stx)
  (syntax-case stx ()
    ((_ (name term ...))
     (identifier? (syntax name))
     (syntax (gerbil-ascent-negation
              name (list (relational-term term) ...))))
    ((_ bad)
     (raise-syntax-error #f "expected a relational negation atom"
                         (syntax bad)))))

;;; Reducer names are literal syntax. The runtime constructor maps only the
;;; closed numeric/count set to procedures and admission rebuilds that map.
(defsyntax (relational-reduce stx)
  (syntax-case stx ()
    ((_ output mode (input ...) (name term ...))
     (and (identifier? (syntax name))
          (identifier? (syntax mode)))
     (syntax (relational-reducer
              'output 'mode '(input ...) 'name
              (list (relational-term term) ...))))
    ((_ bad ...)
     (raise-syntax-error #f "expected checked reduction" stx))))

;;; Reduction inside a fragment binds its input to the fresh or imported
;;; relation handle, while the checked reducer descriptor stays identical.
(defsyntax (relational-reduce/lexical stx)
  (syntax-case stx ()
    ((_ output mode (input ...) (name term ...))
     (and (identifier? (syntax name))
          (identifier? (syntax mode)))
     (syntax (relational-reducer
              'output 'mode '(input ...) name
              (list (relational-term term) ...))))
    ((_ bad ...)
     (raise-syntax-error #f "expected checked reduction" stx))))

;;; Rule-local operands admit only bound logic variables or scalar values
;;; captured once during construction. A plain Scheme identifier is never
;;; interpreted as a hidden runtime callback or a literal symbol.
(defsyntax (relational-operator-input stx)
  (syntax-case stx (value)
    ((_ (value expression))
     (syntax (relational-operator-literal expression)))
    ((_ input)
     (identifier? (syntax input))
     (let* ((datum (syntax->datum (syntax input)))
            (spelling (symbol->string datum)))
       (if (and (not (eq? datum '?_))
                (> (string-length spelling) 1)
                (char=? (string-ref spelling 0) #\?))
         (syntax (vector 'variable 'input))
         (raise-syntax-error
          #f "operator input must be a ?variable or scalar literal"
          (syntax input)))))
    ((_ input)
     (let (datum (syntax->datum (syntax input)))
       (if (or (exact-integer? datum) (boolean? datum)
               (char? datum))
         (syntax (relational-operator-literal input))
         (raise-syntax-error
          #f "operator input must be an immutable scalar literal"
          (syntax input)))))))

;;; Both public forms share one rule-body grammar. The three lowering macros
;;; choose named or lexical relation references; scalar operators use the
;;; same checked descriptor path in either form. Keeping this expansion
;;; centralized prevents a fragment-only clause from bypassing admission.
(defsyntax (relational-checked-clause stx)
  (def (logic-variable? input)
    (and (identifier? input)
         (let* ((datum (syntax->datum input))
                (spelling (symbol->string datum)))
           (and (not (eq? datum '?_))
                (> (string-length spelling) 1)
                (char=? (string-ref spelling 0) #\?)))))
  (syntax-case stx (where compute not reduce)
    ((_ atom-lowering negation-lowering reduce-lowering
        (where (operation input ...)))
     (identifier? (syntax operation))
     (syntax (relational-where
              'operation (list (relational-operator-input input) ...))))
    ((_ atom-lowering negation-lowering reduce-lowering
        (compute output (operation input ...)))
     (and (logic-variable? (syntax output))
          (identifier? (syntax operation)))
     (syntax (relational-compute
              'output 'operation
              (list (relational-operator-input input) ...))))
    ((_ atom-lowering negation-lowering reduce-lowering
        (not (name term ...)))
     (syntax (negation-lowering (name term ...))))
    ((_ atom-lowering negation-lowering reduce-lowering
        (reduce output (mode input ...) (name term ...)))
     (and (logic-variable? (syntax output))
          (identifier? (syntax mode))
          (andmap logic-variable? (syntax->list (syntax (input ...)))))
     (syntax (reduce-lowering output mode (input ...)
                              (name term ...))))
    ((_ atom-lowering negation-lowering reduce-lowering
        (name term ...))
     (and (identifier? (syntax atom-lowering))
          (identifier? (syntax name))
          (not (memq (syntax->datum (syntax name))
                     '(where compute not reduce))))
     (syntax (atom-lowering (name term ...))))
    ((_ atom-lowering negation-lowering reduce-lowering bad)
     (raise-syntax-error
      #f "expected atom, not, reduce, where, or compute clause"
                         (syntax bad)))))

;;; This collector preserves declaration and body order for the planner.
;;; The final limits form is mandatory so every compiled program has finite
;;; resource bounds before its first solve; no evaluation happens here.
(defsyntax (relational-collect stx)
  (syntax-case stx (relation lattice rule limits)
    ((_ (declared ...) (lowered ...)
        (lattice name (column ...) rows mode) rest ...)
     (and (identifier? (syntax name))
          (identifier? (syntax mode))
          (andmap identifier? (syntax->list (syntax (column ...)))))
     (syntax (relational-collect
              (declared ...
                        (relational-checked-lattice
                         'name (length '(column ...)) rows 'mode))
              (lowered ...) rest ...)))
    ((_ (declared ...) (lowered ...)
        (relation name (column ...) rows) rest ...)
     (and (identifier? (syntax name))
          (andmap identifier? (syntax->list (syntax (column ...)))))
     (syntax (relational-collect
              (declared ...
                        (relational-source
                         'name (length '(column ...)) rows))
              (lowered ...) rest ...)))
    ((_ (declared ...) (lowered ...)
        (relation name (column ...)) rest ...)
     (and (identifier? (syntax name))
          (andmap identifier? (syntax->list (syntax (column ...)))))
     (syntax (relational-collect
              (declared ...
                        (relational-source
                         'name (length '(column ...)) []))
              (lowered ...) rest ...)))
    ((_ (declared ...) (lowered ...) (rule head body ...) rest ...)
     (syntax (relational-collect
              (declared ...)
              (lowered ...
                       (gerbil-ascent-rule
                        (list (relational-atom head))
                        (list (relational-checked-clause
                               relational-atom relational-negation
                               relational-reduce
                               body) ...)))
              rest ...)))
    ((_ (declared ...) (lowered ...) (limits input derived output))
     (syntax (let (relations (list declared ...))
               (gerbil-ascent-program
                relations (list lowered ...) input derived output
                (map (lambda (relation) (.ref relation 'name))
                     relations)))))
    ((_ (declared ...) (lowered ...) bad rest ...)
     (raise-syntax-error
      #f "expected relation, rule, or final limits clause"
      (syntax bad)))
    ((_ (declared ...) (lowered ...))
     (raise-syntax-error
      #f "relational-program requires a final limits clause" stx))))

;; relational-program
;;   : (-> Syntax CheckedPositiveProgramExpression)
;;   | doc m%
;;       Build a checked relational program. Source and derived values are
;;       immutable scalar atoms. Rules admit only fixed checked scalar
;;       operators, not host closures or plain Scheme identifiers. Fixed
;;       rule-local literals and explicit (value ...) inputs are captured
;;       when the program is constructed. The final
;;       limits clause supplies resource-failure bounds.
;;
;;       # Examples
;;
;;       ```scheme
;;       (relational-program
;;         (relation edge (from to) '((1 2)))
;;         (relation path (from to))
;;         (rule (path ?x ?y) (edge ?x ?y))
;;         (limits 4 4 8))
;;       ;; => a program value; evaluating it derives path(1, 2)
;;       ```
;;     %
;;; Boundary: This frame lowers only syntax with inspectable rule dependencies.
;;; Source expressions stay lexical while rules reject host calls.
;;; Invariant: Evaluation cannot observe an undeclared changing relation.
(defsyntax (relational-program stx)
  (syntax-case stx ()
    ((_ clause ...)
     (syntax (relational-collect () () clause ...)))))

;; relational-fragment
;;   : (-> Syntax FirstClassFragmentExpression)
;;   | doc m%
;;       Instantiate a checked fragment with fresh source and private
;;       predicate names. Imports are existing relation handles. Named
;;       exports are recorded on the existing typed POO fragment value.
;;
;;       # Examples
;;
;;       ```scheme
;;       (relational-fragment
;;         (import)
;;         (source (edge (from to) '((1 2))))
;;         (private (path (from to)))
;;         (export (reach path))
;;         (rule (path ?x ?y) (edge ?x ?y)))
;;       ;; => a fragment with a reach export
;;       ```
;;     %
;;; Boundary: Imports preserve caller handles while declarations get fresh names.
;;; Invariant: Separate uses of one Scheme builder cannot alias by spelling.
;;; Final graph admission checks the assembled relation namespace.
(defrules relational-fragment (import source private export rule)
  ((_ (import (import-name imported-handle) ...)
      (source (source-name (source-column ...) source-rows) ...)
      (private (private-name (private-column ...)) ...)
      (export (public-name exported-name) ...)
      (rule (head head-term ...)
            (body body-term ...) ...) ...)
   (let ((import-name imported-handle) ...
         (source-name (gensym 'source-name)) ...
         (private-name (gensym 'private-name)) ...)
     (gerbil-ascent-fragment
      (list (relational-source source-name
                               (length '(source-column ...))
                               source-rows) ...
            (relational-source private-name
                               (length '(private-column ...))
                               []) ...)
      (list
       (gerbil-ascent-rule
        (list (relational-atom/lexical (head head-term ...)))
        (list (relational-checked-clause
               relational-atom/lexical relational-negation/lexical
               relational-reduce/lexical
               (body body-term ...)) ...)) ...)
      (list (cons 'public-name exported-name) ...)
      (list source-name ...)))))

;;; file: program/scheme-checked.ss
;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import "objects.ss"
        (only-in "aggregators.ss"
                 gerbil-ascent-count gerbil-ascent-sum
                 gerbil-ascent-min gerbil-ascent-max)
        (only-in :clan/poo/object .ref)
        (only-in :gerbil-ascent/table/provider
                 gerbil-ascent-hash-index-provider)
        (only-in :gerbil-ascent/table/storage
                 gerbil-ascent-set-storage-provider))

(export relational-scalar? relational-copy-row relational-copy-rows
        relational-finite-rows
        relational-source
        relational-checked-lattice relational-lattice-fragment
        relational-finite-view relational-captured-value
        relational-term-fingerprint relational-reducer
        relational-operator-literal relational-operand-variables
        relational-where relational-compute)

;;; The checked language admits only scalar atoms with stable equality and
;;; hash behavior. Copy list spines before a source or mapping retains rows.
(def (relational-scalar? value)
  (or (exact-integer? value) (boolean? value)
      (symbol? value) (char? value)))

(def (relational-copy-row row arity)
  (unless (and (list? row) (= (length row) arity)
               (andmap relational-scalar? row))
    (error "relational row has wrong arity or non-scalar value" row))
  (map identity row))

(def (relational-copy-rows rows arity)
  (unless (and (exact-integer? arity) (<= 0 arity) (list? rows))
    (error "invalid relational row signature" arity))
  (map (lambda (row) (relational-copy-row row arity)) rows))

;;; Materialize a finite pointwise graph at construction. Missing inputs
;;; produce no rows, repeated inputs produce several, and evaluation uses
;;; ordinary relation joins without invoking a captured host procedure.
(def (relational-finite-rows input-arity output-arity entries)
  (unless (and (exact-integer? input-arity) (<= 0 input-arity)
               (exact-integer? output-arity) (<= 0 output-arity)
               (list? entries))
    (error "invalid finite view signature"))
  (map
   (lambda (entry)
     (unless (and (list? entry) (= (length entry) 2))
       (error "finite view entry needs input and output rows" entry))
     (append (relational-copy-row (car entry) input-arity)
             (relational-copy-row (cadr entry) output-arity)))
   entries))

;;; Restrict sources and results to immutable scalar atoms. Computed exact
;;; integers can grow beyond the source domain; budgets stop such a solve as
;;; failure and must never be read as evidence of completed closure.
(def (relational-source name arity rows)
  ;; Retain the scalar restriction on later source replacement and on
  ;; derived rows.  The relation constructor already checks every row.
  (gerbil-ascent-relation
   name arity (relational-copy-rows rows arity)
   gerbil-ascent-hash-index-provider
   gerbil-ascent-set-storage-provider
   (make-list arity relational-scalar?)))

;;; Lattice joins are chosen by a closed descriptor and rebuilt during
;;; admission. The last column is an exact integer; keys stay scalar.
(def (relational-lattice-join mode)
  (case mode
    ((max)
     (lambda (left right)
       (unless (and (exact-integer? left) (exact-integer? right))
         (error "max lattice needs exact integer values"))
       (max left right)))
    ((min)
     (lambda (left right)
       (unless (and (exact-integer? left) (exact-integer? right))
         (error "min lattice needs exact integer values"))
       (min left right)))
    (else (error "unknown checked lattice join" mode))))

(def (relational-checked-lattice name arity rows mode)
  (unless (and (exact-integer? arity) (> arity 0) (list? rows))
    (error "invalid checked lattice signature" name arity))
  (let (copied (relational-copy-rows rows arity))
    (for-each
     (lambda (row)
       (unless (exact-integer? (last row))
         (error "checked lattice needs exact integer value" row)))
     copied)
    (gerbil-ascent-lattice
     name arity copied
     (relational-lattice-join mode)
     gerbil-ascent-hash-index-provider
     (append (make-list (- arity 1) relational-scalar?)
             (list exact-integer?))
     (vector 'lattice mode))))

;;; A lattice fragment is one source declaration with a fresh handle.
;;; Its label can be imported by rule fragments without exposing the
;;; private relation name or trusting a caller-supplied join procedure.
(def (relational-lattice-fragment label arity rows mode)
  (unless (symbol? label)
    (error "lattice fragment label must be a symbol" label))
  (let (handle (gensym 'lattice))
    (gerbil-ascent-fragment
     (list (relational-checked-lattice handle arity rows mode))
     [] (list (cons label handle)) (list handle))))

;;; An explicit finite pointwise view is an extensional source fragment.
;;; A rule imports its handle and joins the input/output columns normally;
;;; unlisted inputs have no outputs and repeated inputs have many.
(def (relational-finite-view label input-arity output-arity entries)
  (unless (symbol? label)
    (error "finite view label must be a symbol" label))
  (let (handle (gensym 'view))
    (gerbil-ascent-fragment
     (list (relational-source
            handle (+ input-arity output-arity)
            (relational-finite-rows input-arity output-arity entries)))
     [] (list (cons label handle)) (list handle))))

;;; An explicit host capture is evaluated when the program or fragment is
;;; constructed. Restrict it to immutable scalar values before any rule can
;;; observe it; mutable collections cannot be smuggled into a solved graph.
(def (relational-captured-value value)
  (unless (relational-scalar? value)
    (error "relational value capture requires an immutable scalar" value))
  (gerbil-ascent-literal value))

;;; A rule-local literal is fixed when its program or fragment is built.
;;; The descriptor is copied again at admission, so later caller mutation
;;; cannot alter an executing rule. Symbols in the input list denote logic
;;; variables; vectors distinguish explicitly captured literal values.
(def (relational-operator-literal value)
  (unless (relational-scalar? value)
    (error "relational operator literal requires a scalar" value))
  (vector 'literal value))

(def (relational-copy-operand operand)
  (cond
   ((symbol? operand) (vector 'variable operand))
   ((and (vector? operand) (= (vector-length operand) 2))
    (case (vector-ref operand 0)
      ((variable)
       (unless (symbol? (vector-ref operand 1))
         (error "invalid relational operator variable" operand))
       (vector 'variable (vector-ref operand 1)))
      ((literal) (relational-operator-literal (vector-ref operand 1)))
      (else (error "invalid relational operator operand" operand))))
   (else (error "invalid relational operator operand" operand))))

(def (relational-operand-variables operands)
  (unless (list? operands)
    (error "relational operator operands must be a list" operands))
  (filter-map
   (lambda (operand)
     (and (vector? operand)
          (= (vector-length operand) 2)
          (eq? (vector-ref operand 0) 'variable)
          (vector-ref operand 1)))
   operands))

(def (relational-operator-call operation-procedure operands)
  (lambda values
    (let loop ((remaining operands) (bound values) (arguments []))
      (if (null? remaining)
        (begin
          (unless (null? bound)
            (error "relational operator argument mismatch"))
          (apply operation-procedure (reverse arguments)))
        (let (operand (car remaining))
          (if (eq? (vector-ref operand 0) 'variable)
            (if (pair? bound)
              (loop (cdr remaining) (cdr bound)
                    (cons (car bound) arguments))
              (error "relational operator argument mismatch"))
            (loop (cdr remaining) bound
                  (cons (vector-ref operand 1) arguments))))))))

(def (relational-term-fingerprint terms)
  (map (lambda (term)
         (cons (.ref term 'kind) (.ref term 'value)))
       terms))

;;; Fixed reducers consume a completed lower stratum. A procedure stored
;;; in a caller-owned Aggregate is never accepted on its own authority.
(def (relational-reducer-procedure mode inputs)
  (case mode
    ((count)
     (unless (null? inputs)
       (error "checked count takes no value variable"))
     gerbil-ascent-count)
    ((sum min max)
     (unless (= (length inputs) 1)
       (error "checked numeric reduction needs one value variable"))
     (let (reducer (case mode
                    ((sum) gerbil-ascent-sum)
                    ((min) gerbil-ascent-min)
                    ((max) gerbil-ascent-max)))
       (lambda (tuples)
         (for-each
          (lambda (tuple)
            (unless (and (list? tuple) (= (length tuple) 1)
                         (exact-integer? (car tuple)))
              (error "numeric reduction needs exact integer rows")))
          tuples)
         (reducer tuples))))
    (else (error "unknown checked reducer" mode))))

(def (relational-reducer output mode inputs relation terms)
  (gerbil-ascent-aggregate
   output relation terms inputs
   (relational-reducer-procedure mode inputs) #f
   (vector 'reduce mode output relation
           (map identity inputs)
           (relational-term-fingerprint terms))))

;;; Fixed scalar operators are declared by name, arity and input mode.
;;; Their procedures are built locally; a rule cannot supply a host closure.
(def (relational-operator-procedure mode operation arity)
  (case mode
    ((where)
     (case operation
       ((even?)
        (unless (= arity 1)
          (error "even? expects one relational input"))
        (lambda (value)
          (unless (exact-integer? value)
            (error "even? expects an exact integer" value))
          (even? value)))
       ((<)
        (unless (= arity 2)
          (error "< expects two relational inputs"))
        (lambda (left right)
          (unless (and (exact-integer? left) (exact-integer? right))
            (error "< expects exact integers" left right))
          (< left right)))
       (else (error "unknown relational filter operator" operation))))
    ((compute)
     (case operation
       ((+)
        (unless (= arity 2)
          (error "+ expects two relational inputs"))
        (lambda (left right)
          (unless (and (exact-integer? left) (exact-integer? right))
            (error "+ expects exact integers" left right))
          (+ left right)))
       ((identity)
        (unless (= arity 1)
          (error "identity expects one relational input"))
        (lambda (value) value))
       (else (error "unknown relational projection operator" operation))))
    (else (error "unknown relational operator mode" mode))))

(def (relational-where operation variables)
  (let* ((operands (map relational-copy-operand variables))
         (inputs (relational-operand-variables operands)))
    (gerbil-ascent-guard
     inputs
     (relational-operator-call
      (relational-operator-procedure 'where operation (length operands))
      operands)
     (vector 'where operation operands))))

(def (relational-compute output operation variables)
  (let* ((operands (map relational-copy-operand variables))
         (inputs (relational-operand-variables operands)))
    (gerbil-ascent-binding
     output inputs
     (relational-operator-call
      (relational-operator-procedure 'compute operation (length operands))
      operands)
     (vector 'compute operation operands output))))

;;; file: program/scheme-admission.ss
;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import "objects.ss" "scheme-checked.ss"
        (only-in "types.ss" GerbilAscentFragmentContract
                 GerbilAscentProgramContract)
        (only-in "evaluate.ss" gerbil-ascent-make-engine)
        (only-in "session.ss" gerbil-ascent-open-session
                 gerbil-ascent-session-append-source!
                 gerbil-ascent-session-replace-source!
                 gerbil-ascent-session-replace-sources!
                 gerbil-ascent-session-run)
        (only-in :clan/poo/object .ref)
        (only-in :clan/poo/mop validate)
        (only-in :std/error exception->string)
        (only-in :std/list/list append-map find))

(export relational-export relational-compose relational-admit
        relational-admit/report
        relational-admission-report? relational-admission-report-admission
        relational-admission-report-diagnostic
        relational-diagnostic? relational-diagnostic-code
        relational-diagnostic-path relational-diagnostic-detail
        relational-solve relational-query relational-query-name
        relational-open-session relational-session-append-source!
        relational-session-replace-source!
        relational-session-replace-sources!
        relational-session-transaction!
        relational-session-run relational-open-program-session
        relational-program-append-source!
        relational-program-replace-source!
        relational-program-transaction!
        relational-program-session-run relational-program-query)

(defstruct relational-admission (run))
(defstruct relational-diagnostic (code path detail))
(defstruct relational-admission-report (admission diagnostic))
(defstruct relational-solution (result))
(defstruct relational-session (engine source-arities))
(defstruct relational-program-session (engine source-arities))
(defstruct relational-program-solution (result))

;;; Completed results own their relation snapshots. Public queries copy the
;;; row spines so a caller cannot mutate a later query through an old answer.
(def (relational-result-rows result name)
  (unless (.ref result 'finished)
    (error "relational query requires a completed result"))
  (map (lambda (row) (map identity row))
       ((.ref result 'rows-of) name)))

;;; A public label is scoped to its fragment instance, rather than to the
;;; process or composed program. Only declared labels can reveal a handle.
(def (relational-export fragment label)
  (validate GerbilAscentFragmentContract fragment)
  ((.ref fragment 'exports) label))

;;; A query observes only a completed result and a handle exported by the
;;; supplied fragment. Copy returned rows so callers cannot edit the snapshot.
(def (relational-query solution fragment label)
  (unless (relational-solution? solution)
    (error "relational query requires a solved value" solution))
  (let (result (relational-solution-result solution))
    (relational-result-rows result (relational-export fragment label))))

;;; Named one-shot programs may contain private derived relations, so they
;;; cannot use the retained session API, which requires every relation to be
;;; source-capable. Query the completed admitted result directly.
(def (relational-query-name solution name)
  (unless (and (relational-solution? solution) (symbol? name))
    (error "relational named query requires a solved value" name))
  (let (result (relational-solution-result solution))
    (relational-result-rows result name)))

(def (relational-program-query solution name)
  (unless (and (relational-program-solution? solution) (symbol? name))
    (error "relational program query requires a named solution" name))
  (let (result (relational-program-solution-result solution))
    (relational-result-rows result name)))

;;; Composition is inert. Admission checks the assembled schema and rules
;;; later, after every fragment has contributed to the whole program.
(def (relational-compose fragments input-limit derived-limit output-limit)
  (for-each
   (lambda (fragment)
     (validate GerbilAscentFragmentContract fragment))
   fragments)
  (gerbil-ascent-program
   (append-map (lambda (fragment) (.ref fragment 'relations)) fragments)
   (append-map (lambda (fragment) (.ref fragment 'rules)) fragments)
   input-limit derived-limit output-limit
   (append-map (lambda (fragment) (.ref fragment 'source-handles))
               fragments)))

;;; Admission rebuilds only the checked relational grammar. This removes
;;; caller-owned row/rule lists before planning and rejects old host callbacks.
(def (relational-copy-term term)
  (case (.ref term 'kind)
    ((variable) (gerbil-ascent-variable (.ref term 'value)))
    ((wildcard) (gerbil-ascent-wildcard))
    ((literal)
     (let (value (.ref term 'value))
       (unless (relational-scalar? value)
         (error "non-scalar relational literal" value))
       (gerbil-ascent-literal value)))
    (else (error "unsupported relational term" (.ref term 'kind)))))

(def (relational-copy-atom atom)
  (unless (eq? (.ref atom 'ascent-clause-kind) 'atom)
    (error "unsupported relational clause"))
  (gerbil-ascent-atom
   (.ref atom 'relation)
   (map relational-copy-term (.ref atom 'terms))))

;;; Rebuild from the descriptor, never from the callback stored for the old
;;; evaluator. An unmarked guard or binding cannot cross admission.
(def (relational-copy-clause clause)
  (case (.ref clause 'ascent-clause-kind)
    ((atom) (relational-copy-atom clause))
    ((negation)
     (gerbil-ascent-negation
      (.ref clause 'relation)
      (map relational-copy-term (.ref clause 'terms))))
    ((aggregate)
     (let ((descriptor (.ref clause 'checked-operator))
           (terms (.ref clause 'terms)))
       (unless (and (vector? descriptor)
                    (= (vector-length descriptor) 6)
                    (eq? (vector-ref descriptor 0) 'reduce)
                    (eq? (vector-ref descriptor 2)
                         (.ref clause 'variable))
                    (eq? (vector-ref descriptor 3)
                         (.ref clause 'relation))
                    (equal? (vector-ref descriptor 4)
                            (.ref clause 'variables))
                    (equal? (vector-ref descriptor 5)
                            (relational-term-fingerprint terms))
                    (not (.ref clause 'output-pattern)))
         (error "untrusted relational reduction"))
       (relational-reducer
        (vector-ref descriptor 2) (vector-ref descriptor 1)
        (vector-ref descriptor 4) (vector-ref descriptor 3)
        (map relational-copy-term terms))))
    ((guard)
     (let (descriptor (.ref clause 'checked-operator))
       (unless (and (vector? descriptor)
                    (= (vector-length descriptor) 3)
                    (eq? (vector-ref descriptor 0) 'where)
                    (equal? (relational-operand-variables
                             (vector-ref descriptor 2))
                            (.ref clause 'variables)))
         (error "untrusted relational filter"))
       (relational-where (vector-ref descriptor 1)
                         (vector-ref descriptor 2))))
    ((binding)
     (let (descriptor (.ref clause 'checked-operator))
       (unless (and (vector? descriptor)
                    (= (vector-length descriptor) 4)
                    (eq? (vector-ref descriptor 0) 'compute)
                    (equal? (relational-operand-variables
                             (vector-ref descriptor 2))
                            (.ref clause 'variables))
                    (eq? (vector-ref descriptor 3)
                         (.ref clause 'variable)))
         (error "untrusted relational projection"))
       (relational-compute (vector-ref descriptor 3)
                            (vector-ref descriptor 1)
                            (vector-ref descriptor 2))))
    (else (error "unsupported relational clause"
                 (.ref clause 'ascent-clause-kind)))))

(def (relational-copy-rule rule)
  (gerbil-ascent-rule
   (map relational-copy-atom (.ref rule 'heads))
   (map relational-copy-clause (.ref rule 'body))))

;;; The engine constructor checks relation names, arities, rule bindings,
;;; dependencies and budgets before the admission value becomes observable.
(def (relational-snapshot-program program)
  (validate GerbilAscentProgramContract program)
  (gerbil-ascent-program
   (map (lambda (relation)
          (case (.ref relation 'storage-kind)
            ((relation)
             (relational-source
              (.ref relation 'name)
              (.ref relation 'arity)
              (.ref relation 'rows)))
            ((lattice)
             (let (descriptor (.ref relation 'checked-operator))
               (unless (and (vector? descriptor)
                            (= (vector-length descriptor) 2)
                            (eq? (vector-ref descriptor 0) 'lattice))
                 (error "untrusted relational lattice"))
               (relational-checked-lattice
                (.ref relation 'name)
                (.ref relation 'arity)
                (.ref relation 'rows)
                (vector-ref descriptor 1))))
            (else (error "unsupported relational storage kind"))))
        (.ref program 'relations))
   (map relational-copy-rule (.ref program 'rules))
   (.ref program 'max-input-facts)
   (.ref program 'max-derived-facts)
   (.ref program 'max-output-facts)
   (.ref program 'source-handles)))

;;; Direct admission raises on invalid input, as do the low-level program
;;; constructors. A report caller may observe a planner path without
;;; duplicating the planner's binding and stratification rules.
(def (relational-admit program (on-plan-error #f))
  (let (snapshot (relational-snapshot-program program))
    (let ((run (gerbil-ascent-make-engine
                snapshot #f #f #f #f on-plan-error))
          (status 'ready)
          (complete-result #f))
      (make-relational-admission
       (lambda ()
         (case status
           ((complete) complete-result)
           ((failed) (error "relational solve previously failed"))
           ((running) (error "reentrant relational solve"))
           (else
            (set! status 'running)
            (with-catch
             (lambda (failure)
               (set! status 'failed)
               (raise failure))
             (lambda ()
               (let (result (run))
                 (unless (.ref result 'finished)
                   (error "relational solve did not complete"))
                 (set! complete-result result)
                 (set! status 'complete)
                 result))))))))))

;;; One typed result covers both admitted and rejected programs. The path is
;;; zero-based: (rule N body M), (rule N head M), or (program) when a failure
;;; occurs before rule planning. Detail is explanatory, never parsed as data.
(def (relational-admit/report program)
  (let (path '(program))
    (with-catch
     (lambda (failure)
       (make-relational-admission-report
        #f
        (make-relational-diagnostic
         (cond
          ((and (pair? path) (eq? (car path) 'rule))
           (if (eq? (caddr path) 'body)
             'invalid-body 'invalid-head))
          ((equal? path '(program dependencies))
           'invalid-dependencies)
          (else 'invalid-program))
         path (exception->string failure))))
     (lambda ()
       (make-relational-admission-report
        (relational-admit
         program (lambda (location _failure) (set! path location)))
        #f)))))

;;; The prepared engine runs once. Successful repeats reuse its completed
;;; result; a failed run cannot expose or retry partially changed state.
(def (relational-solve admission)
  (unless (relational-admission? admission)
    (error "relational solve requires admission" admission))
  (make-relational-solution
   ((relational-admission-run admission))))

;;; Retained sessions accept replacements only through exported source
;;; handles. The old session owns rollback after an update or solve fails.
(def (relational-source-arities snapshot)
  (let (sources (.ref snapshot 'source-handles))
    (map (lambda (name)
           (let (relation
                 (find (lambda (candidate)
                         (eq? (.ref candidate 'name) name))
                       (.ref snapshot 'relations)))
             (unless relation
               (error "relational source has no declaration" name))
             (cons name (.ref relation 'arity))))
         sources)))

(def (relational-open-session program)
  (let* ((snapshot (relational-snapshot-program program))
         (arities (relational-source-arities snapshot)))
    (make-relational-session
     (gerbil-ascent-open-session snapshot)
     arities)))

(def (relational-open-program-session program)
  (let* ((snapshot (relational-snapshot-program program))
         (relations (.ref snapshot 'relations))
         (arities (relational-source-arities snapshot)))
    (unless (= (length relations) (length arities))
      (error "named program session requires source-capable relations"))
    (make-relational-program-session
     (gerbil-ascent-open-session snapshot)
     arities)))

(def (relational-replace-source/checked! engine arities name rows)
  (let (arity (and (symbol? name) (assq name arities)))
    (unless arity
      (error "relation is not a source in this session" name))
    (let (copied (relational-copy-rows rows (cdr arity)))
      ;; The checked copy already validates every row and owns its list spine.
      (gerbil-ascent-session-replace-source! engine name copied)
      (void))))

;;; Insert one checked source row into the retained positive session. The
;;; underlying session decides whether its admitted plan can reuse deltas;
;;; a caller still observes results only after a completed run.
(def (relational-append-source/checked! engine arities name row)
  (let (arity (and (symbol? name) (assq name arities)))
    (unless arity
      (error "relation is not a source in this session" name))
    (let (copied (relational-copy-row row (cdr arity)))
      (gerbil-ascent-session-append-source! engine name copied)
      (void))))

(def (relational-session-append-source! session fragment label row)
  (unless (relational-session? session)
    (error "relational source append requires a session" session))
  (validate GerbilAscentFragmentContract fragment)
  (let* ((name (relational-export fragment label))
         (arity (assq name (relational-session-source-arities session))))
    (unless (and (memq name (.ref fragment 'source-handles)) arity)
      (error "relational export is not a source in this session" label))
    (relational-append-source/checked!
     (relational-session-engine session)
     (relational-session-source-arities session) name row)))

(def (relational-session-replace-source! session fragment label rows)
  (unless (relational-session? session)
    (error "relational source replacement requires a session" session))
  (validate GerbilAscentFragmentContract fragment)
  (let* ((name (relational-export fragment label))
         (arity (assq name (relational-session-source-arities session))))
    (unless (and (memq name (.ref fragment 'source-handles)) arity)
      (error "relational export is not a source in this session" label))
    (relational-replace-source/checked!
     (relational-session-engine session)
     (relational-session-source-arities session) name rows)))

;;; Both named programs and composed fragments share one checked source
;;; replacement boundary. Nothing enters the Session before all rows have
;;; been copied and every source name has passed arity and uniqueness checks.
(def (relational-checked-replacements arities entries)
  (unless (and (list? entries) (pair? entries))
    (error "relational transaction requires source updates" entries))
  (let (seen (make-hash-table-eq))
    (map
     (lambda (entry)
       (unless (and (pair? entry) (symbol? (car entry)))
         (error "invalid relational source update" entry))
       (let* ((name (car entry))
              (arity (assq name arities)))
         (unless arity
           (error "relation is not a source in this session" name))
         (when (hash-get seen name)
           (error "duplicate relational transaction source" name))
         (hash-put! seen name #t)
         (let (rows (relational-copy-rows (cdr entry) (cdr arity)))
           (cons name rows))))
     entries)))

;;; Updates are (fragment label rows) triples. Each handle must be an
;;; exported source in this composed session. The returned solution is
;;; complete, or the previous completed snapshot remains current.
(def (relational-session-transaction! session updates)
  (unless (relational-session? session)
    (error "relational transaction requires a session" session))
  (unless (and (list? updates) (pair? updates))
    (error "relational transaction requires source updates" updates))
  (let (entries
        (map
         (lambda (update)
           (unless (and (list? update) (= (length update) 3)
                        (symbol? (cadr update)))
             (error "invalid relational transaction update" update))
           (let* ((fragment (car update))
                  (label (cadr update)))
             (let (name (relational-export fragment label))
               (unless (memq name (.ref fragment 'source-handles))
                 (error "relational export is not a source in this session"
                        label))
               (cons name (caddr update)))))
         updates))
    (make-relational-solution
     (gerbil-ascent-session-replace-sources!
      (relational-session-engine session)
      (relational-checked-replacements
       (relational-session-source-arities session) entries)))))

;;; Single-fragment batches use the same cross-fragment transaction owner.
(def (relational-session-replace-sources! session fragment replacements)
  (unless (list? replacements)
    (error "relational batch replacements must be a list" replacements))
  (relational-session-transaction!
   session
   (map
    (lambda (replacement)
      (unless (and (pair? replacement) (symbol? (car replacement)))
        (error "invalid relational source replacement" replacement))
      (list fragment (car replacement) (cdr replacement)))
    replacements)))

(def (relational-program-replace-source! session name rows)
  (unless (relational-program-session? session)
    (error "named source replacement requires a program session" session))
  (relational-replace-source/checked!
   (relational-program-session-engine session)
   (relational-program-session-source-arities session) name rows))

(def (relational-program-append-source! session name row)
  (unless (relational-program-session? session)
    (error "named source append requires a program session" session))
  (relational-append-source/checked!
   (relational-program-session-engine session)
   (relational-program-session-source-arities session) name row))

;;; The direct named program uses the same atomic Session transaction and
;;; row checks. Its result retains the distinct named-solution query type.
(def (relational-program-transaction! session replacements)
  (unless (relational-program-session? session)
    (error "named transaction requires a program session" session))
  (make-relational-program-solution
   (gerbil-ascent-session-replace-sources!
    (relational-program-session-engine session)
    (relational-checked-replacements
     (relational-program-session-source-arities session)
     replacements))))

(def (relational-session-result engine)
  (let (result (gerbil-ascent-session-run engine))
    (unless (.ref result 'finished)
      (error "relational session did not complete"))
    result))

(def (relational-session-run session)
  (unless (relational-session? session)
    (error "relational run requires a session" session))
  (make-relational-solution
   (relational-session-result (relational-session-engine session))))

(def (relational-program-session-run session)
  (unless (relational-program-session? session)
    (error "named run requires a program session" session))
  (make-relational-program-solution
   (relational-session-result
    (relational-program-session-engine session))))

(import :std/test :gerbil-ascent/program/scheme-language)
(def edge-data '((11 12) (12 13) (11 14)))
(def blocked-data '((12 13)))
(def replacement-data '((11 14)))
(def first-label 'gate11)
(def second-label 'other11)
(def (canonical rows)
  (list-sort (lambda (left right)
    (if (= (car left) (car right)) (< (cadr left) (cadr right))
      (< (car left) (car right)))) rows))
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(def result
  (canonical
   (relational-query-name
    (relational-solve
     (relational-admit
      (relational-program
       (relation edge (from to) edge-data)
       (relation joined (from to))
       (rule (joined ?x ?z) (edge ?x ?y) (edge ?y ?z))
       (limits 32 64 128))))
    'joined)))

(check-equal? result '?)
