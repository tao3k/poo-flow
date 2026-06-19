;;; -*- Gerbil -*-
;;; Boundary: non-mutating module doctor diagnostics.
;;; Invariant: diagnostics never change activation behavior.

(import :core/task
        :core/flow
        :modules/descriptor)

(export make-poo-flow-module-diagnostic
        poo-flow-module-diagnostic?
        poo-flow-module-diagnostic-severity
        poo-flow-module-diagnostic-code
        poo-flow-module-diagnostic-target
        poo-flow-module-diagnostic-detail
        poo-flow-module-diagnostic->alist
        poo-flow-module-diagnostics
        poo-flow-module-diagnostics-status
        make-poo-flow-module-doctor-report
        poo-flow-module-doctor-report?
        poo-flow-module-doctor-report-modules
        poo-flow-module-doctor-report-status
        poo-flow-module-doctor-report-diagnostics
        poo-flow-module-doctor
        poo-flow-module-doctor-ok?
        poo-flow-module-doctor-report->alist)

;;; Boundary: diagnostic records are typed values until projected at the edge.
;; : (-> Symbol Symbol Symbol Detail PooModuleDiagnostic)
(defstruct poo-flow-module-diagnostic
  (severity
   code
   target
   detail)
  transparent: #t)

;; : (-> PooModuleDiagnostic Alist)
(def (poo-flow-module-diagnostic->alist diagnostic)
  (list (cons 'severity (poo-flow-module-diagnostic-severity diagnostic))
        (cons 'code (poo-flow-module-diagnostic-code diagnostic))
        (cons 'target (poo-flow-module-diagnostic-target diagnostic))
        (cons 'detail (poo-flow-module-diagnostic-detail diagnostic))))

;; : (-> DiagnosticKey [DiagnosticKey] Boolean)
(def (poo-flow-module-diagnostic-key-member? value values)
  (cond
   ((null? values) #f)
   ((equal? value (car values)) #t)
   (else
    (poo-flow-module-diagnostic-key-member? value (cdr values)))))

;;; Boundary: duplicate computation preserves first duplicate owner order.
;;; Intent: doctor remains responsive when downstream overlays repeat template option keys.
;; : (-> [DiagnosticKey] [DiagnosticKey] [DiagnosticKey])
(def (poo-flow-module-duplicate-symbols/add values emitted)
  (cond
   ((null? values) '())
   ((and (poo-flow-module-diagnostic-key-member? (car values) (cdr values))
         (not (poo-flow-module-diagnostic-key-member? (car values) emitted)))
    (cons (car values)
          (poo-flow-module-duplicate-symbols/add
           (cdr values)
           (cons (car values) emitted))))
   (else
    (poo-flow-module-duplicate-symbols/add (cdr values) emitted))))

;;; Boundary: duplicate computation is quadratic, not recursively exponential.
;; : (-> [DiagnosticKey] [DiagnosticKey])
(def (poo-flow-module-duplicate-symbols values)
  (poo-flow-module-duplicate-symbols/add values '()))

;;; Boundary: option diagnostics look only at keys, not option payloads.
;; : (-> ModuleOptionAlist [Symbol])
(def (poo-flow-module-option-keys options)
  (if (null? options)
    '()
    (cons (caar options)
          (poo-flow-module-option-keys (cdr options)))))

;;; Boundary: task diagnostic projection ignores task payloads.
;; : (-> [PooModuleDescriptor] [Symbol])
(def (poo-flow-module-task-family-names modules)
  (map task-family-name (poo-flow-module-all-task-descriptors modules)))

;;; Boundary: flow diagnostic projection ignores flow payloads.
;; : (-> [PooModuleDescriptor] [Symbol])
(def (poo-flow-module-flow-declaration-kinds modules)
  (map flow-declaration-kind (poo-flow-module-all-flow-descriptors modules)))

;;; Boundary: option diagnostic projection ignores option values.
;; : (-> [PooModuleDescriptor] [Symbol])
(def (poo-flow-module-all-option-keys modules)
  (poo-flow-module-option-keys (poo-flow-module-all-options modules)))

;;; Boundary: duplicate detail shape is shared across task/flow/option diagnostics.
;; : (-> Symbol [Symbol] DiagnosticDetail)
(def (poo-flow-module-duplicate-detail key duplicates)
  (map (lambda (value)
         (list (cons key value)))
       duplicates))

;;; Boundary: empty details suppress diagnostics instead of emitting noise.
;; : (-> Symbol Symbol Symbol DiagnosticDetail [PooModuleDiagnostic])
(def (poo-flow-module-diagnostic-if-present severity code target detail)
  (if (null? detail)
    '()
    (list (make-poo-flow-module-diagnostic severity code target detail))))

;;; Boundary: missing import diagnostics reuse activation validation facts.
;; : (-> [PooModuleDescriptor] [PooModuleDiagnostic])
(def (poo-flow-module-missing-import-diagnostics modules)
  (poo-flow-module-diagnostic-if-present
   'error
   'missing-module-imports
   'imports
   (poo-flow-module-missing-imports modules)))

;;; Boundary: duplicate task names remain warnings in this slice.
;; : (-> [PooModuleDescriptor] [PooModuleDiagnostic])
(def (poo-flow-module-duplicate-task-diagnostics modules)
  (poo-flow-module-diagnostic-if-present
   'warning
   'duplicate-task-family
   'task-registry
   (poo-flow-module-duplicate-detail
    'task-family
    (poo-flow-module-duplicate-symbols
     (poo-flow-module-task-family-names modules)))))

;;; Boundary: duplicate flow kinds remain warnings in this slice.
;; : (-> [PooModuleDescriptor] [PooModuleDiagnostic])
(def (poo-flow-module-duplicate-flow-diagnostics modules)
  (poo-flow-module-diagnostic-if-present
   'warning
   'duplicate-flow-declaration
   'flow-registry
   (poo-flow-module-duplicate-detail
    'flow-kind
    (poo-flow-module-duplicate-symbols
     (poo-flow-module-flow-declaration-kinds modules)))))

;;; Boundary: duplicate option keys remain warnings in this slice.
;; : (-> [PooModuleDescriptor] [PooModuleDiagnostic])
(def (poo-flow-module-duplicate-option-diagnostics modules)
  (poo-flow-module-diagnostic-if-present
   'warning
   'duplicate-module-option
   'options
   (poo-flow-module-duplicate-detail
    'option
    (poo-flow-module-duplicate-symbols
     (poo-flow-module-all-option-keys modules)))))

;;; Boundary: empty modules are visible as diagnostics, not activation blockers.
;; : (-> PooModuleDescriptor Boolean)
(def (poo-flow-module-empty-contribution? module)
  (and (null? (poo-flow-module-task-descriptors module))
       (null? (poo-flow-module-flow-descriptors module))))

;;; Boundary: empty-contribution remains warning-only until loader semantics exist.
;; : (-> [PooModuleDescriptor] DiagnosticDetail)
(def (poo-flow-module-empty-contribution-detail modules)
  (cond
   ((null? modules) '())
   ((poo-flow-module-empty-contribution? (car modules))
    (cons (list (cons 'module (poo-flow-module-name (car modules))))
          (poo-flow-module-empty-contribution-detail (cdr modules))))
   (else
    (poo-flow-module-empty-contribution-detail (cdr modules)))))

;;; Boundary: empty contribution diagnostics are warning-only.
;; : (-> [PooModuleDescriptor] [PooModuleDiagnostic])
(def (poo-flow-module-empty-contribution-diagnostics modules)
  (poo-flow-module-diagnostic-if-present
   'warning
   'empty-module-contribution
   'module
   (poo-flow-module-empty-contribution-detail modules)))

;;; Boundary: doctor runs over closure so inline imports are visible.
;; : (-> [PooModuleDescriptor] [PooModuleDiagnostic])
(def (poo-flow-module-diagnostics modules)
  (let (closed-modules (poo-flow-module-closure modules))
    (append (poo-flow-module-missing-import-diagnostics closed-modules)
            (poo-flow-module-duplicate-task-diagnostics closed-modules)
            (poo-flow-module-duplicate-flow-diagnostics closed-modules)
            (poo-flow-module-duplicate-option-diagnostics closed-modules)
            (poo-flow-module-empty-contribution-diagnostics closed-modules))))

;; : (-> DiagnosticSeverity [PooModuleDiagnostic] [PooModuleDiagnostic])
(def (poo-flow-module-diagnostics-with-severity severity diagnostics)
  (cond
   ((null? diagnostics) '())
   ((eq? (poo-flow-module-diagnostic-severity (car diagnostics)) severity)
    (cons (car diagnostics)
          (poo-flow-module-diagnostics-with-severity severity (cdr diagnostics))))
   (else
    (poo-flow-module-diagnostics-with-severity severity (cdr diagnostics)))))

;;; Boundary: any error diagnostic upgrades the whole report to error.
;; : (-> [PooModuleDiagnostic] Symbol)
(def (poo-flow-module-diagnostics-status diagnostics)
  (cond
   ((pair? (poo-flow-module-diagnostics-with-severity 'error diagnostics)) 'error)
   ((pair? diagnostics) 'warning)
   (else 'ok)))

;;; Boundary: reports summarize health and keep diagnostic records typed.
;; : (-> [Symbol] Symbol [PooModuleDiagnostic] PooModuleDoctorReport)
(defstruct poo-flow-module-doctor-report
  (modules
   status
   diagnostics)
  transparent: #t)

;;; Boundary: doctor reports summarize closure health without activation.
;; : (-> [PooModuleDescriptor] PooModuleDoctorReport)
(def (poo-flow-module-doctor modules)
  (let ((closed-modules (poo-flow-module-closure modules))
        (diagnostics (poo-flow-module-diagnostics modules)))
    (make-poo-flow-module-doctor-report
     (poo-flow-module-names closed-modules)
     (poo-flow-module-diagnostics-status diagnostics)
     diagnostics)))

;;; Boundary: doctor ok is a status predicate only.
;; : (-> PooModuleDoctorReport Boolean)
(def (poo-flow-module-doctor-ok? report)
  (eq? (poo-flow-module-doctor-report-status report) 'ok))

;;; Boundary: alist conversion is reserved for CLI/agent presentation edges.
;; : (-> PooModuleDoctorReport Alist)
(def (poo-flow-module-doctor-report->alist report)
  (list (cons 'modules (poo-flow-module-doctor-report-modules report))
        (cons 'status (poo-flow-module-doctor-report-status report))
        (cons 'diagnostics
              (map poo-flow-module-diagnostic->alist
                   (poo-flow-module-doctor-report-diagnostics report)))))
