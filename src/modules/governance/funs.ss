;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: turn an admitted governance Profile into a generic contribution.
;;; Invariant: this projection remains inert and grants no runtime authority.
(import (only-in :clan/poo/object .ref)
        (only-in :std/srfi/1 every)
        (only-in :poo-flow/src/module-system/contribution/interface
                 make-contribution)
        (only-in :poo-flow/src/modules/governance/types
                 poo-flow-governance-profile?))

(export poo-flow-governance-contribution)

(def (poo-flow-governance-contribution profile-value facets requirements)
  (unless (poo-flow-governance-profile? profile-value)
    (error "invalid governance profile" profile-value))
  (unless (and (list? facets) (pair? facets) (every symbol? facets)
               (list? requirements) (every symbol? requirements))
    (error "invalid governance contribution facets or requirements"))
  (make-contribution
   (.ref profile-value 'identity)
   (.ref profile-value 'revision)
   (.ref profile-value 'owner)
   profile-value
   facets
   requirements))
