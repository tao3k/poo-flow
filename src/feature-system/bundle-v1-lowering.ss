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
        +feature-bundle-v1-component-kind+
        +feature-bundle-v1-edge-kind+
        +feature-bundle-v1-evidence-kind+
        +feature-bundle-v1-native-component-kind+
        +feature-bundle-v1-native-edge-kind+
        +feature-bundle-v1-native-evidence-kind+
        +feature-bundle-v1-region-kind+
        +feature-bundle-v1-descriptor-kind+
        +feature-bundle-v1-diagnostic-kind+
        +feature-bundle-v1-lowering-plan-kind+
        feature-bundle-v1-compact-id?
        feature-bundle-v1-component
        feature-bundle-v1-component?
        feature-bundle-v1-edge
        feature-bundle-v1-edge?
        feature-bundle-v1-evidence
        feature-bundle-v1-evidence?
        feature-bundle-v1-native-component?
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
        require-feature-bundle-v1-lowering-plan)

(import :std/crypto/digest
        :std/sort
        :clan/poo/object
        :poo-flow/src/utilities/functional)

(def +feature-bundle-v1-schema+ 'poo-flow.bundle.1)
(def +feature-bundle-v1-schema-major+ 1)
(def +feature-bundle-v1-schema-minor+ 0)
(def +feature-bundle-v1-descriptor-size+ 256)
(def +feature-bundle-v1-digest-bytes+ 32)
(def +feature-bundle-v1-symbol-row-size+ 32)
(def +feature-bundle-v1-component-row-size+ 200)
(def +feature-bundle-v1-edge-row-size+ 80)
(def +feature-bundle-v1-evidence-row-size+ 96)
(def +feature-bundle-v1-row-alignment+ 8)
(def +feature-bundle-v1-arena-alignment+ 64)
(def +feature-bundle-v1-descriptor-flags+ 3)
(def +feature-bundle-v1-component-enabled-flag+ 1)
(def +feature-bundle-v1-uint64-modulus+ 18446744073709551616)

(def +feature-bundle-v1-compact-id-kind+
  'poo-flow.feature-bundle-v1-compact-id.v1)
(def +feature-bundle-v1-component-kind+
  'poo-flow.feature-bundle-v1-component.v1)
(def +feature-bundle-v1-edge-kind+
  'poo-flow.feature-bundle-v1-edge.v1)
(def +feature-bundle-v1-evidence-kind+
  'poo-flow.feature-bundle-v1-evidence.v1)
(def +feature-bundle-v1-native-component-kind+
  'poo-flow.feature-bundle-v1-native-component.v1)
(def +feature-bundle-v1-native-edge-kind+
  'poo-flow.feature-bundle-v1-native-edge.v1)
(def +feature-bundle-v1-native-evidence-kind+
  'poo-flow.feature-bundle-v1-native-evidence.v1)
(def +feature-bundle-v1-region-kind+
  'poo-flow.feature-bundle-v1-region.v1)
(def +feature-bundle-v1-descriptor-kind+
  'poo-flow.feature-bundle-v1-descriptor.v1)
(def +feature-bundle-v1-diagnostic-kind+
  'poo-flow.feature-bundle-v1-diagnostic.v1)
(def +feature-bundle-v1-lowering-plan-kind+
  'poo-flow.feature-bundle-v1-lowering-plan.v1)

(defsyntax define-poo-value
  (syntax-rules ()
    ((_ (name field ...) kind-value)
     (def (name field ...)
       (object<-alist
        (list (cons 'kind kind-value)
              (cons 'schema-version 1)
              (cons 'field field) ...))))))

(define-poo-value
  (feature-bundle-v1-compact-id domain source high low)
  +feature-bundle-v1-compact-id-kind+)

(define-poo-value
  (feature-bundle-v1-component
   case-id component-id object-id type-id contract-id role-id capability-id
   policy-id strategy-id adapter-id projection-id composition-order)
  +feature-bundle-v1-component-kind+)

(define-poo-value
  (feature-bundle-v1-edge
   case-id source-component-id target-component-id relation-id
   composition-order)
  +feature-bundle-v1-edge-kind+)

(define-poo-value
  (feature-bundle-v1-evidence
   case-id obligation-id contract-id evidence-type-id proof-system-id
   composition-order)
  +feature-bundle-v1-evidence-kind+)

(define-poo-value
  (feature-bundle-v1-native-component
   case-id component-id object-id type-id contract-id role-id capability-id
   policy-id strategy-id adapter-id projection-id composition-order flags
   reserved0 reserved1)
  +feature-bundle-v1-native-component-kind+)

(define-poo-value
  (feature-bundle-v1-native-edge
   case-id source-component-id target-component-id relation-id
   composition-order flags reserved0)
  +feature-bundle-v1-native-edge-kind+)

(define-poo-value
  (feature-bundle-v1-native-evidence
   case-id obligation-id contract-id evidence-type-id proof-system-id
   composition-order flags reserved0)
  +feature-bundle-v1-native-evidence-kind+)

(define-poo-value
  (feature-bundle-v1-region name offset length stride alignment count)
  +feature-bundle-v1-region-kind+)

(define-poo-value
  (feature-bundle-v1-descriptor
   struct-size flags schema-major schema-minor reserved0 bundle-id digest
   bundle-epoch arena-bytes symbols components edges evidence-obligations
   metadata-bytes reserved component-rows edge-rows evidence-rows)
  +feature-bundle-v1-descriptor-kind+)

(define-poo-value
  (feature-bundle-v1-diagnostic code subject detail)
  +feature-bundle-v1-diagnostic-kind+)

(define-poo-value
  (feature-bundle-v1-lowering-plan status accepted? descriptor diagnostics)
  +feature-bundle-v1-lowering-plan-kind+)

(def (poo-kind? value expected-kind)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) expected-kind)))

(def (feature-bundle-v1-compact-id? value)
  (poo-kind? value +feature-bundle-v1-compact-id-kind+))

(def (feature-bundle-v1-component? value)
  (poo-kind? value +feature-bundle-v1-component-kind+))

(def (feature-bundle-v1-edge? value)
  (poo-kind? value +feature-bundle-v1-edge-kind+))

(def (feature-bundle-v1-evidence? value)
  (poo-kind? value +feature-bundle-v1-evidence-kind+))

(def (feature-bundle-v1-native-component? value)
  (poo-kind? value +feature-bundle-v1-native-component-kind+))

(def (feature-bundle-v1-native-edge? value)
  (poo-kind? value +feature-bundle-v1-native-edge-kind+))

(def (feature-bundle-v1-native-evidence? value)
  (poo-kind? value +feature-bundle-v1-native-evidence-kind+))

(def (feature-bundle-v1-region? value)
  (poo-kind? value +feature-bundle-v1-region-kind+))

(def (feature-bundle-v1-descriptor? value)
  (poo-kind? value +feature-bundle-v1-descriptor-kind+))

(def (feature-bundle-v1-diagnostic? value)
  (poo-kind? value +feature-bundle-v1-diagnostic-kind+))

(def (feature-bundle-v1-lowering-plan? value)
  (poo-kind? value +feature-bundle-v1-lowering-plan-kind+))

(def (valid-uint64? value)
  (and (integer? value)
       (exact? value)
       (>= value 0)
       (< value +feature-bundle-v1-uint64-modulus+)))

(def (valid-semantic-id? value)
  (cond
   ((symbol? value) #t)
   ((string? value) (> (string-length value) 0))
   ((valid-uint64? value) #t)
   (else #f)))

(def (semantic-id->string value)
  (cond
   ((symbol? value) (string-append "symbol:" (symbol->string value)))
   ((string? value) (string-append "string:" value))
   ((and (integer? value) (exact? value))
    (string-append "integer:" (number->string value)))
   (else (error "Bundle v1 semantic identity expected" value))))

(def (digest-segment->uint64 digest start)
  (poo-flow-fold-left
   (lambda (byte accumulator)
     (modulo (+ (* accumulator 256) byte)
             +feature-bundle-v1-uint64-modulus+))
   0
   (u8vector->list (subu8vector digest start (+ start 8)))))

(def (feature-bundle-v1-lower-compact-id domain source)
  (unless (and (symbol? domain) (valid-semantic-id? source))
    (error "Bundle v1 compact identity requires a domain and semantic id"
           domain source))
  (let* ((canonical
          (string-append "poo-flow.bundle-v1.id/"
                         (symbol->string domain)
                         "/"
                         (semantic-id->string source)))
         (digest (sha256 canonical)))
    (feature-bundle-v1-compact-id
     domain source
     (digest-segment->uint64 digest 0)
     (digest-segment->uint64 digest 8))))

(def (feature-bundle-v1-compact-id=? left right)
  (and (= (.ref left 'high) (.ref right 'high))
       (= (.ref left 'low) (.ref right 'low))))

(def (feature-bundle-v1-compact-id<? left right)
  (or (< (.ref left 'high) (.ref right 'high))
      (and (= (.ref left 'high) (.ref right 'high))
           (< (.ref left 'low) (.ref right 'low)))))

(def (valid-composition-order? value)
  (valid-uint64? value))

(def (object-has-valid-ids? value slots)
  (poo-flow-all?
   (lambda (slot)
     (and (.slot? value slot)
          (valid-semantic-id? (.ref value slot))))
   slots))

(def (valid-component? value)
  (and (feature-bundle-v1-component? value)
       (object-has-valid-ids?
        value
        '(case-id component-id object-id type-id contract-id role-id
          capability-id policy-id strategy-id adapter-id projection-id))
       (.slot? value 'composition-order)
       (valid-composition-order? (.ref value 'composition-order))))

(def (valid-edge? value)
  (and (feature-bundle-v1-edge? value)
       (object-has-valid-ids?
        value
        '(case-id source-component-id target-component-id relation-id))
       (.slot? value 'composition-order)
       (valid-composition-order? (.ref value 'composition-order))))

(def (valid-evidence? value)
  (and (feature-bundle-v1-evidence? value)
       (object-has-valid-ids?
        value
        '(case-id obligation-id contract-id evidence-type-id proof-system-id))
       (.slot? value 'composition-order)
       (valid-composition-order? (.ref value 'composition-order))))

(def (lower-component value)
  (feature-bundle-v1-native-component
   (feature-bundle-v1-lower-compact-id 'case (.ref value 'case-id))
   (feature-bundle-v1-lower-compact-id 'component (.ref value 'component-id))
   (feature-bundle-v1-lower-compact-id 'object (.ref value 'object-id))
   (feature-bundle-v1-lower-compact-id 'type (.ref value 'type-id))
   (feature-bundle-v1-lower-compact-id 'contract (.ref value 'contract-id))
   (feature-bundle-v1-lower-compact-id 'role (.ref value 'role-id))
   (feature-bundle-v1-lower-compact-id
    'capability (.ref value 'capability-id))
   (feature-bundle-v1-lower-compact-id 'policy (.ref value 'policy-id))
   (feature-bundle-v1-lower-compact-id 'strategy (.ref value 'strategy-id))
   (feature-bundle-v1-lower-compact-id 'adapter (.ref value 'adapter-id))
   (feature-bundle-v1-lower-compact-id
    'projection (.ref value 'projection-id))
   (.ref value 'composition-order)
   +feature-bundle-v1-component-enabled-flag+
   0
   0))

(def (lower-edge value)
  (feature-bundle-v1-native-edge
   (feature-bundle-v1-lower-compact-id 'case (.ref value 'case-id))
   (feature-bundle-v1-lower-compact-id
    'component (.ref value 'source-component-id))
   (feature-bundle-v1-lower-compact-id
    'component (.ref value 'target-component-id))
   (feature-bundle-v1-lower-compact-id 'relation (.ref value 'relation-id))
   (.ref value 'composition-order)
   0
   0))

(def (lower-evidence value)
  (feature-bundle-v1-native-evidence
   (feature-bundle-v1-lower-compact-id 'case (.ref value 'case-id))
   (feature-bundle-v1-lower-compact-id
    'obligation (.ref value 'obligation-id))
   (feature-bundle-v1-lower-compact-id 'contract (.ref value 'contract-id))
   (feature-bundle-v1-lower-compact-id
    'evidence-type (.ref value 'evidence-type-id))
   (feature-bundle-v1-lower-compact-id
    'proof-system (.ref value 'proof-system-id))
   (.ref value 'composition-order)
   0
   0))

(def (compare-compact-ids left right)
  (cond
   ((feature-bundle-v1-compact-id<? left right) -1)
   ((feature-bundle-v1-compact-id=? left right) 0)
   (else 1)))

(def (compare-component-rows left right)
  (let ((case-order
         (compare-compact-ids (.ref left 'case-id) (.ref right 'case-id))))
    (if (= case-order 0)
        (compare-compact-ids
         (.ref left 'component-id) (.ref right 'component-id))
        case-order)))

(def (compare-edge-rows left right)
  (let* ((case-order
          (compare-compact-ids (.ref left 'case-id) (.ref right 'case-id)))
         (source-order
          (if (= case-order 0)
              (compare-compact-ids
               (.ref left 'source-component-id)
               (.ref right 'source-component-id))
              case-order))
         (composition-order
          (if (= source-order 0)
              (cond
               ((< (.ref left 'composition-order)
                   (.ref right 'composition-order)) -1)
               ((> (.ref left 'composition-order)
                   (.ref right 'composition-order)) 1)
               (else 0))
              source-order))
         (target-order
          (if (= composition-order 0)
              (compare-compact-ids
               (.ref left 'target-component-id)
               (.ref right 'target-component-id))
              composition-order)))
    (if (= target-order 0)
        (compare-compact-ids
         (.ref left 'relation-id) (.ref right 'relation-id))
        target-order)))

(def (compare-evidence-rows left right)
  (let ((case-order
         (compare-compact-ids (.ref left 'case-id) (.ref right 'case-id))))
    (if (= case-order 0)
        (compare-compact-ids
         (.ref left 'obligation-id) (.ref right 'obligation-id))
        case-order)))

(def (strictly-ordered? values compare)
  (or (null? values)
      (null? (cdr values))
      (and (< (compare (car values) (cadr values)) 0)
           (strictly-ordered? (cdr values) compare))))

(def (align-up value alignment)
  (* (quotient (+ value (- alignment 1)) alignment) alignment))

(def (make-region name offset count stride alignment)
  (feature-bundle-v1-region
   name offset (* count stride) stride alignment count))

(def (compact-id->canonical value)
  (list (.ref value 'high) (.ref value 'low)))

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

(def (edge-row->canonical value)
  (list
   (compact-id->canonical (.ref value 'case-id))
   (compact-id->canonical (.ref value 'source-component-id))
   (compact-id->canonical (.ref value 'target-component-id))
   (compact-id->canonical (.ref value 'relation-id))
   (.ref value 'composition-order)
   (.ref value 'flags)
   (.ref value 'reserved0)))

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

(def (bundle-digest bundle-id components edges evidence)
  (sha256
   (call-with-output-string
    (lambda (port)
      (write
       (list +feature-bundle-v1-schema+
             (compact-id->canonical bundle-id)
             (poo-flow-map component-row->canonical components)
             (poo-flow-map edge-row->canonical edges)
             (poo-flow-map evidence-row->canonical evidence))
       port)))))

(def (build-descriptor bundle-id bundle-epoch components edges evidence)
  (let* ((component-count (length components))
         (edge-count (length edges))
         (evidence-count (length evidence))
         (symbols (make-region 'symbols 0 0
                               +feature-bundle-v1-symbol-row-size+
                               +feature-bundle-v1-row-alignment+))
         (component-offset 0)
         (component-region
          (make-region 'components component-offset component-count
                       +feature-bundle-v1-component-row-size+
                       +feature-bundle-v1-row-alignment+))
         (edge-offset
          (align-up (+ component-offset (.ref component-region 'length))
                    +feature-bundle-v1-row-alignment+))
         (edge-region
          (make-region 'edges edge-offset edge-count
                       +feature-bundle-v1-edge-row-size+
                       +feature-bundle-v1-row-alignment+))
         (evidence-offset
          (align-up (+ edge-offset (.ref edge-region 'length))
                    +feature-bundle-v1-row-alignment+))
         (evidence-region
          (make-region 'evidence-obligations evidence-offset evidence-count
                       +feature-bundle-v1-evidence-row-size+
                       +feature-bundle-v1-row-alignment+))
         (metadata-offset
          (+ evidence-offset (.ref evidence-region 'length)))
         (metadata (make-region 'metadata-bytes metadata-offset 0 1 1))
         (arena-bytes
          (max +feature-bundle-v1-arena-alignment+
               (align-up metadata-offset
                         +feature-bundle-v1-arena-alignment+))))
    (feature-bundle-v1-descriptor
     +feature-bundle-v1-descriptor-size+
     +feature-bundle-v1-descriptor-flags+
     +feature-bundle-v1-schema-major+
     +feature-bundle-v1-schema-minor+
     0
     bundle-id
     (bundle-digest bundle-id components edges evidence)
     bundle-epoch
     arena-bytes
     symbols component-region edge-region evidence-region metadata
     '(0 0 0 0 0 0 0)
     components edges evidence)))

(def (rejected-plan code subject detail)
  (feature-bundle-v1-lowering-plan
   'rejected #f #f
   (list (feature-bundle-v1-diagnostic code subject detail))))

(def (feature-bundle-v1-lowering
      bundle-id bundle-epoch components edges evidence)
  (cond
   ((not (valid-semantic-id? bundle-id))
    (rejected-plan 'invalid-bundle-id bundle-id
                   'expected-nonempty-symbol-string-or-uint64))
   ((not (valid-uint64? bundle-epoch))
    (rejected-plan 'invalid-bundle-epoch bundle-id 'expected-uint64))
   ((not (and (list? components) (list? edges) (list? evidence)))
    (rejected-plan 'invalid-collection-shape bundle-id
                   'expected-proper-lists))
   ((not (poo-flow-list-of? valid-component? components))
    (rejected-plan 'invalid-component bundle-id
                   'expected-poo-native-component))
   ((not (poo-flow-list-of? valid-edge? edges))
    (rejected-plan 'invalid-edge bundle-id 'expected-poo-native-edge))
   ((not (poo-flow-list-of? valid-evidence? evidence))
    (rejected-plan 'invalid-evidence bundle-id
                   'expected-poo-native-evidence))
   (else
    (let* ((native-components
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
          native-components native-edges native-evidence)
         '())))))))

(def (require-feature-bundle-v1-lowering-plan value)
  (unless (and (feature-bundle-v1-lowering-plan? value)
               (.slot? value 'accepted?)
               (.ref value 'accepted?))
    (error "Accepted Bundle v1 lowering plan expected" value))
  value)
