;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;; Context owns Memory as an optional Feature. Session is an independent Module.
(import :poo-flow/src/feature-system/model
        :poo-flow/src/feature-system/feature-manifest)
(export ai-agentic-context-core-feature ai-agentic-context-memory-feature
        poo-flow-ai-agentic-context-profile)
(def ai-agentic-context-core-feature
  (feature-descriptor
    (feature-descriptor-base 'ai-agentic-context/core 'ai-agentic-context)))
(def ai-agentic-context-memory-feature
  (feature-descriptor (feature-spec-compose
    (feature-descriptor-base 'ai-agentic-context/memory 'ai-agentic-context)
    (feature-required-features ai-agentic-context-core-feature))))
(def (poo-flow-ai-agentic-context-profile memory?)
  (unless (boolean? memory?)
    (error "Context Feature selections must be Boolean values"))
  (require-valid-feature-manifest-bundle
    (feature-manifest-bundle 'ai-agentic-context
      (append (list ai-agentic-context-core-feature)
        (if memory? (list ai-agentic-context-memory-feature) '())))))
