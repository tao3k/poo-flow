;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: phase-owned parser and immutable declaration model for use-composition.
;;; Invariant: syntax remains syntax until the public macro lowers the declaration.

(import :gerbil/expander
        (only-in :std/list/list fold))

(export parse-poo-flow-composition-declaration
        composition-declaration-name
        composition-declaration-modules
        composition-declaration-compose
        composition-declaration-stages
        composition-profile-syntax-name
        composition-profile-syntax-mode
        composition-profile-syntax-module-name
        composition-profile-syntax-value
        composition-profile-syntax-sections
        composition-profile-section-syntax-slot
        composition-profile-section-syntax-value
        composition-profile-ref-syntax-module
        composition-profile-ref-syntax-slot
        composition-stage-syntax-name
        composition-stage-syntax-clauses
        composition-clause-syntax-kind
        composition-clause-syntax-payload)

;;; Compile-time declaration root.  The alias index is parser-owned and is not
;;; exposed to runtime lowering; it prevents repeated module scans while
;;; retaining binding-aware identifier checks.
(defclass composition-declaration
  (name modules module-alias-index compose stages source))

;;; One declarative module row.  A composition owns one or more rows; aliases
;;; remain lexical names and never replace the module identity.
(defclass composition-module-syntax
  (name alias profiles source))

(export composition-module-syntax-name
        composition-module-syntax-alias
        composition-module-syntax-profiles)

;;; Profile IR node: distinguishes inline and referenced profiles before expansion.
(defclass composition-profile-syntax
  (name mode module-name value sections source))

;;; Section IR node: preserves the source-bearing slot/value pair for diagnostics.
(defclass composition-profile-section-syntax
  (slot value source))

;;; Reference IR node: keeps module and exported slot identity separate.
(defclass composition-profile-ref-syntax
  (module slot source))

;;; Stage IR node: owns an ordered set of already parsed composition clauses.
(defclass composition-stage-syntax
  (name clauses source))

;;; Clause IR node: records the closed clause kind with its normalized payload.
(defclass composition-clause-syntax
  (kind payload source))

;;; Parser fold state is named because each field has a different invariant.
;;; Reversed accumulators preserve declaration order with one final reverse.
(defclass composition-declaration-fold-state
  (compose-reversed stages-reversed stage-name-index))

;; : (-> Symbol String Syntax Bottom)
(def (composition-raise-syntax-error category message source)
  (raise-syntax-error
   #f
   (string-append (symbol->string category) ": " message)
   source))

;; : (-> Syntax Syntax Boolean)
(def (composition-literal=? candidate literal)
  (and (identifier? candidate)
       (eq? (syntax->datum candidate)
            (syntax->datum literal))))

;; : (-> Syntax Symbol String [Syntax])
(def (composition-syntax-list source category message)
  (let (items (syntax->list source))
    (if items
      items
      (composition-raise-syntax-error category message source))))

;; : (-> Syntax Symbol String Syntax)
(def (composition-require-identifier source category message)
  (if (identifier? source)
    source
    (composition-raise-syntax-error category message source)))

;; : (-> Syntax Symbol)
(def (composition-profile-section-slot key)
  (cond
   ((composition-literal=? key #':extends) 'extends)
   ((composition-literal=? key #':kind) 'kind)
   ((composition-literal=? key #':scope) 'scope)
   ((composition-literal=? key #':storage) 'storage)
   ((composition-literal=? key #':analysis) 'analysis)
   ((composition-literal=? key #':publish) 'publish)
   ((composition-literal=? key #':retention) 'retention)
   ((composition-literal=? key #':capabilities) 'capabilities)
   ((composition-literal=? key #':guard) 'guard)
   ((composition-literal=? key #':with) 'hooks)
   (else
    (composition-raise-syntax-error
     'composition-unknown-profile-section
     "expected one of :extends, :with, :kind, :scope, :capabilities, :guard, :storage, :analysis, :publish, or :retention"
     key))))

;; : (-> [Syntax] [CompositionProfileSectionSyntax])
(def (composition-parse-profile-sections sections)
  (cond
   ((null? sections) '())
   ((null? (cdr sections))
    (composition-raise-syntax-error
     'composition-missing-profile-section-value
     "profile section key requires a value"
     (car sections)))
   (else
    (let* ((key (car sections))
           (value (cadr sections))
           (slot (composition-profile-section-slot key)))
      (when (eq? slot 'hooks)
        (composition-syntax-list
         value
         'composition-unknown-profile-section
         ":with expects a parenthesized list of named extension functions"))
      (cons
       (composition-profile-section-syntax
        slot: slot
        value: value
        source: key)
       (composition-parse-profile-sections (cddr sections)))))))

;; : (-> Syntax Syntax CompositionProfileSyntax)
(def (composition-imported-profile module-name profile-name source)
  (composition-require-identifier
   profile-name
   'composition-invalid-module-form
   "imported profile names must be identifiers")
  (composition-profile-syntax
   name: profile-name
   mode: 'imported
   module-name: module-name
   value: #f
   sections: '()
   source: source))

;; : (-> Syntax Syntax CompositionProfileSyntax)
(def (composition-existing-profile module-name profile-name source)
  (composition-require-identifier
   profile-name
   'composition-invalid-module-form
   "an existing POO profile reference must be an identifier")
  (composition-profile-syntax
   name: profile-name
   mode: 'existing
   module-name: module-name
   value: profile-name
   sections: '()
   source: source))

;; : (-> Syntax Syntax [Syntax] CompositionProfileSyntax)
(def (composition-local-profile module-name profile-name sections source)
  (composition-require-identifier
   profile-name
   'composition-invalid-module-form
   "local profile names must be identifiers")
  (composition-profile-syntax
   name: profile-name
   mode: 'local
   module-name: module-name
   value: #f
   sections: (composition-parse-profile-sections sections)
   source: source))

;; : (-> HashTable Symbol Syntax Symbol String Void)
(def (composition-require-fresh-symbol! name-index name source category message)
  (when (hash-key? name-index name)
    (composition-raise-syntax-error category message source))
  (hash-put! name-index name #t))

;; : (-> Syntax Syntax [Syntax] HashTable CompositionProfileSyntax)
(def (composition-parse-profile-body module-name clause body name-index)
  (match body
    ([profile-name . sections]
     (let (name (syntax->datum profile-name))
       (composition-require-fresh-symbol!
        name-index name profile-name
        'composition-duplicate-profile
        "profile names must be unique inside one composition module")
       (if (null? sections)
         (composition-existing-profile module-name profile-name clause)
         (composition-local-profile
          module-name profile-name sections clause))))
    (else
     (composition-raise-syntax-error
      'composition-invalid-module-form
      "profile expects an existing POO object or a named profile with section pairs"
      clause))))

;; : (-> Syntax [Syntax] [CompositionProfileSyntax])
(def (composition-parse-profiles module-name clauses)
  (let ((name-index (make-hash-table-eq)))
   (let clause-loop ((rest clauses) (out '()))
    (if (null? rest)
      (reverse out)
      (let* ((clause (car rest))
             (items
              (composition-syntax-list
               clause
               'composition-invalid-module-form
               "use-module expects profile or profiles declarations")))
        (match items
          ([head . body]
           (cond
            ((composition-literal=? head #'profiles)
             (when (null? body)
               (composition-raise-syntax-error
                'composition-invalid-module-form
                "profiles expects one or more imported profile names"
                clause))
             (let profile-loop ((profiles body) (next-out out))
               (if (null? profiles)
                 (clause-loop (cdr rest) next-out)
                 (let* ((profile-name (car profiles))
                        (name (syntax->datum profile-name)))
                   (composition-require-fresh-symbol!
                    name-index name profile-name
                    'composition-duplicate-profile
                    "profile names must be unique inside one composition module")
                   (profile-loop
                    (cdr profiles)
                    (cons
                     (composition-imported-profile
                      module-name profile-name clause)
                     next-out))))))
            ((composition-literal=? head #'profile)
             (clause-loop
              (cdr rest)
              (cons (composition-parse-profile-body
                     module-name clause body name-index)
                    out)))
            (else
             (composition-raise-syntax-error
              'composition-invalid-module-form
              "use-module accepts only profile and profiles declarations"
              clause))))
          (else
           (composition-raise-syntax-error
            'composition-invalid-module-form
            "use-module expects profile or profiles declarations"
            clause))))))))

;; Syntax identifiers cannot be keyed by datum alone: equal spelling can carry
;; different bindings.  The symbol selects a small bucket; free-identifier=?
;; remains the final authority inside that bucket.
(def (composition-find-module-by-alias alias-index alias)
  (let loop ((rest (or (hash-get alias-index (syntax->datum alias)) '())))
    (cond ((null? rest) #f)
          ((free-identifier=? alias
                             (composition-module-syntax-alias (car rest)))
           (car rest))
          (else (loop (cdr rest))))))

(def (composition-index-module-alias! alias-index module)
  (let* ((alias (composition-module-syntax-alias module))
         (key (syntax->datum alias))
         (bucket (or (hash-get alias-index key) '())))
    (when (let loop ((rest bucket))
            (and (pair? rest)
                 (or (free-identifier=?
                      alias (composition-module-syntax-alias (car rest)))
                     (loop (cdr rest)))))
      (composition-raise-syntax-error
       'composition-duplicate-module-alias
       "module aliases must be unique inside one composition"
       alias))
    (hash-put! alias-index key (cons module bucket))))

(def (composition-profile-ref alias-index module-name profile-name source)
  (composition-require-identifier
   module-name
   'composition-invalid-compose-clause
   "profile references require a module alias identifier")
  (unless (composition-find-module-by-alias alias-index module-name)
    (composition-raise-syntax-error
     'composition-invalid-compose-clause
     "profile reference must use an alias declared by modules/use-module"
     module-name))
  (composition-require-identifier
   profile-name
   'composition-invalid-compose-clause
   "profile references require a profile identifier")
  (composition-profile-ref-syntax
   module: module-name
   slot: profile-name
   source: source))

;; Add one compose declaration directly to the reversed accumulator.  This
;; avoids singleton result lists and append-map intermediates for large forms.
(def (composition-add-compose-item alias-index item out)
  (let (items
        (composition-syntax-list
         item
         'composition-invalid-compose-clause
         "compose expects profile or profiles references"))
    (match items
      ([head module-name profile-name]
       (if (composition-literal=? head #'profile)
         (cons
          (composition-profile-ref
           alias-index module-name profile-name item)
          out)
         (composition-raise-syntax-error
          'composition-invalid-compose-clause
          "profile reference must be (profile alias profile-name)"
          item)))
      ([head module-name . profile-names]
       (if (composition-literal=? head #'profiles)
         (begin
           (when (null? profile-names)
             (composition-raise-syntax-error
              'composition-invalid-compose-clause
              "profiles reference requires one or more profile names"
              item))
           (let loop ((rest profile-names) (next-out out))
             (if (null? rest)
               next-out
               (loop
                (cdr rest)
                (cons
                 (composition-profile-ref
                  alias-index module-name (car rest) item)
                 next-out)))))
         (composition-raise-syntax-error
          'composition-invalid-compose-clause
          "compose expects (profile alias name) or (profiles alias name ...)"
          item)))
      (else
       (composition-raise-syntax-error
        'composition-invalid-compose-clause
        "compose expects (profile alias name) or (profiles alias name ...)"
        item)))))

;; : (-> HashTable [Syntax] [CompositionProfileRefSyntax] [CompositionProfileRefSyntax])
(def (composition-add-compose-items alias-index items out)
  (let loop ((rest items) (next-out out))
    (if (null? rest)
      next-out
      (loop (cdr rest)
            (composition-add-compose-item
             alias-index (car rest) next-out)))))

;; : (-> Syntax CompositionClauseSyntax)
(def (composition-parse-stage-clause clause)
  (let (items
        (composition-syntax-list
         clause
         'composition-invalid-stage-clause
         "stage expects graph, loop, prove, handoff, step, guard, edges, or route clauses"))
    (match items
      ([head . payload]
       (let (kind-value
             (cond
              ((composition-literal=? head #'graph) 'graph)
              ((composition-literal=? head #'loop) 'loop)
              ((composition-literal=? head #'prove) 'prove)
              ((composition-literal=? head #'handoff) 'handoff)
              ((composition-literal=? head #'step) 'step)
              ((composition-literal=? head #'guard) 'guard)
              ((composition-literal=? head #'edges) 'edges)
              ((composition-literal=? head #'route) 'route)
              (else
               (composition-raise-syntax-error
                'composition-invalid-stage-clause
                "unknown stage clause; expected graph, loop, prove, handoff, step, guard, edges, or route"
                head))))
         (composition-clause-syntax
          kind: kind-value
          payload: payload
          source: clause)))
      (else
       (composition-raise-syntax-error
        'composition-invalid-stage-clause
        "stage clause must be a parenthesized declaration"
        clause)))))

;; : (-> Syntax CompositionStageSyntax)
(def (composition-parse-stage stage-form)
  (let (items
        (composition-syntax-list
         stage-form
         'composition-invalid-stage-clause
         "stage must be (stage name clause ...)"))
    (match items
      ([head stage-name . clauses]
       (unless (composition-literal=? head #'stage)
         (composition-raise-syntax-error
          'composition-invalid-stage-clause
          "stage must begin with the stage grammar literal"
          head))
       (composition-require-identifier
        stage-name
        'composition-invalid-stage-clause
        "stage name must be an identifier")
       (let loop ((rest clauses) (out '()))
         (if (null? rest)
           (composition-stage-syntax
            name: stage-name
            clauses: (reverse out)
            source: stage-form)
           (loop
            (cdr rest)
            (cons (composition-parse-stage-clause (car rest)) out)))))
      (else
       (composition-raise-syntax-error
        'composition-invalid-stage-clause
        "stage must be (stage name clause ...)"
        stage-form)))))

;; : (-> Syntax [CompositionModuleSyntax] HashTable CompositionDeclarationFoldState Syntax CompositionDeclaration)
(def (composition-finish-declaration
      composition-name modules module-alias-index state source)
  (let ((compose-reversed
         (composition-declaration-fold-state-compose-reversed state))
        (stages-reversed
         (composition-declaration-fold-state-stages-reversed state)))
   (if (null? compose-reversed)
    (composition-raise-syntax-error
     'composition-missing-profile-operand
     "use-composition requires at least one profile operand"
     source)
    (composition-declaration
     name: composition-name
     modules: modules
     module-alias-index: module-alias-index
     compose: (reverse compose-reversed)
     stages: (reverse stages-reversed)
     source: source))))

;; : (-> HashTable Syntax CompositionDeclarationFoldState CompositionDeclarationFoldState)
(def (composition-add-declaration-form module-alias-index form state)
  (let (items
        (composition-syntax-list
         form
         'composition-invalid-stage-clause
         "use-composition expects compose or stage forms after use-module"))
    (match items
      ([head . body]
       (cond
        ((composition-literal=? head #'compose)
         (composition-declaration-fold-state
          compose-reversed:
          (composition-add-compose-items
           module-alias-index body
           (composition-declaration-fold-state-compose-reversed state))
          stages-reversed:
          (composition-declaration-fold-state-stages-reversed state)
          stage-name-index:
          (composition-declaration-fold-state-stage-name-index state)))
        ((composition-literal=? head #'stage)
         (let* ((stage (composition-parse-stage form))
                (stage-name
                 (syntax->datum (composition-stage-syntax-name stage)))
                (stage-name-index
                 (composition-declaration-fold-state-stage-name-index state)))
           (composition-require-fresh-symbol!
            stage-name-index stage-name
            (composition-stage-syntax-name stage)
            'composition-duplicate-stage
            "stage names must be unique inside one composition")
           (composition-declaration-fold-state
            compose-reversed:
            (composition-declaration-fold-state-compose-reversed state)
            stages-reversed:
            (cons stage
                  (composition-declaration-fold-state-stages-reversed state))
            stage-name-index: stage-name-index)))
        (else
         (composition-raise-syntax-error
          'composition-invalid-stage-clause
          "use-composition expects compose or stage forms after use-module"
          form))))
      (else
       (composition-raise-syntax-error
        'composition-invalid-stage-clause
        "use-composition expects parenthesized compose or stage forms"
        form)))))

;; : (-> Syntax [CompositionModuleSyntax] HashTable [Syntax] Syntax CompositionDeclaration)
(def (composition-build-declaration
      composition-name modules module-alias-index forms source)
  (let (state
        (fold
         (lambda (form state)
           (composition-add-declaration-form module-alias-index form state))
         (composition-declaration-fold-state
          compose-reversed: '()
          stages-reversed: '()
          stage-name-index: (make-hash-table-eq))
         forms))
    (composition-finish-declaration
     composition-name modules module-alias-index state source)))

(def (composition-parse-module-form module-form)
  (let (module-items
        (composition-syntax-list
         module-form
         'composition-invalid-module-form
         "expected canonical (use-module module-name as alias ...)"))
    (match module-items
      ([head module-name marker alias profile-clauses ...]
       (unless (composition-literal=? head #'use-module)
         (composition-raise-syntax-error
          'composition-invalid-module-form
          "expected canonical (use-module module-name as alias ...)"
          module-form))
       (unless (composition-literal=? marker #'as)
         (composition-raise-syntax-error
          'composition-invalid-module-form
          "expected canonical (use-module module-name as alias ...)"
          module-form))
       (composition-require-identifier
        module-name 'composition-invalid-module-form
        "module name must be an identifier")
       (composition-require-identifier
        alias 'composition-invalid-module-form
        "module alias must be an identifier")
       (composition-module-syntax
        name: module-name
        alias: alias
        profiles: (composition-parse-profiles module-name profile-clauses)
        source: module-form))
      (else
       (composition-raise-syntax-error
        'composition-invalid-module-form
        "expected canonical (use-module module-name as alias ...)"
        module-form)))))

(def (composition-parse-modules module-form)
  (let (items
        (composition-syntax-list
         module-form 'composition-invalid-module-form
         "expected (modules (use-module module-name as alias ...) ...)"))
    (match items
      ([head rows ...]
       (if (composition-literal=? head #'modules)
         (begin
           (when (null? rows)
             (composition-raise-syntax-error
              'composition-invalid-module-form
              "modules requires at least one use-module declaration"
              module-form))
           (let ((alias-index (make-hash-table-eq)))
            (let loop ((rest rows) (out '()))
             (if (null? rest)
               (values (reverse out) alias-index)
               (let (module (composition-parse-module-form (car rest)))
                 (composition-index-module-alias! alias-index module)
                 (loop (cdr rest) (cons module out)))))))
         (let* ((module (composition-parse-module-form module-form))
                (alias-index (make-hash-table-eq)))
           (composition-index-module-alias! alias-index module)
           (values (list module) alias-index))))
      (else
       (let* ((module (composition-parse-module-form module-form))
              (alias-index (make-hash-table-eq)))
         (composition-index-module-alias! alias-index module)
         (values (list module) alias-index))))))

;; : (-> Syntax Syntax [Syntax] CompositionDeclaration)
(def (parse-poo-flow-composition-declaration
      composition-name
      module-form
      forms
      source)
  (composition-require-identifier
   composition-name
   'composition-invalid-module-form
   "composition name must be an identifier")
  (let-values (((modules module-alias-index)
                (composition-parse-modules module-form)))
    (composition-build-declaration
     composition-name modules module-alias-index forms source)))
