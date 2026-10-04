;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (rename-in (only-in :gerbil/tools/gxtest main) (main gxtest-main))
        "../../temporal-applicability-test.ss")
(export main)
;;; Statically linked owner modules; upstream gxtest still owns discovery,
;;; assertions, Case profiles, reporting and exit status.
(def (main . args)
  (exit (apply gxtest-main args)))
