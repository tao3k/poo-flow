-- SPDX-FileCopyrightText: 2026 tao3k team and Contributors
--
-- SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

import Lake
open Lake DSL

package «poo-flow-temporal-poo-proof» where
  version := v!"0.1.0"

require LeanPoo from git
  "https://github.com/tao3k/lean-poo.git"
  @ "71609603d45bead8eec6375471991a4f76dbb430"

@[default_target]
lean_lib PooFlowTemporalPooProof where
  roots := #[`PooFlowTemporalPooProof.TruthMaintenance,
             `PooFlowTemporalPooProof.ConclusionSelection]
