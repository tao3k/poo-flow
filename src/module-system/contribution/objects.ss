;;; Pure contributor admission. No domain registry, discovery, or activation.
(import (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :std/srfi/1 every append-map delete-duplicates))
(export contribution-contract-id Contribution. make-contribution
        contribution? contribution-diagnostics admit-contributions)

(def contribution-contract-id 'poo-flow.contribution.v1)
(def Contribution. (.o kind: 'poo-flow.contribution))

(def (nonempty-string? value)
  (and (string? value) (> (string-length value) 0)))

(def (contribution? value)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot))
              '(kind identity revision owner core-contract facets requires profile))
       (eq? (.ref value 'kind) 'poo-flow.contribution)
       (every (lambda (slot) (nonempty-string? (.ref value slot)))
              '(identity revision owner))
       (symbol? (.ref value 'core-contract))
       (list? (.ref value 'facets))
       (pair? (.ref value 'facets))
       (every symbol? (.ref value 'facets))
       (list? (.ref value 'requires))
       (every symbol? (.ref value 'requires))
       (object? (.ref value 'profile))))

(def (make-contribution identity-value revision-value owner-value
                        profile-value facets-value requirements-value)
  (let ((result (.o (:: @ Contribution.)
                   identity: identity-value revision: revision-value
                   owner: owner-value core-contract: contribution-contract-id
                   facets: facets-value requires: requirements-value
                   profile: profile-value)))
    (unless (contribution? result) (error "invalid contribution" identity-value))
    result))

(def (contribution-diagnostics value capabilities)
  (cond
   ((not (contribution? value)) '(invalid-contribution))
   ((not (eq? (.ref value 'core-contract) contribution-contract-id))
    '(incompatible-core-contract))
   (else
    (map (lambda (requirement)
           (.o reason: 'missing-capability
               contribution: (.ref value 'identity)
               capability: requirement))
         (filter (lambda (requirement) (not (memq requirement capabilities)))
                 (.ref value 'requires))))))

(def (admit-contributions values capabilities)
  (unless (and (list? values) (list? capabilities) (every symbol? capabilities))
    (error "admission expects contribution and capability lists"))
  (let* ((valid-values (filter contribution? values))
         (identities (map (lambda (value) (.ref value 'identity)) valid-values))
         (duplicate? (not (= (length identities)
                            (length (delete-duplicates identities)))))
         (reasons-value
          (append (if duplicate? '(duplicate-contribution-export) '())
                  (append-map (lambda (value)
                                (contribution-diagnostics value capabilities))
                              values)))
         (accepted-value (null? reasons-value)))
    (.o kind: 'poo-flow.contribution-admission
        core-contract: contribution-contract-id
        accepted?: accepted-value reasons: reasons-value
        selected: (if accepted-value values '())
        runtime-executed?: #f)))
