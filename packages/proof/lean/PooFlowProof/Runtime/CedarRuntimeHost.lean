import PooFlowProof.Runtime.CedarNative

/-! Root identity for the AOT Runtime Host link graph. Runtime behavior lives
in the Rust staticlib and the exported CedarNative function. -/

namespace PooFlowProof.Runtime.CedarRuntimeHost

def linked : Bool := true

end PooFlowProof.Runtime.CedarRuntimeHost
