;;; -*- Gerbil -*-
;;; Boundary: public POO-native sandbox profile authoring interface.
;;; Invariant: users write Gerbil POO objects; projection stays report-only.

(import :clan/poo/object)

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

;; : (-> Alist [Symbol] Alist)
(def (profile-metadata-without metadata keys)
  (filter (lambda (entry)
            (not (and (pair? entry)
                      (profile-metadata-remove-key? (car entry) keys))))
          metadata))

;; : (-> Alist [Alist])
(def (profile-derivation-path metadata)
  (let (entry (assoc 'derivation-path metadata))
    (if (and entry (list? (cdr entry))) (cdr entry) '())))

;; : (-> Symbol Symbol Symbol Value Alist)
(def (profile-derivation-step profile-name parent-profile scope scope-ref)
  (append
   (list (cons 'profile profile-name)
         (cons 'parent-profile parent-profile)
         (cons 'scope scope)
         (cons 'derived-by 'poo-native-profile-object))
   (if scope-ref
     (list (cons 'scope-ref scope-ref))
     '())))

;; : (-> Alist Symbol Symbol Symbol Value Alist... Alist)
(def (profile-derivation-metadata parent-metadata
                                  profile-name
                                  parent-profile
                                  scope
                                  scope-ref
                                  . maybe-extra)
  (let (extra (if (null? maybe-extra) '() (car maybe-extra)))
    (append
     (profile-metadata-without parent-metadata
                               '(derivation-path runtime-executed))
     (list (cons 'derivation-path
                 (append
                  (profile-derivation-path parent-metadata)
                  (list
                   (profile-derivation-step profile-name
                                            parent-profile
                                            scope
                                            scope-ref))))
           (cons 'runtime-executed #f))
     extra)))
