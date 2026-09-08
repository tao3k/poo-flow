;;; -*- Gerbil -*-
;;; Checked construction and native inherited-slot plan collection.
(import (only-in :clan/poo/object .o .ref .slot? object? .extend .mix
                               $constant-slot-spec $computed-slot-spec)
        (only-in :clan/poo/mop element?) "types.ss")
(export poo-combination-generic poo-combination-method poo-method-bundle
        poo-method-root poo-method-prototype poo-combination-failure?
        combination-fail require-generic require-plan receiver-plan make-frame)
(def (combination-fail code-value generic: (generic-value #f)
                       qualifier: (qualifier-value #f) method: (method-value #f))
  (raise (.o (:: @ (.ref CombinationFailure 'proto))
             code: code-value generic: generic-value
             qualifier: qualifier-value method: method-value)))
(def (poo-combination-failure? value) (element? CombinationFailure value))
(def (require-generic value)
  (unless (element? CombinationGeneric value) (combination-fail 'invalid-generic)) value)
(def (checked type value code)
  (unless (element? type value) (combination-fail code)) value)
(def (poo-combination-generic identity-value collector-slot-value
                             from: (from-value 'instance)
                             required: (required-value 0) rest?: (rest-value #t))
  (checked CombinationGeneric
    (.o (:: self (.ref CombinationGeneric 'proto))
        identity: identity-value collector-slot: collector-slot-value
        from: from-value required: required-value rest?: rest-value
        root: (make-root self)) 'invalid-generic))
(def (poo-combination-method identity-value body-value)
  (checked CombinationMethod
    (.o (:: @ (.ref CombinationMethod 'proto)) identity: identity-value body: body-value) 'invalid-method))
(def (poo-method-bundle around: (around-value #f) before: (before-value #f)
                        primary: (primary-value #f) after: (after-value #f))
  (checked CombinationBundle
    (.o (:: @ (.ref CombinationBundle 'proto))
        around: around-value before: before-value primary: primary-value after: after-value) 'invalid-bundle))
(def (make-plan generic-value around-value before-value primary-value after-value)
  (.o (:: @ (.ref CombinationPlan 'proto))
      generic: generic-value around: around-value before: before-value
      primary: primary-value after: after-value
      ;; Explicit native demand: derived once per receiver plan.
      after-order: (reverse after)))
(def (require-plan generic candidate)
  ;; Plans come from our collector. Preserve upstream C3/slot exceptions.
  (unless (combination-instance? (.ref CombinationPlan 'proto) candidate)
    (combination-fail 'invalid-method-plan generic: (.ref generic 'identity)))
  (unless (.ref candidate 'valid?)
    (combination-fail 'invalid-method-plan generic: (.ref generic 'identity)))
  (unless (eq? (.ref candidate 'generic) generic)
    (combination-fail 'generic-slot-collision generic: (.ref generic 'identity))) candidate)
(def (prepend-method bundle qualifier parent)
  (let (method (.ref bundle qualifier))
    (if method (cons method (.ref parent qualifier)) (.ref parent qualifier))))
(def (extend-plan generic bundle inherited)
  (let (parent (require-plan generic (inherited)))
    (make-plan generic (prepend-method bundle 'around parent)
               (prepend-method bundle 'before parent) (prepend-method bundle 'primary parent)
               (prepend-method bundle 'after parent))))
(def (validate-owners owners)
  ;; Metadata only: this does not order methods or redo C3 linearization.
  (let loop ((remaining owners))
    (unless (null? remaining)
      (let (generic (car remaining))
        (for-each
         (lambda (other)
           (when (and (not (eq? generic other))
                      (eq? (.ref generic 'collector-slot) (.ref other 'collector-slot)))
             (combination-fail 'generic-slot-collision generic: (.ref generic 'identity))))
         (cdr remaining)))
      (loop (cdr remaining)))) #t)
(def CombinationRoot.
  (.o poo/combination/owners: '()
      poo/combination/owners-valid?: (validate-owners poo/combination/owners)))
(def (make-root generic)
  (.extend CombinationRoot.
    (cons 'poo/combination/owners
          ($computed-slot-spec (lambda (_self inherited) (cons generic (inherited)))))
    (cons (.ref generic 'collector-slot)
          ($constant-slot-spec (make-plan generic '() '() '() '())))))
(def (poo-method-root generic)
  (require-generic generic)
  ;; One shared native root per descriptor, no mutable global registry.
  (.ref generic 'root))
(def (poo-method-prototype base generic bundle)
  (require-generic generic)
  (checked CombinationBundle bundle 'invalid-bundle)
  (unless (and (object? base) (.slot? base (.ref generic 'collector-slot)))
    (combination-fail 'missing-method-root generic: (.ref generic 'identity)))
  (when (.slot? base 'poo/combination/owners-valid?) (.ref base 'poo/combination/owners-valid?))
  (require-plan generic (.ref base (.ref generic 'collector-slot)))
  (.extend base
    (cons (.ref generic 'collector-slot)
      ($computed-slot-spec (lambda (_self inherited) (extend-plan generic bundle inherited))))))
(def (receiver-plan generic receiver)
  (unless (object? receiver)
    (combination-fail 'invalid-receiver generic: (.ref generic 'identity)))
  (let (owner
         (if (eq? (.ref generic 'from) 'instance) receiver
             (if (.slot? receiver '.type) (.ref receiver '.type)
                 (combination-fail 'missing-dispatch-type generic: (.ref generic 'identity)))))
    (unless (object? owner)
      (combination-fail 'invalid-dispatch-type generic: (.ref generic 'identity)))
    (when (.slot? owner 'poo/combination/owners-valid?) (.ref owner 'poo/combination/owners-valid?))
    (unless (.slot? owner (.ref generic 'collector-slot))
      (combination-fail 'no-applicable-method generic: (.ref generic 'identity)))
    (require-plan generic (.ref owner (.ref generic 'collector-slot)))))
(def (make-frame plan-value arguments-value next-value qualifier-value method-value)
  ;; A hot-path value family: reuse the static prototype and constant defaults.
  ;; These internal rows are native constructor inputs, not an authoring DSL.
  (.mix (.ref CombinationFrame 'proto)
    defaults: (list (cons 'plan plan-value) (cons 'arguments arguments-value)
                    (cons 'next next-value) (cons 'qualifier qualifier-value)
                    (cons 'method method-value))))
