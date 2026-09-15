;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

((schema . poo-flow.package-spec-root-mode-ab.v1)
 (scenarioKind . package-spec-projection-ab)
 (rootCount . 4)
 (minimumClosureTargetCount . 100)
 (maxModulesSpecNanoseconds . 5000000000)
 (rule . POO-FLOW-PACKAGE-SPEC-ROOT-MODE-001)
 (expectedOutcome . "four direct std/make roots are fast but incomplete; public-entry projection materializes the required package closure"))
