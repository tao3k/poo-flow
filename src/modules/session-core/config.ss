;;; -*- Gerbil -*-
;;; Boundary: session-core module selection.
;;; Invariant: session-core enables report-only session declarations; it never
;;; realizes sandbox runtimes or Marlin handlers.

(import :poo-flow/src/module-system/base
        :poo-flow/src/modules/session/config)

(export (import: :poo-flow/src/modules/session/config)
        +poo-flow-session-core-default-flags+
        poo-flow-session-core-module-bundles)

;; : [Symbol]
(def +poo-flow-session-core-default-flags+
  '(+lineage +placement +handoff +graph +transform +doctor))

;;; Session-core is the OpenRath-inspired flowing-value module. Workflow,
;;; sandbox, memory, tool, and selector modules can build around it later.
;; : (-> Unit [[PooUserModuleSelection]])
(def poo-flow-session-core-module-bundles
  (list
   (poo-flow-user-module-bundle
    (session session-core
             +lineage
             +placement
             +handoff
             +graph
             +transform
             +doctor))))
