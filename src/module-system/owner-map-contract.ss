(import :std/sugar)

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

(def (poo-flow-owner-map-ref value key)
  (let (entry (assq key value))
    (and entry (cdr entry))))

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

(def (poo-flow-module-system-owner-map-valid? rows)
  (and (= (length rows)
          (length +poo-flow-module-system-owner-map-required-row-identities+))
       (let loop ((required
                   +poo-flow-module-system-owner-map-required-row-identities+))
         (or (null? required)
             (and (= 1
                     (length
                      (filter (lambda (row)
                                (eq? (poo-flow-owner-map-ref row 'row-identity)
                                     (car required)))
                              rows)))
                  (loop (cdr required)))))
       (let loop ((remaining rows))
         (or (null? remaining)
             (and (poo-flow-module-system-owner-map-row-valid?
                   (car remaining))
                  (loop (cdr remaining)))))))
