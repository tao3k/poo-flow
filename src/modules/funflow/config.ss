;;; -*- Gerbil -*-
;;; Boundary: Funflow module configuration belongs to the Funflow module owner.
;;; Invariant: this file only declares maintained Funflow module rows.

(import :poo-flow/src/module-system/base
        :poo-flow/src/modules/workflow/cicd)

(export poo-flow-funflow-cicd-default-payload
        poo-flow-funflow-config-flags
        poo-flow-funflow-pipeline-config
        poo-flow-funflow-pipeline-check-config
        poo-flow-funflow-pipeline-runtime-command-manifests
        poo-flow-funflow-module-bundles
        poo-upstream-flow-funflow-module-bundles)

;;; The CI/CD payload is a Funflow feature, not a new top-level category. It is
;;; inspectable module data; adapters such as GitHub, Docker, or Nix stay out.
;; : UserModuleFlagEntry
(def poo-flow-funflow-cicd-default-payload
  '(+cicd
    (checks +parallel +typed-receipts)
    (artifacts +export)
    (release +manual-gate)
    (webhook +server)
    (runtime +manifest-handoff)))

;;; Pipeline clause parsing is intentionally shallow: Funflow owns the public
;;; syntax and check-map construction, while sandbox profile refs and runtime
;;; descriptors remain unresolved until later module/object validation.
;; : (-> String Boolean Value Void)
(def (poo-flow-funflow-require message ok? value)
  (if ok?
    (void)
    (error message value)))

;; : (-> Symbol List Value Value)
(def (poo-flow-funflow-plist-ref key clauses default)
  (cond
   ((null? clauses) default)
   ((not (pair? clauses)) default)
   ((eq? (car clauses) key)
    (if (pair? (cdr clauses))
      (cadr clauses)
      default))
   ((pair? (cdr clauses))
    (poo-flow-funflow-plist-ref key (cddr clauses) default))
   (else default)))

;; : (-> List Boolean)
(def (poo-flow-funflow-plist-shape? clauses)
  (cond
   ((null? clauses) #t)
   ((and (pair? clauses)
         (symbol? (car clauses))
         (pair? (cdr clauses)))
    (poo-flow-funflow-plist-shape? (cddr clauses)))
   (else #f)))

;;; Funflow `:needs` names other checks in the same pipeline. Object/profile
;;; inheritance stays in `:inherits` so the two extension axes do not blur.
;; : (-> [FunflowPipelineDependencyRefCandidate] Boolean)
(def (poo-flow-funflow-symbol-list? values)
  (cond
   ((null? values) #t)
   ((and (pair? values)
         (symbol? (car values)))
    (poo-flow-funflow-symbol-list? (cdr values)))
   (else #f)))

;; : (-> Value [Symbol])
(def (poo-flow-funflow-needs->refs needs)
  (cond
   ((not needs) '())
   ((symbol? needs) (list needs))
   ((list? needs)
    (poo-flow-funflow-require
     "funflow pipeline :needs list must contain only symbols"
     (poo-flow-funflow-symbol-list? needs)
     needs)
    needs)
   (else
    (error "funflow pipeline :needs must be a symbol or list" needs))))

;;; Check rows map directly to the shared workflow CI/CD object. The user-facing
;;; `:inherits` name is preserved as the profile-ref slot so future C3 profile
;;; resolution can compose one or many supers without this parser doing it.
;; : (-> FunflowPipelineCheckForm PooFlowCicdCheck)
(def (poo-flow-funflow-pipeline-check-config check-form)
  (poo-flow-funflow-require
   "funflow pipeline check must be (check name ...)"
   (and (pair? check-form)
        (eq? (car check-form) 'check)
        (pair? (cdr check-form))
        (symbol? (cadr check-form)))
   check-form)
  (let* ((name (cadr check-form))
         (clauses (cddr check-form))
         (dependency-refs
          (poo-flow-funflow-needs->refs
           (poo-flow-funflow-plist-ref ':needs clauses '()))))
    (poo-flow-funflow-require
     "funflow pipeline check clauses must be keyword/value pairs"
     (poo-flow-funflow-plist-shape? clauses)
     check-form)
    (poo-flow-cicd-check
     name
     (poo-flow-funflow-plist-ref ':inherits clauses #f)
     (poo-flow-funflow-plist-ref ':command clauses '())
     (poo-flow-funflow-plist-ref ':inputs clauses '())
     (poo-flow-funflow-plist-ref ':config clauses '())
     (poo-flow-funflow-plist-ref ':artifacts clauses '())
     (poo-flow-funflow-plist-ref ':cache clauses '())
     (poo-flow-funflow-plist-ref ':secrets clauses '())
     (poo-flow-funflow-plist-ref ':result clauses '())
     (poo-flow-funflow-plist-ref ':runtime clauses 'manifest-handoff)
     (list (cons 'source 'funflow-pipeline)
           (cons 'check name)
           (cons 'dependency-refs dependency-refs)))))

;; : (-> [FunflowPipelineCheckForm] [PooFlowCicdCheck])
(def (poo-flow-funflow-pipeline-checks checks)
  (cond
   ((null? checks) '())
   ((pair? checks)
    (cons (poo-flow-funflow-pipeline-check-config (car checks))
          (poo-flow-funflow-pipeline-checks (cdr checks))))
   (else
    (error "funflow pipeline checks must be a list" checks))))

;; : (-> Symbol [FunflowPipelineCheckForm] PooFlowCicdCheckMap)
(def (poo-flow-funflow-pipeline-config name checks . maybe-metadata)
  (poo-flow-cicd-check-map
   name
   (poo-flow-funflow-pipeline-checks checks)
   (if (null? maybe-metadata)
     (list (cons 'source 'funflow-config)
           (cons 'pipeline name))
     (car maybe-metadata))))

;;; Funflow owns the public pipeline object, while workflow/cicd owns the
;;; runtime-command manifest projection shape.
;; : (-> PooFlowCicdCheckMap [PooSandboxProfile] Alist)
(def (poo-flow-funflow-pipeline-runtime-command-manifests
      pipeline
      . maybe-profile-catalog)
  (if (null? maybe-profile-catalog)
    (poo-flow-cicd-check-map->runtime-command-manifests pipeline)
    (poo-flow-cicd-check-map->runtime-command-manifests
     pipeline
     (car maybe-profile-catalog))))

;;; Config flags carry both the normal Funflow feature vocabulary and the POO
;;; check-map object. This keeps `use-module` ergonomic while giving downstream
;;; tools a typed object to inspect before runtime handoff.
;; : (-> PooFlowCicdCheckMap Alist [UserModuleFlagEntry])
(def (poo-flow-funflow-config-flags pipeline user-config)
  (list '+functional
        '+dag
        '+typed-receipts
        '+runtime-manifest
        poo-flow-funflow-cicd-default-payload
        (cons ':config (list pipeline))
        (cons ':workflow-pipeline pipeline)
        (cons ':user-config user-config)))

;;; The Funflow module is the default functional DAG flow surface.
;; : (-> Unit [[PooUserModuleSelection]])
(def poo-flow-funflow-module-bundles
  (list
   (list
    (poo-flow-user-module-selection
     'flow
     'funflow
     (list '+functional
           '+dag
           '+typed-receipts
           '+runtime-manifest
           poo-flow-funflow-cicd-default-payload)))))

;; : (-> Unit [[PooUserModuleSelection]])
(def poo-upstream-flow-funflow-module-bundles
  poo-flow-funflow-module-bundles)
