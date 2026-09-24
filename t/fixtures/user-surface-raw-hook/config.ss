;;; Inert negative fixture: raw self/super hooks belong to maintained behavior.
(user-composition raw-hook
  (compose profiles
    (lambda (self super) (super self))))
