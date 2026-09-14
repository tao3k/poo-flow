;;; -*- Gerbil -*-
(import :std/test
        (only-in "../src/module-system/poo-clos/funcs.ss"
                 poo-clos-initarg-list? poo-clos-initarg-ref
                 poo-clos-initarg-index poo-clos-initarg-index-first-of
                 poo-clos-identity-index poo-clos-leftmost-index-by
                 poo-clos-first-invalid-initarg
                 poo-clos-position-index/identity
                 poo-clos-natural-permutation?
                 poo-clos-topological-order/identity))

(export poo-clos-funcs-test)

(def poo-clos-funcs-test
  (test-suite "POO CLOS linear algorithm functions"
    (test-case "plist traversal preserves presence and leftmost values"
      (check (poo-clos-initarg-list? '(alpha 1 beta #f alpha 2)) => #t)
      (check (poo-clos-initarg-list? '(alpha 1 beta)) => #f)
      (check (call-with-values
              (lambda () (poo-clos-initarg-ref '(alpha #f alpha 2) 'alpha))
              cons)
             => '(#t . #f)))
    (test-case "ordered indexes select call order across aliases"
      (let (index (poo-clos-initarg-index '(second 2 first 1 second 9)))
        (check (call-with-values
                (lambda ()
                  (poo-clos-initarg-index-first-of index '(first second)))
                cons)
               => '(#t . 2))))
    (test-case "identity indexes support one-pass invalid-key admission"
      (let (valid (poo-clos-identity-index '(alpha beta)))
        (check (poo-clos-first-invalid-initarg
                '(alpha 1 allow-other-keys #t gamma 3)
                valid (lambda (name) (eq? name 'allow-other-keys)))
               => 'gamma)))
    (test-case "object indexes retain the first declaration"
      (let* ((first '(payload first))
             (second '(payload second))
             (index
              (poo-clos-leftmost-index-by car (list first second))))
        (check (hash-get index 'payload) => first)))
    (test-case "identity topology indexes edges once and delegates ambiguity"
      (let ((a (cons 'a '())) (b (cons 'b '()))
            (c (cons 'c '())) (d (cons 'd '())))
        (check
         (poo-clos-topological-order/identity
          (list a b c d)
          (list (cons a b) (cons a c) (cons b d) (cons c d))
          (lambda (candidate? _result) (if (candidate? b) b #f)))
         => (list a b c d))
        (check
         (poo-clos-topological-order/identity
          (list a b) (list (cons a b) (cons b a))
         (lambda (_candidate? _result) #f))
         => #f)))
    (test-case "positions and natural permutations use bounded native indexes"
      (let* ((a (cons 'a '())) (b (cons 'b '()))
             (positions (poo-clos-position-index/identity (list a b))))
        (check (hash-get positions a) => 0)
        (check (hash-get positions b) => 1)
        (check (poo-clos-natural-permutation? '(2 0 1) 3) => #t)
        (check (poo-clos-natural-permutation? '(2 0 2) 3) => #f)
        (check (poo-clos-natural-permutation? '(3 0 1) 3) => #f)))))
