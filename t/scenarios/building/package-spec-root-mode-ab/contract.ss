;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

((schema . poo-flow.package-spec-root-mode-ab.v1)
 (scenarioKind . package-spec-projection-ab)
 (rootCount . 9)
 (minimumClosureTargetCount . 100)
 (maxModulesSpecNanoseconds . 5000000000)
 (requiredPublicOwners
  "src/core/plan.ss"
  "src/module-system/profile-composition/interface.ss"
  "src/feature-system/bundle-v1-composition-writer.ss"
  "src/contract/runtime-v0-abi-schema.ss"
  "src/policy/cedar-authority.ss"
  "src/proof/generated/proof-case-vector-v1.ss"
  "src/proof/proof-case-vector.ss"
  "src/qualification/runtime-symbol-manifest.ss")
 (rule . POO-FLOW-PACKAGE-SPEC-ROOT-MODE-001)
 (expectedOutcome . "nine direct std/make roots are fast but incomplete; public-entry projection materializes the required package closure"))
