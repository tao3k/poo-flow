(import :clan/poo/object
        :std/format
        (only-in :poo-flow/src/module-system/profile-composition-builders
                 poo-flow-profile-ref))

(export composition->typescript-string
        composition->typescript-file!)

(def (typescript-string value)
  (format "~s"
          (cond
           ((symbol? value) (symbol->string value))
           ((string? value) value)
           (else (format "~a" value)))))

(def (composition-ref object slot)
  (.ref object slot))

(def (composition-name composition)
  (composition-ref composition 'name))

(def (composition-stages composition)
  (composition-ref composition 'stages))

(def (composition-profile-bindings composition)
  (composition-ref composition 'profile-bindings))

(def (profile-binding-name binding)
  (composition-ref binding 'slot))

(def (module-binding-by-alias modules alias)
  (let loop ((rest modules))
    (cond
     ((null? rest) #f)
     ((eq? (composition-ref (car rest) 'alias) alias) (car rest))
     (else (loop (cdr rest))))))

(def (profile-by-binding modules binding)
  (let* ((alias (profile-binding-alias binding))
         (module-binding (module-binding-by-alias modules alias)))
    (unless module-binding
      (error "POO-FLOW-TS-E105 unresolved Profile module alias" alias))
    (let* ((module (composition-ref module-binding 'module))
           (profile
            (poo-flow-profile-ref module (profile-binding-name binding))))
      (unless profile
        (error "POO-FLOW-TS-E106 unresolved Profile binding"
               (profile-binding-name binding)))
      profile)))

(def (profile-binding-alias binding)
  (composition-ref binding 'alias))

(def (stage-name stage)
  (composition-ref stage 'name))

(def (stage-clauses stage)
  (composition-ref stage 'clauses))

(def (clause-kind clause)
  (composition-ref clause 'clause-kind))

(def (clause-payload clause)
  (composition-ref clause 'payload))

(def (stage-by-name stages name)
  (let loop ((rest stages))
    (cond
     ((null? rest) #f)
     ((eq? (stage-name (car rest)) name) (car rest))
     (else (loop (cdr rest))))))

(def (binding-by-name bindings name)
  (let loop ((rest bindings))
    (cond
     ((null? rest) #f)
     ((eq? (profile-binding-name (car rest)) name) (car rest))
     (else (loop (cdr rest))))))

(def (target-clause? kind)
  (or (eq? kind 'step) (eq? kind 'handoff)))

(def (stage-targets stage stages bindings)
  (let loop ((rest (stage-clauses stage)) (out '()))
    (if (null? rest)
      (reverse out)
      (let* ((clause (car rest))
             (kind (clause-kind clause)))
        (if (not (target-clause? kind))
          (loop (cdr rest) out)
          (let (payload (clause-payload clause))
            (unless (and (pair? payload)
                         (null? (cdr payload))
                         (symbol? (car payload)))
              (error
               "POO-FLOW-TS-E101 step and handoff require one symbolic target"
               (stage-name stage)
               kind
               payload))
            (let (target (car payload))
              (cond
               ((stage-by-name stages target)
                (loop (cdr rest) (cons (list 'case target kind) out)))
               ((binding-by-name bindings target)
                (loop (cdr rest) (cons (list 'profile target kind) out)))
               (else
                (error
                 "POO-FLOW-TS-E102 unknown Case or Profile target"
                 (stage-name stage)
                 kind
                 target))))))))))

(def (case-target-names stage stages bindings)
  (let loop ((rest (stage-targets stage stages bindings)) (out '()))
    (cond
     ((null? rest) (reverse out))
     ((eq? (caar rest) 'case)
      (loop (cdr rest) (cons (cadar rest) out)))
     (else (loop (cdr rest) out)))))

(def (referenced-case-names stages bindings)
  (let stage-loop ((rest stages) (out '()))
    (if (null? rest)
      out
      (let target-loop
          ((targets (case-target-names (car rest) stages bindings))
           (next out))
        (if (null? targets)
          (stage-loop (cdr rest) next)
          (target-loop
           (cdr targets)
           (if (memq (car targets) next)
             next
             (cons (car targets) next))))))))

(def (root-stage-names stages bindings)
  (let ((referenced (referenced-case-names stages bindings)))
    (let loop ((rest stages) (out '()))
      (cond
       ((null? rest) (reverse out))
       ((memq (stage-name (car rest)) referenced)
        (loop (cdr rest) out))
       (else
        (loop (cdr rest) (cons (stage-name (car rest)) out)))))))

;; Node = (id name kind parent-id source-id relation detail)
(def (projection-node
      id name kind parent-id source-id relation detail
      object-subtype scope capabilities)
  (list
   id name kind parent-id source-id relation detail
   object-subtype scope capabilities))

(def (node-id node) (list-ref node 0))
(def (node-name node) (list-ref node 1))
(def (node-kind node) (list-ref node 2))
(def (node-parent-id node) (list-ref node 3))
(def (node-source-id node) (list-ref node 4))
(def (node-relation node) (list-ref node 5))
(def (node-detail node) (list-ref node 6))
(def (node-object-subtype node) (list-ref node 7))
(def (node-scope node) (list-ref node 8))
(def (node-capabilities node) (list-ref node 9))

;; Edge = (source target label)
(def (projection-edge source target label)
  (list source target label))

(def (path-child path name)
  (string-append path "/" (symbol->string name)))

(def (case-instance-id path)
  (string-append "case:" path))

(def (profile-instance-id path name)
  (string-append "profile:" (path-child path name)))

(def (profile-source-id binding)
  (string-append
   "profile:"
   (symbol->string (profile-binding-alias binding))
   "/"
   (symbol->string (profile-binding-name binding))))

(def (build-case-instance
      stage-name-value path parent-id relation stages bindings modules active)
  (when (memq stage-name-value active)
    (error "POO-FLOW-TS-E103 recursive Case cycle"
           (reverse (cons stage-name-value active))))
  (let* ((stage (stage-by-name stages stage-name-value))
         (id (case-instance-id path))
         (case-node
          (projection-node
           id
           stage-name-value
           'case
           parent-id
           (string-append "case-definition:"
                          (symbol->string stage-name-value))
           relation
           "Reusable Case instance"
           #f #f '()))
         (targets (stage-targets stage stages bindings)))
    (let loop ((rest targets)
               (nodes (list case-node))
               (edges '()))
      (if (null? rest)
        (values nodes edges)
        (let* ((target (car rest))
               (target-kind (car target))
               (target-name (cadr target))
               (target-relation (caddr target)))
          (if (eq? target-kind 'case)
            (let* ((child-path (path-child path target-name))
                   (child-id (case-instance-id child-path)))
              (let-values
                  (((child-nodes child-edges)
                    (build-case-instance
                     target-name
                     child-path
                     id
                     target-relation
                     stages
                     bindings
                     modules
                     (cons stage-name-value active))))
                (loop
                 (cdr rest)
                 (append nodes child-nodes)
                 (append
                  edges
                  (list (projection-edge id child-id target-relation))
                  child-edges))))
            (let* ((binding (binding-by-name bindings target-name))
                   (profile (profile-by-binding modules binding))
                   (profile-id (profile-instance-id path target-name))
                   (profile-node
                    (projection-node
                     profile-id
                     target-name
                     'profile-instance
                     id
                     (profile-source-id binding)
                     target-relation
                     "Profile instance"
                     (poo-flow-profile-ref profile 'kind)
                     (poo-flow-profile-ref profile 'scope)
                     (poo-flow-profile-ref profile 'capabilities))))
              (loop
               (cdr rest)
               (append nodes (list profile-node))
               (append
                edges
                (list (projection-edge id profile-id target-relation)))))))))))

(def (composition-projection composition)
  (unless (eq? (composition-ref composition 'kind) 'poo-flow.composition)
    (error "POO-FLOW-TS-E100 expected poo-flow.composition" composition))
  (let* ((name (composition-name composition))
         (stages (composition-stages composition))
         (bindings (composition-profile-bindings composition))
         (modules (composition-ref composition 'modules))
         (root-id (string-append "composition:" (symbol->string name)))
         (root-node
          (projection-node
           root-id name 'composition #f
           (string-append "composition-definition:" (symbol->string name))
           'root
           "User Composition instance"
           #f #f '()))
         (roots (root-stage-names stages bindings)))
    (when (null? roots)
      (error "POO-FLOW-TS-E104 composition has no acyclic root Case" name))
    (let loop ((rest roots) (nodes (list root-node)) (edges '()))
      (if (null? rest)
        (values root-id nodes edges)
        (let* ((root-name (car rest))
               (root-path (symbol->string root-name))
               (case-id (case-instance-id root-path)))
          (let-values
              (((case-nodes case-edges)
                (build-case-instance
                 root-name root-path root-id 'compose
                 stages bindings modules '())))
            (loop
             (cdr rest)
             (append nodes case-nodes)
             (append
              edges
              (list (projection-edge root-id case-id 'compose))
              case-edges))))))))

(def (display-string-list values output)
  (display "[" output)
  (let loop ((rest values) (first? #t))
    (unless (null? rest)
      (unless first? (display ", " output))
      (display (typescript-string (car rest)) output)
      (loop (cdr rest) #f)))
  (display "]" output))

(def (display-typescript-node node ordinal output)
  (display "    { id: " output)
  (display (typescript-string (node-id node)) output)
  (display ", ordinal: " output)
  (display ordinal output)
  (display ", name: " output)
  (display (typescript-string (node-name node)) output)
  (display ", kind: " output)
  (display (typescript-string (node-kind node)) output)
  (display ", dependencies: " output)
  (display-string-list
   (if (node-parent-id node) (list (node-parent-id node)) '())
   output)
  (when (node-parent-id node)
    (display ", parentId: " output)
    (display (typescript-string (node-parent-id node)) output))
  (display ", sourceId: " output)
  (display (typescript-string (node-source-id node)) output)
  (display ", relation: " output)
  (display (typescript-string (node-relation node)) output)
  (display ", detail: " output)
  (display (typescript-string (node-detail node)) output)
  (when (node-object-subtype node)
    (display ", objectSubtype: " output)
    (display (typescript-string (node-object-subtype node)) output))
  (when (node-scope node)
    (display ", scope: " output)
    (display (typescript-string (node-scope node)) output))
  (when (eq? (node-kind node) 'profile-instance)
    (display ", capabilities: " output)
    (display-string-list (node-capabilities node) output))
  (display " },\n" output))

(def (display-typescript-edge edge output)
  (display "    { source: " output)
  (display (typescript-string (car edge)) output)
  (display ", target: " output)
  (display (typescript-string (cadr edge)) output)
  (display ", label: " output)
  (display (typescript-string (caddr edge)) output)
  (display " },\n" output))

(def (composition->typescript-string composition)
  (let (output (open-output-string))
    (let-values (((root-id nodes edges)
                  (composition-projection composition)))
      (display "// Generated from a POO Flow User Composition. Do not edit.\n" output)
      (display "export type WorkflowNodeKind = \"composition\" | \"case\" | \"profile-instance\";\n" output)
      (display "export type WorkflowStep = { readonly id: string; readonly ordinal: number; readonly name: string; readonly kind: WorkflowNodeKind; readonly dependencies: readonly string[]; readonly parentId?: string; readonly sourceId: string; readonly relation: string; readonly detail: string; readonly objectSubtype?: string; readonly scope?: string; readonly capabilities?: readonly string[] };\n" output)
      (display "export type WorkflowDefinition = { readonly id: string; readonly rootId: string; readonly steps: readonly WorkflowStep[]; readonly edges: readonly { readonly source: string; readonly target: string; readonly label: string }[] };\n\n" output)
      (display "export const workflow = {\n  id: " output)
      (display (typescript-string (composition-name composition)) output)
      (display ",\n  rootId: " output)
      (display (typescript-string root-id) output)
      (display ",\n  steps: [\n" output)
      (let loop ((rest nodes) (ordinal 1))
        (unless (null? rest)
          (display-typescript-node (car rest) ordinal output)
          (loop (cdr rest) (+ ordinal 1))))
      (display "  ],\n  edges: [\n" output)
      (for-each (lambda (edge) (display-typescript-edge edge output)) edges)
      (display "  ],\n} as const satisfies WorkflowDefinition;\n\n" output)
      (display "export const workflowTopology = new Uint32Array([1, " output)
      (display (length nodes) output)
      (display ", " output)
      (display (length edges) output)
      (display "]);\n" output)
      (get-output-string output))))

(def (composition->typescript-file! composition path)
  (call-with-output-file path
    (lambda (output)
      (display (composition->typescript-string composition) output))))
