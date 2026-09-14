;;; -*- Gerbil -*-
;;; Boundary: phase-owned parser and immutable plan for use-composition.
;;; Invariant: syntax remains syntax until the public macro lowers the plan.

(import :gerbil/expander
        (only-in :std/srfi/1 append-map fold))

(export parse-poo-flow-composition-syntax-plan
        composition-syntax-plan-name
        composition-syntax-plan-modules
        composition-syntax-plan-module-name
        composition-syntax-plan-alias
        composition-syntax-plan-profiles
        composition-syntax-plan-compose
        composition-syntax-plan-stages
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

;;; Syntax IR root: retains source syntax beside normalized profiles, compose clauses, and stages.
(defclass composition-syntax-plan
  (name modules compose stages source))

;;; One declarative module row.  A composition owns one or more rows; aliases
;;; remain lexical names and never replace the module identity.
(defclass composition-module-syntax
  (name alias profiles source))

(export composition-module-syntax-name
        composition-module-syntax-alias
        composition-module-syntax-profiles)

;;; These three projections keep syntax-plan inspection source compatible while
;;; the actual plan is multi-module.  New lowering consumes `modules` directly.
(def (composition-syntax-plan-module-name plan)
  (composition-module-syntax-name (car (composition-syntax-plan-modules plan))))
(def (composition-syntax-plan-alias plan)
  (composition-module-syntax-alias (car (composition-syntax-plan-modules plan))))
(def (composition-syntax-plan-profiles plan)
  (append-map composition-module-syntax-profiles
              (composition-syntax-plan-modules plan)))

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

;; : (-> Syntax Syntax [Syntax] [Symbol] (values CompositionProfileSyntax Symbol))
(def (composition-parse-profile-body module-name clause body seen)
  (match body
    ([profile-name . sections]
     (let (name (syntax->datum profile-name))
       (when (memq name seen)
         (composition-raise-syntax-error
          'composition-duplicate-profile
          "profile names must be unique inside one composition module"
          profile-name))
       (values
        (if (null? sections)
          (composition-existing-profile module-name profile-name clause)
          (composition-local-profile
           module-name profile-name sections clause))
        name)))
    (else
     (composition-raise-syntax-error
      'composition-invalid-module-form
      "profile expects an existing POO object or a named profile with section pairs"
      clause))))

;; : (-> Syntax Syntax [Syntax] (values [CompositionProfileSyntax] [Symbol]))
(def (composition-parse-profiles module-name clauses)
  (let clause-loop ((rest clauses) (out '()) (seen '()))
    (if (null? rest)
      (values (reverse out) seen)
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
             (let profile-loop ((profiles body) (next-out out) (next-seen seen))
               (if (null? profiles)
                 (clause-loop (cdr rest) next-out next-seen)
                 (let* ((profile-name (car profiles))
                        (name (syntax->datum profile-name)))
                   (when (memq name next-seen)
                     (composition-raise-syntax-error
                      'composition-duplicate-profile
                      "profile names must be unique inside one composition module"
                      profile-name))
                   (profile-loop
                    (cdr profiles)
                    (cons
                     (composition-imported-profile
                      module-name profile-name clause)
                     next-out)
                    (cons name next-seen))))))
            ((composition-literal=? head #'profile)
             (let-values (((profile name)
                           (composition-parse-profile-body
                            module-name clause body seen)))
               (clause-loop (cdr rest)
                            (cons profile out)
                            (cons name seen))))
            (else
             (composition-raise-syntax-error
              'composition-invalid-module-form
              "use-module accepts only profile and profiles declarations"
              clause))))
          (else
           (composition-raise-syntax-error
            'composition-invalid-module-form
            "use-module expects profile or profiles declarations"
            clause)))))))

;; : (-> Syntax Syntax CompositionProfileRefSyntax)
(def (composition-find-module-by-alias modules alias)
  (let loop ((rest modules))
    (cond ((null? rest) #f)
          ((free-identifier=? alias
                             (composition-module-syntax-alias (car rest)))
           (car rest))
          (else (loop (cdr rest))))))

(def (composition-profile-ref modules module-name profile-name source)
  (composition-require-identifier
   module-name
   'composition-invalid-compose-clause
   "profile references require a module alias identifier")
  (unless (composition-find-module-by-alias modules module-name)
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

;; : (-> Syntax Syntax [CompositionProfileRefSyntax])
(def (composition-parse-compose-item modules item)
  (let (items
        (composition-syntax-list
         item
         'composition-invalid-compose-clause
         "compose expects profile or profiles references"))
    (match items
      ([head module-name profile-name]
       (if (composition-literal=? head #'profile)
         (list
          (composition-profile-ref
           modules module-name profile-name item))
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
           (let loop ((rest profile-names) (out '()))
             (if (null? rest)
               (reverse out)
               (loop
                (cdr rest)
                (cons
                 (composition-profile-ref
                  modules module-name (car rest) item)
                 out)))))
         (composition-raise-syntax-error
          'composition-invalid-compose-clause
          "compose expects (profile alias name) or (profiles alias name ...)"
          item)))
      (else
       (composition-raise-syntax-error
        'composition-invalid-compose-clause
        "compose expects (profile alias name) or (profiles alias name ...)"
        item)))))

;; : (-> Syntax [Syntax] [CompositionProfileRefSyntax])
(def (composition-parse-compose modules items)
  (append-map
   (lambda (item)
     (composition-parse-compose-item modules item))
   items))

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

;; : (-> Syntax Syntax Syntax [CompositionProfileSyntax] [CompositionProfileRefSyntax] [CompositionStageSyntax] Syntax CompositionSyntaxPlan)
(def (composition-finish-syntax-plan composition-name modules
                                     compose-out stage-out source)
  (if (null? compose-out)
    (composition-raise-syntax-error
     'composition-missing-profile-operand
     "use-composition requires at least one profile operand"
     source)
    (composition-syntax-plan
     name: composition-name
     modules: modules
     compose: (reverse compose-out)
     stages: (reverse stage-out)
     source: source)))

;; : (-> Syntax Syntax [CompositionProfileRefSyntax] [CompositionStageSyntax] [Symbol] CompositionPlanFoldState)
(def (composition-add-plan-form modules form compose-out stage-out stage-seen)
  (let (items
        (composition-syntax-list
         form
         'composition-invalid-stage-clause
         "use-composition expects compose or stage forms after use-module"))
    (match items
      ([head . body]
       (cond
        ((composition-literal=? head #'compose)
         (list (append (reverse (composition-parse-compose modules body))
                       compose-out)
               stage-out
               stage-seen))
        ((composition-literal=? head #'stage)
         (let* ((stage (composition-parse-stage form))
                (stage-name
                 (syntax->datum (composition-stage-syntax-name stage))))
           (when (memq stage-name stage-seen)
             (composition-raise-syntax-error
              'composition-duplicate-stage
              "stage names must be unique inside one composition"
              (composition-stage-syntax-name stage)))
           (list compose-out
                 (cons stage stage-out)
                 (cons stage-name stage-seen))))
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

;; : (-> Syntax Syntax CompositionPlanFoldState CompositionPlanFoldState)
(def (composition-fold-plan-form modules form state)
  (composition-add-plan-form
   modules
   form
   (car state)
   (cadr state)
   (caddr state)))

;; : (-> Syntax Syntax Syntax [CompositionProfileSyntax] [Syntax] Syntax CompositionSyntaxPlan)
(def (composition-build-syntax-plan composition-name modules forms source)
  (let (state
        (fold
         (lambda (form state)
           (composition-fold-plan-form modules form state))
         (list '() '() '())
         forms))
    (match state
      ([compose-out stage-out _stage-seen]
       (composition-finish-syntax-plan
        composition-name modules compose-out stage-out source)))))

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
       (let-values (((profiles _seen)
                     (composition-parse-profiles module-name profile-clauses)))
         (composition-module-syntax
          name: module-name alias: alias profiles: profiles source: module-form)))
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
           (let loop ((rest rows) (out '()) (aliases '()))
             (if (null? rest)
               (reverse out)
               (let* ((module (composition-parse-module-form (car rest)))
                      (alias (composition-module-syntax-alias module))
                      (alias-name (syntax->datum alias)))
                 (when (memq alias-name aliases)
                   (composition-raise-syntax-error
                    'composition-duplicate-module-alias
                    "module aliases must be unique inside one composition"
                    alias))
                 (loop (cdr rest) (cons module out)
                       (cons alias-name aliases))))))
         (list (composition-parse-module-form module-form))))
      (else (list (composition-parse-module-form module-form))))))

;; : (-> Syntax Syntax [Syntax] CompositionSyntaxPlan)
(def (parse-poo-flow-composition-syntax-plan
      composition-name
      module-form
      forms
      source)
  (composition-require-identifier
   composition-name
   'composition-invalid-module-form
   "composition name must be an identifier")
  (composition-build-syntax-plan
   composition-name (composition-parse-modules module-form) forms source))
