import PooFlowProof.FFI

def main : IO Unit := do
  if (← PooFlowProof.cBridgeMatchesCanonical) then
    IO.println "poo-flow proof FFI smoke: ok"
  else
    throw <| IO.userError "poo-flow proof FFI smoke: proof ABI mismatch"
