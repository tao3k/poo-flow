;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Report-only view of one already-admitted native POO slot.  The effective
;;; value comes only from upstream `.ref`; provenance reads upstream's actual
;;; precedence list and direct slot definitions after that access.  This file
;;; does not recompute a slot, compose a prototype, or own semantic authority.
(import (only-in :clan/poo/object
                 .all-slots .o .ref .slot? object?
                 object-%precedence-list object-defaults object-slots))

(export poo-flow-native-slot-view)

(def (poo-flow-direct-slot? prototype slot)
  (or (assq slot (object-slots prototype))
      (assq slot (object-defaults prototype))))

(def (poo-flow-prototype-label-index labels)
  (unless (object? labels)
    (error "POO slot provenance labels must be a native POO object" labels))
  (let (index (make-hash-table-eq))
    (for-each
     (lambda (name)
       (let (prototype (.ref labels name))
         (unless (and (symbol? name) (object? prototype))
           (error "POO slot provenance label must name a prototype" name))
         (when (hash-key? index prototype)
           (error "duplicate POO slot provenance prototype label" name))
         (hash-put! index prototype name)))
     (.all-slots labels))
    index))

(def (poo-flow-slot-contributor-labels subject slot label-index)
  (let (reversed '())
    (for-each
     (lambda (prototype)
       (when (poo-flow-direct-slot? prototype slot)
         (let (name (hash-get label-index prototype))
           (unless name
             (error "unlabeled native POO slot contributor" slot))
           (set! reversed (cons name reversed)))))
     (object-%precedence-list subject))
    (reverse reversed)))

;;; Labels describe source prototypes for presentation only.  They are checked
;;; against object identity, so a stale or incomplete label map fails closed.
;;; Accessing `subject` realizes only the requested native slot; callers must
;;; use this view at an admitted, pure presentation boundary.
(def (poo-flow-native-slot-view subject slot-name labels)
  (unless (and (object? subject) (symbol? slot-name)
               (.slot? subject slot-name))
    (error "cannot present missing native POO slot" slot-name))
  (let* ((label-index (poo-flow-prototype-label-index labels))
         (resolved-value (.ref subject slot-name))
         (source-labels
          (poo-flow-slot-contributor-labels
           subject slot-name label-index)))
    (.o effective-value: resolved-value
        provenance: source-labels
        slot: slot-name
        kind: 'poo-flow.native-slot-view.v1)))
