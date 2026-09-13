import Lake
open System Lake DSL

package «poo-flow-proof» where
  version := v!"0.1.0"

require Cedar from git
  "https://github.com/cedar-policy/cedar-spec.git"
  @ "e9fa9c1e6b636f29b0897d8706bd7aa5eaf06f9a"
  / "cedar-lean"

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

lean_exe pooFlowDeclarationClosure where
  root := `PooFlowProof.Export.DeclarationClosure

target cedar_native_probe.o (pkg : NPackage __name__) : FilePath := do
  let src := pkg.dir / "native" / "cedar_native_probe.c"
  let obj := pkg.buildDir / "native" / "cedar_native_probe.o"
  buildFileAfterDep obj (← inputFile src true) fun srcFile => do
    let leanDir := (← getLeanIncludeDir).toString
    compileO obj srcFile #["-I", leanDir, "-O2", "-Wall", "-Wextra", "-Werror", "-pthread"]

-- A C-owned main calls Lean's exported function on a dedicated native thread.
-- Lake owns the transitive object graph, just as for the diagnostic executable.
lean_exe cedarNativeProbe where
  root := `PooFlowProof.Runtime.CedarNative
  moreLinkObjs := #[cedar_native_probe.o]
  moreLinkArgs := #["-pthread"]

target cedar_runtime_host.o (pkg : NPackage __name__) : FilePath := do
  let src := pkg.dir / "native" / "cedar_runtime_host.c"
  let obj := pkg.buildDir / "native" / "cedar_runtime_host.o"
  buildFileAfterDep obj (← inputFile src true) fun srcFile => do
    let leanDir := (← getLeanIncludeDir).toString
    compileO obj srcFile #["-I", leanDir, "-O2", "-Wall", "-Wextra", "-Werror", "-pthread"]

target cedar_runtime_core.a (_pkg : NPackage __name__) : FilePath := do
  let some archive ← IO.getEnv "POO_FLOW_CEDAR_RUNTIME_CORE_ARCHIVE"
    | error "POO_FLOW_CEDAR_RUNTIME_CORE_ARCHIVE must name the Rust static archive"
  inputFile archive false

-- The outer build supplies the Cargo archive as an explicit input. The final
-- executable contains both Cedar engines and the Runtime Host; it discovers
-- no Lake cache or repository path at runtime.
lean_exe cedarRuntimeHost where
  root := `PooFlowProof.Runtime.CedarRuntimeHost
  moreLinkObjs := #[cedar_runtime_host.o, cedar_runtime_core.a]
  moreLinkArgs := #["-pthread"]
