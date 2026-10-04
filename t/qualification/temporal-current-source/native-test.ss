;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (rename-in (only-in :gerbil/tools/gxtest main) (main gxtest-main))
        (only-in :gerbil/runtime/init gerbil-load-expander!)
        "../../temporal-applicability-test.ss")
(export main)
;;; Statically linked owner modules; upstream gxtest still owns discovery,
;;; assertions, Case profiles, reporting and exit status.
(def (main . args)
  (def (completed-stage message)
    (when (getenv "POO_FLOW_TEST_PROGRESS" #f)
      (let (port (current-error-port))
        (display message port)
        (newline port)
        (force-output port))))
  (completed-stage "poo-test: static module initialization completed")
  ;; gxtest imports source modules. Match the official Gerbil main's expander
  ;; initialization before delegating discovery and execution to gxtest.
  (gerbil-load-expander!)
  (completed-stage "poo-test: official expander initialization completed")
  (exit (apply gxtest-main args)))
