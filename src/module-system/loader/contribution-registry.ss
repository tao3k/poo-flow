;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: POO Flow-owned trusted contribution registry.
;;; Invariant: init declarations stay pure; missing checkouts become registry
;;; source refs for an explicit package/runtime materialization boundary.

(import (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :std/list/list every)
        (only-in :poo-flow/src/core/funcs
                 poo-flow-make-value-index
                 poo-flow-value-index-put!
                 poo-flow-value-index-ref)
        :poo-flow/src/module-system/loader/source
        :poo-flow/src/module-system/loader/collection)

(export poo-flow-contribution-registry-entry-prototype
        make-poo-flow-contribution-registry-entry
        poo-flow-contribution-registry-entry?
        poo-flow-contribution-registry-entry-name
        poo-flow-contribution-registry-entry-repository
        poo-flow-contribution-registry-entry-revision
        poo-flow-contribution-registry-entry-checkout-root
        poo-flow-contribution-registry-entry-modules-directory
        poo-flow-contribution-registry-entry-module-names
        poo-flow-contribution-registry-prototype
        make-poo-flow-contribution-registry
        poo-flow-contribution-registry?
        poo-flow-contribution-registry-entries
        poo-flow-contribution-registry-ref
        poo-flow-contribution-registry-ref-module
        poo-flow-contribution-registry-collection
        poo-flow-contribution-registry-load-path
        poo-flow-official-contribution-registry
        poo-flow-official-contribution-load-path)

(def poo-flow-contribution-registry-entry-prototype
  (.o (contribution-registry-entry? #t)))

(def (poo-flow-contribution-registry-entry? value)
  (and (object? value)
       (.slot? value 'contribution-registry-entry?)
       (.ref value 'contribution-registry-entry?)
       (every (lambda (slot) (.slot? value slot))
              '(name repository revision checkout-root modules-directory
                     module-names))))

(def (make-poo-flow-contribution-registry-entry
      name-value repository-value revision-value checkout-root-value
      modules-directory-value module-names-value)
  (unless (and (symbol? name-value)
               (string? repository-value)
               (string? revision-value)
               (string? checkout-root-value)
               (string? modules-directory-value)
               (list? module-names-value)
               (every symbol? module-names-value))
    (error "invalid POO Flow contribution registry entry" name-value))
  (.o (:: @ poo-flow-contribution-registry-entry-prototype)
      (name name-value)
      (repository repository-value)
      (revision revision-value)
      (checkout-root checkout-root-value)
      (modules-directory modules-directory-value)
      (module-names module-names-value)))

(def (poo-flow-contribution-registry-entry-name entry) (.ref entry 'name))
(def (poo-flow-contribution-registry-entry-repository entry) (.ref entry 'repository))
(def (poo-flow-contribution-registry-entry-revision entry) (.ref entry 'revision))
(def (poo-flow-contribution-registry-entry-checkout-root entry) (.ref entry 'checkout-root))
(def (poo-flow-contribution-registry-entry-modules-directory entry) (.ref entry 'modules-directory))
(def (poo-flow-contribution-registry-entry-module-names entry) (.ref entry 'module-names))

(def poo-flow-contribution-registry-prototype
  (.o (contribution-registry? #t)))

(def (poo-flow-contribution-registry? value)
  (and (object? value)
       (.slot? value 'contribution-registry?)
       (.ref value 'contribution-registry?)
       (.slot? value 'entries)
       (.slot? value 'ref-name)
       (.slot? value 'ref-module)
       (procedure? (.ref value 'ref-name))
       (procedure? (.ref value 'ref-module))))

(def (poo-flow-contribution-registry-index! index key entry kind)
  (call-with-values
   (lambda () (poo-flow-value-index-ref index key))
   (lambda (present? _)
     (when present?
       (error "duplicate POO Flow registered contribution key" kind key))
     (poo-flow-value-index-put! index key entry))))

(def (make-poo-flow-contribution-registry entries-value)
  (unless (and (list? entries-value)
               (every poo-flow-contribution-registry-entry? entries-value))
    (error "invalid POO Flow contribution registry entries" entries-value))
  (let ((by-name (poo-flow-make-value-index))
        (by-module (poo-flow-make-value-index)))
    (for-each
     (lambda (entry)
       (poo-flow-contribution-registry-index!
        by-name (poo-flow-contribution-registry-entry-name entry) entry 'name)
       (for-each
        (lambda (module-name)
          (poo-flow-contribution-registry-index!
           by-module module-name entry 'module))
        (poo-flow-contribution-registry-entry-module-names entry)))
     entries-value)
    (.o (:: @ poo-flow-contribution-registry-prototype)
        (entries entries-value)
        ;; Hash tables are private implementation state behind methods. Keeping
        ;; them out of public POO slots prevents object reflection/composition
        ;; from traversing a large mutable index.
        (ref-name
         (lambda (key)
           (call-with-values
            (lambda () (poo-flow-value-index-ref by-name key))
            (lambda (present? value) (and present? value)))))
        (ref-module
         (lambda (key)
           (call-with-values
            (lambda () (poo-flow-value-index-ref by-module key))
            (lambda (present? value) (and present? value))))))))

(def (poo-flow-contribution-registry-entries registry) (.ref registry 'entries))

(def (poo-flow-contribution-registry-index-ref registry slot key)
  ((.ref registry slot) key))

(def (poo-flow-contribution-registry-ref registry name)
  (poo-flow-contribution-registry-index-ref registry 'ref-name name))

(def (poo-flow-contribution-registry-ref-module registry module-name)
  (poo-flow-contribution-registry-index-ref registry 'ref-module module-name))

(def (poo-flow-contribution-entry-source entry)
  (make-poo-flow-module-source-collection
   (poo-flow-contribution-registry-entry-name entry)
   'contributor
   (poo-flow-contribution-registry-entry-checkout-root entry)
   (poo-flow-contribution-registry-entry-modules-directory entry)))

(def (poo-flow-contribution-registry-remote-source entry requested-name)
  (make-poo-flow-module-source-ref
   'registry requested-name
   (list
    (cons 'registry 'poo-flow-official)
    (cons 'contribution
          (poo-flow-contribution-registry-entry-name entry))
    (cons 'repository
          (poo-flow-contribution-registry-entry-repository entry))
    (cons 'revision
          (poo-flow-contribution-registry-entry-revision entry))
    (cons 'checkout-root
          (poo-flow-contribution-registry-entry-checkout-root entry))
    (cons 'modules-directory
          (poo-flow-contribution-registry-entry-modules-directory entry))
    (cons 'materialization 'required))))

(def (poo-flow-contribution-registry-locate registry _collection module-key roles)
  (let* ((requested-name (cdr module-key))
         (by-name (poo-flow-contribution-registry-ref registry requested-name))
         (entry (or by-name
                    (poo-flow-contribution-registry-ref-module
                     registry requested-name))))
    (if (not entry)
      '()
      (let* ((source (poo-flow-contribution-entry-source entry))
             (modules-root
              (poo-flow-module-source-collection-modules-root source)))
        (if (file-exists? modules-root)
          (if by-name
            (poo-flow-load-modules source)
            (poo-flow-module-source-collection-locate
             source module-key))
          (list
           (poo-flow-contribution-registry-remote-source
            entry requested-name)))))))

(def (poo-flow-contribution-registry-collection registry)
  (.o (:: @ poo-flow-module-source-collection-prototype)
      (identity 'poo-flow-official-registry)
      (owner 'registry)
      (source-root ".")
      (modules-directory ".")
      (locate
       (lambda (collection module-key roles)
         (poo-flow-contribution-registry-locate
          registry collection module-key roles)))))

(def (poo-flow-contribution-registry-load-path registry)
  (extend-poo-flow-module-load-path
   poo-flow-default-module-load-path
   'poo-flow-with-official-contributions
   (list (poo-flow-contribution-registry-collection registry))))

;;; This list is reviewed and maintained by POO Flow. The git revision is the
;;; same immutable commit pinned by the repository submodule.
(def poo-flow-official-contribution-registry
  (make-poo-flow-contribution-registry
   (list
    (make-poo-flow-contribution-registry-entry
     'lambda-episteme
     "https://github.com/tao3k/lambda-episteme.git"
     "70f9075ca9c42b70777ae738341391464008bcbe"
     "packages/lambda-episteme"
     "modules"
     '(decision-kind diataxis healthcare ontology))
    (make-poo-flow-contribution-registry-entry
     'lambda-aitia
     "https://github.com/tao3k/lambda-aitia.git"
     "0216ceb14b621f440ab89a2d01edea30aa57c4c0"
     "packages/lambda-aitia"
     "modules"
     '(ADR assurance gitops sdlc)))))

(def poo-flow-official-contribution-load-path
  (poo-flow-contribution-registry-load-path
   poo-flow-official-contribution-registry))
