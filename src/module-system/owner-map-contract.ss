;;; Boundary: declarative owner-map row validation only; artifact loading and
;;; observability remain in their dedicated module-system owners.
(export +poo-flow-module-system-owner-map-schema-id+
        +poo-flow-module-system-owner-map-schema-version+
        +poo-flow-module-system-owner-map-artifact-id+
        +poo-flow-module-system-owner-map-required-row-identities+
        poo-flow-module-system-owner-map-row-valid?
        poo-flow-module-system-owner-map-valid?)

(def +poo-flow-module-system-owner-map-schema-id+
  "poo-flow.module-system-owner-map")

(def +poo-flow-module-system-owner-map-schema-version+ 1)

(def +poo-flow-module-system-owner-map-artifact-id+
  "poo-flow.module-system-owner-map.v1")

(def +poo-flow-module-system-owner-map-required-row-identities+
  '(rfc45-07-mix-module-expansion
    rfc45-02-g0-decision
    rfc45-03-runtime-context-recovery
    rfc45-04-observability-snapshot
    rfc45-05-lineage-cycle
    rfc45-06-gerbil-poo-consumption
    rfc45-07-public-composition
    rfc45-08-parent-qualification))

;; : (-> Alist Symbol Object)
(def (poo-flow-owner-map-ref value key)
  (let (entry (assq key value))
    (and entry (cdr entry))))

;; : (-> Alist Boolean)
(def (poo-flow-module-system-owner-map-row-valid? row)
  (and (pair? row)
       (member (poo-flow-owner-map-ref row 'row-identity)
               +poo-flow-module-system-owner-map-required-row-identities+)
       (string? (poo-flow-owner-map-ref row 'source-path))
       (symbol? (poo-flow-owner-map-ref row 'source-symbol))
       (string? (poo-flow-owner-map-ref row 'test-path))
       (symbol? (poo-flow-owner-map-ref row 'test-symbol))
       (string? (poo-flow-owner-map-ref row 'build-target))
       (eq? (poo-flow-owner-map-ref row 'implementation-state)
            'implemented)))

;; : (-> Symbol [Alist] Integer)
(def (poo-flow-owner-map-row-identity-count identity rows)
  (match rows
    ([] 0)
    ([row . rest]
     (+ (if (eq? (poo-flow-owner-map-ref row 'row-identity) identity) 1 0)
        (poo-flow-owner-map-row-identity-count identity rest)))))

;; : (-> [Symbol] [Alist] Boolean)
(def (poo-flow-owner-map-required-identities-valid? required rows)
  (match required
    ([] #t)
    ([identity . rest]
     (and (= 1 (poo-flow-owner-map-row-identity-count identity rows))
          (poo-flow-owner-map-required-identities-valid? rest rows)))))

;; : (-> [Alist] Boolean)
(def (poo-flow-owner-map-rows-valid? rows)
  (match rows
    ([] #t)
    ([row . rest]
     (and (poo-flow-module-system-owner-map-row-valid? row)
          (poo-flow-owner-map-rows-valid? rest)))))

;; poo-flow-module-system-owner-map-valid?
;;   : (forall (a) (-> (List a) Boolean))
;;   : (-> [Alist] Boolean)
;;   | doc m%
;;       Validate complete, unique owner-map coverage and every row contract.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-module-system-owner-map-valid? rows)
;;       ;; => #t when every required owner row occurs exactly once
;;       ```
;;     %
(def (poo-flow-module-system-owner-map-valid? rows)
  (and (= (length rows)
          (length +poo-flow-module-system-owner-map-required-row-identities+))
       (poo-flow-owner-map-required-identities-valid?
        +poo-flow-module-system-owner-map-required-row-identities+
        rows)
       (poo-flow-owner-map-rows-valid? rows)))
