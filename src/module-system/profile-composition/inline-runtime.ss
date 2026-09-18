;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: runtime helpers used by user-facing composition macros.
;;; Invariant: keep POO object construction and hook normalization outside
;;; macro parser modules so macro expansion remains shallow and reusable.

(import (only-in :clan/poo/object .all-slots .mix .o .ref object<-alist)
        (only-in :std/srfi/1 fold))

(export poo-flow-scenario-inline-section-slot
        poo-flow-scenario-inline-alist-ref
        poo-flow-scenario-inline-profile-field
        poo-flow-scenario-inline-profile-ref/default
        poo-flow-scenario-inline-profile-normalize
        poo-flow-scenario-inline-apply-hooks
        poo-flow-scenario-inline-imported-profile
        poo-flow-scenario-inline-module
        poo-flow-scenario-inline-profile)

;; : (-> Symbol Symbol)
(def (poo-flow-scenario-inline-section-slot key)
  (case key
    ((:extends extends) 'extends)
    ((:kind kind) 'kind)
    ((:scope scope) 'scope)
    ((:storage storage) 'storage)
    ((:analysis analysis) 'analysis)
    ((:publish publish) 'publish)
    ((:retention retention) 'retention)
    ((:capabilities capabilities) 'capabilities)
    ((:guard guard) 'guard)
    ((:with with) 'hooks)
    (else key)))

;; : (-> Alist Symbol Datum Datum)
(def (poo-flow-scenario-inline-alist-ref alist key default)
  (let (entry (assoc key alist))
    (if entry (cdr entry) default)))

;; : (-> PooProfile Symbol Datum Datum)
(def (poo-flow-scenario-inline-profile-ref/default profile key default)
  (poo-flow-scenario-inline-profile-ref/default*
   profile
   (.all-slots profile)
   key
   default))

;; : (-> PooProfile [Symbol] Symbol Datum Datum)
(def (poo-flow-scenario-inline-profile-ref/default*
      profile
      slots
      key
      default)
  (if (memq key slots)
    (.ref profile key)
    default))

;; : (-> Alist Datum Symbol Datum Datum)
(def (poo-flow-scenario-inline-profile-field sections base key default)
  (poo-flow-scenario-inline-alist-ref
   sections
   key
   (if base
     (poo-flow-scenario-inline-profile-ref/default base key default)
     default)))

;;; Boundary: inline profile normalization keeps authoring-time profile values
;;; deterministic before composition stages inherit or extend them.
;; : (-> PooProfile PooProfile PooProfile)
(def (poo-flow-scenario-inline-profile-normalize base profile)
  (.mix profile base))

;; : (-> PooProfile [(-> PooProfile PooProfile)] PooProfile)
(def (poo-flow-scenario-inline-apply-hooks profile hooks)
  (fold
   (lambda (hook out)
     (poo-flow-scenario-inline-profile-normalize out (hook out)))
   profile
   hooks))

;; : (-> Symbol Symbol PooProfile)
(def (poo-flow-scenario-inline-imported-profile module-name profile-name)
  (.o (kind 'poo-flow.scenario.imported-profile.v1)
      (name profile-name)
      (module module-name)
      (profile profile-name)
      (guard #f)
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
;;   (poo-flow-scenario-inline-module '(default) (list profile))
;;   ;; result: (.ref module 'default) returns `profile`.
(def (poo-flow-scenario-inline-module profile-names profile-values)
  (unless (= (length profile-names) (length profile-values))
    (error "inline composition module name/value arity mismatch"
           profile-names
           profile-values))
  (object<-alist (map cons profile-names profile-values)))

;;; Boundary: inline profile construction is the runtime value edge for
;;; use-composition macro output and must preserve POO-native profile objects.
;; : (-> Symbol Alist PooProfile)
(def (poo-flow-scenario-inline-profile profile-name sections)
  (let* ((base (poo-flow-scenario-inline-alist-ref sections 'extends #f))
         (hook-values
          (poo-flow-scenario-inline-alist-ref sections 'hooks '()))
         (overlay
          (.o name: profile-name
              extends: base
              kind:
              (poo-flow-scenario-inline-profile-field
               sections base 'kind profile-name)
              scope:
              (poo-flow-scenario-inline-profile-field
               sections base 'scope '())
              storage:
              (poo-flow-scenario-inline-profile-field
               sections base 'storage '())
              analysis:
              (poo-flow-scenario-inline-profile-field
               sections base 'analysis '())
              publish:
              (poo-flow-scenario-inline-profile-field
               sections base 'publish '())
              retention:
              (poo-flow-scenario-inline-profile-field
               sections base 'retention '())
              capabilities:
              (poo-flow-scenario-inline-profile-field
               sections base 'capabilities '())
              guard:
              (poo-flow-scenario-inline-profile-field
               sections base 'guard #f)
              hooks: hook-values
              runtime-executed: #f
              source: 'poo-flow.scenario.inline-profile.v1))
         (profile
          (if base
            (poo-flow-scenario-inline-profile-normalize base overlay)
            overlay)))
    (poo-flow-scenario-inline-apply-hooks profile hook-values)))
