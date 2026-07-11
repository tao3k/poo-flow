(export #t)

(import :clan/poo/object
        :std/crypto/digest
        :std/sort
        :std/text/hex)

(def +poo-flow-organization-bundle-schema+
  'poo-flow.organization-bundle.v2)
(def +poo-flow-organization-facet-schema+
  'poo-flow.organization-facet.v1)

(def +poo-flow-organization-bundle-digest-algorithm+ 'sha256)

(def (poo-flow-organization-principal principal-id-value)
  (.o (kind 'principal) (id principal-id-value)))

(def (poo-flow-organization-role role-id-value)
  (.o (kind 'role) (id role-id-value)))

(def (poo-flow-organization-agent agent-id-value principal-id-value role-id-value
                                  parent-id-value authorities-value
                                  context-visible-value)
  (.o (kind 'agent)
      (id agent-id-value)
      (principal-id principal-id-value)
      (role-id role-id-value)
      (parent-id parent-id-value)
      (authorities authorities-value)
      (context-visible context-visible-value)))

(def (poo-flow-organization-capability capability-id-value delegable-value?)
  (.o (kind 'capability)
      (id capability-id-value)
      (delegable? delegable-value?)))

(def (poo-flow-organization-delegation parent-id-value child-id-value
                                       capability-id-value)
  (.o (kind 'delegation)
      (id (list parent-id-value child-id-value capability-id-value))
      (parent-id parent-id-value)
      (child-id child-id-value)
      (capability-id capability-id-value)))

(def (poo-flow-organization-context-projection agent-id-value visible-value)
  (.o (kind 'context-projection)
      (id agent-id-value)
      (agent-id agent-id-value)
      (visible visible-value)))

(def (poo-flow-organization-tool-effect effect-id-value capability-id-value
                                        effect-kind-value)
  (.o (kind 'tool-effect)
      (id effect-id-value)
      (capability-id capability-id-value)
      (effect-kind effect-kind-value)))

(def (poo-flow-organization-protocol-transition transition-id-value
                                                participants-value
                                                capability-id-value)
  (.o (kind 'protocol-transition)
      (id transition-id-value)
      (participants participants-value)
      (capability-id capability-id-value)))

(def (poo-flow-organization-evidence-obligation obligation-id-value
                                                subject-id-value
                                                target-kind-value
                                                target-id-value)
  (.o (kind 'evidence-obligation)
      (id obligation-id-value)
      (subject-id subject-id-value)
      (target-kind target-kind-value)
      (target-id target-id-value)))

(def (poo-flow-organization-facet facet-name-value entities-value relations-value
                                  constraints-value)
  (.o (kind (case facet-name-value
              ((organization) 'poo-flow.organization-facet.organization)
              ((authority) 'poo-flow.organization-facet.authority)
              ((context) 'poo-flow.organization-facet.context)
              ((protocol) 'poo-flow.organization-facet.protocol)
              ((evidence) 'poo-flow.organization-facet.evidence)
              (else (error "unknown organization facet" facet-name-value))))
      (schema +poo-flow-organization-facet-schema+)
      (facet-name facet-name-value)
      (entities entities-value)
      (relations relations-value)
      (constraints constraints-value)))

(def (poo-flow-organization-organization-facet entities . rest)
  (poo-flow-organization-facet 'organization entities
                               (if (pair? rest) (car rest) '())
                               (if (and (pair? rest) (pair? (cdr rest)))
                                 (cadr rest) '())))
(def (poo-flow-organization-authority-facet entities relations . constraints)
  (poo-flow-organization-facet 'authority entities relations
                               (if (pair? constraints) (car constraints) '())))
(def (poo-flow-organization-context-facet entities . constraints)
  (poo-flow-organization-facet 'context entities '()
                               (if (pair? constraints) (car constraints) '())))
(def (poo-flow-organization-protocol-facet entities relations . constraints)
  (poo-flow-organization-facet 'protocol entities relations
                               (if (pair? constraints) (car constraints) '())))
(def (poo-flow-organization-evidence-facet entities relations . constraints)
  (poo-flow-organization-facet 'evidence entities relations
                               (if (pair? constraints) (car constraints) '())))
(def (poo-flow-organization-empty-organization-facet)
  (poo-flow-organization-organization-facet '()))
(def (poo-flow-organization-empty-authority-facet)
  (poo-flow-organization-authority-facet '() '()))
(def (poo-flow-organization-empty-context-facet)
  (poo-flow-organization-context-facet '()))
(def (poo-flow-organization-empty-protocol-facet)
  (poo-flow-organization-protocol-facet '() '()))
(def (poo-flow-organization-empty-evidence-facet)
  (poo-flow-organization-evidence-facet '() '()))

(def (poo-flow-organization-bundle epoch-value organization-value authority-value
                                   context-value protocol-value evidence-value)
  (.o (kind +poo-flow-organization-bundle-schema+)
      (epoch epoch-value)
      (organization organization-value)
      (authority authority-value)
      (context context-value)
      (protocol protocol-value)
      (evidence evidence-value)))

(def (poo-flow-organization-object? value expected-kind)
  (and (object? value)
       (with-catch
        (lambda (_failure) #f)
        (lambda () (eq? (.ref value 'kind) expected-kind)))))

(def (poo-flow-organization-bundle? value)
  (poo-flow-organization-object? value +poo-flow-organization-bundle-schema+))

(def (poo-flow-organization-object-id value)
  (.ref value 'id))

(def (semantic-id-string value)
  (cond
   ((symbol? value) (symbol->string value))
   ((string? value) value)
   (else
    (let (port (open-output-string))
      (write value port)
      (get-output-string port)))))

(def (semantic-object<? left right)
  (string<? (semantic-id-string (poo-flow-organization-object-id left))
            (semantic-id-string (poo-flow-organization-object-id right))))

(def (semantic-sort objects)
  (sort (append objects '()) semantic-object<?))

(def (semantic-symbol-sort values)
  (sort (append values '())
        (lambda (left right)
          (string<? (semantic-id-string left) (semantic-id-string right)))))

(def (principal->canonical value)
  (list 'principal (poo-flow-organization-object-id value)))

(def (role->canonical value)
  (list 'role (poo-flow-organization-object-id value)))

(def (agent->canonical value)
  (list 'agent
        (poo-flow-organization-object-id value)
        (list 'principal (.ref value 'principal-id))
        (list 'role (.ref value 'role-id))
        (list 'parent (.ref value 'parent-id))
        (cons 'authorities (semantic-symbol-sort (.ref value 'authorities)))
        (cons 'context-visible
              (semantic-symbol-sort (.ref value 'context-visible)))))

(def (capability->canonical value)
  (list 'capability
        (poo-flow-organization-object-id value)
        (list 'delegable? (.ref value 'delegable?))))

(def (delegation->canonical value)
  (list 'delegation
        (list 'parent (.ref value 'parent-id))
        (list 'child (.ref value 'child-id))
        (list 'capability (.ref value 'capability-id))))

(def (context-projection->canonical value)
  (list 'context-projection
        (list 'agent (.ref value 'agent-id))
        (cons 'visible (semantic-symbol-sort (.ref value 'visible)))))

(def (tool-effect->canonical value)
  (list 'tool-effect
        (poo-flow-organization-object-id value)
        (list 'capability (.ref value 'capability-id))
        (list 'effect-kind (.ref value 'effect-kind))))
(def (protocol-transition->canonical value)
  (list 'protocol-transition (poo-flow-organization-object-id value)
        (cons 'participants (semantic-symbol-sort (.ref value 'participants)))
        (list 'capability (.ref value 'capability-id))))
(def (evidence-obligation->canonical value)
  (list 'evidence-obligation (poo-flow-organization-object-id value)
        (list 'subject (.ref value 'subject-id))
        (list 'target-kind (.ref value 'target-kind))
        (list 'target (.ref value 'target-id))))

(def (semantic-kind=? value kind)
  (and (object? value)
       (with-catch (lambda (_failure) #f)
                   (lambda () (eq? (.ref value 'kind) kind)))))
(def (facet-entities facet kind)
  (filter (lambda (value) (semantic-kind=? value kind))
          (.ref facet 'entities)))
(def (facet-relations facet kind)
  (filter (lambda (value) (semantic-kind=? value kind))
          (.ref facet 'relations)))
(def (facet->canonical facet)
  (list (.ref facet 'facet-name)
        (list 'schema (.ref facet 'schema))
        (cons 'entities
              (map (lambda (value)
                     (case (.ref value 'kind)
                       ((principal) (principal->canonical value))
                       ((role) (role->canonical value))
                       ((agent) (agent->canonical value))
                       ((capability) (capability->canonical value))
                       ((context-projection) (context-projection->canonical value))
                       ((tool-effect) (tool-effect->canonical value))
                       ((protocol-transition) (protocol-transition->canonical value))
                       ((evidence-obligation) (evidence-obligation->canonical value))
                       (else (error "unsupported facet entity" value))))
                   (semantic-sort (.ref facet 'entities))))
        (cons 'relations
              (map (lambda (value)
                     (case (.ref value 'kind)
                       ((delegation) (delegation->canonical value))
                       (else (error "unsupported facet relation" value))))
                   (semantic-sort (.ref facet 'relations))))
        (cons 'constraints (semantic-symbol-sort (.ref facet 'constraints)))))

(def (poo-flow-organization-bundle-normalize/object bundle)
  (unless (poo-flow-organization-bundle? bundle)
    (error "expected POO organization Bundle" bundle))
  (list +poo-flow-organization-bundle-schema+
        (list 'epoch (.ref bundle 'epoch))
        (facet->canonical (.ref bundle 'organization))
        (facet->canonical (.ref bundle 'authority))
        (facet->canonical (.ref bundle 'context))
        (facet->canonical (.ref bundle 'protocol))
        (facet->canonical (.ref bundle 'evidence))
        '(outcomes start allow deny timeout retry cancellation checkpoint
                   restore stale-epoch evidence)))

(def (poo-flow-organization-bundle-normalize bundle)
  (if (and (pair? bundle)
           (eq? (car bundle) +poo-flow-organization-bundle-schema+))
    (begin
      (unless (stable-semantic-value? bundle)
        (error "canonical Bundle contains unstable values" bundle))
      bundle)
    (poo-flow-organization-bundle-normalize/object bundle)))

(def (poo-flow-organization-canonical->string canonical)
  (let (port (open-output-string))
    (write canonical port)
    (get-output-string port)))

(def (poo-flow-organization-digest canonical . maybe-algorithm)
  (let (algorithm (if (pair? maybe-algorithm)
                     (car maybe-algorithm)
                     +poo-flow-organization-bundle-digest-algorithm+))
    (case algorithm
      ((sha256)
       (hex-encode
        (sha256 (poo-flow-organization-canonical->string canonical))))
      (else (error "unsupported Bundle digest algorithm" algorithm)))))

(def (poo-flow-organization-bundle-identity bundle)
  (let* ((canonical (poo-flow-organization-bundle-normalize bundle))
         (digest-value (poo-flow-organization-digest canonical)))
    (.o (kind 'poo-flow.organization-bundle.identity.v1)
        (algorithm +poo-flow-organization-bundle-digest-algorithm+)
        (digest digest-value)
        (epoch (.ref bundle 'epoch)))))

(def (poo-flow-organization-bundle-identity->alist identity)
  (list (cons 'algorithm (.ref identity 'algorithm))
        (cons 'digest (.ref identity 'digest))
        (cons 'epoch (.ref identity 'epoch))))

(def (stable-semantic-value? value)
  (cond
   ((or (null? value) (symbol? value) (string? value)
        (boolean? value) (number? value)) #t)
   ((pair? value)
    (and (stable-semantic-value? (car value))
         (stable-semantic-value? (cdr value))))
   (else #f)))

(def (semantic-find id objects)
  (find (lambda (value) (equal? id (poo-flow-organization-object-id value)))
        objects))

(def (semantic-duplicate-ids objects)
  (let loop ((rest (semantic-sort objects)) (previous #f) (duplicates '()))
    (if (null? rest)
      (reverse duplicates)
      (let (id (poo-flow-organization-object-id (car rest)))
        (loop (cdr rest)
              id
              (if (and previous (equal? previous id))
                (cons id duplicates)
                duplicates))))))

(def (semantic-subset? child parent)
  (andmap (lambda (value) (member value parent)) child))

(def (semantic-unique-count values)
  (let loop ((rest values) (seen '()))
    (if (null? rest)
      (length seen)
      (loop (cdr rest)
            (if (member (car rest) seen)
              seen
              (cons (car rest) seen))))))

(def (semantic-proper-subset? child parent)
  (and (semantic-subset? child parent)
       (< (semantic-unique-count child)
          (semantic-unique-count parent))))

(def (diagnostic code path expected observed)
  (list (cons 'code code)
        (cons 'path path)
        (cons 'expected expected)
        (cons 'observed observed)))

(def (poo-flow-organization-bundle-validate/unsafe bundle . maybe-identity)
  (let* ((organization (.ref bundle 'organization))
         (authority (.ref bundle 'authority))
         (context-facet (.ref bundle 'context))
         (protocol (.ref bundle 'protocol))
         (evidence (.ref bundle 'evidence))
         (principals (facet-entities organization 'principal))
         (roles (facet-entities organization 'role))
         (agents (facet-entities organization 'agent))
         (capabilities (facet-entities authority 'capability))
         (delegations (facet-relations authority 'delegation))
         (contexts (facet-entities context-facet 'context-projection))
         (effects (facet-entities protocol 'tool-effect))
         (transitions (facet-entities protocol 'protocol-transition))
         (obligations (facet-entities evidence 'evidence-obligation))
         (epoch (.ref bundle 'epoch))
         (identity-value (if (pair? maybe-identity)
                           (car maybe-identity)
                           (poo-flow-organization-bundle-identity bundle)))
         (diagnostic-values '()))
    (def (reject! code path expected observed)
      (set! diagnostic-values
            (append diagnostic-values
                    (list (diagnostic code path expected observed)))))
    (for-each
     (lambda (entry)
       (let ((name (car entry)) (facet (cdr entry)))
         (unless (and (object? facet)
                      (eq? (.ref facet 'schema)
                           +poo-flow-organization-facet-schema+)
                      (eq? (.ref facet 'facet-name) name))
           (reject! 'invalid-facet (list 'facets name)
                    'typed-facet 'invalid))))
     (list (cons 'organization organization) (cons 'authority authority)
           (cons 'context context-facet) (cons 'protocol protocol)
           (cons 'evidence evidence)))
    (unless (and (integer? epoch) (>= epoch 0))
      (reject! 'invalid-epoch '(epoch) 'nonnegative-integer 'invalid))
    (for-each
     (lambda (entry)
       (let ((label (car entry)) (values (cdr entry)))
         (when (null? values)
           (reject! 'missing-members (list label) 'nonempty 'empty))
         (for-each
          (lambda (id)
            (reject! 'duplicate-identity (list label id) 'unique 'duplicate))
          (semantic-duplicate-ids values))))
     (list (cons 'principals principals)
           (cons 'roles roles)
           (cons 'agents agents)
           (cons 'capabilities capabilities)
           (cons 'context-projections contexts)
           (cons 'tool-effects effects)))
    (let ((identity-entities
           (append principals roles agents capabilities effects
                   transitions obligations)))
      (for-each
       (lambda (id)
         (let ((kinds (map (lambda (value) (.ref value 'kind))
                           (filter (lambda (value)
                                     (equal? (.ref value 'id) id))
                                   identity-entities))))
           (when (> (semantic-unique-count kinds) 1)
             (reject! 'incompatible-shared-identity
                      (list 'identity-universe id) 'one-kind kinds))))
       (semantic-duplicate-ids identity-entities)))
    (for-each
     (lambda (agent)
       (let ((agent-id (.ref agent 'id))
             (principal-id (.ref agent 'principal-id))
             (role-id (.ref agent 'role-id)))
         (unless (semantic-find principal-id principals)
           (reject! 'missing-principal (list 'agents agent-id 'principal)
                    'declared principal-id))
         (unless (semantic-find role-id roles)
           (reject! 'missing-role (list 'agents agent-id 'role)
                    'declared role-id))))
     agents)
    (let* ((roots (filter (lambda (agent) (not (.ref agent 'parent-id))) agents))
           (children (filter (lambda (agent) (.ref agent 'parent-id)) agents)))
      (unless (= (length roots) 1)
        (reject! 'invalid-root-count '(agents) 1 (length roots)))
      (unless (= (length children) 1)
        (reject! 'invalid-child-count '(agents) 1 (length children)))
      (when (and (= (length roots) 1) (= (length children) 1))
        (let* ((parent (car roots))
               (child (car children))
               (parent-id (.ref parent 'id))
               (child-id (.ref child 'id))
               (parent-authority (.ref parent 'authorities))
               (child-authority (.ref child 'authorities))
               (context (semantic-find child-id contexts)))
          (unless (equal? (.ref child 'parent-id) parent-id)
            (reject! 'invalid-parent-binding (list 'agents child-id 'parent)
                     parent-id (.ref child 'parent-id)))
          (unless (semantic-proper-subset? child-authority parent-authority)
            (reject! 'authority-not-strict-subset
                     (list 'agents child-id 'authorities)
                     'strict-subset child-authority))
          (unless context
            (reject! 'missing-context-projection
                     (list 'context-projections child-id) 'declared 'missing))
          (when (and context
                     (not (semantic-subset? (.ref context 'visible)
                                            (.ref parent 'context-visible))))
            (reject! 'context-visibility-leak
                     (list 'context-projections child-id 'visible)
                     'parent-visible-subset (.ref context 'visible)))
          (for-each
           (lambda (authority)
             (let (delegation
                   (find (lambda (value)
                           (and (equal? (.ref value 'parent-id) parent-id)
                                (equal? (.ref value 'child-id) child-id)
                                (equal? (.ref value 'capability-id) authority)))
                         delegations))
               (unless delegation
                 (reject! 'undelegated-authority
                          (list 'agents child-id 'authorities authority)
                          'explicit-delegation 'missing))))
           child-authority))))
    (for-each
     (lambda (effect)
       (let* ((effect-id (.ref effect 'id))
              (capability-id (.ref effect 'capability-id))
              (capability (semantic-find capability-id capabilities)))
         (unless capability
           (reject! 'undeclared-tool-effect
                    (list 'tool-effects effect-id 'capability)
                    'declared capability-id))))
     effects)
    (for-each
     (lambda (transition)
       (let ((transition-id (.ref transition 'id))
             (capability-id (.ref transition 'capability-id)))
         (for-each
          (lambda (participant)
            (unless (semantic-find participant agents)
              (reject! 'missing-protocol-participant
                       (list 'protocol transition-id 'participants participant)
                       'declared-agent participant)))
          (.ref transition 'participants))
         (unless (semantic-find capability-id capabilities)
           (reject! 'unauthorized-protocol-capability
                    (list 'protocol transition-id 'capability)
                    'declared-capability capability-id))))
     transitions)
    (for-each
     (lambda (obligation)
       (let ((obligation-id (.ref obligation 'id))
             (subject-id (.ref obligation 'subject-id))
             (target-kind (.ref obligation 'target-kind))
             (target-id (.ref obligation 'target-id)))
         (unless (semantic-find subject-id agents)
           (reject! 'missing-evidence-subject
                    (list 'evidence obligation-id 'subject)
                    'declared-agent subject-id))
         (unless
          (case target-kind
            ((transition) (semantic-find target-id transitions))
            ((effect) (semantic-find target-id effects))
            ((subject) (semantic-find target-id agents))
            (else #f))
          (reject! 'missing-evidence-target
                   (list 'evidence obligation-id 'target)
                   target-kind target-id))))
     obligations)
    (unless (stable-semantic-value?
             (poo-flow-organization-bundle-normalize bundle))
      (reject! 'unstable-semantic-value '(bundle) 'canonical 'unstable))
    (let (computed (poo-flow-organization-bundle-identity bundle))
      (unless (and (eq? (.ref identity-value 'algorithm)
                        +poo-flow-organization-bundle-digest-algorithm+)
                   (equal? (.ref identity-value 'digest) (.ref computed 'digest))
                   (equal? (.ref identity-value 'epoch) epoch))
        (reject! 'bundle-identity-mismatch '(identity)
                 (poo-flow-organization-bundle-identity->alist computed)
                 (poo-flow-organization-bundle-identity->alist identity-value))))
    (.o (kind 'poo-flow.organization-bundle.validation-receipt.v1)
        (identity identity-value)
        (accepted? (null? diagnostic-values))
        (diagnostics diagnostic-values))))

(def (poo-flow-organization-bundle-validate bundle . maybe-identity)
  (with-catch
   (lambda (_failure)
     (.o (kind 'poo-flow.organization-bundle.validation-receipt.v1)
         (identity #f)
         (accepted? #f)
         (diagnostics
          (list (diagnostic 'unstable-semantic-value
                            '(bundle)
                            'canonical
                            'unstable)))))
   (lambda ()
     (apply poo-flow-organization-bundle-validate/unsafe
            bundle
            maybe-identity))))

(def (poo-flow-organization-validation-accepted? receipt)
  (.ref receipt 'accepted?))

(def (poo-flow-organization-validation-diagnostics receipt)
  (.ref receipt 'diagnostics))
