;;; -*- Gerbil -*-
;;; Boundary: module source refs and structured import values.
;;; Invariant: imports describe source refs or inline profiles.
;;; They never load files, query registries, or evaluate modules.
;;; Intent: callers can inspect provenance and profile payloads before any loader exists.
;;; Ownership: source/import shapes are parser-visible facts consumed by descriptors and catalogs.
;;; Descriptors may inspect the profile slot to expand inline modules.
;;; Catalogs may compare source refs by kind/value for deterministic lookup.
;;; Future loader backends must consume these values from outside this owner.
;;; Agents should treat this file as the source/import shape authority.
;;; No function here may read a path, query a registry, or evaluate a profile.

(import (only-in :clan/poo/object .o .ref object?)
        :modules/interface)

(export make-poo-module-source-ref
        poo-module-source-ref?
        poo-module-source-ref-kind
        poo-module-source-ref-value
        poo-module-source-ref-metadata
        make-poo-module-local-source
        make-poo-module-package-source
        make-poo-module-registry-source
        make-poo-module-generated-source
        poo-module-source-ref=?
        poo-module-source-ref->alist
        poo-local-source
        poo-source-ref
        poo-module-import-source-ref?
        poo-module-import-local-source?
        poo-module-import-normalize-source
        poo-import
        poo-imports
        poo-imports-append
        poo-extensions
        poo-extensions-append
        poo-import?)

;;; Boundary: source refs are metadata only and shared by catalog/import code.
;;; Intent: keep loader provenance comparable without granting this layer IO authority.
;; PooModuleSourceRef <- Symbol Value Alist
(defstruct poo-module-source-ref
  (kind
   value
   metadata)
  transparent: #t)

;;; Boundary: local sources are path metadata, not file reads.
;; PooModuleSourceRef <- Path
(def (make-poo-module-local-source path)
  (make-poo-module-source-ref 'local path '()))

;;; Boundary: package sources are symbolic references for future loaders.
;; PooModuleSourceRef <- Symbol
(def (make-poo-module-package-source package-name)
  (make-poo-module-source-ref 'package package-name '()))

;;; Boundary: registry sources name catalogs without querying them.
;; PooModuleSourceRef <- Symbol
(def (make-poo-module-registry-source registry-name)
  (make-poo-module-source-ref 'registry registry-name '()))

;;; Boundary: generated sources are provenance tags for constructed modules.
;; PooModuleSourceRef <- Symbol
(def (make-poo-module-generated-source module-name)
  (make-poo-module-source-ref 'generated module-name '()))

;;; Boundary: source equality ignores metadata and compares resolver identity.
;; Boolean <- PooModuleSourceRef PooModuleSourceRef
(def (poo-module-source-ref=? left right)
  (and (eq? (poo-module-source-ref-kind left)
            (poo-module-source-ref-kind right))
       (equal? (poo-module-source-ref-value left)
               (poo-module-source-ref-value right))))

;;; Boundary: source refs project to alists only at inspection boundaries.
;; Alist <- PooModuleSourceRef
(def (poo-module-source-ref->alist source-ref)
  (list (cons 'kind (poo-module-source-ref-kind source-ref))
        (cons 'value (poo-module-source-ref-value source-ref))
        (cons 'metadata (poo-module-source-ref-metadata source-ref))))

;;; Boundary: import-local sources are catalog-compatible source refs.
;; PooModuleSourceRef <- Path
(def (poo-local-source source-path)
  (make-poo-module-source-ref 'local source-path
                              (list (cons 'kind poo-module-import-local-source-kind))))

;;; Boundary: arbitrary source values are wrapped without interpretation.
;; PooModuleSourceRef <- SourceRefInput
(def (poo-source-ref source-value)
  (cond
   ((poo-module-source-ref? source-value) source-value)
   (else
    (make-poo-module-source-ref 'source source-value
                                (list (cons 'kind poo-module-import-source-ref-kind))))))

;; Boolean <- SourceRefInput
(def (poo-module-import-source-ref? value)
  (poo-module-source-ref? value))

;; Boolean <- SourceRefInput
(def (poo-module-import-local-source? value)
  (and (poo-module-source-ref? value)
       (eq? (poo-module-source-ref-kind value) 'local)))

;; PooModuleSourceRef <- SourceRefInput
(def (poo-module-import-normalize-source source-value)
  (cond
   ((string? source-value)
    (poo-local-source source-value))
   ((poo-module-import-source-ref? source-value)
    source-value)
   (else
    (poo-source-ref source-value))))

;;; Boundary: import values keep source identity separate from profile payloads.
;;; Intent: a source/profile pair can be resolved or projected without parsing a file path.
;; PooImport <- MaybePooModuleSourceRef ModuleImportProfile
(def (make-poo-import source-ref-value profile-value)
  (.o kind: poo-module-import-kind
      source-ref: source-ref-value
      profile: profile-value))

;;; Boundary: one-arg import is profile-only, two-arg import binds source+profile.
;; PooImport <- ModuleImportArg...
(def (poo-import . import-values)
  (cond
   ;; Profile-only imports are already in-memory module/profile values.
   ((= (length import-values) 1)
    (make-poo-import #f (car import-values)))
   ;; Source/profile imports preserve source identity without invoking a loader.
   ((= (length import-values) 2)
    (make-poo-import
     (poo-module-import-normalize-source (car import-values))
     (cadr import-values)))
   (else
    (error "poo-import expects profile or source/profile"))))

;;; Boundary: import lists preserve caller order for closure expansion.
;; [PooImport] <- Value...
(def (poo-imports . import-values)
  import-values)

;;; Boundary: inherited imports are prepended before direct imports.
;; [PooImport] <- [PooImport] [PooImport]
(def (poo-imports-append inherited-imports direct-imports)
  (append inherited-imports direct-imports))

;;; Boundary: extensions stay first-class values until projection.
;; [ModuleExtension] <- ModuleExtension...
(def (poo-extensions . extension-values)
  extension-values)

;;; Boundary: inherited extensions are prepended before direct extensions.
;; [ModuleExtension] <- [ModuleExtension] [ModuleExtension]
(def (poo-extensions-append inherited-extensions direct-extensions)
  (append inherited-extensions direct-extensions))

;; Boolean <- ModuleImportCandidate
(def (poo-import? value)
  (and (object? value)
       (poo-module-object-has-slot? value 'kind)
       (poo-module-kind=? (.ref value 'kind) poo-module-import-kind)))
