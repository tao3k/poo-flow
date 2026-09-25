;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Report-only presentation of one native POO slot.  Upstream `.ref` is the
;;; sole evaluator.  The source registry is declarative maintainer metadata,
;;; bound to prototype identity and checked before any slot is presented.
(import (only-in :clan/poo/object
                 .all-slots .o .ref .slot? object?
                 $computed-slot-spec?
                 object-%precedence-list object-defaults object-slots))

(export poo-flow-native-slot-view
        poo-flow-native-slot-presentation)

(def (poo-flow-direct-slot-mode prototype slot)
  (let (method (assq slot (object-slots prototype)))
    (cond
     (method
      (if ($computed-slot-spec? (cdr method))
        'super-aware
        'replacement))
     ((assq slot (object-defaults prototype)) 'default)
     (else #f))))

(def (poo-flow-prototype-source-index registry)
  (unless (object? registry)
    (error "POO slot source registry must be a native POO object" registry))
  (let (index (make-hash-table-eq))
    (for-each
     (lambda (name)
       (let* ((entry (.ref registry name))
              (prototype (and (object? entry)
                              (.slot? entry 'prototype)
                              (.ref entry 'prototype)))
              (path (and (object? entry)
                         (.slot? entry 'source-path)
                         (.ref entry 'source-path)))
              (line (and (object? entry)
                         (.slot? entry 'source-line)
                         (.ref entry 'source-line))))
         (unless (and (symbol? name) (object? prototype)
                      (string? path) (> (string-length path) 0)
                      (integer? line) (> line 0))
           (error "invalid POO prototype source declaration" name))
         (when (hash-key? index prototype)
           (error "duplicate POO slot provenance prototype label" name))
         (hash-put! index prototype
                    (.o label: name source-path: path source-line: line))))
     (.all-slots registry))
    index))

(def (poo-flow-prototype-source index prototype)
  (let (entry (hash-get index prototype))
    (unless entry
      (error "unlabeled native POO prototype" prototype))
    entry))

(def (poo-flow-slot-declaration-steps subject slot index)
  (let (reversed '())
    (for-each
     (lambda (prototype)
       (let (mode-value (poo-flow-direct-slot-mode prototype slot))
         (when mode-value
           (let (source (poo-flow-prototype-source index prototype))
             (set! reversed
                   (cons (.o label: (.ref source 'label)
                             mode: mode-value
                             source-path: (.ref source 'source-path)
                             source-line: (.ref source 'source-line))
                         reversed))))))
     (object-%precedence-list subject))
    (reverse reversed)))

;;; The declaration lineage is not a claim that every ancestor contributed to
;;; the returned value: native methods may replace or combine earlier values.
;;; All precedence members must be named, including non-declaring prototypes.
(def (poo-flow-native-slot-view subject slot-name registry)
  (unless (and (object? subject) (symbol? slot-name)
               (.slot? subject slot-name))
    (error "cannot present missing native POO slot" slot-name))
  (let* ((source-index (poo-flow-prototype-source-index registry))
         (precedence-value
          (map (lambda (prototype)
                 (poo-flow-prototype-source source-index prototype))
               (object-%precedence-list subject)))
         (declarations-value
          (poo-flow-slot-declaration-steps
           subject slot-name source-index))
         (resolved-value (.ref subject slot-name))
         (source-labels
          (map (lambda (entry) (.ref entry 'label)) declarations-value))
         (composition-value
          (map (lambda (entry)
                 (.o label: (.ref entry 'label)
                     mode: (.ref entry 'mode)))
               declarations-value)))
    (.o effective-value: resolved-value
        provenance: source-labels
        composition-chain: composition-value
        declaration-sources: declarations-value
        precedence-sources: precedence-value
        slot: slot-name
        kind: 'poo-flow.native-slot-view.v1)))

;;; The ordinary path does not require source metadata.  Detailed levels use
;;; the identity-bound registry and the same upstream evaluator.
(def (poo-flow-native-slot-presentation
      subject slot-name (level 'default) (registry #f))
  (unless (and (object? subject) (symbol? slot-name)
               (.slot? subject slot-name))
    (error "cannot present missing native POO slot" slot-name))
  (unless (memq level '(default provenance composition advanced source))
    (error "unknown native POO slot presentation level" level))
  (case level
    ((default)
     (.o effective-value: (.ref subject slot-name)))
    (else
     (let* ((view (poo-flow-native-slot-view subject slot-name registry))
            (provenance-view
             (.o effective-value: (.ref view 'effective-value)
                 declaration-lineage: (.ref view 'provenance))))
       (if (eq? level 'provenance)
         provenance-view
         (let (composition-view
               (.o (:: @ provenance-view)
                   composition-chain: (.ref view 'composition-chain)))
           (if (eq? level 'composition)
             composition-view
             (let (advanced-view
                   (.o (:: @ composition-view)
                       native-precedence: (.ref view 'precedence-sources)))
               (if (eq? level 'advanced)
                 advanced-view
                 (.o (:: @ advanced-view)
                     source-declarations:
                     (.ref view 'declaration-sources)))))))))))
