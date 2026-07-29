import PooFlowProof.PooC3.ControlPolicyProfileProjection

namespace PooFlowProof.PooC3.UseCompositionMacroContract

structure CurrentMacroGap where
  parsesDedicatedModuleForm : Prop
  dedicatedModuleParsingObserved : parsesDedicatedModuleForm
  parsesClauseSequence : Prop
  clauseParsingObserved : parsesClauseSequence
  returnsExpressionWithoutNamedBinding : Prop
  missingBindingObserved : returnsExpressionWithoutNamedBinding
  requiresDuplicateOuterDefinition : Prop
  duplicateDefinitionObserved : requiresDuplicateOuterDefinition
  composeIsClauseTransformer : Prop
  clauseComposeObserved : composeIsClauseTransformer
  profilesIsClauseTransformer : Prop
  clauseProfilesObserved : profilesIsClauseTransformer
  usesAlistLowering : Prop
  alistLoweringObserved : usesAlistLowering
  implementationAndDocumentationDisagree : Prop
  disagreementObserved : implementationAndDocumentationDisagree
  verifiedDefprofileImplementationExists : Prop
  noVerifiedDefprofile : ¬ verifiedDefprofileImplementationExists

structure TargetMacroShape where
  operandCountAfterMacroName : Nat
  exactlyTwoOperands : operandCountAfterMacroName = 2
  compositionNameIsIdentifier : Prop
  identifierEstablished : compositionNameIsIdentifier
  compositionExpressionPreserved : Prop
  expressionPreservationEstablished : compositionExpressionPreserved
  moduleLevelBindingCount : Nat
  exactlyOneBinding : moduleLevelBindingCount = 1
  enclosingDefinitionRequired : Prop
  noEnclosingDefinition : ¬ enclosingDefinitionRequired
  stableIdentityProjected : Prop
  identityProjectionEstablished : stableIdentityProjected
  rootInstantiationCount : Nat
  exactlyOneRootInstantiation : rootInstantiationCount = 1

structure HygieneContract where
  lexicalReferencesPreserved : Prop
  lexicalPreservationEstablished : lexicalReferencesPreserved
  importedBindingIdentitiesPreserved : Prop
  importedIdentitiesEstablished : importedBindingIdentitiesPreserved
  sourceLocationsPreserved : Prop
  sourceLocationsEstablished : sourceLocationsPreserved
  privateTemporaryCaptureOccurs : Prop
  noTemporaryCapture : ¬ privateTemporaryCaptureOccurs
  expressionConvertedToDatum : Prop
  noDatumConversion : ¬ expressionConvertedToDatum
  textualIdentifierDispatchOccurs : Prop
  noTextualDispatch : ¬ textualIdentifierDispatchOccurs
  importRenamingMutatesStableIdentity : Prop
  identityIndependentOfImportRename : ¬ importRenamingMutatesStableIdentity

structure ThinMacroBoundary where
  parsesComposeBody : Prop
  noComposeParsing : ¬ parsesComposeBody
  enumeratesOperands : Prop
  noOperandEnumeration : ¬ enumeratesOperands
  expandsProfileClauses : Prop
  noProfileClauseExpansion : ¬ expandsProfileClauses
  resolvesModuleAliases : Prop
  noAliasResolution : ¬ resolvesModuleAliases
  constructsAlist : Prop
  noAlistConstruction : ¬ constructsAlist
  callsObjectFromAlist : Prop
  noObjectFromAlist : ¬ callsObjectFromAlist
  manufacturesHooks : Prop
  noHookManufacture : ¬ manufacturesHooks
  inspectsPolicies : Prop
  noPolicyInspection : ¬ inspectsPolicies
  issuesCapabilities : Prop
  noCapabilityIssuance : ¬ issuesCapabilities
  installsRuntimeHandler : Prop
  noHandlerInstallation : ¬ installsRuntimeHandler
  evaluatesProfileDuringExpansion : Prop
  noExpansionEvaluation : ¬ evaluatesProfileDuringExpansion

structure ValueLevelBoundary where
  composeIsPureFunction : Prop
  composePurityEstablished : composeIsPureFunction
  profilesIsPooStrategy : Prop
  profilesStrategyEstablished : profilesIsPooStrategy
  useModuleIsIndependentValueProjection : Prop
  independentUseModuleEstablished : useModuleIsIndependentValueProjection
  profileBundlePreservesImportsIdentityCapability : Prop
  bundleProjectionEstablished : profileBundlePreservesImportsIdentityCapability
  recursiveImportsResolvedOutsideMacro : Prop
  importsPhaseEstablished : recursiveImportsResolvedOutsideMacro
  onlyAdmittedBackendImportsProjected : Prop
  backendProjectionEstablished : onlyAdmittedBackendImportsProjected

structure PhaseBoundary where
  expansionOwnsOnlyStructureAndIdentity : Prop
  expansionBoundaryEstablished : expansionOwnsOnlyStructureAndIdentity
  valueInitializationEvaluatesExpression : Prop
  valuePhaseEstablished : valueInitializationEvaluatesExpression
  rootOwnsSinglePooInstantiation : Prop
  rootBoundaryEstablished : rootOwnsSinglePooInstantiation
  runtimeReentersMacroExpansion : Prop
  noRuntimeReentry : ¬ runtimeReentersMacroExpansion
  macroPerformsPackageDiscovery : Prop
  noPackageDiscovery : ¬ macroPerformsPackageDiscovery

structure DirectReplacementBoundary where
  oldGrammarAccepted : Prop
  oldGrammarRejected : ¬ oldGrammarAccepted
  legacyParserFallbackExists : Prop
  noLegacyFallback : ¬ legacyParserFallbackExists
  syntaxVersionTokenExists : Prop
  noSyntaxVersionToken : ¬ syntaxVersionTokenExists
  deprecationPeriodExists : Prop
  noDeprecationPeriod : ¬ deprecationPeriodExists
  automaticSourceRewriteExists : Prop
  noAutomaticRewrite : ¬ automaticSourceRewriteExists
  runtimeCompatibilityAdapterExists : Prop
  noRuntimeCompatibilityAdapter : ¬ runtimeCompatibilityAdapterExists

structure ErrorBoundary where
  invalidArityIsMacroError : Prop
  arityErrorEstablished : invalidArityIsMacroError
  nonIdentifierIsMacroError : Prop
  identifierErrorEstablished : nonIdentifierIsMacroError
  identityOrRootProjectionFailureIsMacroBoundaryError : Prop
  projectionErrorEstablished : identityOrRootProjectionFailureIsMacroBoundaryError
  expressionErrorsPreserveOwnerAndLocation : Prop
  expressionErrorOwnershipEstablished : expressionErrorsPreserveOwnerAndLocation
  semanticFailureCollapsedToClauseParserError : Prop
  noSemanticErrorCollapse : ¬ semanticFailureCollapsedToClauseParserError

structure MacroAdmissionClosure where
  targetNameIsUseComposition : Prop
  twoOperandShapeEstablished : Prop
  singleBindingEstablished : Prop
  identityProjectionPooNative : Prop
  composeAndProfilesAreValues : Prop
  importsBoundaryEstablished : Prop
  clauseParserRemovedFromPublicPath : Prop
  noCompatibilitySurface : Prop
  hygieneEstablished : Prop
  phaseBoundaryEstablished : Prop
  userInterfaceCasesAligned : Prop
  gerbilPooCallsVerified : Prop
  priorRfcObligationsSatisfied : Prop

def ImplementationAdmitted (closure : MacroAdmissionClosure) : Prop :=
  closure.targetNameIsUseComposition ∧
    closure.twoOperandShapeEstablished ∧
    closure.singleBindingEstablished ∧
    closure.identityProjectionPooNative ∧
    closure.composeAndProfilesAreValues ∧
    closure.importsBoundaryEstablished ∧
    closure.clauseParserRemovedFromPublicPath ∧
    closure.noCompatibilitySurface ∧
    closure.hygieneEstablished ∧
    closure.phaseBoundaryEstablished ∧
    closure.userInterfaceCasesAligned ∧
    closure.gerbilPooCallsVerified ∧
    closure.priorRfcObligationsSatisfied

theorem currentMacroParsesDedicatedModuleForm
    (gap : CurrentMacroGap) :
    gap.parsesDedicatedModuleForm :=
  gap.dedicatedModuleParsingObserved

theorem currentMacroParsesClauseSequence
    (gap : CurrentMacroGap) :
    gap.parsesClauseSequence :=
  gap.clauseParsingObserved

theorem currentMacroDoesNotCreateNamedBinding
    (gap : CurrentMacroGap) :
    gap.returnsExpressionWithoutNamedBinding :=
  gap.missingBindingObserved

theorem currentCallSiteRequiresDuplicateDefinition
    (gap : CurrentMacroGap) :
    gap.requiresDuplicateOuterDefinition :=
  gap.duplicateDefinitionObserved

theorem currentComposeAndProfilesAreClauseTransformers
    (gap : CurrentMacroGap) :
    gap.composeIsClauseTransformer ∧ gap.profilesIsClauseTransformer :=
  ⟨gap.clauseComposeObserved, gap.clauseProfilesObserved⟩

theorem currentPathUsesAlistLowering
    (gap : CurrentMacroGap) :
    gap.usesAlistLowering :=
  gap.alistLoweringObserved

theorem currentImplementationAndDocumentationDisagree
    (gap : CurrentMacroGap) :
    gap.implementationAndDocumentationDisagree :=
  gap.disagreementObserved

theorem noVerifiedDefprofileMayBeAssumed
    (gap : CurrentMacroGap) :
    ¬ gap.verifiedDefprofileImplementationExists :=
  gap.noVerifiedDefprofile

theorem targetMacroHasExactlyTwoOperands
    (shape : TargetMacroShape) :
    shape.operandCountAfterMacroName = 2 :=
  shape.exactlyTwoOperands

theorem targetNameMustBeIdentifier
    (shape : TargetMacroShape) :
    shape.compositionNameIsIdentifier :=
  shape.identifierEstablished

theorem targetPreservesExpressionAsOneSchemeExpression
    (shape : TargetMacroShape) :
    shape.compositionExpressionPreserved :=
  shape.expressionPreservationEstablished

theorem targetCreatesExactlyOneBinding
    (shape : TargetMacroShape) :
    shape.moduleLevelBindingCount = 1 :=
  shape.exactlyOneBinding

theorem targetRequiresNoOuterDefinition
    (shape : TargetMacroShape) :
    ¬ shape.enclosingDefinitionRequired :=
  shape.noEnclosingDefinition

theorem targetProjectsStableCompositionIdentity
    (shape : TargetMacroShape) :
    shape.stableIdentityProjected :=
  shape.identityProjectionEstablished

theorem targetInstantiatesRootExactlyOnce
    (shape : TargetMacroShape) :
    shape.rootInstantiationCount = 1 :=
  shape.exactlyOneRootInstantiation

theorem hygienePreservesLexicalReferences
    (hygiene : HygieneContract) :
    hygiene.lexicalReferencesPreserved :=
  hygiene.lexicalPreservationEstablished

theorem hygienePreservesImportedBindingIdentities
    (hygiene : HygieneContract) :
    hygiene.importedBindingIdentitiesPreserved :=
  hygiene.importedIdentitiesEstablished

theorem hygienePreservesSourceLocations
    (hygiene : HygieneContract) :
    hygiene.sourceLocationsPreserved :=
  hygiene.sourceLocationsEstablished

theorem hygienicTemporariesCannotCapture
    (hygiene : HygieneContract) :
    ¬ hygiene.privateTemporaryCaptureOccurs :=
  hygiene.noTemporaryCapture

theorem expressionIsNotConvertedToDatum
    (hygiene : HygieneContract) :
    ¬ hygiene.expressionConvertedToDatum :=
  hygiene.noDatumConversion

theorem macroDoesNotDispatchOnTextualIdentifiers
    (hygiene : HygieneContract) :
    ¬ hygiene.textualIdentifierDispatchOccurs :=
  hygiene.noTextualDispatch

theorem importRenamingCannotMutateStableIdentity
    (hygiene : HygieneContract) :
    ¬ hygiene.importRenamingMutatesStableIdentity :=
  hygiene.identityIndependentOfImportRename

theorem macroDoesNotParseComposeBody
    (boundary : ThinMacroBoundary) :
    ¬ boundary.parsesComposeBody :=
  boundary.noComposeParsing

theorem macroDoesNotEnumerateOperands
    (boundary : ThinMacroBoundary) :
    ¬ boundary.enumeratesOperands :=
  boundary.noOperandEnumeration

theorem macroDoesNotExpandProfileClauses
    (boundary : ThinMacroBoundary) :
    ¬ boundary.expandsProfileClauses :=
  boundary.noProfileClauseExpansion

theorem macroDoesNotResolveModuleAliases
    (boundary : ThinMacroBoundary) :
    ¬ boundary.resolvesModuleAliases :=
  boundary.noAliasResolution

theorem macroConstructsNoAlist
    (boundary : ThinMacroBoundary) :
    ¬ boundary.constructsAlist :=
  boundary.noAlistConstruction

theorem macroCallsNoObjectFromAlist
    (boundary : ThinMacroBoundary) :
    ¬ boundary.callsObjectFromAlist :=
  boundary.noObjectFromAlist

theorem macroManufacturesNoHooks
    (boundary : ThinMacroBoundary) :
    ¬ boundary.manufacturesHooks :=
  boundary.noHookManufacture

theorem macroDoesNotInspectPolicies
    (boundary : ThinMacroBoundary) :
    ¬ boundary.inspectsPolicies :=
  boundary.noPolicyInspection

theorem macroIssuesNoCapabilities
    (boundary : ThinMacroBoundary) :
    ¬ boundary.issuesCapabilities :=
  boundary.noCapabilityIssuance

theorem macroInstallsNoRuntimeHandler
    (boundary : ThinMacroBoundary) :
    ¬ boundary.installsRuntimeHandler :=
  boundary.noHandlerInstallation

theorem macroDoesNotEvaluateProfilesDuringExpansion
    (boundary : ThinMacroBoundary) :
    ¬ boundary.evaluatesProfileDuringExpansion :=
  boundary.noExpansionEvaluation

theorem composeAndProfilesRemainValueLevelAbstractions
    (boundary : ValueLevelBoundary) :
    boundary.composeIsPureFunction ∧ boundary.profilesIsPooStrategy :=
  ⟨boundary.composePurityEstablished, boundary.profilesStrategyEstablished⟩

theorem useModuleRemainsIndependentValueProjection
    (boundary : ValueLevelBoundary) :
    boundary.useModuleIsIndependentValueProjection :=
  boundary.independentUseModuleEstablished

theorem profileBundlePreservesImportsIdentityCapability
    (boundary : ValueLevelBoundary) :
    boundary.profileBundlePreservesImportsIdentityCapability :=
  boundary.bundleProjectionEstablished

theorem recursiveImportsResolveOutsideMacro
    (boundary : ValueLevelBoundary) :
    boundary.recursiveImportsResolvedOutsideMacro :=
  boundary.importsPhaseEstablished

theorem onlyAdmittedBackendImportsAreProjected
    (boundary : ValueLevelBoundary) :
    boundary.onlyAdmittedBackendImportsProjected :=
  boundary.backendProjectionEstablished

theorem expansionOwnsOnlyStructureAndIdentity
    (boundary : PhaseBoundary) :
    boundary.expansionOwnsOnlyStructureAndIdentity :=
  boundary.expansionBoundaryEstablished

theorem valueInitializationOwnsExpressionEvaluation
    (boundary : PhaseBoundary) :
    boundary.valueInitializationEvaluatesExpression :=
  boundary.valuePhaseEstablished

theorem rootOwnsSinglePooInstantiation
    (boundary : PhaseBoundary) :
    boundary.rootOwnsSinglePooInstantiation :=
  boundary.rootBoundaryEstablished

theorem runtimeCannotReenterMacroExpansion
    (boundary : PhaseBoundary) :
    ¬ boundary.runtimeReentersMacroExpansion :=
  boundary.noRuntimeReentry

theorem macroPerformsNoPackageDiscovery
    (boundary : PhaseBoundary) :
    ¬ boundary.macroPerformsPackageDiscovery :=
  boundary.noPackageDiscovery

theorem oldGrammarIsRejected
    (replacement : DirectReplacementBoundary) :
    ¬ replacement.oldGrammarAccepted :=
  replacement.oldGrammarRejected

theorem noLegacyParserFallbackExists
    (replacement : DirectReplacementBoundary) :
    ¬ replacement.legacyParserFallbackExists :=
  replacement.noLegacyFallback

theorem noSyntaxVersionTokenExists
    (replacement : DirectReplacementBoundary) :
    ¬ replacement.syntaxVersionTokenExists :=
  replacement.noSyntaxVersionToken

theorem noDeprecationPeriodExists
    (replacement : DirectReplacementBoundary) :
    ¬ replacement.deprecationPeriodExists :=
  replacement.noDeprecationPeriod

theorem noAutomaticSourceRewriteExists
    (replacement : DirectReplacementBoundary) :
    ¬ replacement.automaticSourceRewriteExists :=
  replacement.noAutomaticRewrite

theorem noRuntimeCompatibilityAdapterExists
    (replacement : DirectReplacementBoundary) :
    ¬ replacement.runtimeCompatibilityAdapterExists :=
  replacement.noRuntimeCompatibilityAdapter

theorem invalidArityIsOwnedByMacro
    (boundary : ErrorBoundary) :
    boundary.invalidArityIsMacroError :=
  boundary.arityErrorEstablished

theorem nonIdentifierErrorIsOwnedByMacro
    (boundary : ErrorBoundary) :
    boundary.nonIdentifierIsMacroError :=
  boundary.identifierErrorEstablished

theorem identityAndRootProjectionFailureIsMacroBoundaryError
    (boundary : ErrorBoundary) :
    boundary.identityOrRootProjectionFailureIsMacroBoundaryError :=
  boundary.projectionErrorEstablished

theorem expressionErrorsPreserveSemanticOwnerAndLocation
    (boundary : ErrorBoundary) :
    boundary.expressionErrorsPreserveOwnerAndLocation :=
  boundary.expressionErrorOwnershipEstablished

theorem semanticFailureCannotCollapseToClauseParserError
    (boundary : ErrorBoundary) :
    ¬ boundary.semanticFailureCollapsedToClauseParserError :=
  boundary.noSemanticErrorCollapse

theorem implementationRequirements
    (closure : MacroAdmissionClosure)
    (admitted : ImplementationAdmitted closure) :
    closure.targetNameIsUseComposition ∧
      closure.twoOperandShapeEstablished ∧
      closure.singleBindingEstablished ∧
      closure.identityProjectionPooNative ∧
      closure.composeAndProfilesAreValues ∧
      closure.importsBoundaryEstablished ∧
      closure.clauseParserRemovedFromPublicPath ∧
      closure.noCompatibilitySurface ∧
      closure.hygieneEstablished ∧
      closure.phaseBoundaryEstablished ∧
      closure.userInterfaceCasesAligned ∧
      closure.gerbilPooCallsVerified ∧
      closure.priorRfcObligationsSatisfied :=
  admitted

theorem wrongTargetMacroNameBlocksImplementation
    (closure : MacroAdmissionClosure)
    (missing : ¬ closure.targetNameIsUseComposition) :
    ¬ ImplementationAdmitted closure := by
  intro admitted
  exact missing (implementationRequirements closure admitted).1

theorem compatibilitySurfaceBlocksImplementation
    (closure : MacroAdmissionClosure)
    (invalid : ¬ closure.noCompatibilitySurface) :
    ¬ ImplementationAdmitted closure := by
  intro admitted
  exact invalid
    (implementationRequirements closure admitted).2.2.2.2.2.2.2.1

theorem unverifiedGerbilPooCallsBlockImplementation
    (closure : MacroAdmissionClosure)
    (missing : ¬ closure.gerbilPooCallsVerified) :
    ¬ ImplementationAdmitted closure := by
  intro admitted
  exact missing
    (implementationRequirements closure admitted).2.2.2.2.2.2.2.2.2.2.2.1

end PooFlowProof.PooC3.UseCompositionMacroContract
