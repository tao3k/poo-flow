(export #t)

(import :clan/poo/object
        :std/crypto/digest
        :std/sort
        :std/text/hex)

(def +poo-flow-organization-bundle-schema+
  'poo-flow.organization-bundle.v1)

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

(def (poo-flow-organization-bundle epoch-value principals-value roles-value
                                   agents-value capabilities-value
                                   delegations-value context-projections-value
                                   tool-effects-value)
  (.o (kind +poo-flow-organization-bundle-schema+)
      (epoch epoch-value)
      (principals principals-value)
      (roles roles-value)
      (agents agents-value)
      (capabilities capabilities-value)
      (delegations delegations-value)
      (context-projections context-projections-value)
      (tool-effects tool-effects-value)))

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

(def (poo-flow-organization-bundle-normalize/object bundle)
  (unless (poo-flow-organization-bundle? bundle)
    (error "expected POO organization Bundle" bundle))
  (list +poo-flow-organization-bundle-schema+
        (list 'epoch (.ref bundle 'epoch))
        (cons 'principals
              (map principal->canonical
                   (semantic-sort (.ref bundle 'principals))))
        (cons 'roles
              (map role->canonical
                   (semantic-sort (.ref bundle 'roles))))
        (cons 'agents
              (map agent->canonical
                   (semantic-sort (.ref bundle 'agents))))
        (cons 'capabilities
              (map capability->canonical
                   (semantic-sort (.ref bundle 'capabilities))))
        (cons 'delegations
              (map delegation->canonical
                   (semantic-sort (.ref bundle 'delegations))))
        (cons 'context-projections
              (map context-projection->canonical
                   (semantic-sort (.ref bundle 'context-projections))))
        (cons 'tool-effects
              (map tool-effect->canonical
                   (semantic-sort (.ref bundle 'tool-effects))))
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
  (let* ((principals (.ref bundle 'principals))
         (roles (.ref bundle 'roles))
         (agents (.ref bundle 'agents))
         (capabilities (.ref bundle 'capabilities))
         (delegations (.ref bundle 'delegations))
         (contexts (.ref bundle 'context-projections))
         (effects (.ref bundle 'tool-effects))
         (epoch (.ref bundle 'epoch))
         (identity-value (if (pair? maybe-identity)
                           (car maybe-identity)
                           (poo-flow-organization-bundle-identity bundle)))
         (diagnostic-values '()))
    (def (reject! code path expected observed)
      (set! diagnostic-values
            (append diagnostic-values
                    (list (diagnostic code path expected observed)))))
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
