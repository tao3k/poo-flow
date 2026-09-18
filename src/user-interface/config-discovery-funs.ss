;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Pure path-role predicates shared by config discovery and its admission
;;; tests. No filesystem access or expander state belongs here.

(import (only-in :std/srfi/13 string-contains string-suffix?))

(export poo-flow-ui-scenario-declaration?)

(def (poo-flow-ui-scenario-declaration? path)
  (and (string? path)
       (string-suffix? ".ss" path)
       (or (string-suffix? "/scenario.ss" path)
           (and (string-contains path "/profiles/") #t))))
