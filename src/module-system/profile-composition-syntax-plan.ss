;;; -*- Gerbil -*-
;;; Boundary: phase-owned parser and immutable plan for use-composition.
;;; Invariant: syntax remains syntax until the public macro lowers the plan.

(import :gerbil/expander)

(export parse-poo-flow-composition-syntax-plan
        composition-syntax-plan-name
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

(defclass composition-syntax-plan
  (name module-name alias profiles compose stages source))

(defclass composition-profile-syntax
  (name mode module-name value sections source))

(defclass composition-profile-section-syntax
  (slot value source))

(defclass composition-profile-ref-syntax
  (module slot source))

(defclass composition-stage-syntax
  (name clauses source))

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
   ((composition-literal=? key #':with) 'hooks)
   (else
    (composition-raise-syntax-error
     'composition-unknown-profile-section
     "expected one of :extends, :with, :kind, :scope, :capabilities, :storage, :analysis, :publish, or :retention"
     key))))

;; : (-> [Syntax] [CompositionProfileSectionSyntax])
(def (composition-parse-profile-sections sections)
  (let loop ((rest sections) (out '()))
    (cond
     ((null? rest)
      (reverse out))
     ((null? (cdr rest))
      (composition-raise-syntax-error
       'composition-missing-profile-section-value
       "profile section key requires a value"
       (car rest)))
     (else
      (let* ((key (car rest))
             (value (cadr rest))
             (slot (composition-profile-section-slot key)))
        (when (eq? slot 'hooks)
          (composition-syntax-list
           value
           'composition-unknown-profile-section
           ":with expects a parenthesized list of named extension functions"))
        (loop
         (cddr rest)
         (cons
          (composition-profile-section-syntax
           slot: slot
           value: value
           source: key)
          out)))))))

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
             (match body
               ([profile-name]
                (let (name (syntax->datum profile-name))
                  (when (memq name seen)
                    (composition-raise-syntax-error
                     'composition-duplicate-profile
                     "profile names must be unique inside one composition module"
                     profile-name))
                  (clause-loop
                   (cdr rest)
                   (cons
                    (composition-existing-profile
                     module-name profile-name clause)
                    out)
                   (cons name seen))))
               ([profile-name . sections]
                (let (name (syntax->datum profile-name))
                  (when (memq name seen)
                    (composition-raise-syntax-error
                     'composition-duplicate-profile
                     "profile names must be unique inside one composition module"
                     profile-name))
                  (clause-loop
                   (cdr rest)
                   (cons
                    (composition-local-profile
                     module-name profile-name sections clause)
                    out)
                   (cons name seen))))
               (else
                (composition-raise-syntax-error
                 'composition-invalid-module-form
                 "profile expects an existing POO object or a named profile with section pairs"
                 clause))))
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
(def (composition-profile-ref alias module-name profile-name source)
  (composition-require-identifier
   module-name
   'composition-invalid-compose-clause
   "profile references require a module alias identifier")
  (unless (free-identifier=? module-name alias)
    (composition-raise-syntax-error
     'composition-invalid-compose-clause
     "profile reference must use the alias declared by use-module"
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
(def (composition-parse-compose-item alias item)
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
           alias module-name profile-name item))
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
                  alias module-name (car rest) item)
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
(def (composition-parse-compose alias items)
  (let item-loop ((rest items) (out '()))
    (if (null? rest)
      (reverse out)
      (let ref-loop ((refs (composition-parse-compose-item alias (car rest)))
                     (next-out out))
        (if (null? refs)
          (item-loop (cdr rest) next-out)
          (ref-loop (cdr refs) (cons (car refs) next-out)))))))

;; : (-> Syntax CompositionClauseSyntax)
(def (composition-parse-stage-clause clause)
  (let (items
        (composition-syntax-list
         clause
         'composition-invalid-stage-clause
         "stage expects graph, loop, prove, handoff, step, edges, or route clauses"))
    (match items
      ([head . payload]
       (let (kind
             (cond
              ((composition-literal=? head #'graph) 'graph)
              ((composition-literal=? head #'loop) 'loop)
              ((composition-literal=? head #'prove) 'prove)
              ((composition-literal=? head #'handoff) 'handoff)
              ((composition-literal=? head #'step) 'step)
              ((composition-literal=? head #'edges) 'edges)
              ((composition-literal=? head #'route) 'route)
              (else
               (composition-raise-syntax-error
                'composition-invalid-stage-clause
                "unknown stage clause; expected graph, loop, prove, handoff, step, edges, or route"
                head))))
         (composition-clause-syntax
          kind: kind
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
        module-name
        'composition-invalid-module-form
        "module name must be an identifier")
       (composition-require-identifier
        alias
        'composition-invalid-module-form
        "module alias must be an identifier")
       (let-values (((profiles _seen)
                     (composition-parse-profiles
                      module-name profile-clauses)))
         (let form-loop ((rest forms)
                         (compose-out '())
                         (stage-out '())
                         (stage-seen '()))
           (if (null? rest)
             (composition-syntax-plan
              name: composition-name
              module-name: module-name
              alias: alias
              profiles: profiles
              compose: (reverse compose-out)
              stages: (reverse stage-out)
              source: source)
             (let* ((form (car rest))
                    (items
                     (composition-syntax-list
                      form
                      'composition-invalid-stage-clause
                      "use-composition expects compose or stage forms after use-module")))
               (match items
                 ([head . body]
                  (cond
                   ((composition-literal=? head #'compose)
                    (let ref-loop
                        ((refs (composition-parse-compose alias body))
                         (next-out compose-out))
                      (if (null? refs)
                        (form-loop
                         (cdr rest) next-out stage-out stage-seen)
                        (ref-loop
                         (cdr refs) (cons (car refs) next-out)))))
                   ((composition-literal=? head #'stage)
                    (let* ((stage (composition-parse-stage form))
                           (stage-name
                            (syntax->datum
                             (composition-stage-syntax-name stage))))
                      (when (memq stage-name stage-seen)
                        (composition-raise-syntax-error
                         'composition-duplicate-stage
                         "stage names must be unique inside one composition"
                         (composition-stage-syntax-name stage)))
                      (form-loop
                       (cdr rest)
                       compose-out
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
                   form))))))))
      ([head . _]
       (composition-raise-syntax-error
        'composition-invalid-module-form
        "expected canonical (use-module module-name as alias ...)"
        module-form))
      (else
       (composition-raise-syntax-error
        'composition-invalid-module-form
        "expected canonical (use-module module-name as alias ...)"
        module-form)))))
