;;; -*- Gerbil -*-
;;; Boundary: loop-engine intent lookup, use-case naming, and runtime ids.
;;; Invariant: helpers normalize report data only; they do not build manifests.

(export poo-flow-user-loop-engine-intent-ref
        poo-flow-user-loop-engine-section-ref
        poo-flow-user-loop-engine-use-case-name
        poo-flow-user-loop-engine-intent-use-case-name
        poo-flow-user-loop-engine-use-case-names/add
        poo-flow-user-loop-engine-use-case-names
        poo-flow-user-loop-engine-use-case-name?
        poo-flow-user-loop-engine-runtime-id
        poo-flow-user-loop-engine-intent-workflow-ref)

;;; Intent lookup is total because partial loop declarations still need a
;;; presentable handoff report and unresolved sandbox diagnostics.
;; : (-> Alist Symbol Value Value)
(def (poo-flow-user-loop-engine-intent-ref intent key default-value)
  (let (entry (assoc key intent))
    (if entry (cdr entry) default-value)))

;;; Section lookup supports the Doom-style nested config rows where section
;;; names are carried as association keys inside init declarations.
;; : (-> [Value] Symbol Value Value)
(def (poo-flow-user-loop-engine-section-ref entries key default-value)
  (cond
   ((null? entries) default-value)
   ((and (pair? (car entries))
         (equal? (caar entries) key))
    (cdar entries))
   (else
    (poo-flow-user-loop-engine-section-ref (cdr entries) key default-value))))

;;; Use-case names become runtime ids, so this normalizer accepts an explicit
;;; single use-case row, then falls back to the first declared use-case list row.
;; : (-> Value [Value] Symbol)
(def (poo-flow-user-loop-engine-use-case-name use-case use-cases)
  (cond
   ((and (pair? use-case) (symbol? (car use-case))) (car use-case))
   ((and (pair? use-cases)
         (pair? (car use-cases))
         (symbol? (caar use-cases)))
    (caar use-cases))
   (else 'loop-engine)))

;; : (-> Alist Symbol)
(def (poo-flow-user-loop-engine-intent-use-case-name intent)
  (poo-flow-user-loop-engine-use-case-name
   (poo-flow-user-loop-engine-intent-ref intent 'use-case '())
   (poo-flow-user-loop-engine-intent-ref intent 'use-cases '())))

;;; Use-case accumulation preserves declaration order while ignoring malformed
;;; rows that cannot produce stable runtime identifiers.
;; : (-> [Value] [Symbol])
(def (poo-flow-user-loop-engine-use-case-names/add use-cases)
  (cond
   ((null? use-cases) '())
   ((and (pair? (car use-cases))
         (symbol? (caar use-cases)))
    (cons (caar use-cases)
          (poo-flow-user-loop-engine-use-case-names/add (cdr use-cases))))
   (else
    (poo-flow-user-loop-engine-use-case-names/add (cdr use-cases)))))

;;; The use-case set is intentionally empty when no explicit rows exist. The
;;; runtime workflow ref still falls back through the single-use-case path.
;; : (-> Alist [Symbol])
(def (poo-flow-user-loop-engine-use-case-names intent)
  (let ((use-case
         (poo-flow-user-loop-engine-intent-ref intent 'use-case '()))
        (use-cases
         (poo-flow-user-loop-engine-intent-ref intent 'use-cases '())))
    (append
     (if (and (pair? use-case) (symbol? (car use-case)))
       (list (car use-case))
       '())
     (poo-flow-user-loop-engine-use-case-names/add use-cases))))

;;; Use-case membership is Boolean-normalized for sandbox rows that use
;;; `(case . profile)` shorthand.
;; : (-> Symbol [Symbol] Boolean)
(def (poo-flow-user-loop-engine-use-case-name? value use-case-names)
  (and (member value use-case-names) #t))

;;; Runtime ids are stable report identifiers. They are not executable names and
;;; must remain independent from Marlin CLI routing.
;; : (-> Symbol String Symbol)
(def (poo-flow-user-loop-engine-runtime-id use-case-name suffix)
  (string->symbol
   (string-append "loop-engine/"
                  (symbol->string use-case-name)
                  "/"
                  suffix)))

;;; Workflow refs fall back to `loop-engine` so incomplete declarations remain
;;; presentable while diagnostics explain missing or malformed sections.
;; : (-> Alist Symbol)
(def (poo-flow-user-loop-engine-intent-workflow-ref intent)
  (let ((workflow-ref
         (poo-flow-user-loop-engine-section-ref
          (poo-flow-user-loop-engine-intent-ref intent 'use-case '())
          'workflow
          #f)))
    (if workflow-ref workflow-ref 'loop-engine)))
