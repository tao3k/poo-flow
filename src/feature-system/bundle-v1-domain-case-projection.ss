(export +feature-bundle-v1-domain-case-projection-kind+
        +feature-bundle-v1-domain-case-diagnostic-kind+
        +feature-bundle-v1-no-capability-id+
        +feature-bundle-v1-no-policy-id+
        +feature-bundle-v1-no-strategy-id+
        +feature-bundle-v1-no-adapter-id+
        +feature-bundle-v1-no-projection-id+
        +feature-bundle-v1-parent-relation-id+
        feature-bundle-v1-domain-case-projection?
        feature-bundle-v1-domain-case-diagnostic?
        feature-bundle-v1-project-domain-case
        require-feature-bundle-v1-domain-case-projection)

(import (only-in :std/srfi/1 iota zip)
        :std/sort
        :clan/poo/object
        :poo-flow/src/utilities/functional
        :poo-flow/src/module-system/domain-case
        :poo-flow/src/feature-system/bundle-v1-lowering
        :poo-flow/src/feature-system/runtime-handoff-plan)

(def +feature-bundle-v1-domain-case-projection-kind+
  'poo-flow.feature-bundle-v1-domain-case-projection.v1)
(def +feature-bundle-v1-domain-case-diagnostic-kind+
  'poo-flow.feature-bundle-v1-domain-case-diagnostic.v1)

(def +feature-bundle-v1-no-capability-id+
  'poo-flow.bundle-v1.no-capability)
(def +feature-bundle-v1-no-policy-id+
  'poo-flow.bundle-v1.no-policy)
(def +feature-bundle-v1-no-strategy-id+
  'poo-flow.bundle-v1.no-strategy)
(def +feature-bundle-v1-no-adapter-id+
  'poo-flow.bundle-v1.no-adapter)
(def +feature-bundle-v1-no-projection-id+
  'poo-flow.bundle-v1.no-projection)
(def +feature-bundle-v1-parent-relation-id+
  'poo-flow.bundle-v1.component-parent)

(defsyntax define-poo-value
  (syntax-rules ()
    ((_ (name field ...) kind-value)
     (def (name field ...)
       (object<-alist
        (list (cons 'kind kind-value)
              (cons 'schema-version 1)
              (cons 'field field) ...))))))

(define-poo-value
  (feature-bundle-v1-domain-case-diagnostic code subject detail)
  +feature-bundle-v1-domain-case-diagnostic-kind+)

(define-poo-value
  (feature-bundle-v1-domain-case-projection
   status accepted? bundle-id bundle-epoch runtime-handoff-plan assembly
   components edges evidence-obligations lowering-plan diagnostics)
  +feature-bundle-v1-domain-case-projection-kind+)

(def (poo-kind? value expected-kind)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) expected-kind)))

(def (feature-bundle-v1-domain-case-projection? value)
  (poo-kind? value +feature-bundle-v1-domain-case-projection-kind+))

(def (feature-bundle-v1-domain-case-diagnostic? value)
  (poo-kind? value +feature-bundle-v1-domain-case-diagnostic-kind+))

(def (indexed-values values)
  (zip (iota (length values)) values))

(def (resolved-handoff-kind? value expected-kind)
  (and (object? value)
       (.slot? value 'handoff-kind)
       (eq? (.ref value 'handoff-kind) expected-kind)))

(def (resolved-handoff-owner-id value)
  (.ref (.ref (.ref value 'projection-binding) 'projection) 'owner-id))

(def (component-entry indexed-component)
  (let ((index (car indexed-component))
        (component (cadr indexed-component)))
    (list
     (feature-bundle-v1-lower-compact-id
      'component (.ref component 'component-id))
     index
     component)))

(def (bundle-handoff-entry handoff)
  (list
   (feature-bundle-v1-lower-compact-id
    'component (resolved-handoff-owner-id handoff))
   handoff))

(def (entry<? left right)
  (feature-bundle-v1-compact-id<? (car left) (car right)))

(def (sorted-entries entries)
  (stable-sort entries entry<?))

(def (adjacent-duplicate-entry? entries)
  (and (pair? entries)
       (pair? (cdr entries))
       (or (feature-bundle-v1-compact-id=?
            (caar entries) (caadr entries))
           (adjacent-duplicate-entry? (cdr entries)))))

(def (effective-algebra-id policy-strategy-binding slot fallback)
  (let ((binding (.ref policy-strategy-binding slot)))
    (if (.ref binding 'algebra-id)
        (.ref binding 'algebra-id)
        fallback)))

(def (project-component
      case-id policy-id strategy-id component-index component handoff)
  (let* ((component-id (.ref component 'component-id))
         (type-id (.ref (.ref component 'type-contract) 'type-id))
         (adapter-binding
          (and handoff (.ref handoff 'adapter-binding)))
         (projection-binding
          (and handoff (.ref handoff 'projection-binding))))
    (feature-bundle-v1-component
     case-id
     component-id
     component-id
     type-id
     type-id
     component-id
     (if adapter-binding
         (.ref adapter-binding 'capability-id)
         +feature-bundle-v1-no-capability-id+)
     policy-id
     strategy-id
     (if handoff
         (.ref handoff 'provider-module-id)
         +feature-bundle-v1-no-adapter-id+)
     (if projection-binding
         (.ref projection-binding 'projection-id)
         +feature-bundle-v1-no-projection-id+)
     component-index)))

(def (merge-components-and-handoffs
      case-id policy-id strategy-id component-entries handoff-entries)
  (let loop ((components component-entries)
             (handoffs handoff-entries)
             (result '()))
    (cond
     ((null? components)
      (if (null? handoffs)
          (list 'ready (reverse result))
          (list 'orphan-runtime-bundle-handoff-owner
                (resolved-handoff-owner-id (cadar handoffs)))))
     ((null? handoffs)
      (loop
       (cdr components)
       '()
       (cons
        (project-component
         case-id policy-id strategy-id
         (cadar components) (caddar components) #f)
        result)))
     (else
      (let* ((component-entry (car components))
             (handoff-entry (car handoffs))
             (component-id (car component-entry))
             (handoff-id (car handoff-entry)))
        (cond
         ((feature-bundle-v1-compact-id<? component-id handoff-id)
          (loop
           (cdr components)
           handoffs
           (cons
            (project-component
             case-id policy-id strategy-id
             (cadr component-entry) (caddr component-entry) #f)
            result)))
         ((feature-bundle-v1-compact-id<? handoff-id component-id)
          (list 'orphan-runtime-bundle-handoff-owner
                (resolved-handoff-owner-id (cadr handoff-entry))))
         (else
          (loop
           (cdr components)
           (cdr handoffs)
           (cons
            (project-component
             case-id policy-id strategy-id
             (cadr component-entry) (caddr component-entry)
             (cadr handoff-entry))
            result)))))))))

(def (project-component-edges case-id components)
  (poo-flow-append-map
   (lambda (component)
     (poo-flow-map
      (lambda (indexed-parent)
        (feature-bundle-v1-edge
         case-id
         (.ref component 'component-id)
         (cadr indexed-parent)
         +feature-bundle-v1-parent-relation-id+
         (car indexed-parent)))
      (indexed-values (.ref component 'parent-component-ids))))
   components))

(def (project-evidence-obligations case-id resolved-handoffs)
  (poo-flow-map
   (lambda (indexed-handoff)
     (let ((index (car indexed-handoff))
           (handoff (cadr indexed-handoff)))
       (feature-bundle-v1-evidence
        case-id
        (.ref handoff 'handoff-id)
        (.ref handoff 'contract-id)
        (.ref handoff 'projection-schema-id)
        (.ref handoff 'provider-module-id)
        index)))
   (indexed-values
    (poo-flow-filter-map
     (lambda (handoff)
       (and (resolved-handoff-kind?
             handoff +feature-evidence-obligation-kind+)
            handoff))
     resolved-handoffs))))

(def (rejected-projection/context
      code subject detail bundle-id bundle-epoch runtime-handoff-plan assembly
      components edges evidence-obligations lowering-plan)
  (feature-bundle-v1-domain-case-projection
   'rejected #f bundle-id bundle-epoch runtime-handoff-plan assembly
   components edges evidence-obligations lowering-plan
   (list
    (feature-bundle-v1-domain-case-diagnostic code subject detail))))

(def (rejected-projection code subject detail)
  (rejected-projection/context
   code subject detail #f #f #f #f '() '() '() #f))

(def (accepted-runtime-handoff-plan? value)
  (with-catch
   (lambda (_failure) #f)
   (lambda ()
     (eq? (require-feature-runtime-handoff-plan value) value))))

(def (project-ready-runtime-handoff-plan bundle-epoch runtime-handoff-plan)
  (let* ((adapter-projection-binding
          (.ref runtime-handoff-plan 'adapter-projection-binding))
         (assembly (.ref adapter-projection-binding 'assembly))
         (policy-strategy-binding
          (.ref adapter-projection-binding 'policy-strategy-binding))
         (composition-plan (.ref assembly 'composition-plan))
         (bundle-id (.ref composition-plan 'bundle-id))
         (case-id (.ref assembly 'domain-case-id))
         (components (.ref assembly 'components))
         (resolved-handoffs
          (.ref runtime-handoff-plan 'resolved-handoffs))
         (bundle-handoffs
          (poo-flow-filter-map
           (lambda (handoff)
             (and (resolved-handoff-kind?
                   handoff +feature-runtime-bundle-handoff-kind+)
                  handoff))
           resolved-handoffs))
         (component-entries
          (sorted-entries
           (poo-flow-map component-entry (indexed-values components))))
         (handoff-entries
          (sorted-entries
           (poo-flow-map bundle-handoff-entry bundle-handoffs)))
         (policy-id
          (effective-algebra-id
           policy-strategy-binding 'policy-binding
           +feature-bundle-v1-no-policy-id+))
         (strategy-id
          (effective-algebra-id
           policy-strategy-binding 'strategy-binding
           +feature-bundle-v1-no-strategy-id+)))
    (cond
     ((not (poo-flow-list-of? poo-flow-case-component-valid? components))
      (rejected-projection/context
       'invalid-domain-case-components case-id
       'expected-accepted-poo-case-components
       bundle-id bundle-epoch runtime-handoff-plan assembly
       '() '() '() #f))
     ((adjacent-duplicate-entry? component-entries)
      (rejected-projection/context
       'duplicate-domain-case-component-id case-id
       'component-identity-must-be-unique
       bundle-id bundle-epoch runtime-handoff-plan assembly
       '() '() '() #f))
     ((adjacent-duplicate-entry? handoff-entries)
      (rejected-projection/context
       'duplicate-runtime-bundle-handoff-owner case-id
       'one-runtime-bundle-handoff-per-component
       bundle-id bundle-epoch runtime-handoff-plan assembly
       '() '() '() #f))
     (else
      (let ((component-result
             (merge-components-and-handoffs
              case-id policy-id strategy-id
              component-entries handoff-entries)))
        (if (not (eq? (car component-result) 'ready))
            (rejected-projection/context
             (car component-result) case-id (cadr component-result)
             bundle-id bundle-epoch runtime-handoff-plan assembly
             '() '() '() #f)
            (let* ((bundle-components (cadr component-result))
                   (bundle-edges
                    (project-component-edges case-id components))
                   (bundle-evidence
                    (project-evidence-obligations
                     case-id resolved-handoffs))
                   (lowering-plan
                    (feature-bundle-v1-lowering
                     bundle-id bundle-epoch
                     bundle-components bundle-edges bundle-evidence)))
              (if (.ref lowering-plan 'accepted?)
                  (feature-bundle-v1-domain-case-projection
                   'ready #t bundle-id bundle-epoch
                   runtime-handoff-plan assembly
                   bundle-components bundle-edges bundle-evidence
                   lowering-plan '())
                  (rejected-projection/context
                   'bundle-v1-lowering-rejected bundle-id
                   (.ref lowering-plan 'diagnostics)
                   bundle-id bundle-epoch runtime-handoff-plan assembly
                   bundle-components bundle-edges bundle-evidence
                   lowering-plan)))))))))

(def (feature-bundle-v1-project-domain-case
      bundle-epoch runtime-handoff-plan)
  (if (not (accepted-runtime-handoff-plan? runtime-handoff-plan))
      (rejected-projection
       'runtime-handoff-plan-rejected runtime-handoff-plan
       'expected-accepted-feature-runtime-handoff-plan)
      (with-catch
       (lambda (_failure)
         (rejected-projection/context
          'invalid-runtime-handoff-owner-graph runtime-handoff-plan
          'expected-domain-case-binding-and-resolved-handoffs
          #f bundle-epoch runtime-handoff-plan #f '() '() '() #f))
       (lambda ()
         (project-ready-runtime-handoff-plan
          bundle-epoch runtime-handoff-plan)))))

(def (require-feature-bundle-v1-domain-case-projection value)
  (unless (and (feature-bundle-v1-domain-case-projection? value)
               (.slot? value 'accepted?)
               (.ref value 'accepted?))
    (error "Accepted Bundle v1 Domain Case projection expected" value))
  value)
