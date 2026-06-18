;;; -*- Gerbil -*-
;;; Boundary: user-facing module doctor presentations.
;;; Invariant: doctor presentation explains data and never activates runtime execution.
;;; Intent: borrow Doom's doctor ergonomics while keeping Nix-style receipts explicit.
;;; Parser policy should treat this file as the module-system doctor surface owner.

(import (only-in :clan/poo/object .o .ref)
        :modules/source
        :modules/descriptor
        :modules/diagnostics
        :modules/projection
        :modules/loader
        :modules/merge)

(export poo-module-doctor-presentation-kind
        poo-module-source-doctor-presentation-kind
        pooModuleDoctorPresentation
        pooModuleSourceDoctorPresentation)

;;; Boundary: value-catalog doctor kind identifies summaries over in-memory modules.
;; ModuleKindId <- Unit
(def poo-module-doctor-presentation-kind
  "poo.modules.doctor-presentation.v1")

;;; Boundary: source doctor kind identifies summaries that include loader receipts.
;; ModuleKindId <- Unit
(def poo-module-source-doctor-presentation-kind
  "poo.modules.source-doctor-presentation.v1")

;;; Boundary: validation receipt projection stays local to the doctor edge.
;; Alist <- PooModuleOptionValidationReceipt
(def (poo-module-validation-receipt->alist receipt)
  (list (cons 'id (poo-module-option-validation-receipt-id receipt))
        (cons 'source-module
              (poo-module-option-validation-receipt-source-module receipt))
        (cons 'valid? (poo-module-option-validation-receipt-valid? receipt))
        (cons 'code (poo-module-option-validation-receipt-code receipt))
        (cons 'messages (poo-module-option-validation-receipt-messages receipt))
        (cons 'metadata (poo-module-option-validation-receipt-metadata receipt))))

;;; Boundary: import profiles are summarized without resolving source refs.
;; Value <- ModuleImportProfile
(def (poo-module-import-profile-summary profile)
  (cond
   ((poo-module-config? profile) (poo-module-name profile))
   (else profile)))

;;; Boundary: import summaries expose source metadata and profile identity only.
;; Alist <- ModuleImportValue
(def (poo-module-import-summary import-value)
  (if (poo-import? import-value)
    (let ((source-ref (.ref import-value 'source-ref))
          (profile (.ref import-value 'profile)))
      (list (cons 'source
                  (if source-ref
                    (poo-module-source-ref->alist source-ref)
                    #f))
            (cons 'profile
                  (poo-module-import-profile-summary profile))))
    (list (cons 'source #f)
          (cons 'profile
                (poo-module-import-profile-summary import-value)))))

;;; Boundary: import graph is a per-module projection, not a resolver action.
;; Alist <- PooModuleDescriptor
(def (poo-module-import-graph-entry module)
  (cons (poo-module-name module)
        (map poo-module-import-summary
             (poo-module-imports module))))

;;; Boundary: full import graph keeps named imports unresolved for doctor visibility.
;; Alist <- [PooModuleDescriptor]
(def (poo-module-import-graph modules)
  (map poo-module-import-graph-entry modules))

;;; Boundary: contribution summary counts descriptor payloads without interpreting them.
;; Alist <- PooModuleDescriptor
(def (poo-module-contribution-summary module)
  (list (cons 'module (poo-module-name module))
        (cons 'import-count (length (poo-module-imports module)))
        (cons 'task-count (length (poo-module-task-descriptors module)))
        (cons 'flow-count (length (poo-module-flow-descriptors module)))
        (cons 'option-count (length (poo-module-options module)))
        (cons 'extension-count (length (poo-module-extensions module)))
        (cons 'script-count (length (poo-module-scripts module)))
        (cons 'hook-count (length (poo-module-hooks module)))))

;;; Boundary: contribution summaries are intentionally shallow for CLI-sized output.
;; [Alist] <- [PooModuleDescriptor]
(def (poo-module-contribution-summaries modules)
  (map poo-module-contribution-summary modules))

;;; Boundary: merge status collapses detailed receipts into one doctor-level signal.
;; Boolean <- [PooModuleOptionMergeReceipt]
(def (poo-module-merge-receipts-all-valid? receipts)
  (cond
   ((null? receipts) #t)
   ((poo-module-option-merge-receipt-valid? (car receipts))
    (poo-module-merge-receipts-all-valid? (cdr receipts)))
   (else #f)))

;;; Boundary: root doctor presentation is the shared data projection for both callers.
;; POOObject <- PooModuleDescriptor
(def (poo-module-root-doctor-presentation root-module)
  (let* ((closed-modules (poo-module-closure (list root-module)))
         (doctor-report (poo-module-doctor closed-modules))
         (evaluation-value (poo-module-evaluate root-module))
         (validation-receipts
          (.ref evaluation-value 'validation-receipts))
         (merge-receipts
          (poo-module-option-merge-receipts root-module)))
    (.o kind: poo-module-doctor-presentation-kind
        root-module-id: (poo-module-name root-module)
        module-ids: (poo-module-names closed-modules)
        doctor-status: (poo-module-doctor-report-status doctor-report)
        doctor-ok: (poo-module-doctor-ok? doctor-report)
        diagnostics:
        (map poo-module-diagnostic->alist
             (poo-module-doctor-report-diagnostics doctor-report))
        import-graph: (poo-module-import-graph closed-modules)
        contributions: (poo-module-contribution-summaries closed-modules)
        validation-receipt-count: (length validation-receipts)
        merge-status:
        (if (poo-module-merge-receipts-all-valid? merge-receipts) 'ok 'error)
        merge-receipt-count: (length merge-receipts)
        merged-options: (poo-module-merged-option-alist root-module)
        module-evaluation-kind: (.ref evaluation-value 'kind)
        scheme-owner: "gerbil-poo"
        runtime-owner: "poo-flow-runtime"
        runtime-executed: #f
        replayable: #t)))

;;; Boundary: value-catalog doctor mirrors system presentation root selection.
;;; Intent: callers can inspect already-built module values without invoking source loaders.
;;; Runtime activation remains an explicit resolver step outside this presentation helper.
;; POOObject <- PooModuleValueCatalog MaybeModuleName
(def (pooModuleDoctorPresentation catalog . maybe-root-module-id)
  (poo-module-root-doctor-presentation
   (poo-module-value-catalog-root
    catalog
    (if (null? maybe-root-module-id) #f (car maybe-root-module-id)))))

;;; Boundary: source doctor ignores failed loads here because receipts retain failures.
;; [PooModuleDescriptor] <- [PooModuleLoadReceipt]
(def (poo-module-loaded-modules-from-receipts receipts)
  (cond
   ((null? receipts) '())
   ((poo-module-load-receipt-loaded? (car receipts))
    (cons (poo-module-load-receipt-module (car receipts))
          (poo-module-loaded-modules-from-receipts (cdr receipts))))
   (else
    (poo-module-loaded-modules-from-receipts (cdr receipts)))))

;;; Boundary: source doctor surfaces loader evidence before descriptor diagnostics.
;; POOObject <- [PooModuleLoaderBackend] [PooModuleSourceRef]
(def (pooModuleSourceDoctorPresentation backends source-refs)
  (let* ((load-receipts
          (poo-module-load-source-receipts backends source-refs))
         (loaded-modules
          (poo-module-loaded-modules-from-receipts load-receipts))
         (root-module
          (if (null? loaded-modules) #f (car loaded-modules))))
    (.o kind: poo-module-source-doctor-presentation-kind
        source-count: (length source-refs)
        loaded-count: (length loaded-modules)
        load-receipts: (map poo-module-load-receipt->alist load-receipts)
        module-doctor:
        (if root-module
          (poo-module-root-doctor-presentation root-module)
          #f)
        runtime-executed: #f
        replayable: #t)))
