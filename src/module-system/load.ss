;;; -*- Gerbil -*-
;;; Boundary: hygienic Doom-style module selection syntax.
;;; Invariant: expansion produces POO selection values only; source discovery,
;;; descriptor realization, and runtime effects stay behind loader boundaries.

(import (only-in :poo-flow/src/module-system/base
                 poo-flow-user-module-bundle))

(export poo-flow-modules!)

(defrules poo-flow-modules/category
  (:core :flow :workflow :session :loop :sandbox :custom)
  ((_ category) '())
  ((_ category :core row ...) (poo-flow-modules! :core row ...))
  ((_ category :flow row ...) (poo-flow-modules! :flow row ...))
  ((_ category :workflow row ...) (poo-flow-modules! :flow row ...))
  ((_ category :session row ...) (poo-flow-modules! :session row ...))
  ((_ category :loop row ...) (poo-flow-modules! :loop row ...))
  ((_ category :sandbox row ...) (poo-flow-modules! :sandbox row ...))
  ((_ category :custom row ...) (poo-flow-modules! :custom row ...))
  ((_ category (module flag ...) row ...)
   (cons (poo-flow-user-module-bundle (category module flag ...))
         (poo-flow-modules/category category row ...))))

(defrules poo-flow-modules/custom
  (:core :flow :workflow :session :loop :sandbox :custom)
  ((_) '())
  ((_ :core row ...) (poo-flow-modules! :core row ...))
  ((_ :flow row ...) (poo-flow-modules! :flow row ...))
  ((_ :workflow row ...) (poo-flow-modules! :flow row ...))
  ((_ :session row ...) (poo-flow-modules! :session row ...))
  ((_ :loop row ...) (poo-flow-modules! :loop row ...))
  ((_ :sandbox row ...) (poo-flow-modules! :sandbox row ...))
  ((_ :custom row ...) (poo-flow-modules/custom row ...))
  ((_ (module root flag ...) row ...)
   (cons (poo-flow-user-module-bundle (custom module root flag ...))
         (poo-flow-modules/custom row ...))))

;;; One macro serves the maintained collection and downstream init.ss files.
(defrules poo-flow-modules!
  (:core :flow :workflow :session :loop :sandbox :custom)
  ((_) '())
  ((_ :core row ...) (poo-flow-modules/category core row ...))
  ((_ :flow row ...) (poo-flow-modules/category flow row ...))
  ((_ :workflow row ...) (poo-flow-modules/category flow row ...))
  ((_ :session row ...) (poo-flow-modules/category session row ...))
  ((_ :loop row ...) (poo-flow-modules/category loop row ...))
  ((_ :sandbox row ...) (poo-flow-modules/category sandbox row ...))
  ((_ :custom row ...) (poo-flow-modules/custom row ...)))
