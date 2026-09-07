;;; Boundary: bounded owner-map observation value construction; persistence and
;;; runtime publication are outside this pure POO object owner.
(import (only-in :std/srfi/1 drop)
        (only-in :clan/poo/object .o object?))

(export poo-flow-owner-map-event-prototype
        poo-flow-detached-snapshot-prototype
        poo-flow-owner-map-event
        poo-flow-detached-snapshot
        poo-flow-bounded-event-append
        poo-flow-owner-map-observation-object?)

(def poo-flow-owner-map-event-prototype
  (.o (kind 'owner-map-event)))

(def poo-flow-detached-snapshot-prototype
  (.o (kind 'detached-snapshot)))

;; : (-> Symbol Symbol Symbol Integer POOObject)
(def (poo-flow-owner-map-event row-identity stage status sequence)
  (.o (kind 'owner-map-event)
      (row-identity row-identity)
      (stage stage)
      (status status)
      (sequence sequence)))

;; : (-> Integer [Symbol] String POOObject)
(def (poo-flow-detached-snapshot generation row-identities digest)
  (.o (kind 'detached-snapshot)
      (generation generation)
      (row-identities row-identities)
      (digest digest)))

;; poo-flow-bounded-event-append
;;   : (forall (a) (-> (List a) a Integer (List a)))
;;   : (-> [POOObject] POOObject Integer [POOObject])
;;   | doc m%
;;       Append one event and retain only the newest bounded suffix.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-bounded-event-append '(a b) 'c 2)
;;       ;; => (b c)
;;       ```
;;     %
(def (poo-flow-bounded-event-append events event limit)
  (let* ((next (append events (list event)))
         (overflow (max 0 (- (length next) limit))))
    (drop next overflow)))

;; : (-> Object Boolean)
(def (poo-flow-owner-map-observation-object? value)
  (object? value))
