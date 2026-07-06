;;; -*- Gerbil -*-
;;; Boundary: runtime facade for profile composition objects.
;;; Invariant: builders and accessors stay in separate policy owners.

(import :poo-flow/src/module-system/profile-composition-builders
        :poo-flow/src/module-system/profile-composition-accessors
        :poo-flow/src/module-system/profile-composition-compose-accessor)

(export (import: :poo-flow/src/module-system/profile-composition-builders)
        (import: :poo-flow/src/module-system/profile-composition-accessors)
        (import: :poo-flow/src/module-system/profile-composition-compose-accessor))
