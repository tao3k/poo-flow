import Lean

open Lean

namespace PooFlowProof.Export.DeclarationClosure

private def schemaId := "poo-flow.lean-declaration-closure.v1"

structure Config where
  rootModule : Name := .anonymous
  rootDeclarations : Array Name := #[]
  baseImports : Array Name := #[`Init]
  output : Option System.FilePath := none

structure Declaration where
  name : Name
  kind : String
  ownerModule : Name
  localDependencies : Array Name

structure RangedDeclaration where
  declaration : Declaration
  sourceRange : DeclarationRange

structure NamedRange where
  name : Name
  ownerModule : Name
  sourceRange : DeclarationRange

structure ClosureState where
  visiting : Std.HashSet Name := {}
  emitted : Std.HashSet Name := {}
  declarations : Array Declaration := #[]

private def usage :=
  "usage: lake env lean --run PooFlowProof/Export/DeclarationClosure.lean -- " ++
  "--root-module <module> --root-declaration <name>... " ++
  "[--base-import <module>]... [--output <path>]"

private partial def parseArgs (args : List String) (config : Config := {}) :
    Except String Config :=
  match args with
  | [] =>
      if config.rootModule.isAnonymous then
        throw "missing --root-module"
      else if config.rootDeclarations.isEmpty then
        throw "missing --root-declaration"
      else
        return config
  | "--root-module" :: value :: rest =>
      if !config.rootModule.isAnonymous then
        throw "duplicate --root-module"
      else
        parseArgs rest { config with rootModule := value.toName }
  | "--root-declaration" :: value :: rest =>
      parseArgs rest {
        config with
        rootDeclarations := config.rootDeclarations.push value.toName
      }
  | "--base-import" :: value :: rest =>
      parseArgs rest {
        config with
        baseImports := config.baseImports.push value.toName
      }
  | "--output" :: value :: rest =>
      if config.output.isSome then
        throw "duplicate --output"
      else
        parseArgs rest { config with output := some value }
  | option :: _ =>
      throw s!"unknown or incomplete option: {option}"

private def declarationKind : ConstantInfo → String
  | .axiomInfo _ => "axiom"
  | .defnInfo _ => "definition"
  | .thmInfo _ => "theorem"
  | .opaqueInfo _ => "opaque"
  | .quotInfo _ => "quotient"
  | .inductInfo _ => "inductive"
  | .ctorInfo _ => "constructor"
  | .recInfo _ => "recursor"

private def nameLess (left right : Name) : Bool :=
  left.toString (escape := false) < right.toString (escape := false)

private def uniqueSortedNames (names : Array Name) : Array Name :=
  let names := names.foldl (init := ({} : Std.HashSet Name)) fun seen name =>
    seen.insert name
  names.toArray.qsort nameLess

private def directDependencies (info : ConstantInfo) : Array Name :=
  let fromType := info.type.getUsedConstants
  let fromValue :=
    match info.value? (allowOpaque := true) with
    | none => #[]
    | some value => value.getUsedConstants
  uniqueSortedNames (fromType ++ fromValue)

private def ownerModule (env : Environment) (name : Name) : Except String Name := do
  let some moduleIdx := env.getModuleIdxFor? name
    | throw s!"declaration-owner-missing: {name}"
  let some moduleName := env.header.moduleNames[moduleIdx]?
    | throw s!"declaration-owner-index-invalid: {name}: {moduleIdx}"
  return moduleName

private partial def visitDeclaration
    (baseEnv fullEnv : Environment)
    (name : Name)
    (state : ClosureState) :
    Except String ClosureState := do
  if baseEnv.contains name then
    return state
  if state.emitted.contains name then
    return state
  if state.visiting.contains name then
    throw s!"declaration-cycle: {name}"
  let some info := fullEnv.find? name
    | throw s!"declaration-missing: {name}"
  let dependencies := (directDependencies info).filter fun dependency =>
    fullEnv.contains dependency && !baseEnv.contains dependency
  let mut state := {
    state with
    visiting := state.visiting.insert name
  }
  for dependency in dependencies do
    state ← visitDeclaration baseEnv fullEnv dependency state
  let moduleName ← ownerModule fullEnv name
  return {
    visiting := state.visiting.erase name
    emitted := state.emitted.insert name
    declarations := state.declarations.push {
      name
      kind := declarationKind info
      ownerModule := moduleName
      localDependencies := dependencies
    }
  }

private def nameJson (name : Name) : Json :=
  .str (name.toString (escape := false))

private def namesJson (names : Array Name) : Json :=
  .arr (names.map nameJson)

private def sourceRangeJson (sourceRange : DeclarationRange) : Json :=
  .mkObj [
    ("start_line", toJson sourceRange.pos.line),
    ("start_column", toJson sourceRange.pos.column),
    ("start_char_utf16", toJson sourceRange.charUtf16),
    ("end_line", toJson sourceRange.endPos.line),
    ("end_column", toJson sourceRange.endPos.column),
    ("end_char_utf16", toJson sourceRange.endCharUtf16)
  ]

private def declarationJson (ranged : RangedDeclaration) : Json :=
  let declaration := ranged.declaration
  .mkObj [
    ("kind", .str declaration.kind),
    ("local_dependencies", namesJson declaration.localDependencies),
    ("name", nameJson declaration.name),
    ("owner_module", nameJson declaration.ownerModule),
    ("source_range", sourceRangeJson ranged.sourceRange)
  ]

private def collectDeclarationRanges
    (env : Environment)
    (declarations : Array Declaration) :
    IO (Except String (Array RangedDeclaration)) := do
  let action : Core.CoreM (Except String (Array RangedDeclaration)) := do
    let mut result : Array RangedDeclaration := #[]
    for declaration in declarations do
      if let some ranges ← findDeclarationRanges? declaration.name then
        result := result.push {
          declaration
          sourceRange := ranges.range
        }
    let rangedNames :=
      result.foldl
        (init := ({} : Std.HashSet Name))
        fun names ranged => names.insert ranged.declaration.name
    return .ok (result.map fun ranged => {
      ranged with
      declaration := {
        ranged.declaration with
        localDependencies :=
          ranged.declaration.localDependencies.filter rangedNames.contains
      }
    })
  let context : Core.Context := {
    fileName := "<declaration-closure-export>"
    fileMap := FileMap.ofString ""
  }
  let state : Core.State := { env }
  match ← EIO.toIO' ((action.run context) state) with
  | .error _ =>
      return .error "declaration-source-range-failed"
  | .ok (result, _) =>
      return result

private def positionLe (left right : Position) : Bool :=
  decide (
    left.line < right.line ∨
      (left.line = right.line ∧ left.column ≤ right.column)
  )

private def rangeContains
    (outer inner : DeclarationRange) :
    Bool :=
  positionLe outer.pos inner.pos &&
    positionLe inner.endPos outer.endPos

private def collectSourceFamilyNames
    (env : Environment)
    (declarations : Array Declaration) :
    IO (Except String (Array Name)) := do
  let action : Core.CoreM (Except String (Array Name)) := do
    let selectedNames :=
      declarations.foldl
        (init := ({} : Std.HashSet Name))
        fun names declaration => names.insert declaration.name
    let selectedModules :=
      declarations.foldl
        (init := ({} : Std.HashSet Name))
        fun modules declaration => modules.insert declaration.ownerModule
    let mut candidates : Array NamedRange := #[]
    for (name, _) in env.constants.toList do
      match ownerModule env name with
      | .error _ =>
          pure ()
      | .ok moduleName =>
          if selectedModules.contains moduleName then
            if let some ranges ← findDeclarationRanges? name then
              candidates := candidates.push {
                name
                ownerModule := moduleName
                sourceRange := ranges.range
              }
    let selectedRanges := candidates.filter fun candidate =>
      selectedNames.contains candidate.name
    let mut familyNames : Std.HashSet Name := {}
    for selected in selectedRanges do
      let mut outer := selected.sourceRange
      for candidate in candidates do
        if candidate.ownerModule = selected.ownerModule &&
            rangeContains candidate.sourceRange outer then
          outer := candidate.sourceRange
      for candidate in candidates do
        let isSourceDependencyCarrier :=
          selectedNames.contains candidate.name ||
            match env.find? candidate.name with
            | some (.inductInfo _) => true
            | some (.ctorInfo _) => true
            | _ => false
        if isSourceDependencyCarrier &&
            candidate.ownerModule = selected.ownerModule &&
            rangeContains outer candidate.sourceRange then
          familyNames := familyNames.insert candidate.name
    return .ok (uniqueSortedNames familyNames.toArray)
  let context : Core.Context := {
    fileName := "<declaration-source-family-export>"
    fileMap := FileMap.ofString ""
  }
  let state : Core.State := { env }
  match ← EIO.toIO' ((action.run context) state) with
  | .error _ =>
      return .error "declaration-source-family-failed"
  | .ok (result, _) =>
      return result

private partial def closeSourceFamilies
    (baseEnv fullEnv : Environment)
    (state : ClosureState) :
    IO (Except String ClosureState) := do
  match ← collectSourceFamilyNames fullEnv state.declarations with
  | .error error =>
      return .error error
  | .ok familyNames =>
      let previousSize := state.declarations.size
      let mut nextState := state
      for name in familyNames do
        nextState ←
          match visitDeclaration baseEnv fullEnv name nextState with
          | .ok visited => pure visited
          | .error error => return .error error
      if nextState.declarations.size = previousSize then
        return .ok nextState
      closeSourceFamilies baseEnv fullEnv nextState

private def receiptJson
    (config : Config)
    (declarations : Array RangedDeclaration) :
    Json :=
  let ownerModules :=
    uniqueSortedNames (declarations.map (·.declaration.ownerModule))
  .mkObj [
    ("base_imports", namesJson config.baseImports),
    ("declarations", .arr (declarations.map declarationJson)),
    ("lean_version", .str versionString),
    ("owner_modules", namesJson ownerModules),
    ("root_declarations", namesJson config.rootDeclarations),
    ("root_module", nameJson config.rootModule),
    ("schema_id", .str schemaId)
  ]

private def run (config : Config) : IO (Except String Json) := do
  try
    let baseEnv ← importModules
      (config.baseImports.map fun moduleName => { module := moduleName })
      {}
    let fullEnv ← importModules #[{ module := config.rootModule }] {}
    let mut state : ClosureState := {}
    for rootDeclaration in config.rootDeclarations do
      state ←
        match visitDeclaration baseEnv fullEnv rootDeclaration state with
        | .ok nextState => pure nextState
        | .error error => return .error error
    state ←
      match ← closeSourceFamilies baseEnv fullEnv state with
      | .ok nextState => pure nextState
      | .error error => return .error error
    match ← collectDeclarationRanges fullEnv state.declarations with
    | .error error => return .error error
    | .ok declarations =>
        let rangedNames :=
          declarations.foldl
            (init := ({} : Std.HashSet Name))
            fun names ranged => names.insert ranged.declaration.name
        match config.rootDeclarations.find? fun root =>
          !rangedNames.contains root with
        | some root =>
            return .error s!"root-source-range-missing: {root}"
        | none =>
            return .ok (receiptJson config declarations)
  catch error =>
    return .error s!"lean-environment-import-failed: {error}"

end PooFlowProof.Export.DeclarationClosure

def main (args : List String) : IO UInt32 := do
  match PooFlowProof.Export.DeclarationClosure.parseArgs args with
  | .error error =>
      IO.eprintln s!"{error}\n{PooFlowProof.Export.DeclarationClosure.usage}"
      return 2
  | .ok config =>
      match ← PooFlowProof.Export.DeclarationClosure.run config with
      | .error error =>
          IO.eprintln error
          return 1
      | .ok receipt =>
          let output := receipt.compress ++ "\n"
          match config.output with
          | none => IO.print output
          | some path => IO.FS.writeFile path output
          return 0
