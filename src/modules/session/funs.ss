;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: session config data and linear row projection functions.
;;; Invariant: functions stay below syntax/config and perform no runtime work.

(import (only-in :std/sugar filter)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/declaration/interface
        :poo-flow/src/module-system/declaration/config-syntax)

(export +poo-flow-session-core-config-kind+
        session-config
        poo-flow-session-core-poo-config?
        poo-flow-session-core-poo-config->rows
        poo-flow-session-core-poo-configs->rows
        poo-flow-session-core-poo-config-flags)

(def (poo-flow-session-core-config-rows/tail rows tail)
  (append rows tail))

(def +poo-flow-session-core-config-kind+ 'poo-flow.session-core.config)

(defpoo-module-config-prototype
  session-config
  (slots ((kind +poo-flow-session-core-config-kind+)
          (rows '())
          (metadata '())
          (runtime-owner "marlin-agent-core")
          (runtime-executed #f))))

(defpoo-module-config-kind-predicate
  poo-flow-session-core-poo-config?
  +poo-flow-session-core-config-kind+)

(def (poo-flow-session-core-poo-config->rows config)
  (let (rows (.ref config 'rows))
    (if (list? rows)
      rows
      (error "session-core config rows must be a list" rows))))

(def (poo-flow-session-core-poo-configs->rows configs)
  (cond
   ((null? configs) '())
   ((pair? configs)
    (poo-flow-session-core-config-rows/tail
     (poo-flow-session-core-poo-config->rows (car configs))
     (poo-flow-session-core-poo-configs->rows (cdr configs))))
   (else
    (error "session-core POO configs must be a list" configs))))

(def (poo-flow-session-core-poo-config-flags prototypes user-config)
  (let* ((configs (filter poo-flow-session-core-poo-config? prototypes))
         (rows (poo-flow-session-core-poo-configs->rows configs)))
    (list '+policy
          '+typed-receipts
          (cons ':config rows)
          (cons ':session-rows rows)
          (cons ':session-config-prototypes configs)
          (cons ':user-config user-config))))
