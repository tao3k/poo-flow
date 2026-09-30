;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Source-neutral Module diagnostic and DoctorReport POO values. Product
;;; owners decide which facts are findings and how to present them.

(import (only-in :core/object-family/syntax defpoo-object-family)
        (only-in :std/list/list any))

(export poo-flow-module-diagnostic-prototype
        make-poo-flow-module-diagnostic
        poo-flow-module-diagnostic?
        poo-flow-module-diagnostic-severity
        poo-flow-module-diagnostic-code
        poo-flow-module-diagnostic-target
        poo-flow-module-diagnostic-detail
        poo-flow-module-diagnostics-status
        poo-flow-module-doctor-report-prototype
        make-poo-flow-module-doctor-report
        poo-flow-module-doctor-report?
        poo-flow-module-doctor-report-modules
        poo-flow-module-doctor-report-status
        poo-flow-module-doctor-report-diagnostics
        poo-flow-module-doctor-ok?)

(defpoo-object-family
  (prototype poo-flow-module-diagnostic-prototype
             module-diagnostic?
             poo-flow-module-diagnostic?)
  (constructor make-poo-flow-module-diagnostic
               (severity-value severity)
               (code-value code)
               (target-value target)
               (detail-value detail))
  (accessors
   (poo-flow-module-diagnostic-severity severity)
   (poo-flow-module-diagnostic-code code)
   (poo-flow-module-diagnostic-target target)
   (poo-flow-module-diagnostic-detail detail))
  (projections))

(def (poo-flow-module-diagnostics-status diagnostics)
  (cond
   ((any (lambda (diagnostic)
           (eq? (poo-flow-module-diagnostic-severity diagnostic) 'error))
         diagnostics)
    'error)
   ((pair? diagnostics) 'warning)
   (else 'ok)))

(defpoo-object-family
  (prototype poo-flow-module-doctor-report-prototype
             module-doctor-report?
             poo-flow-module-doctor-report?)
  (constructor make-poo-flow-module-doctor-report
               (modules-value modules)
               (status-value status)
               (diagnostics-value diagnostics))
  (accessors
   (poo-flow-module-doctor-report-modules modules)
   (poo-flow-module-doctor-report-status status)
   (poo-flow-module-doctor-report-diagnostics diagnostics))
  (projections))

(def (poo-flow-module-doctor-ok? report)
  (eq? (poo-flow-module-doctor-report-status report) 'ok))
