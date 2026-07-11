;;; -*- Gerbil -*-
;;; Internal support shared by semantic tool-core object owners.

(import (only-in :clan/poo/object .ref)
        :poo-flow/src/modules/session/objects)

(export poo-flow-tool-field-rows
        poo-flow-tool-slot
        poo-flow-tool-ref?
        poo-flow-tool-symbol-list?
        poo-flow-tool-alist?
        poo-flow-tool-valid-sandbox-profile-ref?)

(defrules poo-flow-tool-field-rows ()
  ((_ (field value) ...)
   (list (cons 'field value) ...)))

(def (poo-flow-tool-slot object key default-value)
  (with-catch
   (lambda (_failure) default-value)
   (lambda ()
     (.ref object key))))

(def (poo-flow-tool-ref? value)
  (symbol? value))

(def (poo-flow-tool-symbol-list? values)
  (and (list? values)
       (poo-flow-session-every? symbol? values)))

(def (poo-flow-tool-alist? value)
  (list? value))

(def (poo-flow-tool-valid-sandbox-profile-ref? sandbox-required?
                                               sandbox-profile-ref)
  (or (not sandbox-required?)
      (symbol? sandbox-profile-ref)))
