;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: Funflow declares its dependency on POO CLOS without importing
;;; runtime implementation factors.

(import (only-in :poo-flow/src/module-system/loader/source
                 poo-flow-standard-library-source))

(export poo-flow-funflow-method-combination-module-ref)

;;; Engineering note: a standard-library source ref is inert module metadata;
;;; descriptor realization remains owned by the Loader.
;; : PooModuleSourceRef
(def poo-flow-funflow-method-combination-module-ref
  (poo-flow-standard-library-source 'poo-clos))
