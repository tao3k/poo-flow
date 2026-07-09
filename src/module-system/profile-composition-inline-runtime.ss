;;; -*- Gerbil -*-
;;; Boundary: runtime helpers used by user-facing composition macros.
;;; Invariant: keep POO object construction and hook normalization outside
;;; macro parser modules so macro expansion remains shallow and reusable.

(import (only-in :clan/poo/object .all-slots .o .ref object<-alist))

(export poo-flow-composition-inline-section-slot
        poo-flow-composition-inline-alist-ref
        poo-flow-composition-inline-profile-field
        poo-flow-composition-inline-profile-ref/default
        poo-flow-composition-inline-profile-normalize
        poo-flow-composition-inline-apply-hooks
        poo-flow-composition-inline-imported-profile
        poo-flow-composition-inline-module
        poo-flow-composition-inline-profile)

;; : (-> Symbol Symbol)
(def (poo-flow-composition-inline-section-slot key)
  (case key
    ((:extends extends) 'extends)
    ((:kind kind) 'kind)
    ((:scope scope) 'scope)
    ((:storage storage) 'storage)
    ((:analysis analysis) 'analysis)
    ((:publish publish) 'publish)
    ((:retention retention) 'retention)
    ((:capabilities capabilities) 'capabilities)
    ((:with with) 'hooks)
    (else key)))

;; : (-> Alist Symbol Datum Datum)
(def (poo-flow-composition-inline-alist-ref alist key default)
  (let (entry (assoc key alist))
    (if entry (cdr entry) default)))

;; : (-> PooProfile Symbol Datum Datum)
(def (poo-flow-composition-inline-profile-ref/default profile key default)
  (poo-flow-composition-inline-profile-ref/default*
   profile
   (.all-slots profile)
   key
   default))

;; : (-> PooProfile [Symbol] Symbol Datum Datum)
(def (poo-flow-composition-inline-profile-ref/default*
      profile
      slots
      key
      default)
  (if (memq key slots)
    (.ref profile key)
    default))

;; : (-> Alist Datum Symbol Datum Datum)
(def (poo-flow-composition-inline-profile-field sections base key default)
  (poo-flow-composition-inline-alist-ref
   sections
   key
   (if base
     (poo-flow-composition-inline-profile-ref/default base key default)
     default)))

;;; Boundary: inline profile normalization keeps authoring-time profile values
;;; deterministic before composition stages inherit or extend them.
;; : (-> PooProfile PooProfile PooProfile)
(def (poo-flow-composition-inline-profile-normalize base profile)
  (let ((base-slots (.all-slots base))
        (profile-slots (.all-slots profile)))
    (object<-alist
     (list
      (cons 'name
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'name
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'name 'profile)))
      (cons 'extends
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'extends
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'extends #f)))
      (cons 'kind
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'kind
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'kind 'profile)))
      (cons 'scope
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'scope
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'scope '())))
      (cons 'storage
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'storage
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'storage '())))
      (cons 'analysis
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'analysis
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'analysis '())))
      (cons 'publish
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'publish
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'publish '())))
      (cons 'retention
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'retention
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'retention '())))
      (cons 'capabilities
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'capabilities
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'capabilities '())))
      (cons 'hooks
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'hooks
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'hooks '())))
      (cons 'runtime-executed
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'runtime-executed
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'runtime-executed #f)))
      (cons 'source
            (poo-flow-composition-inline-profile-ref/default*
             profile profile-slots 'source
             (poo-flow-composition-inline-profile-ref/default*
              base base-slots 'source
              'poo-flow.composition.inline-profile)))))))

;; : (-> PooProfile [(-> PooProfile PooProfile)] PooProfile)
(def (poo-flow-composition-inline-apply-hooks profile hooks)
  (foldl
   (lambda (hook out)
     (poo-flow-composition-inline-profile-normalize out (hook out)))
   profile
   hooks))

;; : (-> Symbol Symbol PooProfile)
(def (poo-flow-composition-inline-imported-profile module-name profile-name)
  (.o (kind 'poo-flow.composition.imported-profile)
      (name profile-name)
      (module module-name)
      (profile profile-name)
      (source (list 'use-module module-name))
      (runtime-executed #f)))

;; : (-> List List Object)
;; | doc m%
;; Builds the runtime POO module object for inline profile composition.
;; `profile-names` and `profile-values` must have the same length; each name is
;; installed through one POO object construction boundary, so composed profile
;; objects remain reusable by `.ref` lookup after construction.
;;
;; # Examples
;;   (poo-flow-composition-inline-module '(default) (list profile))
;;   ;; result: (.ref module 'default) returns `profile`.
(def (poo-flow-composition-inline-module profile-names profile-values)
  (unless (= (length profile-names) (length profile-values))
    (error "inline composition module name/value arity mismatch"
           profile-names
           profile-values))
  (object<-alist (map cons profile-names profile-values)))

;;; Boundary: inline profile construction is the runtime value edge for
;;; use-composition macro output and must preserve POO-native profile objects.
;; : (-> Symbol Alist PooProfile)
(def (poo-flow-composition-inline-profile profile-name sections)
  (let* ((base (poo-flow-composition-inline-alist-ref sections 'extends #f))
         (hooks (poo-flow-composition-inline-alist-ref sections 'hooks '()))
         (profile
          (if base
            (object<-alist
             (list
              (cons ':extends base)
              (cons 'name profile-name)
              (cons 'extends base)
              (cons 'kind
                    (poo-flow-composition-inline-profile-field
                     sections base 'kind profile-name))
              (cons 'scope
                    (poo-flow-composition-inline-profile-field
                     sections base 'scope '()))
              (cons 'storage
                    (poo-flow-composition-inline-profile-field
                     sections base 'storage '()))
              (cons 'analysis
                    (poo-flow-composition-inline-profile-field
                     sections base 'analysis '()))
              (cons 'publish
                    (poo-flow-composition-inline-profile-field
                     sections base 'publish '()))
              (cons 'retention
                    (poo-flow-composition-inline-profile-field
                     sections base 'retention '()))
              (cons 'capabilities
                    (poo-flow-composition-inline-profile-field
                     sections base 'capabilities '()))
              (cons 'hooks hooks)
              (cons 'runtime-executed #f)
              (cons 'source 'poo-flow.composition.inline-profile)))
            (object<-alist
             (list
              (cons 'name profile-name)
              (cons 'extends #f)
              (cons 'kind
                    (poo-flow-composition-inline-alist-ref
                     sections 'kind profile-name))
              (cons 'scope
                    (poo-flow-composition-inline-alist-ref
                     sections 'scope '()))
              (cons 'storage
                    (poo-flow-composition-inline-alist-ref
                     sections 'storage '()))
              (cons 'analysis
                    (poo-flow-composition-inline-alist-ref
                     sections 'analysis '()))
              (cons 'publish
                    (poo-flow-composition-inline-alist-ref
                     sections 'publish '()))
              (cons 'retention
                    (poo-flow-composition-inline-alist-ref
                     sections 'retention '()))
              (cons 'capabilities
                    (poo-flow-composition-inline-alist-ref
                     sections 'capabilities '()))
              (cons 'hooks hooks)
              (cons 'runtime-executed #f)
              (cons 'source 'poo-flow.composition.inline-profile))))))
    (poo-flow-composition-inline-apply-hooks profile hooks)))
