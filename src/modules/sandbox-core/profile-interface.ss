;;; -*- Gerbil -*-
;;; Boundary: public POO-native sandbox profile authoring interface.
;;; Invariant: users write Gerbil POO objects; projection stays report-only.

(import :clan/poo/object
        :poo-flow/src/modules/sandbox-core/profile-support/projection-syntax)

(export #t
        (import: :clan/poo/object))

;; : (-> Unit NetworkPolicy)
(def (deny-network)
  '(deny-by-default))

;; : (-> String... NetworkPolicy)
(def (allowlisted-network . hosts)
  (cons 'allowlisted hosts))

;; : PooSandboxFilesystemPrototype
(def runtime-volume-filesystem
  (.o
  scope: 'volume
  materialized-by: 'runtime
  mounts: 'runtime))

;; : PooSandboxResourcesPrototype
(def runtime-volume-resources
  (.o
  filesystem: runtime-volume-filesystem
  cpu: 2
  memory: "4Gi"))

;; : PooSandboxFilesystemPrototype
(def readonly-project-workspace-filesystem
  (.o
  scope: 'project-workspace
  paths: '(((role . project-workspace)
            (source . ".")
            (project-marker . "gerbil.pkg")
            (target . "/workspace/project")
            (mode . read-only)))
  access: 'read-only))

;; : PooSandboxResourcesPrototype
(def readonly-project-workspace-resources
  (.o
  filesystem: readonly-project-workspace-filesystem
  cpu: 1
  memory: "1Gi"
  timeout-ms: 90000))

;; : PooSandboxFilesystemPrototype
(def readwrite-project-workspace-filesystem
  (.o
  scope: 'project-workspace
  paths: '(((role . project-workspace)
            (source . ".")
            (project-marker . "gerbil.pkg")
            (target . "/workspace/project")
            (mode . read-write)))
  access: 'read-write))

;; : PooSandboxResourcesPrototype
(def readwrite-project-workspace-resources
  (.o
  filesystem: readwrite-project-workspace-filesystem
  cpu: 2
  memory: "4Gi"
  timeout-ms: 300000))

;; : PooSandboxProfilePrototype
(def sandbox-profile
  (.o
  backend-kind: 'sandbox
  backend-ref: #f
  network: (deny-network)
  capabilities: '(process-run filesystem-read tmpdir)
  resources: runtime-volume-resources
  metadata: '((declared-by . poo-flow-poo-prototype)
              (runtime-executed . #f))))

;; : (-> Symbol [Symbol] Boolean)
(def (profile-metadata-remove-key? key keys)
  (and (member key keys) #t))

;;; Boundary: profile metadata without is the policy-visible edge for sandbox,
;;; core behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> Alist [Symbol] Alist Alist)
(def (profile-metadata-without/rev metadata keys result-rev)
  (cond
   ((null? metadata) result-rev)
   ((and (pair? (car metadata))
         (profile-metadata-remove-key? (caar metadata) keys))
    (profile-metadata-without/rev (cdr metadata) keys result-rev))
   (else
    (profile-metadata-without/rev
     (cdr metadata)
     keys
     (cons (car metadata) result-rev)))))

;; : (-> Alist [Symbol] Alist)
(def (profile-metadata-without metadata keys)
  (reverse (profile-metadata-without/rev metadata keys '())))

;;; Boundary: profile derivation path is the policy-visible edge for sandbox,
;;; core behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> Alist [Alist])
(def (profile-derivation-path metadata)
  (let (entry (assoc 'derivation-path metadata))
    (if (and entry (list? (cdr entry))) (cdr entry) '())))

;;; Boundary: profile derivation step is the policy-visible edge for sandbox,
;;; core behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> Symbol Symbol Symbol Value Alist)
(def (profile-derivation-step profile-name parent-profile scope scope-ref)
  (poo-flow-sandbox-profile-field-rows/tail
   (if scope-ref
     (poo-flow-sandbox-profile-field-rows (scope-ref scope-ref))
     '())
   (profile profile-name)
   (parent-profile parent-profile)
   (scope scope)
   (derived-by 'poo-native-profile-object)))

;;; Boundary: profile derivation metadata is the policy-visible edge for
;;; sandbox, core behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> Alist Symbol Symbol Symbol Value Alist... Alist)
(def (profile-derivation-metadata parent-metadata
                                  profile-name
                                  parent-profile
                                  scope
                                  scope-ref
                                  . maybe-extra)
  (let (extra (if (null? maybe-extra) '() (car maybe-extra)))
    (poo-flow-sandbox-profile-rows/tail
     (profile-metadata-without parent-metadata
                               '(derivation-path runtime-executed))
     (poo-flow-sandbox-profile-field-rows/tail
      extra
      (derivation-path
       (poo-flow-sandbox-profile-rows/tail
        (profile-derivation-path parent-metadata)
        (list
         (profile-derivation-step profile-name
                                  parent-profile
                                  scope
                                  scope-ref))))
      (runtime-executed #f)))))
