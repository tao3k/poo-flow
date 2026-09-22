;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: checked-out official contribution source collections.
;;; Invariant: Git submodule gitlinks own revisions and .gitmodules owns URLs;
;;; this module only composes local module source roots.

(import :poo-flow/src/module-system/loader/collection)

(export poo-flow-official-contribution-sources
        poo-flow-official-contribution-load-path)

(def poo-flow-official-contribution-sources
  (list
   (make-poo-flow-contribution-module-source
    'lambda-episteme "packages/lambda-episteme")
   (make-poo-flow-contribution-module-source
    'lambda-aitia "packages/lambda-aitia")))

(def poo-flow-official-contribution-load-path
  (extend-poo-flow-module-load-path
   poo-flow-default-module-load-path
   'poo-flow-with-official-contributions
   poo-flow-official-contribution-sources))
