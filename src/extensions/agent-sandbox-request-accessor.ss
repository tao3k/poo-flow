;;; -*- Gerbil -*-
;;; Owner: agent-sandbox task request accessors live here.
;;; Boundary:
;;; - Request construction owns normalized data.
;;; - This module only reads stable task fields.
;;; Import contract:
;;; - Request owner re-exports these readers through the facade.
;;; Runtime contract:
;;; - Accessors never validate or execute backend-specific policy.
;;; - Absent fields resolve through explicit accessor defaults.
;;; Policy evidence:
;;; - Descriptor tests assert each public accessor field.

(import :core/api)

(export task-agent-sandbox-config
        task-agent-sandbox-config-ref
        task-agent-sandbox-schema
        task-agent-sandbox-backend-kind
        task-agent-sandbox-backend-ref
        task-agent-sandbox-command
        task-agent-sandbox-args
        task-agent-sandbox-env
        task-agent-sandbox-workdir
        task-agent-sandbox-mounts
        task-agent-sandbox-network-policy
        task-agent-sandbox-capabilities
        task-agent-sandbox-resource-policy
        task-agent-sandbox-output-policy
        task-agent-sandbox-metadata)

;;; Config access is intentionally guarded by task kind so generic runner code
;;; can ask for sandbox metadata without destructuring unrelated tasks.
;; AgentSandboxConfig | #f <- Task
(def (task-agent-sandbox-config task)
  (if (eq? (task-kind task) 'agent-sandbox)
    (cadr (task-request task))
    #f))

;;; Accessors share one tolerant lookup path so extension consumers can probe
;;; optional sandbox fields without forcing every runner to branch by task kind.
;;; The shared config lookup keeps every public accessor on one fallback path.
;; Value <- Task Symbol Value
(def (task-agent-sandbox-config-ref task key default)
  (let ((config (task-agent-sandbox-config task)))
    (if config
      (let (entry (assoc key config))
        (if entry
          (cdr entry)
          default))
      default)))

;;; Boundary:
;;; - Public accessors differ only by stable field key and default.
;;; - The factory keeps repeated API surface as data, not duplicated logic.
;;; This is intentionally a value factory, not macro sugar: descriptor tests can
;;; call each exported accessor as an ordinary function while every missing
;;; field still resolves through the same task-kind guard above.
;; (Value <- Task) <- Symbol Value
(def (task-agent-sandbox-accessor key default)
  (lambda (task)
    (task-agent-sandbox-config-ref task key default)))

;; Symbol | #f <- Task
(def task-agent-sandbox-schema
  (task-agent-sandbox-accessor 'schema #f))

;; Symbol | #f <- Task
(def task-agent-sandbox-backend-kind
  (task-agent-sandbox-accessor 'backend-kind #f))

;; BackendRef | #f <- Task
(def task-agent-sandbox-backend-ref
  (task-agent-sandbox-accessor 'backend-ref #f))

;; Command | #f <- Task
(def task-agent-sandbox-command
  (task-agent-sandbox-accessor 'command #f))

;; [Arg] <- Task
(def task-agent-sandbox-args
  (task-agent-sandbox-accessor 'args '()))

;; Env <- Task
(def task-agent-sandbox-env
  (task-agent-sandbox-accessor 'env '()))

;; Workdir | #f <- Task
(def task-agent-sandbox-workdir
  (task-agent-sandbox-accessor 'workdir #f))

;; Mounts <- Task
(def task-agent-sandbox-mounts
  (task-agent-sandbox-accessor 'mounts '()))

;; NetworkPolicy <- Task
(def task-agent-sandbox-network-policy
  (task-agent-sandbox-accessor 'network-policy '()))

;; Capabilities <- Task
(def task-agent-sandbox-capabilities
  (task-agent-sandbox-accessor 'capabilities '()))

;; ResourcePolicy <- Task
(def task-agent-sandbox-resource-policy
  (task-agent-sandbox-accessor 'resource-policy '()))

;; OutputPolicy | #f <- Task
(def task-agent-sandbox-output-policy
  (task-agent-sandbox-accessor 'output-policy #f))

;; Metadata <- Task
(def task-agent-sandbox-metadata
  (task-agent-sandbox-accessor 'metadata '()))
