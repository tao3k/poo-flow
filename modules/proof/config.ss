;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Proof core declares the Lego stud and mandatory assurance slots. Concrete
;;; engines, artifacts and vertical claims are always supplied by contributors.
(import (only-in :clan/poo/object .o)
        (only-in :clan/poo/mop validate)
        "types.ss"
        "funs.ss")

(export PooFlowProofModule.
        poo-flow-proof-module)

(def PooFlowProofModule.
  (.o (:: self)
      kind: +poo-flow-proof-module-kind+
      identity: "poo-flow/modules/proof"
      required-slots: '(artifacts receipts refinements)
      optional-slots:
      '(documentation presentation-metadata reference-implementation)
      providers: (.o)
      .admit-assurance: poo-flow-proof-assurance))

(def (poo-flow-proof-module identity-value provider-values)
  (validate
   PooFlowProofModule
   (.o (:: @ PooFlowProofModule.)
       identity: identity-value
       providers: provider-values)))
