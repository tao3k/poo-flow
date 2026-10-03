;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :clan/poo/object .o) (only-in :clan/poo/mop validate) "bundle-types.ss")
(export poo-flow-tla-source-file-value poo-flow-tla-tool-artifact poo-flow-tla-toolchain-value
        poo-flow-tla-bundle-value poo-flow-tla-checked-bundle-value)
(def (poo-flow-tla-source-file-value name text sha doc)
  (validate PooFlowTlaSourceFile (.o kind: 'tla/source-file identity: name content: text semantic-digest: sha document: doc)))
(def (poo-flow-tla-tool-artifact filename sha)
  (validate PooFlowTlaToolArtifact (.o kind: 'tla/tool-artifact path: filename semantic-digest: sha)))
(def (poo-flow-tla-toolchain-value java-value jar-value files sha)
  (validate PooFlowTlaToolchain (.o kind: 'tla/toolchain java: java-value jar: jar-value artifacts: files semantic-digest: sha)))
(def (poo-flow-tla-bundle-value root files tools count sha)
  (validate PooFlowTlaBundle (.o kind: 'tla/source-bundle identity: root sources: files toolchain: tools workers: count semantic-digest: sha)))
(def (poo-flow-tla-checked-bundle-value id bundle-sha tool-sha transcript transcript-sha)
  (validate PooFlowTlaCheckedBundle (.o kind: 'tla/checked-bundle identity: id bundle-digest: bundle-sha toolchain-digest: tool-sha
                                      output: transcript output-digest: transcript-sha semantic-refinement?: #f action-authorized?: #f)))
