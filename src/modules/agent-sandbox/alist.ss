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
;; : (-> Alist Symbol Value Value)
(def (agent-sandbox-option options key default)
  (agent-sandbox-alist-ref options key default))

;;; Optional extension metadata sometimes crosses owner boundaries as `#f`,
;;; symbolic policy names, or partial rows before a validator normalizes it.
;;; Lookup treats those values as absent so validators can report field-level
;;; errors instead of leaking a generic `assoc` exception from this helper.
;; : (-> MaybeAlist Symbol Value Value)
(def (agent-sandbox-alist-ref alist key default)
  (let loop ((entries (if (list? alist) alist '())))
    (cond
     ((null? entries) default)
     ((not (pair? entries)) default)
     ((and (pair? (car entries))
           (equal? (caar entries) key))
      (cdar entries))
     (else
      (loop (cdr entries))))))

;; : (-> MaybeAlist Alist)
(def (agent-sandbox-normalize-alist alist)
  (if (list? alist) alist '()))

;;; Alist merge keeps task-local policy first. Downstream bridges that use
;;; assoc get task overrides before profile defaults.
;; : (-> MaybeAlist MaybeAlist Alist)
(def (agent-sandbox-merge-alists primary secondary)
  (append (agent-sandbox-normalize-alist primary)
          (agent-sandbox-normalize-alist secondary)))

;;; False means "use profile default".
;;; An empty alist is still an explicit task-level override.
;; : (-> MaybeValue Value Value)
(def (agent-sandbox-override value default)
  (if value value default))
