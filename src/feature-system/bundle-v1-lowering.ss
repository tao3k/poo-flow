;;; Boundary: lowers POO feature compositions into the fixed Bundle v1 layout.
;;; Invariant: symbol interning and row emission are deterministic for canonical input.
(export +feature-bundle-v1-schema+
        +feature-bundle-v1-schema-major+
        +feature-bundle-v1-schema-minor+
        +feature-bundle-v1-descriptor-size+
        +feature-bundle-v1-digest-bytes+
        +feature-bundle-v1-symbol-row-size+
        +feature-bundle-v1-component-row-size+
        +feature-bundle-v1-edge-row-size+
        +feature-bundle-v1-evidence-row-size+
        +feature-bundle-v1-row-alignment+
        +feature-bundle-v1-arena-alignment+
        +feature-bundle-v1-descriptor-flags+
        +feature-bundle-v1-component-enabled-flag+
        +feature-bundle-v1-compact-id-kind+
        +feature-bundle-v1-symbol-kind+
        +feature-bundle-v1-component-kind+
        +feature-bundle-v1-edge-kind+
        +feature-bundle-v1-evidence-kind+
        +feature-bundle-v1-native-component-kind+
        +feature-bundle-v1-native-symbol-kind+
        +feature-bundle-v1-native-edge-kind+
        +feature-bundle-v1-native-evidence-kind+
        +feature-bundle-v1-region-kind+
        +feature-bundle-v1-descriptor-kind+
        +feature-bundle-v1-diagnostic-kind+
        +feature-bundle-v1-lowering-plan-kind+
        +feature-bundle-v1-no-capability-id+
        +feature-bundle-v1-no-policy-id+
        +feature-bundle-v1-no-strategy-id+
        +feature-bundle-v1-no-adapter-id+
        +feature-bundle-v1-no-projection-id+
        feature-bundle-v1-compact-id?
        feature-bundle-v1-symbol
        feature-bundle-v1-symbol?
        feature-bundle-v1-component
        feature-bundle-v1-component?
        feature-bundle-v1-edge
        feature-bundle-v1-edge?
        feature-bundle-v1-evidence
        feature-bundle-v1-evidence?
        feature-bundle-v1-native-component?
        feature-bundle-v1-native-symbol?
        feature-bundle-v1-native-edge?
        feature-bundle-v1-native-evidence?
        feature-bundle-v1-region?
        feature-bundle-v1-descriptor?
        feature-bundle-v1-diagnostic?
        feature-bundle-v1-lowering-plan?
        feature-bundle-v1-lower-compact-id
        feature-bundle-v1-compact-id=?
        feature-bundle-v1-compact-id<?
        feature-bundle-v1-lowering
        feature-bundle-v1-lowering/with-symbols
        require-feature-bundle-v1-lowering-plan)

(import (only-in :std/crypto/digest sha256)
        (only-in :std/sort stable-sort)
        (only-in :std/srfi/1 fold-right)
        (only-in :clan/poo/object .ref .slot? object? object<-alist)
        :poo-flow/src/utilities/functional)

(import :poo-flow/src/feature-system/bundle-v1-lowering-model)

;; : (-> PooFeatureBundleV1CompactId PooFeatureBundleV1CompactId Integer)
(def (compare-compact-ids left right)
  (cond
   ((feature-bundle-v1-compact-id<? left right) -1)
   ((feature-bundle-v1-compact-id=? left right) 0)
   (else 1)))

;; : (-> PooFeatureBundleV1NativeComponent PooFeatureBundleV1NativeComponent Integer)
(def (compare-component-rows left right)
  (let ((case-order
         (compare-compact-ids (.ref left 'case-id) (.ref right 'case-id))))
    (if (= case-order 0)
        (compare-compact-ids
         (.ref left 'component-id) (.ref right 'component-id))
        case-order)))

;; : (-> PooFeatureBundleV1NativeSymbol PooFeatureBundleV1NativeSymbol Integer)
(def (compare-symbol-rows left right)
  (compare-compact-ids (.ref left 'id) (.ref right 'id)))

;; : (-> Integer Integer Integer)
(def (compare-integers left right)
  (cond
   ((< left right) -1)
   ((> left right) 1)
   (else 0)))

;; : (-> [Integer] Integer)
(def (first-nonzero-comparison comparisons)
  (or (poo-flow-find (lambda (value) (not (= value 0))) comparisons)
      0))

;; : (-> PooFeatureBundleV1NativeEdge PooFeatureBundleV1NativeEdge Integer)
(def (compare-edge-rows left right)
  (first-nonzero-comparison
   (list
    (compare-compact-ids (.ref left 'case-id) (.ref right 'case-id))
    (compare-compact-ids
     (.ref left 'source-component-id)
     (.ref right 'source-component-id))
    (compare-integers
     (.ref left 'composition-order)
     (.ref right 'composition-order))
    (compare-compact-ids
     (.ref left 'target-component-id)
     (.ref right 'target-component-id))
    (compare-compact-ids
     (.ref left 'relation-id) (.ref right 'relation-id)))))

;; : (-> PooFeatureBundleV1NativeEvidence PooFeatureBundleV1NativeEvidence Integer)
(def (compare-evidence-rows left right)
  (let ((case-order
         (compare-compact-ids (.ref left 'case-id) (.ref right 'case-id))))
    (if (= case-order 0)
        (compare-compact-ids
         (.ref left 'obligation-id) (.ref right 'obligation-id))
        case-order)))

;; : (forall (a) (-> (List a) (-> a a Integer) Boolean))
;; : (-> List Procedure Boolean)
(def (strictly-ordered? values compare)
  (or (null? values)
      (null? (cdr values))
      (and (< (compare (car values) (cadr values)) 0)
           (strictly-ordered? (cdr values) compare))))

;; : (-> Integer Integer Integer)
(def (align-up value alignment)
  (* (quotient (+ value (- alignment 1)) alignment) alignment))

;; : (-> Symbol Integer Integer Integer Integer PooFeatureBundleV1Region)
(def (make-region name offset count stride alignment)
  (feature-bundle-v1-region
   name offset (* count stride) stride alignment count))

;; : (-> PooFeatureBundleV1CompactId List)
(def (compact-id->canonical value)
  (list (.ref value 'high) (.ref value 'low)))

;; : (-> PooFeatureBundleV1NativeComponent List)
(def (component-row->canonical value)
  (list
   (compact-id->canonical (.ref value 'case-id))
   (compact-id->canonical (.ref value 'component-id))
   (compact-id->canonical (.ref value 'object-id))
   (compact-id->canonical (.ref value 'type-id))
   (compact-id->canonical (.ref value 'contract-id))
   (compact-id->canonical (.ref value 'role-id))
   (compact-id->canonical (.ref value 'capability-id))
   (compact-id->canonical (.ref value 'policy-id))
   (compact-id->canonical (.ref value 'strategy-id))
   (compact-id->canonical (.ref value 'adapter-id))
   (compact-id->canonical (.ref value 'projection-id))
   (.ref value 'composition-order)
   (.ref value 'flags)
   (.ref value 'reserved0)
   (.ref value 'reserved1)))

;; : (-> PooFeatureBundleV1NativeSymbol List)
(def (symbol-row->canonical value)
  (list
   (compact-id->canonical (.ref value 'id))
   (.ref value 'byte-offset)
   (.ref value 'byte-length)
   (.ref value 'symbol-kind)
   (.ref value 'flags)
   (u8vector->list (.ref value 'value-bytes))))

;; : (-> PooFeatureBundleV1NativeEdge List)
(def (edge-row->canonical value)
  (list
   (compact-id->canonical (.ref value 'case-id))
   (compact-id->canonical (.ref value 'source-component-id))
   (compact-id->canonical (.ref value 'target-component-id))
   (compact-id->canonical (.ref value 'relation-id))
   (.ref value 'composition-order)
   (.ref value 'flags)
   (.ref value 'reserved0)))

;; : (-> PooFeatureBundleV1NativeEvidence List)
(def (evidence-row->canonical value)
  (list
   (compact-id->canonical (.ref value 'case-id))
   (compact-id->canonical (.ref value 'obligation-id))
   (compact-id->canonical (.ref value 'contract-id))
   (compact-id->canonical (.ref value 'evidence-type-id))
   (compact-id->canonical (.ref value 'proof-system-id))
   (.ref value 'composition-order)
   (.ref value 'flags)
   (.ref value 'reserved0)))

;; : (-> PooFeatureBundleV1CompactId List List List List U8Vector)
(def (bundle-digest bundle-id symbols components edges evidence)
  (sha256
   (call-with-output-string
    (lambda (port)
      (write
       (list +feature-bundle-v1-schema+
             (compact-id->canonical bundle-id)
             (poo-flow-map symbol-row->canonical symbols)
             (poo-flow-map component-row->canonical components)
             (poo-flow-map edge-row->canonical edges)
             (poo-flow-map evidence-row->canonical evidence))
       port)))))

;; : (-> [PooFeatureBundleV1NativeSymbol] U8Vector)
(def (symbol-metadata-image symbols)
  (list->u8vector
   (fold-right
    (lambda (symbol bytes)
      (append (u8vector->list (.ref symbol 'value-bytes)) bytes))
    '()
    symbols)))

;; : (-> PooFeatureBundleV1Region Integer)
(def (feature-bundle-v1-region-length region)
  (.ref region 'length))

;; : (-> PooFeatureBundleV1CompactId Integer List List List List PooFeatureBundleV1Descriptor)
(def (build-descriptor bundle-id bundle-epoch symbols components edges evidence)
  (let* ((symbol-count (length symbols))
         (metadata-image (symbol-metadata-image symbols))
         (component-count (length components))
         (edge-count (length edges))
         (evidence-count (length evidence))
         (symbol-region
          (make-region 'symbols 0 symbol-count
                       +feature-bundle-v1-symbol-row-size+
                       +feature-bundle-v1-row-alignment+))
         (component-offset
          (align-up (feature-bundle-v1-region-length symbol-region)
                    +feature-bundle-v1-row-alignment+))
         (component-region
          (make-region 'components component-offset component-count
                       +feature-bundle-v1-component-row-size+
                       +feature-bundle-v1-row-alignment+))
         (edge-offset
          (align-up (+ component-offset
                       (feature-bundle-v1-region-length component-region))
                    +feature-bundle-v1-row-alignment+))
         (edge-region
          (make-region 'edges edge-offset edge-count
                       +feature-bundle-v1-edge-row-size+
                       +feature-bundle-v1-row-alignment+))
         (evidence-offset
          (align-up (+ edge-offset
                       (feature-bundle-v1-region-length edge-region))
                    +feature-bundle-v1-row-alignment+))
         (evidence-region
          (make-region 'evidence-obligations evidence-offset evidence-count
                       +feature-bundle-v1-evidence-row-size+
                       +feature-bundle-v1-row-alignment+))
         (metadata-offset
          (+ evidence-offset
             (feature-bundle-v1-region-length evidence-region)))
         (metadata
          (make-region 'metadata-bytes metadata-offset
                       (u8vector-length metadata-image) 1 1))
         (arena-bytes
          (max +feature-bundle-v1-arena-alignment+
               (align-up (+ metadata-offset
                            (feature-bundle-v1-region-length metadata))
                         +feature-bundle-v1-arena-alignment+))))
    (feature-bundle-v1-descriptor
     +feature-bundle-v1-descriptor-size+
     +feature-bundle-v1-descriptor-flags+
     +feature-bundle-v1-schema-major+
     +feature-bundle-v1-schema-minor+
     0
     bundle-id
     (bundle-digest bundle-id symbols components edges evidence)
     bundle-epoch
     arena-bytes
     symbol-region component-region edge-region evidence-region metadata
     '(0 0 0 0 0 0 0)
     symbols metadata-image components edges evidence)))

;; : (-> Symbol Object Object PooFeatureBundleV1LoweringPlan)
(def (rejected-plan code subject detail)
  (feature-bundle-v1-lowering-plan
   'rejected #f #f
   (list (feature-bundle-v1-diagnostic code subject detail))))

;; : (-> Symbol Integer List List List PooFeatureBundleV1LoweringPlan)
(def (feature-bundle-v1-lowering
      bundle-id bundle-epoch components edges evidence)
  (feature-bundle-v1-lowering/with-symbols
   bundle-id bundle-epoch '() components edges evidence))

;;; Lowering boundary: validate semantic rows before assigning deterministic symbol and arena offsets.
;; : (-> Symbol Integer List List List List PooFeatureBundleV1LoweringPlan)
(def (feature-bundle-v1-lowering/with-symbols
      bundle-id bundle-epoch symbols components edges evidence)
  (cond
   ((not (valid-semantic-id? bundle-id))
    (rejected-plan 'invalid-bundle-id bundle-id
                   'expected-nonempty-symbol-string-or-uint64))
   ((not (valid-uint64? bundle-epoch))
    (rejected-plan 'invalid-bundle-epoch bundle-id 'expected-uint64))
   ((not (and (list? symbols) (list? components) (list? edges)
              (list? evidence)))
    (rejected-plan 'invalid-collection-shape bundle-id
                   'expected-proper-lists))
   ((not (poo-flow-list-of? valid-symbol? symbols))
    (rejected-plan 'invalid-symbol bundle-id
                   'expected-poo-native-symbol))
   ((not (poo-flow-list-of? valid-component? components))
    (rejected-plan 'invalid-component bundle-id
                   'expected-poo-native-component))
   ((not (poo-flow-list-of? valid-edge? edges))
    (rejected-plan 'invalid-edge bundle-id 'expected-poo-native-edge))
   ((not (poo-flow-list-of? valid-evidence? evidence))
    (rejected-plan 'invalid-evidence bundle-id
                   'expected-poo-native-evidence))
   (else
    (let* ((lowered-symbols
            (stable-sort (poo-flow-map lower-symbol symbols)
                         (lambda (left right)
                           (< (compare-symbol-rows left right) 0))))
           (native-symbols (assign-symbol-offsets lowered-symbols))
           (native-components
            (stable-sort (poo-flow-map lower-component components)
                         (lambda (left right)
                           (< (compare-component-rows left right) 0))))
           (native-edges
            (stable-sort (poo-flow-map lower-edge edges)
                         (lambda (left right)
                           (< (compare-edge-rows left right) 0))))
           (native-evidence
            (stable-sort (poo-flow-map lower-evidence evidence)
                         (lambda (left right)
                           (< (compare-evidence-rows left right) 0)))))
      (cond
       ((not (strictly-ordered? native-symbols compare-symbol-rows))
        (rejected-plan 'duplicate-symbol-key bundle-id
                       'symbol-ids-must-be-unique))
       ((not (strictly-ordered? native-components compare-component-rows))
        (rejected-plan 'duplicate-component-key bundle-id
                       'case-id-and-component-id-must-be-unique))
       ((not (strictly-ordered? native-edges compare-edge-rows))
        (rejected-plan 'duplicate-edge-key bundle-id
                       'edge-key-must-be-unique))
       ((not (strictly-ordered? native-evidence compare-evidence-rows))
        (rejected-plan 'duplicate-evidence-key bundle-id
                       'case-id-and-obligation-id-must-be-unique))
       (else
        (feature-bundle-v1-lowering-plan
         'ready #t
        (build-descriptor
          (feature-bundle-v1-lower-compact-id 'bundle bundle-id)
          bundle-epoch
          native-symbols native-components native-edges native-evidence)
         '())))))))

;; : (-> PooFeatureBundleV1LoweringPlan PooFeatureBundleV1LoweringPlan)
(def (require-feature-bundle-v1-lowering-plan value)
  (unless (and (feature-bundle-v1-lowering-plan? value)
               (.slot? value 'accepted?)
               (.ref value 'accepted?))
    (error "Accepted Bundle v1 lowering plan expected" value))
  value)
