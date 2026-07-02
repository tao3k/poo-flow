import Lake
open System Lake DSL

package «poo-flow-proof» where
  version := v!"0.1.0"

@[default_target]
lean_lib PooFlowProof where
  roots := #[`PooFlowProof]

target proof_native.o (pkg : NPackage __name__) : FilePath := do
  let src := pkg.dir / "native" / "poo_flow_proof_ffi.c"
  let obj := pkg.buildDir / "native" / "poo_flow_proof_ffi.o"
  buildFileAfterDep obj (← inputFile src true) fun srcFile => do
    let leanDir := (← getLeanIncludeDir).toString
    compileO obj srcFile #["-I", leanDir, "-fPIC"]

extern_lib proof_native (pkg : NPackage __name__) := do
  let name := nameToStaticLib "proof_native"
  let obj ← fetch <| pkg.target ``proof_native.o
  buildStaticLib (pkg.buildDir / "lib" / name) #[obj]

lean_exe ffiSmoke where
  root := `PooFlowProof.FFISmoke
