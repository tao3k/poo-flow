(import :clan/poo/object
        :poo-flow/src/utilities/functional
        :poo-flow/src/feature-system/bundle-v1-lowering)

(export +feature-bundle-v1-foreign-arena-image-kind+
        +feature-bundle-v1-foreign-arena-diagnostic-kind+
        feature-bundle-v1-foreign-arena-image?
        feature-bundle-v1-foreign-arena-diagnostic?
        feature-bundle-v1-write-foreign-arena
        require-feature-bundle-v1-foreign-arena-image)

(def +feature-bundle-v1-foreign-arena-image-kind+
  'poo-flow.feature-bundle-v1-foreign-arena-image.v1)

(def +feature-bundle-v1-foreign-arena-diagnostic-kind+
  'poo-flow.feature-bundle-v1-foreign-arena-diagnostic.v1)

(def +bundle-v1-descriptor-size+ 256)
(def +bundle-v1-arena-alignment+ 64)
(def +bundle-v1-symbol-row-size+ 32)
(def +bundle-v1-component-row-size+ 200)
(def +bundle-v1-edge-row-size+ 80)
(def +bundle-v1-evidence-row-size+ 96)
(def +uint16-limit+ 65536)
(def +uint32-limit+ 4294967296)
(def +uint64-limit+ 18446744073709551616)
(def +byte-offsets/u16+ '(0 1))
(def +byte-offsets/u32+ '(0 1 2 3))
(def +byte-offsets/u64+ '(0 1 2 3 4 5 6 7))
(def +digest-byte-offsets+
  '(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
    16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31))

(defsyntax define-bundle-v1-foreign-arena-object
  (syntax-rules ()
    ((_ (constructor object-kind) (slot ...))
     (def (constructor slot ...)
       (object<-alist
        (list (cons 'kind object-kind)
              (cons 'slot slot) ...))))))

(define-bundle-v1-foreign-arena-object
  (make-foreign-arena-image +feature-bundle-v1-foreign-arena-image-kind+)
  (status accepted? descriptor descriptor-image arena-image arena-length
          diagnostics))

(define-bundle-v1-foreign-arena-object
  (make-foreign-arena-diagnostic
   +feature-bundle-v1-foreign-arena-diagnostic-kind+)
  (reason detail))

(def (poo-kind? value expected-kind)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) expected-kind)))

(def (feature-bundle-v1-foreign-arena-image? value)
  (poo-kind? value +feature-bundle-v1-foreign-arena-image-kind+))

(def (feature-bundle-v1-foreign-arena-diagnostic? value)
  (poo-kind? value +feature-bundle-v1-foreign-arena-diagnostic-kind+))

(def (require-feature-bundle-v1-foreign-arena-image value)
  (unless (and (feature-bundle-v1-foreign-arena-image? value)
               (.ref value 'accepted?))
    (error "Accepted Bundle v1 foreign arena image expected" value))
  value)

(def (valid-unsigned? value limit)
  (and (exact-integer? value) (<= 0 value) (< value limit)))

(def (write-unsigned-le! target offset value byte-offsets limit)
  (unless (and (u8vector? target)
               (valid-unsigned? offset +uint64-limit+)
               (valid-unsigned? value limit)
               (<= (+ offset (length byte-offsets))
                   (u8vector-length target)))
    (error "Bundle v1 unsigned write is out of bounds"
           offset value (length byte-offsets)))
  (let ((remaining
         (poo-flow-fold-left
          (lambda (byte-offset remaining)
            (u8vector-set! target (+ offset byte-offset)
                           (modulo remaining 256))
            (quotient remaining 256))
          value
          byte-offsets)))
    (unless (= remaining 0)
      (error "Bundle v1 unsigned write overflow" value)))
  target)

(def (write-u16! target offset value)
  (write-unsigned-le! target offset value
                      +byte-offsets/u16+ +uint16-limit+))

(def (write-u32! target offset value)
  (write-unsigned-le! target offset value
                      +byte-offsets/u32+ +uint32-limit+))

(def (write-u64! target offset value)
  (write-unsigned-le! target offset value
                      +byte-offsets/u64+ +uint64-limit+))

(def (write-compact-id! target offset compact-id)
  (unless (and (object? compact-id)
               (.slot? compact-id 'high)
               (.slot? compact-id 'low))
    (error "Bundle v1 compact id expected" compact-id))
  (write-u64! target offset (.ref compact-id 'high))
  (write-u64! target (+ offset 8) (.ref compact-id 'low))
  target)

(def (write-compact-ids! target offset compact-ids)
  (poo-flow-fold-left
   (lambda (compact-id cursor)
     (write-compact-id! target cursor compact-id)
     (+ cursor 16))
   offset
   compact-ids))

(def (write-bytevector! target offset source byte-offsets)
  (unless (u8vector? source)
    (error "Bundle v1 digest bytevector expected" source))
  (poo-flow-fold-left
   (lambda (byte-offset target)
     (u8vector-set! target (+ offset byte-offset)
                    (u8vector-ref source byte-offset))
     target)
   target
   byte-offsets))

(def (write-region! target offset region)
  (write-u64! target offset (.ref region 'offset))
  (write-u64! target (+ offset 8) (.ref region 'length))
  (write-u32! target (+ offset 16) (.ref region 'stride))
  (write-u32! target (+ offset 20) (.ref region 'alignment))
  target)

(def (checked-region! region arena-length expected-stride expected-alignment
                      rows)
  (let ((offset (.ref region 'offset))
        (region-length (.ref region 'length))
        (stride (.ref region 'stride))
        (alignment (.ref region 'alignment))
        (count (.ref region 'count)))
    (unless (and (= stride expected-stride)
                 (= alignment expected-alignment)
                 (= count (length rows))
                 (= region-length (* expected-stride (length rows)))
                 (= (modulo offset expected-alignment) 0)
                 (<= offset arena-length)
                 (<= region-length (- arena-length offset)))
      (error "Bundle v1 region does not match its row table"
             offset region-length stride alignment count
             expected-stride expected-alignment (length rows))))
  region)

(def (write-component-row! target offset row)
  (let ((cursor
         (write-compact-ids!
          target offset
          (list (.ref row 'case-id)
                (.ref row 'component-id)
                (.ref row 'object-id)
                (.ref row 'type-id)
                (.ref row 'contract-id)
                (.ref row 'role-id)
                (.ref row 'capability-id)
                (.ref row 'policy-id)
                (.ref row 'strategy-id)
                (.ref row 'adapter-id)
                (.ref row 'projection-id)))))
    (write-u64! target cursor (.ref row 'composition-order))
    (write-u32! target (+ cursor 8) (.ref row 'flags))
    (write-u32! target (+ cursor 12) (.ref row 'reserved0))
    (write-u64! target (+ cursor 16) (.ref row 'reserved1)))
  target)

(def (write-symbol-row! target offset row)
  (write-compact-id! target offset (.ref row 'id))
  (write-u64! target (+ offset 16) (.ref row 'byte-offset))
  (write-u32! target (+ offset 24) (.ref row 'byte-length))
  (write-u16! target (+ offset 28) (.ref row 'symbol-kind))
  (write-u16! target (+ offset 30) (.ref row 'flags))
  target)

(def (write-edge-row! target offset row)
  (let ((cursor
         (write-compact-ids!
          target offset
          (list (.ref row 'case-id)
                (.ref row 'source-component-id)
                (.ref row 'target-component-id)
                (.ref row 'relation-id)))))
    (write-u64! target cursor (.ref row 'composition-order))
    (write-u32! target (+ cursor 8) (.ref row 'flags))
    (write-u32! target (+ cursor 12) (.ref row 'reserved0)))
  target)

(def (write-evidence-row! target offset row)
  (let ((cursor
         (write-compact-ids!
          target offset
          (list (.ref row 'case-id)
                (.ref row 'obligation-id)
                (.ref row 'contract-id)
                (.ref row 'evidence-type-id)
                (.ref row 'proof-system-id)))))
    (write-u64! target cursor (.ref row 'composition-order))
    (write-u32! target (+ cursor 8) (.ref row 'flags))
    (write-u32! target (+ cursor 12) (.ref row 'reserved0)))
  target)

(def (write-row-table! target region rows row-size row-alignment write-row!)
  (checked-region! region (u8vector-length target)
                   row-size row-alignment rows)
  (poo-flow-fold-left
   (lambda (row index)
     (write-row! target
                 (+ (.ref region 'offset) (* index row-size))
                 row)
     (+ index 1))
   0
   rows)
  target)

(def (write-metadata! target region metadata-image)
  (unless (and (u8vector? metadata-image)
               (= (.ref region 'stride) 1)
               (= (.ref region 'alignment) 1)
               (= (.ref region 'count) (u8vector-length metadata-image))
               (= (.ref region 'length) (u8vector-length metadata-image))
               (<= (.ref region 'offset) (u8vector-length target))
               (<= (.ref region 'length)
                   (- (u8vector-length target) (.ref region 'offset))))
    (error "Bundle v1 metadata region does not match its byte image"
           region metadata-image))
  (let loop ((index 0))
    (when (< index (u8vector-length metadata-image))
      (u8vector-set! target
                     (+ (.ref region 'offset) index)
                     (u8vector-ref metadata-image index))
      (loop (+ index 1))))
  target)

(def (write-reserved! target offset values)
  (unless (= (length values) 7)
    (error "Bundle v1 descriptor requires seven reserved uint64 values"
           values))
  (poo-flow-fold-left
   (lambda (value cursor)
     (write-u64! target cursor value)
     (+ cursor 8))
   offset
   values)
  target)

(def (write-descriptor! target descriptor)
  (let ((digest (.ref descriptor 'digest)))
    (unless (and (= (u8vector-length target) +bundle-v1-descriptor-size+)
                 (= (.ref descriptor 'struct-size)
                    +bundle-v1-descriptor-size+)
                 (u8vector? digest)
                 (= (u8vector-length digest) 32))
      (error "Bundle v1 descriptor image shape is invalid" descriptor))
    (write-u32! target 0 (.ref descriptor 'struct-size))
    (write-u32! target 4 (.ref descriptor 'flags))
    (write-u16! target 8 (.ref descriptor 'schema-major))
    (write-u16! target 10 (.ref descriptor 'schema-minor))
    (write-u32! target 12 (.ref descriptor 'reserved0))
    (write-compact-id! target 16 (.ref descriptor 'bundle-id))
    (write-bytevector! target 32 digest +digest-byte-offsets+)
    (write-u64! target 64 (.ref descriptor 'bundle-epoch))
    (write-u64! target 72 (.ref descriptor 'arena-bytes))
    (write-region! target 80 (.ref descriptor 'symbols))
    (write-region! target 104 (.ref descriptor 'components))
    (write-region! target 128 (.ref descriptor 'edges))
    (write-region! target 152 (.ref descriptor 'evidence-obligations))
    (write-region! target 176 (.ref descriptor 'metadata-bytes))
    (write-reserved! target 200 (.ref descriptor 'reserved)))
  target)

(def (write-arena! target descriptor)
  (let ((symbols (.ref descriptor 'symbols))
        (metadata (.ref descriptor 'metadata-bytes))
        (symbol-rows (.ref descriptor 'symbol-rows))
        (metadata-image (.ref descriptor 'metadata-image))
        (component-rows (.ref descriptor 'component-rows))
        (edge-rows (.ref descriptor 'edge-rows))
        (evidence-rows (.ref descriptor 'evidence-rows)))
    (unless (and (= (u8vector-length target) (.ref descriptor 'arena-bytes))
                 (= (modulo (u8vector-length target)
                            +bundle-v1-arena-alignment+)
                    0))
      (error "Bundle v1 arena image shape is invalid" descriptor))
    (write-row-table! target symbols symbol-rows
                      +bundle-v1-symbol-row-size+ 8 write-symbol-row!)
    (write-metadata! target metadata metadata-image)
    (write-row-table! target (.ref descriptor 'components)
                      component-rows +bundle-v1-component-row-size+ 8
                      write-component-row!)
    (write-row-table! target (.ref descriptor 'edges)
                      edge-rows +bundle-v1-edge-row-size+ 8
                      write-edge-row!)
    (write-row-table! target (.ref descriptor 'evidence-obligations)
                      evidence-rows +bundle-v1-evidence-row-size+ 8
                      write-evidence-row!))
  target)

(def (rejected-image reason detail)
  (make-foreign-arena-image
   'rejected #f #f (make-u8vector 0) (make-u8vector 0) 0
   (list (make-foreign-arena-diagnostic reason detail))))

(def (feature-bundle-v1-write-foreign-arena lowering-plan)
  (with-catch
   (lambda (failure)
     (rejected-image 'foreign-arena-write-failed failure))
   (lambda ()
     (let* ((accepted-plan
             (require-feature-bundle-v1-lowering-plan lowering-plan))
            (descriptor (.ref accepted-plan 'descriptor))
            (descriptor-image
             (make-u8vector +bundle-v1-descriptor-size+ 0))
            (arena-length (.ref descriptor 'arena-bytes))
            (arena-image (make-u8vector arena-length 0)))
       (write-descriptor! descriptor-image descriptor)
       (write-arena! arena-image descriptor)
       (make-foreign-arena-image
        'ready #t descriptor descriptor-image arena-image arena-length '())))))
