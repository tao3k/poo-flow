;;; -*- Gerbil -*-
(import (only-in :std/test test-suite test-case check-equal? check-exception)
        (only-in :clan/poo/object .o .cc .ref .all-slots)
        (only-in :clan/poo/mop element? validate TypeError?)
        "../src/module-system/semantic-module/objects.ss")
(export semantic-module-test)
(def semantic-module-test
  (test-suite "four-slot native Module"
    (test-case "construction has four semantic responsibilities and fresh empties"
      (let* ((identity (poo-flow-semantic-identity 'test 'module))
             (a (poo-flow-semantic-module identity))
             (b (poo-flow-semantic-module identity)))
        (check-equal? (element? SemanticModuleContract a) #t)
        (check-equal? (length (.all-slots a)) 4)
        (check-equal? (eq? (.ref a 'identity) identity) #t)
        (check-equal? (eq? (.ref a 'imports) (.ref b 'imports)) #f)
        (check-equal? (eq? (.ref a 'profiles) (.ref b 'profiles)) #f)
        (check-equal? (element? ModuleImportsContract (.ref a 'profiles)) #f)
        (check-equal? (element? SemanticModuleContract
                              (.o identity: identity imports: (.ref a 'imports)
                                  capabilities: (.ref a 'capabilities) profiles: (.ref a 'profiles))) #f)
        (check-exception (validate SemanticModuleContract (.cc a 'identity 'raw-symbol)) TypeError?)
        (check-exception (validate SemanticModuleContract (.cc a 'imports '())) TypeError?)))
    (test-case "construction does not force import targets or contributions"
      (let* ((imports (poo-flow-empty-imports))
             (lazy-imports (.o (:: @ SemanticImports.)
                              (contributions (error "construction forced imports"))))
             (module (poo-flow-semantic-module
                      (poo-flow-semantic-identity 'test 'lazy) imports: lazy-imports)))
        (check-equal? (element? SemanticModuleContract module) #t)
        (check-equal? (element? ModuleImportsContract imports) #t)))))
