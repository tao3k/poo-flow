(import :clan/poo/object)

(export poo-flow-proof-obligation
        poo-flow-proof-obligation-family-build
        poo-flow-proof-obligation-family-ref
        poo-flow-authorized-effect-obligations
        poo-flow-proof-evidence-roots
        poo-flow-authorized-effect-proof-case
        poo-flow-authorized-effect-proof-case-valid?)

(def +poo-flow-authorized-effect-obligation-layout+
  '((policy-revision-bound . 0)
    (effect-digest-bound . 1)
    (semantic-root-bound . 2)
    (execution-root-bound . 3)
    (obligation-set-complete . 4)
    (nonce-epoch-fresh . 5)
    (diagnostic-non-executable . 6)
    (l3-chain-complete . 7)))

(def (poo-flow-proof-obligation obligation-name obligation-bit
                                obligation-satisfied?)
  (.o (kind 'poo-flow-proof-obligation)
      (schema 'poo-flow.proof-obligation.v1)
      (name obligation-name)
      (bit obligation-bit)
      (satisfied? (and obligation-satisfied? #t))))

(def (poo-flow-proof-obligation-layout-ref name)
  (let (entry (assq name +poo-flow-authorized-effect-obligation-layout+))
    (and entry (cdr entry))))

(def (poo-flow-proof-obligation-valid? obligation)
  (and (eq? (.ref obligation 'kind) 'poo-flow-proof-obligation)
       (let* ((name (.ref obligation 'name))
              (bit (.ref obligation 'bit))
              (expected (poo-flow-proof-obligation-layout-ref name)))
         (and expected
              (exact-integer? bit)
              (= bit expected)))))

(def (poo-flow-proof-obligation-insert obligation obligations)
  (if (null? obligations)
      (list obligation)
      (if (< (.ref obligation 'bit) (.ref (car obligations) 'bit))
          (cons obligation obligations)
          (cons (car obligations)
                (poo-flow-proof-obligation-insert obligation
                                                  (cdr obligations))))))

(def (poo-flow-proof-obligations-sort obligations)
  (let loop ((rest obligations) (sorted '()))
    (if (null? rest)
        sorted
        (loop (cdr rest)
              (poo-flow-proof-obligation-insert (car rest) sorted)))))

(def (poo-flow-proof-obligations-unique? obligations)
  (let loop ((rest obligations) (names '()) (bits '()))
    (if (null? rest)
        #t
        (let* ((obligation (car rest))
               (name (.ref obligation 'name))
               (bit (.ref obligation 'bit)))
          (and (not (memq name names))
               (not (memv bit bits))
               (loop (cdr rest) (cons name names) (cons bit bits)))))))

(def (poo-flow-proof-obligations-complete? obligations)
  (and (= (length obligations)
          (length +poo-flow-authorized-effect-obligation-layout+))
       (let loop ((layout +poo-flow-authorized-effect-obligation-layout+))
         (or (null? layout)
             (and (let find ((rest obligations))
                    (and (pair? rest)
                         (or (eq? (caar layout) (.ref (car rest) 'name))
                             (find (cdr rest)))))
                  (loop (cdr layout)))))))

(def (poo-flow-proof-obligation-mask obligations satisfied-only?)
  (let loop ((rest obligations) (mask 0))
    (if (null? rest)
        mask
        (let (obligation (car rest))
          (loop (cdr rest)
                (if (or (not satisfied-only?)
                        (.ref obligation 'satisfied?))
                    (+ mask (expt 2 (.ref obligation 'bit)))
                    mask))))))

(def (poo-flow-proof-obligation-family-build obligations)
  (unless (and (list? obligations)
               (andmap poo-flow-proof-obligation-valid? obligations))
    (error "invalid proof obligation object" obligations))
  (unless (poo-flow-proof-obligations-unique? obligations)
    (error "duplicate proof obligation name or bit" obligations))
  (unless (poo-flow-proof-obligations-complete? obligations)
    (error "incomplete authorized-effect obligation family" obligations))
  (let* ((canonical (poo-flow-proof-obligations-sort obligations))
         (required-value
          (poo-flow-proof-obligation-mask canonical #f))
         (present-value
          (poo-flow-proof-obligation-mask canonical #t)))
    (.o (kind 'poo-flow-proof-obligation-family)
        (schema 'poo-flow.proof-obligation-family.v1)
        (name 'authorized-effect-token)
        (source 'proof-case-vector-v1)
        (obligations canonical)
        (required-mask required-value)
        (present-mask present-value)
        (complete? (= required-value present-value)))))

(def (poo-flow-proof-obligation-family-ref family name)
  (let loop ((rest (.ref family 'obligations)))
    (and (pair? rest)
         (if (eq? name (.ref (car rest) 'name))
             (car rest)
             (loop (cdr rest))))))

(def (poo-flow-authorized-effect-obligations
      policy-bound? effect-bound? semantic-bound? execution-bound?
      obligation-complete? nonce-fresh? diagnostic-safe? l3-complete?)
  (poo-flow-proof-obligation-family-build
   (list
    (poo-flow-proof-obligation 'policy-revision-bound 0 policy-bound?)
    (poo-flow-proof-obligation 'effect-digest-bound 1 effect-bound?)
    (poo-flow-proof-obligation 'semantic-root-bound 2 semantic-bound?)
    (poo-flow-proof-obligation 'execution-root-bound 3 execution-bound?)
    (poo-flow-proof-obligation 'obligation-set-complete 4 obligation-complete?)
    (poo-flow-proof-obligation 'nonce-epoch-fresh 5 nonce-fresh?)
    (poo-flow-proof-obligation 'diagnostic-non-executable 6 diagnostic-safe?)
    (poo-flow-proof-obligation 'l3-chain-complete 7 l3-complete?))))

(def (poo-flow-proof-evidence-roots semantic-value execution-value batch-value)
  (unless (and semantic-value execution-value)
    (error "proof evidence requires semantic and execution roots"))
  (.o (kind 'poo-flow-proof-evidence-roots)
      (schema 'poo-flow.proof-evidence-roots.v1)
      (semantic-root semantic-value)
      (execution-root execution-value)
      (batch-root batch-value)))

(def (poo-flow-authorized-effect-proof-case
      token-object roots-object obligation-family outcome-value sequence-value
      durability-value epoch-value previous-root-value)
  (unless (eq? (.ref token-object 'kind) 'poo-flow-authorized-effect-token)
    (error "proof case requires AuthorizedEffectToken" token-object))
  (unless (eq? (.ref roots-object 'kind) 'poo-flow-proof-evidence-roots)
    (error "proof case requires proof evidence roots" roots-object))
  (unless (and (eq? (.ref obligation-family 'kind)
                    'poo-flow-proof-obligation-family)
               (eq? (.ref obligation-family 'name) 'authorized-effect-token))
    (error "proof case requires authorized-effect obligation family"
           obligation-family))
  (.o (kind 'poo-flow-authorized-effect-proof-case)
      (schema 'poo-flow.proof-case-vector.v1)
      (token token-object)
      (token-id (.ref token-object 'token-id))
      (binding (.ref token-object 'binding))
      (nonce (.ref token-object 'nonce))
      (epoch epoch-value)
      (sequence sequence-value)
      (semantic-root (.ref roots-object 'semantic-root))
      (execution-root (.ref roots-object 'execution-root))
      (batch-root (.ref roots-object 'batch-root))
      (previous-evidence-root previous-root-value)
      (outcome outcome-value)
      (durability durability-value)
      (obligations obligation-family)
      (required-obligation-mask (.ref obligation-family 'required-mask))
      (present-obligation-mask (.ref obligation-family 'present-mask))
      (obligation-count (length (.ref obligation-family 'obligations)))))

(def (poo-flow-authorized-effect-proof-case-valid? proof-case)
  (and (eq? (.ref proof-case 'kind) 'poo-flow-authorized-effect-proof-case)
       (= (.ref proof-case 'required-obligation-mask)
          (.ref proof-case 'present-obligation-mask))
       (= (.ref proof-case 'obligation-count)
          (length +poo-flow-authorized-effect-obligation-layout+))
       (not (eq? (.ref proof-case 'durability) 'diagnostic))
       (memq (.ref proof-case 'outcome) '(committed denied indeterminate))
       #t))
