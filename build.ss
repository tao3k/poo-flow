#!/usr/bin/env gxi
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; -*- Gerbil -*-
;;; Unique native POO Flow package build entry.

(import (only-in :std/build-script defbuild-script)
        ;; Native package declaration only needs the latency-bounded PackageSpec
        ;; facade. Optional profiles compose through PackageSpec POO slots and
        ;; must not add another framework to the `gerbil build` startup closure.
        (only-in :asp-gerbil-scheme/building-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype
                 default-exclude-dirs))

(def +poo-flow-build-exclude-dirs+
  (append '("packages/lambda-episteme"
            "core"
            "bindings"
            "packages"
            "target"
            "user-interface")
          default-exclude-dirs))

(def +nono-c-include-option+
  (string-append
   "-I"
   (path-expand "bindings/nono-c" (current-directory))))

(def +nono-c-link-option+
  (cond-expand
   (darwin "-Wl,-undefined,dynamic_lookup")
   (else "-ldl")))

;;; Gambit emits a loadable bundle for begin-ffi modules on Darwin.  The
;;; process/AOT consumer supplies libc and runtime symbols at final link time.
(def +runtime-v0-native-ffi-spec+
  (cond-expand
   (darwin
    '(gxc: "src/ffi/runtime-v0-native"
           "-ld-options" "-Wl,-undefined,dynamic_lookup"))
   (else
    '(gxc: "src/ffi/runtime-v0-native"))))

(def +semantic-native-ffi-spec+
  (cond-expand
   (darwin '(gxc: "src/ffi/semantic" "-ld-options" "-Wl,-undefined,dynamic_lookup"))
   (else '(gxc: "src/ffi/semantic"))))

(asp-gerbil-scheme-package-spec!
 (poo-flow-package-spec
 @ asp-gerbil-scheme-library-package-prototype)
 (spec poo-flow-native-spec)
 (public-entry-modules
  '("src/core/api.ss"
    "testing-api.ss"
    "src/graph/interface.ss"
    "src/authoring/module-descriptor.ss"
    "src/user-interface/module-activation.ss"
    "src/user-interface/module-selection-syntax.ss"
    "src/authoring/module-source-collection.ss"
    "src/building/official-contributions.ss"
    "src/user-interface/module-source-selection.ss"
    "src/user-interface/module-source-tree.ss"
    "src/authoring/source-authoring.ss"
    "src/testing/source-admission.ss"
    "src/user-interface/module-diagnostics.ss"
    "src/user-interface/doctor-presentation.ss"
    "src/building/build-projection.ss"
    "src/proof/composition-facts.ss"
    "src/scenario/profile-root.ss"
    "src/scenario/composition-syntax.ss"
    "src/scenario/case.ss"
    "src/scenario/accessors.ss"
    "src/scenario/workload.ss"
    "src/scenario/plan-projection.ss"
    "src/user-interface/profile-core.ss"
    "src/user-interface/init-declaration-syntax.ss"
    "modules/session/interface.ss"
    "modules/funflow/interface.ss"
    "modules/ai-agentic-context/interface.ss"
    "modules/funflow/runtime-load-projection.ss"
    "src/profiles/human-ai-capability.ss"
    "src/profiles/agentic-research.ss"
    "modules/authorization/interface.ss"
    "modules/authorization/providers/cedar/interface.ss"
    "modules/governance/interface.ss"
    "modules/proof/interface.ss"
    "modules/ai-agentic-context/use-host.ss"
    "modules/ai-agentic-context/session-host.ss"
    "src/semantic/context-restriction.ss"
    "src/semantic/orgize-interface.ss"
    "src/semantic/orgize-source-interface.ss"
    "modules/query/interface.ss"
    "modules/search-engine/interface.ss"
    "modules/query/rust-ir.ss"
    "modules/standards/interface.ss"
    "modules/temporal-causality/interface.ss"
    "modules/temporal-causality/ascent-exchange.ss"
    ;; Advanced embedded owner projections must ship in the installed package.
    ;; Ordinary authoring continues through the POO-native Temporal interface.
    "src/ffi/scheme-wire.ss"
    "src/ffi/temporal-policy.ss"
    "src/ffi/context-use.ss"
    "src/ffi/temporal-proof.ss"
    "src/ffi/temporal-proof-host.ss"
    "src/feature-system/interface.ss"))
 (exclude-dirs +poo-flow-build-exclude-dirs+)
 (exclude-modules '("modules/nono-sandbox/_nono.ss"
                    "src/ffi/runtime-v0-native.ss"
                    "src/ffi/semantic.ss"
                    "observe-contribute-import.ss"
                    "performance-tests.ss"
                    "run-contribute-test.ss"))
 (native-prelude-spec
  `((gxc: "modules/nono-sandbox/_nono"
          "-cc-options" ,+nono-c-include-option+
          "-ld-options" ,+nono-c-link-option+)))
 (extra-spec `(,+runtime-v0-native-ffi-spec+ ,+semantic-native-ffi-spec+)))

(defbuild-script (poo-flow-native-spec))
