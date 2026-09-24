;;; Inert negative fixture: root UI may select maintained values, but it must
;;; not reopen the maintainer-owned POO object layer.
(user-composition invalid-root
  (compose profiles
    (.def HiddenAdvancedProfile
      (stages (.o production: 'hidden)))))
