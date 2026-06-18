;;; -*- Gerbil -*-
;;; Boundary: non-mutating module doctor diagnostics.
;;; Invariant: diagnostics never change activation behavior.

(import :core/task
        :core/flow
        :modules/descriptor)

(export make-poo-module-diagnostic
        poo-module-diagnostic?
        poo-module-diagnostic-severity
        poo-module-diagnostic-code
        poo-module-diagnostic-target
        poo-module-diagnostic-detail
        poo-module-diagnostic->alist
        poo-module-diagnostics
        poo-module-diagnostics-status
        make-poo-module-doctor-report
        poo-module-doctor-report?
        poo-module-doctor-report-modules
        poo-module-doctor-report-status
        poo-module-doctor-report-diagnostics
        poo-module-doctor
        poo-module-doctor-ok?
        poo-module-doctor-report->alist)

;;; Boundary: diagnostic records are typed values until projected at the edge.
;; PooModuleDiagnostic <- Symbol Symbol Symbol Detail
(defstruct poo-module-diagnostic
  (severity
   code
   target
   detail)
  transparent: #t)

;; Alist <- PooModuleDiagnostic
(def (poo-module-diagnostic->alist diagnostic)
  (list (cons 'severity (poo-module-diagnostic-severity diagnostic))
        (cons 'code (poo-module-diagnostic-code diagnostic))
        (cons 'target (poo-module-diagnostic-target diagnostic))
        (cons 'detail (poo-module-diagnostic-detail diagnostic))))

;; Boolean <- DiagnosticKey [DiagnosticKey]
(def (poo-module-diagnostic-key-member? value values)
  (cond
   ((null? values) #f)
   ((equal? value (car values)) #t)
   (else
    (poo-module-diagnostic-key-member? value (cdr values)))))

;;; Boundary: duplicate computation preserves first duplicate owner order.
;;; Intent: doctor remains responsive when downstream overlays repeat template option keys.
;; [DiagnosticKey] <- [DiagnosticKey] [DiagnosticKey]
(def (poo-module-duplicate-symbols/add values emitted)
  (cond
   ((null? values) '())
   ((and (poo-module-diagnostic-key-member? (car values) (cdr values))
         (not (poo-module-diagnostic-key-member? (car values) emitted)))
    (cons (car values)
          (poo-module-duplicate-symbols/add
           (cdr values)
           (cons (car values) emitted))))
   (else
    (poo-module-duplicate-symbols/add (cdr values) emitted))))

;;; Boundary: duplicate computation is quadratic, not recursively exponential.
;; [DiagnosticKey] <- [DiagnosticKey]
(def (poo-module-duplicate-symbols values)
  (poo-module-duplicate-symbols/add values '()))

;;; Boundary: option diagnostics look only at keys, not option payloads.
;; [Symbol] <- ModuleOptionAlist
(def (poo-module-option-keys options)
  (if (null? options)
    '()
    (cons (caar options)
          (poo-module-option-keys (cdr options)))))

;;; Boundary: duplicate checks flatten descriptor contributions first.
;;; Boundary: task diagnostic projection ignores task payloads.
;; [Symbol] <- [PooModuleDescriptor]
(def (poo-module-task-family-names modules)
  (map task-family-name (poo-module-all-task-descriptors modules)))

;;; Boundary: flow diagnostic projection ignores flow payloads.
;; [Symbol] <- [PooModuleDescriptor]
(def (poo-module-flow-declaration-kinds modules)
  (map flow-declaration-kind (poo-module-all-flow-descriptors modules)))

;;; Boundary: option diagnostic projection ignores option values.
;; [Symbol] <- [PooModuleDescriptor]
(def (poo-module-all-option-keys modules)
  (poo-module-option-keys (poo-module-all-options modules)))

;;; Boundary: duplicate detail shape is shared across task/flow/option diagnostics.
;; DiagnosticDetail <- Symbol [Symbol]
(def (poo-module-duplicate-detail key duplicates)
  (map (lambda (value)
         (list (cons key value)))
       duplicates))

;;; Boundary: empty details suppress diagnostics instead of emitting noise.
;; [PooModuleDiagnostic] <- Symbol Symbol Symbol DiagnosticDetail
(def (poo-module-diagnostic-if-present severity code target detail)
  (if (null? detail)
    '()
    (list (make-poo-module-diagnostic severity code target detail))))

;;; Boundary: missing import diagnostics reuse activation validation facts.
;; [PooModuleDiagnostic] <- [PooModuleDescriptor]
(def (poo-module-missing-import-diagnostics modules)
  (poo-module-diagnostic-if-present
   'error
   'missing-module-imports
   'imports
   (poo-module-missing-imports modules)))

;;; Boundary: duplicate task names remain warnings in this slice.
;; [PooModuleDiagnostic] <- [PooModuleDescriptor]
(def (poo-module-duplicate-task-diagnostics modules)
  (poo-module-diagnostic-if-present
   'warning
   'duplicate-task-family
   'task-registry
   (poo-module-duplicate-detail
    'task-family
    (poo-module-duplicate-symbols (poo-module-task-family-names modules)))))

;;; Boundary: duplicate flow kinds remain warnings in this slice.
;; [PooModuleDiagnostic] <- [PooModuleDescriptor]
(def (poo-module-duplicate-flow-diagnostics modules)
  (poo-module-diagnostic-if-present
   'warning
   'duplicate-flow-declaration
   'flow-registry
   (poo-module-duplicate-detail
    'flow-kind
    (poo-module-duplicate-symbols (poo-module-flow-declaration-kinds modules)))))

;;; Boundary: duplicate option keys remain warnings in this slice.
;; [PooModuleDiagnostic] <- [PooModuleDescriptor]
(def (poo-module-duplicate-option-diagnostics modules)
  (poo-module-diagnostic-if-present
   'warning
   'duplicate-module-option
   'options
   (poo-module-duplicate-detail
    'option
    (poo-module-duplicate-symbols (poo-module-all-option-keys modules)))))

;;; Boundary: empty modules are visible as diagnostics, not activation blockers.
;; Boolean <- PooModuleDescriptor
(def (poo-module-empty-contribution? module)
  (and (null? (poo-module-task-descriptors module))
       (null? (poo-module-flow-descriptors module))))

;;; Boundary: empty-contribution remains warning-only until loader semantics exist.
;; DiagnosticDetail <- [PooModuleDescriptor]
(def (poo-module-empty-contribution-detail modules)
  (cond
   ((null? modules) '())
   ((poo-module-empty-contribution? (car modules))
    (cons (list (cons 'module (poo-module-name (car modules))))
          (poo-module-empty-contribution-detail (cdr modules))))
   (else
    (poo-module-empty-contribution-detail (cdr modules)))))

;;; Boundary: empty contribution diagnostics are warning-only.
;; [PooModuleDiagnostic] <- [PooModuleDescriptor]
(def (poo-module-empty-contribution-diagnostics modules)
  (poo-module-diagnostic-if-present
   'warning
   'empty-module-contribution
   'module
   (poo-module-empty-contribution-detail modules)))

;;; Boundary: doctor runs over closure so inline imports are visible.
;; [PooModuleDiagnostic] <- [PooModuleDescriptor]
(def (poo-module-diagnostics modules)
  (let (closed-modules (poo-module-closure modules))
    (append (poo-module-missing-import-diagnostics closed-modules)
            (poo-module-duplicate-task-diagnostics closed-modules)
            (poo-module-duplicate-flow-diagnostics closed-modules)
            (poo-module-duplicate-option-diagnostics closed-modules)
            (poo-module-empty-contribution-diagnostics closed-modules))))

;; [PooModuleDiagnostic] <- DiagnosticSeverity [PooModuleDiagnostic]
(def (poo-module-diagnostics-with-severity severity diagnostics)
  (cond
   ((null? diagnostics) '())
   ((eq? (poo-module-diagnostic-severity (car diagnostics)) severity)
    (cons (car diagnostics)
          (poo-module-diagnostics-with-severity severity (cdr diagnostics))))
   (else
    (poo-module-diagnostics-with-severity severity (cdr diagnostics)))))

;;; Boundary: any error diagnostic upgrades the whole report to error.
;; Symbol <- [PooModuleDiagnostic]
(def (poo-module-diagnostics-status diagnostics)
  (cond
   ((pair? (poo-module-diagnostics-with-severity 'error diagnostics)) 'error)
   ((pair? diagnostics) 'warning)
   (else 'ok)))

;;; Boundary: reports summarize health and keep diagnostic records typed.
;; PooModuleDoctorReport <- [Symbol] Symbol [PooModuleDiagnostic]
(defstruct poo-module-doctor-report
  (modules
   status
   diagnostics)
  transparent: #t)

;;; Boundary: doctor reports summarize closure health without activation.
;; PooModuleDoctorReport <- [PooModuleDescriptor]
(def (poo-module-doctor modules)
  (let ((closed-modules (poo-module-closure modules))
        (diagnostics (poo-module-diagnostics modules)))
    (make-poo-module-doctor-report
     (poo-module-names closed-modules)
     (poo-module-diagnostics-status diagnostics)
     diagnostics)))

;;; Boundary: doctor ok is a status predicate only.
;; Boolean <- PooModuleDoctorReport
(def (poo-module-doctor-ok? report)
  (eq? (poo-module-doctor-report-status report) 'ok))

;;; Boundary: alist conversion is reserved for CLI/agent presentation edges.
;; Alist <- PooModuleDoctorReport
(def (poo-module-doctor-report->alist report)
  (list (cons 'modules (poo-module-doctor-report-modules report))
        (cons 'status (poo-module-doctor-report-status report))
        (cons 'diagnostics
              (map poo-module-diagnostic->alist
                   (poo-module-doctor-report-diagnostics report)))))
