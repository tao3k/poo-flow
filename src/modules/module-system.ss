;;; -*- Gerbil -*-
;;; Boundary: public facade for the poo-flow module system.
;;; Invariant: implementation logic stays in the leaf owners below.

(import :modules/interface
        :modules/source
        :modules/descriptor
        :modules/context
        :modules/diagnostics
        :modules/resolver
        :modules/loader
        :modules/projection
        :modules/merge
        :modules/doctor
        :modules/user-config
        :modules/syntax)

(export (import: :modules/interface)
        (import: :modules/source)
        (import: :modules/descriptor)
        (import: :modules/context)
        (import: :modules/diagnostics)
        (import: :modules/resolver)
        (import: :modules/loader)
        (import: :modules/projection)
        (import: :modules/merge)
        (import: :modules/doctor)
        (import: :modules/user-config)
        (import: :modules/syntax))
