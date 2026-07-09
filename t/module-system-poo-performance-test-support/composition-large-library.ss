;;; -*- Gerbil -*-
;;; Boundary: large native POO profile-library composition performance helpers.
;;; Invariant: keeps 1000+ profile object construction outside macro-expansion
;;; scenario modules so macro benchmarks, native POO object families,
;;; object-list enumeration, and indexed profile lookup can be optimized
;;; independently.

(import (only-in :clan/poo/object .o .ref))

(export +poo-performance-large-native-profile-count+
        +poo-performance-large-native-profile-variant-count+
        poo-performance-large-native-profile-name
        poo-performance-large-native-profile-variant-name
        poo-performance-large-native-profile
        poo-performance-large-native-profile-library
        poo-performance-large-native-profile-variant-library
        poo-performance-large-native-profile-object-list
        poo-performance-large-native-profile-index-vector
        poo-performance-large-native-profile-family-object-list
        poo-performance-large-native-profile-family-profile-at
        poo-performance-large-native-profile-family-variant-profile-at
        poo-performance-large-native-profile-composition
        poo-performance-large-native-profile-valid-count*)

;; : Integer
(def +poo-performance-large-native-profile-count+ 2048)

;; : Integer
(def +poo-performance-large-native-profile-variant-count+
  +poo-performance-large-native-profile-count+)

;; : Symbol
(def +poo-performance-large-native-profile-family-handle+
  'community-profiles)

;; poo-performance-large-native-profile-make-name-vector
;;   : (-> Integer String Vector)
;;   | doc m%
;;       Precomputes stable symbolic profile names once so large-profile
;;       construction does not rebuild strings during benchmark validation.
;;
;;       # Examples
;;       ```scheme
;;       (vector-ref
;;        (poo-performance-large-native-profile-make-name-vector 1 "p-")
;;        0)
;;       ;; => p-0
;;       ```
;;     %
(def (poo-performance-large-native-profile-make-name-vector
      count
      prefix)
  (list->vector
   (map (lambda (index)
          (string->symbol
           (string-append prefix (number->string index))))
        (iota count))))

;; : Vector
(def +poo-performance-large-native-profile-names+
  (poo-performance-large-native-profile-make-name-vector
   +poo-performance-large-native-profile-count+
   "community-profile-"))

;; : Vector
(def +poo-performance-large-native-profile-variant-names+
  (poo-performance-large-native-profile-make-name-vector
   +poo-performance-large-native-profile-variant-count+
   "audited-community-profile-"))

;; : (-> Integer Symbol)
(def (poo-performance-large-native-profile-name index)
  (vector-ref +poo-performance-large-native-profile-names+ index))

;; : (-> Integer Symbol)
(def (poo-performance-large-native-profile-variant-name index)
  (vector-ref +poo-performance-large-native-profile-variant-names+ index))

;; : (-> Integer PooObject)
(def (poo-performance-large-native-profile index)
  (.o (name (poo-performance-large-native-profile-name index))
      (scope '(session workflow publish-channel))
      (analysis '(checksum schema provenance))
      (publish '(human-approved proof-gated))
      (retention '(project-retained audit-log))))

;; : (-> PooObject Integer PooObject)
(def (poo-performance-large-native-profile-variant profile index)
  (.o (name (poo-performance-large-native-profile-variant-name index))
      (scope (.ref profile 'scope))
      (analysis '(checksum schema provenance citation-trace))
      (publish '(human-approved proof-gated internal-registry))
      (retention '(project-retained audit-log indexed-hot-path))))

;; poo-performance-large-native-profile-library
;;   : (-> Integer Vector)
;;   | doc m%
;;       Builds the large native POO base-profile vector once for 1000+ profile
;;       composition benchmarks.
;;
;;       # Examples
;;       ```scheme
;;       (vector-length (poo-performance-large-native-profile-library 2))
;;       ;; => 2
;;       ```
;;     %
(def (poo-performance-large-native-profile-library count)
  (list->vector
   (map poo-performance-large-native-profile (iota count))))

;; poo-performance-large-native-profile-variant-library
;;   : (-> Vector Integer Vector)
;;   | doc m%
;;       Builds variant profiles from the shared base-profile vector without
;;       routing through macro expansion or alist adapters.
;;
;;       # Examples
;;       ```scheme
;;       (vector-length
;;        (poo-performance-large-native-profile-variant-library
;;         (poo-performance-large-native-profile-library 1)
;;         1))
;;       ;; => 1
;;       ```
;;     %
(def (poo-performance-large-native-profile-variant-library base-profiles count)
  (list->vector
   (map (lambda (index)
          (poo-performance-large-native-profile-variant
           (vector-ref base-profiles index)
           index))
        (iota count))))

;; : (-> Vector [PooObject])
(def (poo-performance-large-native-profile-object-list profiles)
  (vector->list profiles))

;; : (-> Vector Vector)
(def (poo-performance-large-native-profile-index-vector profiles)
  profiles)

;; : Vector
(def +poo-performance-large-native-profile-base-fixture+
  (poo-performance-large-native-profile-library
   +poo-performance-large-native-profile-count+))

;; : Vector
(def +poo-performance-large-native-profile-variant-fixture+
  (poo-performance-large-native-profile-variant-library
   +poo-performance-large-native-profile-base-fixture+
   +poo-performance-large-native-profile-variant-count+))

;; : (-> PooObject [PooObject])
(def (poo-performance-large-native-profile-family-object-list family)
  (if (eq? (.ref family 'handle)
           +poo-performance-large-native-profile-family-handle+)
    (poo-performance-large-native-profile-object-list
     +poo-performance-large-native-profile-base-fixture+)
    (error "missing large native profile family" (.ref family 'handle))))

;; poo-performance-large-native-profile-family-profile-at
;;   : (-> PooObject Integer PooObject)
;;   | doc m%
;;       Performs direct indexed lookup into the shared native POO profile
;;       family without rebuilding profile objects.
;;
;;       # Examples
;;       ```scheme
;;       (.ref (poo-performance-large-native-profile-family-profile-at
;;              (.o (handle 'community-profiles))
;;              0)
;;             'name)
;;       ;; => community-profile-0
;;       ```
;;     %
(def (poo-performance-large-native-profile-family-profile-at family index)
  (if (eq? (.ref family 'handle)
           +poo-performance-large-native-profile-family-handle+)
    (vector-ref +poo-performance-large-native-profile-base-fixture+ index)
    (error "missing large native profile family" (.ref family 'handle))))

;; : (-> PooObject Integer PooObject)
(def (poo-performance-large-native-profile-family-variant-profile-at family index)
  (if (eq? (.ref family 'handle)
           +poo-performance-large-native-profile-family-handle+)
    (vector-ref +poo-performance-large-native-profile-variant-fixture+ index)
    (error "missing large native profile family" (.ref family 'handle))))

;; : (-> Integer [Integer])
(def (poo-performance-large-native-profile-sample-indexes count)
  (list 0
        (quotient count 8)
        (quotient count 4)
        (quotient count 2)
        (- count 2)
        (- count 1)))

;; : (-> (-> Integer PooObject) Integer Boolean)
(def (poo-performance-large-native-profile-base-pass?
      profile-at
      index)
  (let* ((name (poo-performance-large-native-profile-name index))
         (from-payload (profile-at index)))
    (and (eq? (.ref from-payload 'name) name)
         (memq 'schema (.ref from-payload 'analysis)))))

;; : (-> (-> Integer PooObject) Integer Boolean)
(def (poo-performance-large-native-profile-variant-pass?
      profile-at
      index)
  (let* ((name (poo-performance-large-native-profile-variant-name index))
         (from-payload (profile-at index)))
    (and (eq? (.ref from-payload 'name) name)
         (memq 'citation-trace (.ref from-payload 'analysis))
         (memq 'internal-registry (.ref from-payload 'publish)))))

;; poo-performance-large-native-profile-hot-path-pass?
;;   : (-> PooObject Boolean)
;;   | doc m%
;;       Checks a small deterministic sample of direct family lookups so the
;;       benchmark proves indexed POO profile reuse rather than list traversal.
;;
;;       # Examples
;;       ```scheme
;;       (poo-performance-large-native-profile-hot-path-pass?
;;        (.o (handle 'community-profiles) (count 2048)))
;;       ;; => #t
;;       ```
;;     %
(def (poo-performance-large-native-profile-hot-path-pass? family)
  (let* ((count (.ref family 'count))
         (indexes
          (poo-performance-large-native-profile-sample-indexes count)))
    (andmap
     (lambda (index)
       (and (poo-performance-large-native-profile-base-pass?
             (lambda (profile-index)
               (poo-performance-large-native-profile-family-profile-at
                family
                profile-index))
             index)
            (poo-performance-large-native-profile-variant-pass?
             (lambda (profile-index)
               (poo-performance-large-native-profile-family-variant-profile-at
                family
                profile-index))
             index)))
     indexes)))

;; poo-performance-large-native-profile-composition
;;   : (-> PooObject)
;;   | doc m%
;;       Builds the large-library composition object from shared native POO
;;       profile-family fixtures.
;;
;;       # Examples
;;       ```scheme
;;       (.ref (poo-performance-large-native-profile-composition) 'name)
;;       ;; => native-object-reuse-large-library-performance
;;       ```
;;     %
(def (poo-performance-large-native-profile-composition)
  (let* ((family
          (.o (name 'community-profiles)
              (handle +poo-performance-large-native-profile-family-handle+)
              (count +poo-performance-large-native-profile-count+)
              (variant-count
               +poo-performance-large-native-profile-variant-count+))))
    (.o (name 'native-object-reuse-large-library-performance)
        (modules
         (list (.o (name 'community-profiles)
                   (value family))))
        (stages
         (list
          (.o (name 'production)
              (clauses
               (list
                (.o (name 'compose)
                    (payload
                     (.o (family 'community-profiles)
                         (surface 'object-list-accessor)
                         (count
                          +poo-performance-large-native-profile-count+))))
                (.o (name 'extend)
                    (payload
                     (.o (family 'community-profiles)
                         (surface 'variant-object-list-accessor)
                         (count
                          +poo-performance-large-native-profile-variant-count+))))
                (.o (name 'prove)
                    (payload
                     '(large-native-profile-library
                       direct-poo-profile-reuse
                       hook-override-profile-family
                       indexed-poo-profile-lookup
	                       no-macro-expansion-adapter)))))))))))

;; poo-performance-large-native-profile-valid-count*
;;   : (-> PooObject Integer Integer)
;;   | doc m%
;;       Validates sample lookups through the large native POO profile family and
;;       returns the measured round count only when the composition is coherent.
;;
;;       # Examples
;;       ```scheme
;;       (poo-performance-large-native-profile-valid-count*
;;        (poo-performance-large-native-profile-composition)
;;        1)
;;       ;; => 1
;;       ```
;;     %
(def (poo-performance-large-native-profile-valid-count* composition rounds)
  (let* ((family (.ref (car (.ref composition 'modules)) 'value))
         (stage (car (.ref composition 'stages)))
         (clause (car (.ref stage 'clauses)))
         (payload (.ref clause 'payload))
         (count (.ref payload 'count))
         (first-profile
          (poo-performance-large-native-profile-family-profile-at family 0))
         (last-profile
          (poo-performance-large-native-profile-family-profile-at
           family
           (- count 1))))
    (if (and (= count (.ref family 'count))
             (= (.ref family 'variant-count)
                +poo-performance-large-native-profile-variant-count+)
             (eq? (.ref first-profile 'name)
                  (poo-performance-large-native-profile-name 0))
             (eq? (.ref last-profile 'name)
                  (poo-performance-large-native-profile-name
                   (- count 1))))
      (if (poo-performance-large-native-profile-hot-path-pass? family)
        rounds
        0)
      0)))
