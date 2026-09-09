;;; -*- Gerbil -*-
;;; Boundary: deterministic lazy-slot admission over upstream POO objects.
;;; Invariant: debug paths retain symbols only; receivers and values stay out.

(import :gerbil/gambit
        (only-in :clan/poo/object
                 .o
                 .ref
                 .all-slots
                 .putslot!
                 object?
                 $computed-slot-spec)
        (only-in :clan/poo/mop validate)
        (only-in :clan/debug traced-function)
        (only-in :clan/poo/debug DDT)
        (only-in :std/error deferror-class)
        (only-in "types.ss"
                 PooFlowDebugSlotPolicyContract
                 PooFlowDebugSlotReceiptContract)
        (only-in "func.ss"
                 poo-flow-debug-slot-policy
                 poo-flow-debug-slot-receipt
                 poo-flow-debug-slot-receipt-sexp))

(export PooFlowDebugSlotPolicyContract
        PooFlowDebugSlotReceiptContract
        poo-flow-debug-slot-policy
        poo-flow-debug-slot-receipt
        poo-flow-debug-slot-receipt-sexp
        poo-flow-debug-poo
        PooFlowDebugSlotAnomaly?
        PooFlowDebugSlotAnomaly-receipt)

(deferror-class PooFlowDebugSlotAnomaly (receipt))

;;; Active slots are dynamically scoped per Scheme thread.  A path contains
;;; only receiver/slot symbol pairs and therefore cannot keep a receiver or
;;; computed value alive while a resolution is being diagnosed.
;; : (Parameter [(Pair Symbol Symbol)])
(def poo-flow-debug-active-slot-path (make-parameter '()))

;; : (-> PooFlowDebugSlotReceipt OutputPort Unit)
(def (poo-flow-debug-emit-slot-receipt receipt port)
  (parameterize ((current-error-port port))
    (DDT 'debug-slot poo-flow-debug-slot-receipt-sexp receipt)))

;; : (-> PooFlowDebugSlotReceipt Never)
(def (poo-flow-debug-raise-slot-anomaly receipt)
  (let (failure
        (PooFlowDebugSlotAnomaly
         "POO Flow debug slot admission rejected lazy resolution"
         irritants: '()))
    (set! (PooFlowDebugSlotAnomaly-receipt failure) receipt)
    (raise failure)))

;;; Resolution tracing follows Clan's `traced-function`, but the upstream
;;; printer sees a zero-argument thunk and the closed symbol `resolved` only.
;;; The actual slot value and original exception remain lexical values here.
;; : (forall (a) (-> PooFlowDebugSlotPolicy Symbol Symbol (-> a) OutputPort Boolean a))
;; : (-> PooFlowDebugSlotPolicy Symbol Symbol (-> Object) OutputPort Boolean Object)
(def (poo-flow-debug-resolve-slot policy receiver slot superfun port emit?)
  (let* ((edge (cons receiver slot))
         (path (poo-flow-debug-active-slot-path))
         (depth (length path))
         (rejected-outcome
          (cond ((member edge path) 'rejected-cycle)
                ((>= depth (.ref policy 'maximum-depth)) 'rejected-depth)
                (else #f))))
    (when rejected-outcome
      (let (receipt
            (poo-flow-debug-slot-receipt
             policy receiver slot depth path rejected-outcome))
        (when emit? (poo-flow-debug-emit-slot-receipt receipt port))
        (poo-flow-debug-raise-slot-anomaly receipt)))
    (let ((resolved-value #!void)
          (admitted
           (poo-flow-debug-slot-receipt
            policy receiver slot depth path 'admitted)))
      (when emit? (poo-flow-debug-emit-slot-receipt admitted port))
      (parameterize ((poo-flow-debug-active-slot-path (cons edge path)))
        (let (resolve
              (lambda ()
                (set! resolved-value (superfun))
                'resolved))
          (with-exception-catcher
           (lambda (failure)
             (when emit?
               (poo-flow-debug-emit-slot-receipt
                (poo-flow-debug-slot-receipt
                 policy receiver slot depth path 'raised)
                port))
             (raise failure))
           (lambda ()
             (if emit?
               ((traced-function
                 (list 'poo-flow-debug-slot receiver slot)
                 resolve
                 port))
               (resolve))))))
      (when emit?
        (poo-flow-debug-emit-slot-receipt
         (poo-flow-debug-slot-receipt
          policy receiver slot depth path 'resolved)
         port))
      resolved-value)))

;; : (-> PooFlowDebugSlotPolicy Symbol Symbol OutputPort Boolean SlotSpec)
(def (poo-flow-debug-slot-spec policy receiver slot port emit?)
  ($computed-slot-spec
   (lambda (_self superfun)
     (poo-flow-debug-resolve-slot
      policy receiver slot superfun port emit?))))

;; : (-> PooFlowDebugSlotPolicy Symbol PooObject OutputPort Boolean PooObject)
(def (poo-flow-debug-install-slot-guards! policy receiver source port emit?)
  (let (guarded (.o (:: @ source)))
    (for-each
     (lambda (slot)
       (.putslot!
        guarded
        slot
        (poo-flow-debug-slot-spec policy receiver slot port emit?)))
     (.all-slots source))
    guarded))

;; : (forall (a) (-> PooFlowDebugSlotPolicy Symbol a port: OutputPort emit?: Boolean a))
;; poo-flow-debug-poo
;;   : (-> PooFlowDebugSlotPolicy Symbol PooObject port: OutputPort emit?: Boolean PooObject)
;;   | doc m%
;;       Create a POO proxy whose inherited slots are admitted before lazy
;;       resolution.  Re-entering an active slot or crossing the depth budget
;;       raises a typed anomaly before the upstream cache can recurse.
;;       Successful values retain ordinary POO object-local caching.  Clan's
;;       tracer receives only a zero-argument resolver returning `resolved`.
;;
;;       The receiver name is explicit and symbolic: this boundary never reads
;;       a potentially recursive `sexp` or identity slot to label the object.
;;
;;       # Examples
;;
;;       ```scheme
;;       (def guarded
;;         (poo-flow-debug-poo policy 'configuration configuration))
;;       (.ref guarded 'project-id)
;;       ;; => cached value, or raises PooFlowDebugSlotAnomaly
;;       ```
;;     %
(def (poo-flow-debug-poo policy receiver source
                         port: (port (current-error-port))
                         emit?: (emit? #t))
  (unless (and (symbol? receiver) (object? source)
               (output-port? port) (boolean? emit?))
    (error "invalid POO Flow slot debug request" receiver))
  (unless (eq? (validate PooFlowDebugSlotPolicyContract policy) policy)
    (error "invalid POO Flow debug slot policy"))
  (poo-flow-debug-install-slot-guards!
   policy receiver source port emit?))
