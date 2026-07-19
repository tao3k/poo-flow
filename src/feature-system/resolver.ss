(import :clan/poo/object
        :poo-flow/src/feature-system/model
        :poo-flow/src/utilities/functional)

(export resolve-feature-profile)

(def (selection-id selection)
  (.ref selection 'feature-id))

(def (selection-descriptor selection)
  (.ref selection 'descriptor))

(def (hash-ref/default table key default-value)
  (if (hash-key? table key)
    (hash-get table key)
    default-value))

(def (index-feature-selections selections)
  (let ((index (make-hash-table)))
    (values
     index
     (reverse
      (poo-flow-fold-left
       (lambda (selection diagnostics)
         (let ((feature-id (selection-id selection)))
           (if (hash-key? index feature-id)
             (cons
              (feature-diagnostic
               'duplicate-selection feature-id feature-id #f)
              diagnostics)
             (begin
               (hash-put! index feature-id selection)
               diagnostics))))
       '()
       selections)))))

(def (missing-dependency-diagnostics selections index)
  (poo-flow-fold-right
   (lambda (selection diagnostics)
     (let* ((descriptor (selection-descriptor selection))
            (feature-id (selection-id selection)))
       (append
        (poo-flow-filter-map
         (lambda (required-id)
           (and (not (hash-key? index required-id))
                (feature-diagnostic
                 'missing-dependency feature-id required-id #f)))
         (.ref descriptor 'requires))
        diagnostics)))
   '()
   selections))

(def (conflict-diagnostics selections index)
  (poo-flow-fold-right
   (lambda (selection diagnostics)
     (let* ((descriptor (selection-descriptor selection))
            (feature-id (selection-id selection)))
       (append
        (poo-flow-filter-map
         (lambda (conflict-id)
           (and (hash-key? index conflict-id)
                (feature-diagnostic
                 'feature-conflict feature-id conflict-id #f)))
         (.ref descriptor 'conflicts))
        diagnostics)))
   '()
   selections))

(def (selected-dependencies descriptor index)
  (append
   (poo-flow-filter-map
    (lambda (required-id)
      (and (hash-key? index required-id) required-id))
    (.ref descriptor 'requires))
   (poo-flow-filter-map
    (lambda (optional-id)
      (and (hash-key? index optional-id) optional-id))
    (.ref descriptor 'optional-requires))))

(def (topological-feature-selections selections index)
  (let ((states (make-hash-table))
        (ordered '())
        (diagnostics '()))
    (def (visit feature-id path)
      (case (hash-ref/default states feature-id 'unseen)
        ((done) (void))
        ((visiting)
         (set! diagnostics
           (cons
            (feature-diagnostic
             'dependency-cycle feature-id feature-id
             (reverse (cons feature-id path)))
            diagnostics)))
        (else
         (hash-put! states feature-id 'visiting)
         (let* ((selection (hash-get index feature-id))
                (descriptor (selection-descriptor selection)))
           (for-each
            (lambda (dependency-id)
              (visit dependency-id (cons feature-id path)))
            (selected-dependencies descriptor index))
           (hash-put! states feature-id 'done)
           (set! ordered (cons selection ordered))))))
    (for-each
     (lambda (selection)
       (visit (selection-id selection) '()))
     selections)
    (values (reverse ordered) (reverse diagnostics))))

(def (resolve-feature-profile profile)
  (let ((selections (.ref profile 'selections)))
    (let-values (((index duplicate-diagnostics)
                  (index-feature-selections selections)))
      (let-values (((ordered cycle-diagnostics)
                    (topological-feature-selections selections index)))
        (let* ((diagnostics
                (append
                 duplicate-diagnostics
                 (missing-dependency-diagnostics selections index)
                 (conflict-diagnostics selections index)
                 cycle-diagnostics))
               (status (if (null? diagnostics) 'ready 'rejected)))
          (feature-activation-plan
           profile
           status
           ordered
           (poo-flow-map selection-id ordered)
           diagnostics))))))
