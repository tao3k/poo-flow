;;; -*- Gerbil -*-
;;; Owner: shared agent-sandbox alist combinators live in this utility module.
;;; Boundary: profile, request, and bridge modules reuse these helpers only.
;;; Runtime contract: this module performs no backend selection or execution.
;;; Policy evidence: larger extension owners should import these helpers.

(export agent-sandbox-option
        agent-sandbox-alist-ref
        agent-sandbox-merge-alists
        agent-sandbox-override)

;;; Run-config and profile options stay alist-shaped so bridge commands can pass
;;; metadata without adding Scheme structs at every extension boundary.
;; Value <- Alist Symbol Value
(def (agent-sandbox-option options key default)
  (agent-sandbox-alist-ref options key default))

;;; Shared alist lookup is the only place that treats absent optional extension
;;; fields as defaults. Profile, request, and bridge helpers therefore agree.
;; Value <- Alist Symbol Value
(def (agent-sandbox-alist-ref alist key default)
  (let (entry (and alist (assoc key alist)))
    (if entry
      (cdr entry)
      default)))

;;; Alist merge keeps task-local policy first. Downstream bridges that use
;;; assoc get task overrides before profile defaults.
;; Alist <- Alist Alist
(def (agent-sandbox-merge-alists primary secondary)
  (append (if primary primary '())
          (if secondary secondary '())))

;;; False means "use profile default".
;;; An empty alist is still an explicit task-level override.
;; Value <- MaybeValue Value
(def (agent-sandbox-override value default)
  (if value value default))
