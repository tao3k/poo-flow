(import :clan/poo/object :std/test
        :gslph/src/testing/memory-profile
        :poo-flow/src/semantic/organization-bundle)

(declare-gxtest-memory-exception '((maxHeapMiB . 512)))

(def (five-facet-bundle . overrides)
  (let* ((bad-protocol? (memq 'bad-protocol overrides))
         (bad-evidence? (memq 'bad-evidence overrides))
         (conflict? (memq 'conflict overrides))
         (organization
          (poo-flow-organization-organization-facet
           (list (poo-flow-organization-principal 'pp)
                 (poo-flow-organization-principal 'pc)
                 (poo-flow-organization-role 'rp)
                 (poo-flow-organization-role 'rc)
                 (poo-flow-organization-agent 'parent 'pp 'rp #f
                                              '(write search) '(public private))
                 (poo-flow-organization-agent 'child 'pc 'rc 'parent
                                              '(search) '(public)))))
         (authority
          (poo-flow-organization-authority-facet
           (list (poo-flow-organization-capability
                  (if conflict? 'child 'write) #t)
                 (poo-flow-organization-capability 'search #t))
           (list (poo-flow-organization-delegation
                  'parent 'child 'search))))
         (context
          (poo-flow-organization-context-facet
           (list (poo-flow-organization-context-projection
                  'child '(public)))))
         (protocol
          (poo-flow-organization-protocol-facet
           (list (poo-flow-organization-tool-effect
                  'tool 'search 'external-tool)
                 (poo-flow-organization-protocol-transition
                  'run (if bad-protocol? '(ghost) '(parent child)) 'search))
           '()))
         (evidence
          (poo-flow-organization-evidence-facet
           (list (poo-flow-organization-evidence-obligation
                  'audit 'child 'transition
                  (if bad-evidence? 'missing 'run)))
           '())))
    (poo-flow-organization-bundle 9 organization authority context protocol evidence)))

(def (codes receipt)
  (map (lambda (entry) (cdr (assq 'code entry)))
       (poo-flow-organization-validation-diagnostics receipt)))

(def five-facet-tests
  (test-suite
   "five typed organization facets"
   (test-case "five facets validate and normalize deterministically"
     (let* ((bundle (five-facet-bundle))
            (receipt (poo-flow-organization-bundle-validate bundle))
            (canonical (poo-flow-organization-bundle-normalize bundle)))
       (check-equal? (poo-flow-organization-validation-accepted? receipt) #t)
       (check-equal? (map car (cddr canonical))
                     '(organization authority context protocol evidence outcomes))))
   (test-case "protocol participants resolve through organization facet"
     (check-equal? (not (not (member 'missing-protocol-participant
                                     (codes (poo-flow-organization-bundle-validate
                                             (five-facet-bundle 'bad-protocol)))))) #t))
   (test-case "evidence target resolves through protocol facet"
     (check-equal? (not (not (member 'missing-evidence-target
                                     (codes (poo-flow-organization-bundle-validate
                                             (five-facet-bundle 'bad-evidence)))))) #t))
   (test-case "incompatible shared identity fails closed"
     (check-equal? (not (not (member 'incompatible-shared-identity
                                     (codes (poo-flow-organization-bundle-validate
                                             (five-facet-bundle 'conflict)))))) #t))
   (test-case "missing facet fails closed"
     (let* ((base (five-facet-bundle))
            (invalid (poo-flow-organization-bundle
                      9 (.ref base 'organization) (.ref base 'authority)
                      (.ref base 'context) (.ref base 'protocol) #f)))
       (check-equal? (poo-flow-organization-validation-accepted?
                      (poo-flow-organization-bundle-validate invalid)) #f)))))

(run-tests! five-facet-tests)
