;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: pure model lookup, compatibility, and selection algorithms.
;;; Invariant: this owner consumes admitted POO values and returns an inert
;;; receipt; it neither constructs configuration nor invokes a Provider.

(import (only-in :clan/poo/object .ref)
        (only-in :poo-flow/src/modules/session/objects-core
                 poo-flow-session-every?
                 poo-flow-session-require)
        :poo-flow/src/modules/model-core/objects)

(export poo-flow-model-catalog-find
        poo-flow-model-supports-capability?
        poo-flow-model-supports-capabilities?
        poo-flow-model-select)

(def (poo-flow-model-spec-find model-ref models)
  (cond
   ((null? models) #f)
   ((eq? model-ref (poo-flow-model-spec-ref (car models))) (car models))
   (else (poo-flow-model-spec-find model-ref (cdr models)))))

(def (poo-flow-model-catalog-find catalog model-ref)
  (poo-flow-model-spec-find model-ref (.ref catalog 'models)))

(def (poo-flow-model-supports-capability? spec capability)
  (and (memq capability (poo-flow-model-spec-capabilities spec)) #t))

(def (poo-flow-model-supports-capabilities? spec capabilities)
  (poo-flow-session-every?
   (lambda (capability)
     (poo-flow-model-supports-capability? spec capability))
   capabilities))

(def (poo-flow-model-selection-diagnostic model-ref reason)
  (poo-flow-model-field-rows
   (model-ref model-ref)
   (reason reason)))

(def (poo-flow-model-selection-fallback-receipt policy catalog fallback-ref
                                                fallback-model fallback-valid?
                                                diagnostics)
  (poo-flow-model-selection-receipt
   policy catalog
   (if fallback-valid? #t #f)
   (if fallback-valid? fallback-model #f)
   (if fallback-valid?
     diagnostics
     (cons (poo-flow-model-selection-diagnostic
            fallback-ref 'no-model-selected)
           diagnostics))))

(def (poo-flow-model-select-candidates catalog candidate-model-refs
                                       capabilities diagnostics)
  (cond
   ((null? candidate-model-refs) (values #f (reverse diagnostics)))
   (else
    (let* ((model-ref (car candidate-model-refs))
           (model (poo-flow-model-catalog-find catalog model-ref)))
      (cond
       ((not model)
        (poo-flow-model-select-candidates
         catalog (cdr candidate-model-refs) capabilities
         (cons (poo-flow-model-selection-diagnostic model-ref 'missing-model)
               diagnostics)))
       ((poo-flow-model-supports-capabilities? model capabilities)
        (values model (reverse diagnostics)))
       (else
        (poo-flow-model-select-candidates
         catalog (cdr candidate-model-refs) capabilities
         (cons (poo-flow-model-selection-diagnostic
                model-ref 'missing-capability)
               diagnostics))))))))

(def (poo-flow-model-select policy catalog)
  (poo-flow-session-require "model selection policy must be a model policy"
                            (poo-flow-model-selection-policy? policy) policy)
  (poo-flow-session-require "model selection catalog must be a model catalog"
                            (poo-flow-model-catalog? catalog) catalog)
  (let (required-capabilities (.ref policy 'required-capabilities))
    (let-values (((selected-model diagnostics)
                  (poo-flow-model-select-candidates
                   catalog (.ref policy 'candidate-model-refs)
                   required-capabilities '())))
      (if selected-model
        (poo-flow-model-selection-receipt
         policy catalog #t selected-model diagnostics)
        (let* ((fallback-ref (.ref policy 'fallback-model-ref))
               (fallback-model
                (and fallback-ref
                     (poo-flow-model-catalog-find catalog fallback-ref)))
               (fallback-valid?
                (and fallback-model
                     (poo-flow-model-supports-capabilities?
                      fallback-model required-capabilities))))
          (poo-flow-model-selection-fallback-receipt
           policy catalog fallback-ref fallback-model fallback-valid?
           diagnostics))))))
