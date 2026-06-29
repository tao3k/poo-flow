;;; -*- Gerbil -*-
;;; Boundary: lightweight module entrypoint registry.
;;; Invariant: this owner is data-only; it never imports loaders, resolvers, or POO graphs.

(import :poo-flow/src/module-system/source)

(export poo-flow-module-tree-entrypoint
        poo-flow-module-tree-source
        poo-flow-module-tree-config-source
        poo-flow-module-tree-objects-source
        poo-flow-module-tree-source-refs
        poo-flow-src-modules-root
        poo-flow-src-module-tree-entrypoints
        poo-flow-module-system-source
        poo-flow-module-system-source-refs
        poo-flow-module-category-names
        poo-flow-module-tree-entrypoint-module-name
        poo-flow-module-tree-entrypoint-name-conflict?
        poo-flow-module-tree-entrypoint-conflicts
        poo-flow-src-module-tree-entrypoint-conflicts
        poo-flow-src-modules-source-refs
        poo-flow-user-tree-source
        poo-flow-user-tree-entrypoint-policy
        poo-flow-user-tree-source-allowed-responsibilities
        poo-flow-user-tree-source-denied-responsibilities
        poo-flow-user-tree-source-allows?
        poo-flow-user-tree-source-policy-violations
        poo-flow-user-tree-source-valid?
        poo-flow-user-tree-init-source
        poo-flow-user-tree-objects-source
        poo-flow-user-tree-config-source
        poo-flow-user-tree-modules-config-source
        poo-flow-user-tree-source-refs)

;;; Boundary: tree entrypoints are source metadata, not filesystem reads.
;; : (-> Path Symbol Path)
(def (poo-flow-module-tree-entrypoint module-root-path entrypoint-role)
  (let* ((leaf (string-append (symbol->string entrypoint-role) ".ss"))
         (path-length (string-length module-root-path)))
    (if (and (> path-length 0)
             (char=? (string-ref module-root-path (- path-length 1)) #\/))
      (string-append module-root-path leaf)
      (string-append module-root-path "/" leaf))))

;;; Boundary: a module tree contributes separate config and objects entrypoints.
;; : (-> Path Symbol PooModuleSourceRef)
(def (poo-flow-module-tree-source module-root-path entrypoint-role)
  (let (entrypoint
        (poo-flow-module-tree-entrypoint module-root-path entrypoint-role))
    (make-poo-flow-module-source-ref
     'local
     entrypoint
     (list (cons 'kind 'module-tree)
           (cons 'module-tree-root module-root-path)
           (cons 'entrypoint entrypoint)
           (cons 'entrypoint-role entrypoint-role)))))

;; : (-> Path PooModuleSourceRef)
(def (poo-flow-module-tree-config-source module-root-path)
  (poo-flow-module-tree-source module-root-path 'config))

;; : (-> Path PooModuleSourceRef)
(def (poo-flow-module-tree-objects-source module-root-path)
  (poo-flow-module-tree-source module-root-path 'objects))

;; : (-> Path [PooModuleSourceRef])
(def (poo-flow-module-tree-source-refs module-root-path)
  (list (poo-flow-module-tree-config-source module-root-path)
        (poo-flow-module-tree-objects-source module-root-path)))

;;; Boundary: src/modules is a declared package module tree, not a filesystem scan root.
;; : Path
(def poo-flow-src-modules-root "src/modules")

;;; Boundary: each entry names module-tree entrypoints that exist under src/modules.
;; : [(Path Symbol...)]
(def poo-flow-src-module-tree-entrypoints
  '(("agent-sandbox" config)
    ("cubeSandbox" objects config)
    ("sandbox-core" objects)
    ("funflow" config)
    ("loop-governor" config)
    ("nono-sandbox" objects config)
    ("workflow" flows syntax)))

;;; Boundary: module-system source refs are internal package owners, not
;;; user-interface modules. They stay explicit so the loader never scans src.
;; : (-> Symbol Path PooModuleSourceRef)
(def (poo-flow-module-system-source entrypoint-role entrypoint-path)
  (let (entrypoint
        (string-append "src/module-system/" entrypoint-path))
    (make-poo-flow-module-source-ref
     'local
     entrypoint
     (list (cons 'kind 'module-system)
           (cons 'module-system-root "src/module-system")
           (cons 'entrypoint entrypoint)
           (cons 'entrypoint-role entrypoint-role)))))

;; : (-> Unit [PooModuleSourceRef])
(def (poo-flow-module-system-source-refs)
  (list
   (poo-flow-module-system-source 'profile-config "profile-config.ss")
   (poo-flow-module-system-source 'init-syntax "init-syntax.ss")
   (poo-flow-module-system-source 'root-profile "root-profile.ss")
   (poo-flow-module-system-source 'declaration-case "declaration-case.ss")))

;;; Boundary: category names are registry-owned because module trees, developer
;;; object trees, and user trees all pass through the same naming constraints.
;; : [Symbol]
(def poo-flow-module-category-names
  '(modules flow loop sandbox custom))

;;; Boundary: module registry member predicate is the policy-visible edge for
;;; module-system behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> PooModuleRegistryValue [PooModuleRegistryValue] Boolean)
(def (poo-flow-module-registry-member? value values)
  (cond ((null? values) #f)
        ((equal? value (car values)) #t)
        (else (poo-flow-module-registry-member? value (cdr values)))))

;;; Boundary: module registry alist ref default is the policy-visible edge for
;;; module-system behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> PooModuleRegistryMetadata Symbol PooModuleRegistryMetadataValue PooModuleRegistryMetadataValue)
(def (poo-flow-module-registry-alist-ref/default entries key default-value)
  (let (entry (assoc key entries))
    (if entry (cdr entry) default-value)))

;; : (-> (Path Symbol...) Symbol)
(def (poo-flow-module-tree-entrypoint-module-name entrypoint-spec)
  (string->symbol (car entrypoint-spec)))

;; : (-> (Path Symbol...) Boolean)
(def (poo-flow-module-tree-entrypoint-name-conflict? entrypoint-spec)
  (poo-flow-module-registry-member?
   (poo-flow-module-tree-entrypoint-module-name entrypoint-spec)
   poo-flow-module-category-names))

;;; Conflict receipts are data so doctors can report naming drift without
;;; forcing source loading or descriptor realization.
;; : (-> [(Path Symbol...)] [Alist])
(def (poo-flow-module-tree-entrypoint-conflicts entrypoint-specs)
  (cond
   ((null? entrypoint-specs) '())
   ((poo-flow-module-tree-entrypoint-name-conflict? (car entrypoint-specs))
    (cons
     (list (cons 'code 'module-category-name-conflict)
           (cons 'module-name
                 (poo-flow-module-tree-entrypoint-module-name
                  (car entrypoint-specs)))
           (cons 'module-root (car (car entrypoint-specs)))
           (cons 'categories poo-flow-module-category-names))
     (poo-flow-module-tree-entrypoint-conflicts (cdr entrypoint-specs))))
   (else
    (poo-flow-module-tree-entrypoint-conflicts (cdr entrypoint-specs)))))

;; : (-> Unit [Alist])
(def (poo-flow-src-module-tree-entrypoint-conflicts)
  (poo-flow-module-tree-entrypoint-conflicts
   poo-flow-src-module-tree-entrypoints))

;;; Internal path join stays string-only so this owner never probes the filesystem.
;; : (-> Path Path)
(def (poo-flow-src-module-tree-root module-name)
  (string-append poo-flow-src-modules-root "/" module-name))

;;; Internal expansion keeps module entrypoints ordered for stable diagnostics.
;; : (-> (Path Symbol...) [PooModuleSourceRef])
(def (poo-flow-src-module-tree-entrypoint-source-refs entrypoint-spec)
  (let ((module-root
         (poo-flow-src-module-tree-root (car entrypoint-spec)))
        (entrypoint-roles (cdr entrypoint-spec)))
    (map (lambda (entrypoint-role)
           (poo-flow-module-tree-source module-root entrypoint-role))
         entrypoint-roles)))

;;; Internal recursion flattens the declared tree without forcing source loads.
;; : (-> [(Path Symbol...)] [PooModuleSourceRef])
(def (poo-flow-src-module-tree-entrypoint-source-refs* entrypoint-specs)
  (if (null? entrypoint-specs)
    '()
    (append
     (poo-flow-src-module-tree-entrypoint-source-refs
      (car entrypoint-specs))
     (poo-flow-src-module-tree-entrypoint-source-refs*
      (cdr entrypoint-specs)))))

;;; Boundary: upstream module sources are declared and lazy by default.
;; : (-> [PooModuleSourceRef])
(def (poo-flow-src-modules-source-refs)
  (append
   (poo-flow-src-module-tree-entrypoint-source-refs*
    poo-flow-src-module-tree-entrypoints)
   (poo-flow-module-system-source-refs)))

;;; Boundary: user-root trees have a different shape from upstream modules.
;; : (-> Path Symbol Path Path)
(def (poo-flow-user-tree-entrypoint user-root-path entrypoint-role entrypoint-path)
  (let (path-length (string-length user-root-path))
    (if (and (> path-length 0)
             (char=? (string-ref user-root-path (- path-length 1)) #\/))
      (string-append user-root-path entrypoint-path)
      (string-append user-root-path "/" entrypoint-path))))

;;; Boundary: entrypoint policy is data so loaders and tools can reject misuse.
;; : (-> Symbol Alist)
(def (poo-flow-user-tree-entrypoint-policy entrypoint-role)
  (cond
   ((eq? entrypoint-role 'init)
    '((policy . init-switches-only)
      (allowed-responsibilities
       . (profile-selection module-switch feature-switch
          module-category-switch custom-module-switch))
      (denied-responsibilities
       . (object-contract field-contract sandbox-profile-recipe settings
          package-sync descriptor-realization runtime-execution facade-export))))
   ((eq? entrypoint-role 'objects)
    '((policy . objects-and-contracts-only)
      (allowed-responsibilities
       . (poo-object object-contract field-contract object-inheritance
          object-extension))
      (denied-responsibilities
       . (sandbox-profile-recipe profile-selection module-switch feature-switch
          settings package-sync descriptor-realization runtime-execution
          facade-export))))
   ((eq? entrypoint-role 'config)
    '((policy . tool-facing-facade-only)
      (allowed-responsibilities
       . (facade-export inspection-helper presentation-helper))
      (denied-responsibilities
       . (module-switch feature-switch object-contract field-contract
          package-sync descriptor-realization runtime-execution))))
   ((eq? entrypoint-role 'modules-config)
    '((policy . user-module-helper-only)
      (allowed-responsibilities
       . (configuration-helper syntax-helper module-helper))
      (denied-responsibilities
       . (module-switch feature-switch object-contract package-sync
          descriptor-realization runtime-execution))))
   (else
    '((policy . unknown-entrypoint)
      (allowed-responsibilities . ())
      (denied-responsibilities . (runtime-execution package-sync))))))

;;; Boundary: user-root source refs cover init/config/objects and modules helpers.
;; : (-> Path Symbol Path PooModuleSourceRef)
(def (poo-flow-user-tree-source user-root-path entrypoint-role entrypoint-path)
  (let* ((entrypoint
          (poo-flow-user-tree-entrypoint user-root-path
                                         entrypoint-role
                                         entrypoint-path))
         (policy
          (poo-flow-user-tree-entrypoint-policy entrypoint-role)))
    (make-poo-flow-module-source-ref
     'local
     entrypoint
     (append
      (list (cons 'kind 'user-tree)
            (cons 'user-tree-root user-root-path)
            (cons 'entrypoint entrypoint)
            (cons 'entrypoint-role entrypoint-role))
      policy))))

;; : (-> PooModuleSourceRef [Symbol])
(def (poo-flow-user-tree-source-allowed-responsibilities source-ref)
  (poo-flow-module-registry-alist-ref/default
   (poo-flow-module-source-ref-metadata source-ref)
   'allowed-responsibilities
   '()))

;; : (-> PooModuleSourceRef [Symbol])
(def (poo-flow-user-tree-source-denied-responsibilities source-ref)
  (poo-flow-module-registry-alist-ref/default
   (poo-flow-module-source-ref-metadata source-ref)
   'denied-responsibilities
   '()))

;; : (-> PooModuleSourceRef Symbol Boolean)
(def (poo-flow-user-tree-source-allows? source-ref responsibility)
  (and
   (poo-flow-module-registry-member?
    responsibility
    (poo-flow-user-tree-source-allowed-responsibilities source-ref))
   (not
    (poo-flow-module-registry-member?
     responsibility
     (poo-flow-user-tree-source-denied-responsibilities source-ref)))))

;;; Boundary: user tree source policy violations is the policy-visible edge for
;;; module-system behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> PooModuleSourceRef [Symbol] [Symbol])
(def (poo-flow-user-tree-source-policy-violations source-ref responsibilities)
  (cond ((null? responsibilities) '())
        ((poo-flow-user-tree-source-allows? source-ref (car responsibilities))
         (poo-flow-user-tree-source-policy-violations source-ref
                                                     (cdr responsibilities)))
        (else
         (cons (car responsibilities)
               (poo-flow-user-tree-source-policy-violations
                source-ref
                (cdr responsibilities))))))

;; : (-> PooModuleSourceRef [Symbol] Boolean)
(def (poo-flow-user-tree-source-valid? source-ref responsibilities)
  (null? (poo-flow-user-tree-source-policy-violations source-ref
                                                      responsibilities)))

;; : (-> Path PooModuleSourceRef)
(def (poo-flow-user-tree-init-source user-root-path)
  (poo-flow-user-tree-source user-root-path 'init "init.ss"))

;; : (-> Path PooModuleSourceRef)
(def (poo-flow-user-tree-objects-source user-root-path)
  (poo-flow-user-tree-source user-root-path 'objects "objects.ss"))

;; : (-> Path PooModuleSourceRef)
(def (poo-flow-user-tree-config-source user-root-path)
  (poo-flow-user-tree-source user-root-path 'config "config.ss"))

;; : (-> Path PooModuleSourceRef)
(def (poo-flow-user-tree-modules-config-source user-root-path)
  (poo-flow-user-tree-source user-root-path
                             'modules-config
                             "modules/config.ss"))

;; : (-> Path [PooModuleSourceRef])
(def (poo-flow-user-tree-source-refs user-root-path)
  (list (poo-flow-user-tree-init-source user-root-path)
        (poo-flow-user-tree-objects-source user-root-path)
        (poo-flow-user-tree-config-source user-root-path)
        (poo-flow-user-tree-modules-config-source user-root-path)))
