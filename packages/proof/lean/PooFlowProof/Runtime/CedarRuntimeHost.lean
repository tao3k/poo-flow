-- SPDX-FileCopyrightText: 2026 tao3k team and Contributors
--
-- SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

import PooFlowProof.Runtime.CedarNative

/-! Root identity for the AOT Runtime Host link graph. Runtime behavior lives
in the Rust staticlib and the exported CedarNative function. -/

namespace PooFlowProof.Runtime.CedarRuntimeHost

def linked : Bool := true

end PooFlowProof.Runtime.CedarRuntimeHost
