// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
module NativeSemanticQuery {
  var queryPhase: str
  var contractBound: bool
  var providerBound: bool
  var resultBound: bool
  var semanticRevision: int
  var resultRevision: int
  var actionAuthority: bool
  val QueryPhases = Set("declared", "admitted", "executed", "rejected")
  action Init = all { queryPhase' = "declared", contractBound' = false, providerBound' = false, resultBound' = false, semanticRevision' = 0, resultRevision' = 0, actionAuthority' = false }
  action BindContract = all { queryPhase == "declared", contractBound' = true, queryPhase' = queryPhase, providerBound' = providerBound, resultBound' = resultBound, semanticRevision' = semanticRevision, resultRevision' = resultRevision, actionAuthority' = actionAuthority }
  action AdmitQuery = all { queryPhase == "declared", contractBound, queryPhase' = "admitted", contractBound' = contractBound, providerBound' = providerBound, resultBound' = resultBound, semanticRevision' = semanticRevision, resultRevision' = resultRevision, actionAuthority' = actionAuthority }
  action RejectQuery = all { queryPhase == "declared", not(contractBound), queryPhase' = "rejected", contractBound' = contractBound, providerBound' = providerBound, resultBound' = resultBound, semanticRevision' = semanticRevision, resultRevision' = resultRevision, actionAuthority' = actionAuthority }
  action ExecuteProvider = all { queryPhase == "admitted", contractBound, queryPhase' = "executed", providerBound' = true, resultBound' = true, resultRevision' = semanticRevision, contractBound' = contractBound, semanticRevision' = semanticRevision, actionAuthority' = actionAuthority }
  action Quiesce = all { Set("executed", "rejected").contains(queryPhase), queryPhase' = queryPhase, contractBound' = contractBound, providerBound' = providerBound, resultBound' = resultBound, semanticRevision' = semanticRevision, resultRevision' = resultRevision, actionAuthority' = actionAuthority }
  action step = any { BindContract , AdmitQuery , RejectQuery , ExecuteProvider , Quiesce }
  val TypeInvariant = QueryPhases.contains(queryPhase)  and  (semanticRevision >= 0)  and  (resultRevision >= 0)
  val QueryNeverMutatesSemanticRevision = semanticRevision == 0
  val QueryNeverGrantsActionAuthority = not(actionAuthority)
  val ProviderRequiresAdmission = providerBound  implies  queryPhase == "executed"  and  contractBound
  val ResultBindsProviderAndRevision = resultBound  implies  providerBound  and  resultRevision == semanticRevision
  action init = Init
  val safety = and { TypeInvariant, QueryNeverMutatesSemanticRevision, QueryNeverGrantsActionAuthority, ProviderRequiresAdmission, ResultBindsProviderAndRevision }
}
