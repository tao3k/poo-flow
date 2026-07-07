(import (only-in :clan/poo/object .o .ref object<-alist))

;;; Scenario input: adapter-heavy projection.  The profile starts as an alist,
;;; crosses into POO repeatedly, and computes every descriptor by hand.

(def +profile-data+
  '((name . projection-profile)
    (runtime . python-runtime)
    (policy . control-plane)
    (sandbox . readonly)
    (tool . search-tool)
    (checkpoint . durable)))

(def (profile-object)
  (object<-alist +profile-data+))

(def (projection-descriptor key)
  (let ((profile (profile-object)))
    (vector key (.ref profile key) 'projected)))

(def (projection-descriptors)
  (map projection-descriptor
       '(name runtime policy sandbox tool checkpoint)))
