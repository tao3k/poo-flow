;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :clan/poo/object .ref)
        (only-in :poo-flow/modules/temporal-causality/admission/interface
                 poo-flow-temporal-family-admission-replay
                 poo-flow-temporal-source-snapshot-replay)
        (only-in :poo-flow/modules/temporal-causality/applicability/objects
                 poo-flow-temporal-family-applicability-value))
(export poo-flow-temporal-family-applicability)
;;; Pure comparison with an independently selected host snapshot. This does not
;;; fence a subsequent effect or erase a valid historical classification.
(def (poo-flow-temporal-family-applicability admission current-source)
  (let* ((original (poo-flow-temporal-family-admission-replay admission))
         (current (poo-flow-temporal-source-snapshot-replay current-source)))
    (unless (equal? (.ref (.ref original 'source) 'identity) (.ref current 'identity))
      (error "applicability requires the same logical source"))
    (poo-flow-temporal-family-applicability-value
     (.ref original 'semantic-digest) (.ref original 'source-digest)
     (.ref current 'semantic-digest)
     (if (equal? (.ref original 'source-digest) (.ref current 'semantic-digest))
       'current 'stale))))
