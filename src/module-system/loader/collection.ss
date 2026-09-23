;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: ordered POO-native module sources for maintained, contributor,
;;; and user module trees. Selection declarations remain separate POO values.

(import (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :std/list/list every filter)
        (only-in :poo-flow/src/core/funcs
                 poo-flow-directory-files-recursive
                 poo-flow-make-value-index
                 poo-flow-value-index-put!
                 poo-flow-value-index-ref)
        (only-in :poo-flow/src/module-system/loader/import-policy
                 poo-flow-module-owner-import-file-observations)
        :poo-flow/src/module-system/loader/source)

(export poo-flow-module-source-collection-prototype
        make-poo-flow-module-source-collection
        poo-flow-module-source-collection?
        poo-flow-module-source-collection-identity
        poo-flow-module-source-collection-owner
        poo-flow-module-source-collection-source-root
        poo-flow-module-source-collection-modules-directory
        poo-flow-module-source-collection-modules-root
        poo-flow-module-source-collection-locate
        poo-flow-module-style-policy-prototype
        poo-flow-default-module-style-policy
        poo-flow-module-required-role-files
        poo-flow-module-allowed-entrypoint-roles
        poo-flow-module-source-collection-validate!
        poo-flow-module-source-collection-role-entrypoints
        poo-flow-load-modules
        poo-flow-module-load-path-prototype
        make-poo-flow-module-load-path
        extend-poo-flow-module-load-path
        poo-flow-module-load-path?
        poo-flow-module-load-path-identity
        poo-flow-module-load-path-collections
        poo-flow-module-load-path-locate
        make-poo-flow-contribution-module-source
        make-poo-flow-contribution-root-module-source
        make-poo-flow-contribution-module-load-path
        make-poo-flow-user-interface-module-source
        make-poo-flow-user-interface-module-load-path
        poo-flow-maintained-module-source
        poo-flow-default-module-load-path)

(def (nonempty-string? value)
  (and (string? value) (> (string-length value) 0)))

(def (poo-flow-module-source-collection? value)
  (and (object? value)
       (.slot? value 'module-source-collection?)
       (.ref value 'module-source-collection?)
       (every (lambda (slot) (.slot? value slot))
              '(identity owner source-root modules-directory style-policy locate))
       (symbol? (.ref value 'identity))
       (symbol? (.ref value 'owner))
       (nonempty-string? (.ref value 'source-root))
       (nonempty-string? (.ref value 'modules-directory))
       (object? (.ref value 'style-policy))
       (.slot? (.ref value 'style-policy) 'validate)
       (procedure? (.ref (.ref value 'style-policy) 'validate))
       (procedure? (.ref value 'locate))))

(def (poo-flow-module-source-collection-identity collection)
  (.ref collection 'identity))

(def (poo-flow-module-source-collection-owner collection)
  (.ref collection 'owner))

(def (poo-flow-module-source-collection-source-root collection)
  (.ref collection 'source-root))

(def (poo-flow-module-source-collection-modules-directory collection)
  (.ref collection 'modules-directory))

(def (poo-flow-module-source-collection-modules-root collection)
  (let ((source-root
         (poo-flow-module-source-collection-source-root collection))
        (modules-directory
         (poo-flow-module-source-collection-modules-directory collection)))
    (if (string=? source-root ".")
      modules-directory
      (path-expand modules-directory source-root))))

(def (poo-flow-module-source-entrypoint collection module-key module-root
                                         entrypoint-role)
  (let (entrypoint
        (path-expand (string-append (symbol->string entrypoint-role) ".ss")
                     module-root))
    (make-poo-flow-module-source-ref
     'local entrypoint
     (list (cons 'kind 'module-tree)
           (cons 'module-key module-key)
           (cons 'source-collection
                 (poo-flow-module-source-collection-identity collection))
           (cons 'source-owner
                 (poo-flow-module-source-collection-owner collection))
           (cons 'module-layout 'poo-flow-module-v1)
           (cons 'required-roles poo-flow-module-required-role-files)
           (cons 'module-tree-root module-root)
           (cons 'entrypoint entrypoint)
           (cons 'entrypoint-role entrypoint-role)))))

;;; Categories stay in module identity. Current POO Flow collections use the
;;; flat <modules-root>/<module-name> repository convention.
(def (poo-flow-module-source-collection-default-locate collection module-key
                                                       entrypoint-roles)
  (let (module-name (cdr module-key))
    (if (eq? module-name
             (poo-flow-module-source-collection-identity collection))
      (poo-flow-module-source-collection-role-entrypoints
       collection 'interface)
      (let* ((module-root
              (path-expand
               (symbol->string module-name)
               (poo-flow-module-source-collection-modules-root collection)))
             (interface-path (path-expand "interface.ss" module-root)))
        (if (file-exists? interface-path)
          (map (lambda (entrypoint-role)
                 (poo-flow-module-source-entrypoint
                  collection module-key module-root entrypoint-role))
               entrypoint-roles)
          '())))))

(def (poo-flow-module-source-collection-locate collection module-key)
  ((.ref collection 'locate) collection module-key '(interface)))

;;; poo-flow-load-modules discovery is independent from User Interface enablement.
;;; Each direct modules/<module-name>/ directory contributes one conventional
;;; entrypoint; no contributor-owned init list or registry is involved.
(def poo-flow-module-required-role-files
  '("types.ss" "objects.ss" "funs.ss" "config.ss" "interface.ss"))

;;; The loader constrains stable module roles while leaving domain authors free
;;; to add focused implementation files. syntax.ss is optional and may expose
;;; thin hygienic projections; it is never required for data-only modules.
(def poo-flow-module-allowed-entrypoint-roles
  '(types objects funs config interface syntax))

;;; Style policy constrains the stable module shell and dependency direction.
;;; Domain code remains free to choose gerbil-poo Type/MOP, POO CLOS, native
;;; Gerbil methods, functional combinators, and thin hygienic syntax according
;;; to the semantics it actually needs.
(def (poo-flow-module-read-datums path)
  (call-with-input-file
   path
   (lambda (port)
     (let loop ((datums '()))
       (let (datum (read port))
         (if (eof-object? datum)
           (reverse datums)
           (loop (cons datum datums))))))))

(def (poo-flow-module-role-reference? datum module-name role)
  (let ((leaf (string-append role ".ss"))
        (relative (string-append "./" role))
        (suffix (string-append "/" module-name "/" role)))
    (cond
     ((symbol? datum)
      (let (reference (symbol->string datum))
        (or (string=? reference relative)
            (string-suffix? suffix reference))))
     ((string? datum)
      (or (string=? datum leaf) (string-suffix? suffix datum)))
     ((pair? datum)
      (or (poo-flow-module-role-reference? (car datum) module-name role)
          (poo-flow-module-role-reference? (cdr datum) module-name role)))
     ((vector? datum)
      (poo-flow-module-role-reference? (vector->list datum) module-name role))
     (else #f))))

(def (poo-flow-module-top-form-references-role? datums head module-name role)
  (let loop ((rest datums))
    (and (pair? rest)
         (let (form (car rest))
           (or (and (pair? form) (eq? (car form) head)
                    (poo-flow-module-role-reference?
                     (cdr form) module-name role))
               (loop (cdr rest)))))))

(def (poo-flow-module-interface-validate! module-name module-root)
  (let* ((interface-path (path-expand "interface.ss" module-root))
         (datums (poo-flow-module-read-datums interface-path))
         (public-roles
          (append '(types objects funs config)
                  (if (file-exists? (path-expand "syntax.ss" module-root))
                    '(syntax)
                    '()))))
    (for-each
     (lambda (role)
       (unless (and (poo-flow-module-top-form-references-role?
                     datums 'import module-name (symbol->string role))
                    (poo-flow-module-top-form-references-role?
                     datums 'export module-name (symbol->string role)))
         (error "POO-FLOW-MODULE-E006 interface must import and re-export role"
                module-name role)))
     public-roles)))

(def (poo-flow-module-dependency-direction-validate! module-name module-root)
  (let ((layers '((types objects funs syntax config interface)
                  (objects funs syntax config interface)
                  (funs config interface)
                  (syntax config interface)
                  (config interface))))
    (for-each
     (lambda (layer)
       (let* ((source-role (car layer))
              (path (path-expand
                     (string-append (symbol->string source-role) ".ss")
                     module-root)))
         (when (file-exists? path)
           (let (datums (poo-flow-module-read-datums path))
             (for-each
              (lambda (forbidden-role)
                (when (poo-flow-module-top-form-references-role?
                       datums 'import module-name
                       (symbol->string forbidden-role))
                  (error "POO-FLOW-MODULE-E007 reversed module role dependency"
                         module-name source-role forbidden-role)))
              (cdr layer))))))
     layers)))

(def (poo-flow-module-owner-imports-validate! module-name module-root)
  (for-each
   (lambda (path)
     (let (observations
           (poo-flow-module-owner-import-file-observations
            (string->symbol path) path))
       (when (pair? observations)
         (error "POO-FLOW-MODULE-E008 module owner imports aggregate facade"
                module-name path (car observations)))))
   (filter (lambda (path) (string-suffix? ".ss" path))
           (poo-flow-directory-files-recursive module-root))))

(def (poo-flow-module-default-style-validate! _collection module-name module-root)
  (when (file-exists? (path-expand "init.ss" module-root))
    (error "POO-FLOW-MODULE-E005 init.ss belongs to the User Interface root"
           module-name))
  (poo-flow-module-interface-validate! module-name module-root)
  (poo-flow-module-dependency-direction-validate! module-name module-root)
  (poo-flow-module-owner-imports-validate! module-name module-root)
  module-root)

(def poo-flow-module-style-policy-prototype
  (.o (module-style-policy? #t)
      (validate poo-flow-module-default-style-validate!)))

(def poo-flow-default-module-style-policy
  (.o (:: @ poo-flow-module-style-policy-prototype)))

(def poo-flow-module-source-collection-prototype
  (.o (module-source-collection? #t)
      (style-policy poo-flow-default-module-style-policy)
      (locate poo-flow-module-source-collection-default-locate)))

(def (poo-flow-module-source-collection-directory-names collection)
  (let (modules-root
        (poo-flow-module-source-collection-modules-root collection))
    (if (file-exists? modules-root)
      (let (module-names
          (filter
           (lambda (name)
             (eq? (file-info-type
                   (file-info (path-expand name modules-root)))
                  'directory))
           (list-sort string<? (directory-files modules-root))))
        module-names)
      '())))

(def (poo-flow-module-source-collection-validate-directory-names!
      collection module-names)
  (let (modules-root
        (poo-flow-module-source-collection-modules-root collection))
    (for-each
     (lambda (module-name)
       (let* ((module-root (path-expand module-name modules-root))
              (missing
               (filter
                (lambda (role)
                  (not (file-exists? (path-expand role module-root))))
                poo-flow-module-required-role-files)))
         (unless (null? missing)
           (error "POO-FLOW-MODULE-E001 module is missing required roles"
                  module-name missing))
         ((.ref (.ref collection 'style-policy) 'validate)
          collection module-name module-root)))
     module-names))
  collection)

(def (poo-flow-module-entrypoint-role-valid! entrypoint-role)
  (unless (memq entrypoint-role poo-flow-module-allowed-entrypoint-roles)
    (error "POO-FLOW-MODULE-E002 unsupported module entrypoint role"
           entrypoint-role poo-flow-module-allowed-entrypoint-roles))
  entrypoint-role)

(def (poo-flow-module-source-collection-validate! collection)
  (poo-flow-module-source-collection-validate-directory-names!
   collection
   (poo-flow-module-source-collection-directory-names collection)))

(def (poo-flow-module-source-collection-role-entrypoints collection
                                                         entrypoint-role)
  (unless (poo-flow-module-source-collection? collection)
    (error "POO-FLOW-MODULE-E003 invalid module source collection" collection))
  (poo-flow-module-entrypoint-role-valid! entrypoint-role)
  (let* ((modules-root
          (poo-flow-module-source-collection-modules-root collection))
         (module-names
          (poo-flow-module-source-collection-directory-names collection)))
    (poo-flow-module-source-collection-validate-directory-names!
     collection module-names)
    (map
     (lambda (name)
       (let* ((module-root (path-expand name modules-root))
              (entrypoint
               (path-expand (string-append (symbol->string entrypoint-role) ".ss")
                            module-root)))
         (unless (file-exists? entrypoint)
           (error "POO-FLOW-MODULE-E004 requested optional role is absent"
                  name entrypoint-role))
         (poo-flow-module-source-entrypoint
          collection
          (cons 'custom (string->symbol name))
          module-root
          entrypoint-role)))
     module-names)))

;;; A module collection has one public entrypoint. The hygienic form accepts
;;; exactly one collection expression and lowers to the POO source projection;
;;; callers cannot turn public loading into a role or build-topology selector.
(defrules poo-flow-load-modules ()
  ((_ collection)
   (poo-flow-module-source-collection-role-entrypoints
    collection 'interface)))

(def (make-poo-flow-module-source-collection identity-value owner-value
                                              source-root-value
                                              modules-directory-value)
  (let (collection
        (.o (:: @ poo-flow-module-source-collection-prototype)
            (identity identity-value)
            (owner owner-value)
            (source-root source-root-value)
            (modules-directory modules-directory-value)))
    (unless (poo-flow-module-source-collection? collection)
      (error "invalid POO Flow module source collection" collection))
    collection))

(def poo-flow-module-load-path-prototype
  (.o (module-load-path? #t)))

(def (poo-flow-module-load-path? value)
  (and (object? value)
       (.slot? value 'module-load-path?)
       (.ref value 'module-load-path?)
       (.slot? value 'identity)
       (symbol? (.ref value 'identity))
       (.slot? value 'collections)
       (list? (.ref value 'collections))
       (every poo-flow-module-source-collection?
              (.ref value 'collections))))

(def (poo-flow-module-load-path-identity load-path)
  (.ref load-path 'identity))

(def (poo-flow-module-load-path-collections load-path)
  (.ref load-path 'collections))

(def (poo-flow-module-load-path-valid! load-path)
  (unless (poo-flow-module-load-path? load-path)
    (error "invalid POO Flow module load path" load-path))
  ;; Source counts can be large for user and organization overlays. Keep
  ;; duplicate admission linear through the shared core hash index.
  (let ((seen (poo-flow-make-value-index))
        (identities
         (map poo-flow-module-source-collection-identity
              (poo-flow-module-load-path-collections load-path))))
    (for-each
     (lambda (identity)
       (call-with-values
        (lambda () (poo-flow-value-index-ref seen identity))
        (lambda (present? _)
          (when present?
            (error "duplicate POO Flow module source collection" identities))
          (poo-flow-value-index-put! seen identity #t))))
     identities))
  load-path)

(def (make-poo-flow-module-load-path identity-value collections-value)
  (poo-flow-module-load-path-valid!
   (.o (:: @ poo-flow-module-load-path-prototype)
       (identity identity-value)
       (collections collections-value))))

;;; Appended collections have lower priority. User collections can be placed
;;; first when constructing a load path, matching Doom's override rule without
;;; mutable global load-path state.
(def (extend-poo-flow-module-load-path base identity-value collections-value)
  (unless (poo-flow-module-load-path? base)
    (error "module load path extension requires a valid base" base))
  (poo-flow-module-load-path-valid!
   (.o (:: @ base)
       (identity identity-value)
       (collections
        (append (poo-flow-module-load-path-collections base)
                collections-value)))))

;;; First matching source wins; selection syntax is source-neutral.
(def (poo-flow-module-load-path-locate load-path module-key)
  (let loop ((collections
              (poo-flow-module-load-path-collections load-path)))
    (if (null? collections)
      '()
      (let (source-refs
           (poo-flow-module-source-collection-locate
             (car collections) module-key))
        (if (pair? source-refs)
          source-refs
          (loop (cdr collections)))))))

(def poo-flow-maintained-module-source
  (make-poo-flow-module-source-collection
   'poo-flow-maintained 'poo-flow "." "src/modules"))

;;; Repository-specific source paths are inputs to this core-owned loader
;;; policy; contributor repositories do not publish their own source objects.
(def (make-poo-flow-contribution-module-source identity-value source-root-value)
  (make-poo-flow-module-source-collection
   identity-value 'contributor source-root-value "modules"))

;;; A contribution root is an on-demand projection over checked-out package
;;; directories.  The selected module identity chooses packages/<identity>;
;;; no contributor name, URL, or revision is registered in Scheme.
(def (poo-flow-contribution-root-locate collection module-key entrypoint-roles)
  (let* ((identity (cdr module-key))
         (source-root
          (path-expand
           (symbol->string identity)
           (poo-flow-module-source-collection-source-root collection)))
         (contribution
          (make-poo-flow-contribution-module-source identity source-root)))
    (if (file-exists?
         (poo-flow-module-source-collection-modules-root contribution))
      ;; std/list/list append-map reverses each produced list.  Entrypoint order
      ;; is part of the loader contract, so flatten the bounded role projection
      ;; with native map/apply/append and preserve both role and module order.
      (apply append
             (map (lambda (entrypoint-role)
                    (poo-flow-module-source-collection-role-entrypoints
                     contribution entrypoint-role))
                  entrypoint-roles))
      '())))

(def (make-poo-flow-contribution-root-module-source identity-value
                                                     source-root-value)
  (.o (:: @ poo-flow-module-source-collection-prototype)
      (identity identity-value)
      (owner 'contributor)
      (source-root source-root-value)
      (modules-directory ".")
      (locate poo-flow-contribution-root-locate)))

(def (make-poo-flow-contribution-module-load-path identity-value
                                                  source-root-value)
  (extend-poo-flow-module-load-path
   poo-flow-default-module-load-path
   identity-value
   (list
    (make-poo-flow-contribution-module-source
     identity-value source-root-value))))

(def (make-poo-flow-user-interface-module-source identity-value
                                                  user-interface-root-value)
  (make-poo-flow-module-source-collection
   identity-value 'user user-interface-root-value "modules"))

(def (make-poo-flow-user-interface-module-load-path identity-value
                                                     user-interface-root-value
                                                     base-load-path)
  (make-poo-flow-module-load-path
   identity-value
   (cons
    (make-poo-flow-user-interface-module-source
     identity-value user-interface-root-value)
    (poo-flow-module-load-path-collections base-load-path))))

(def poo-flow-default-module-load-path
  (make-poo-flow-module-load-path
   'poo-flow-default
   (list poo-flow-maintained-module-source)))
