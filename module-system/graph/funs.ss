;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Pure inline-Module closure and closed-world import findings. The caller
;;; supplies descriptor accessors; Core never loads sources or activates tasks.
(export module-closure module-missing-imports)

(def (module-closure roots module-key inline-imports)
  (let (seen (make-hash-table))
    (let loop ((frames (list roots)) (modules-rev '()))
      (cond
       ((null? frames) (reverse modules-rev))
       ((null? (car frames)) (loop (cdr frames) modules-rev))
       (else
        (let* ((siblings (car frames))
               (module (car siblings))
               (key (module-key module))
               (remaining (cons (cdr siblings) (cdr frames))))
          (if (hash-key? seen key)
            (loop remaining modules-rev)
            (begin
              (hash-put! seen key #t)
              (loop (cons (inline-imports module) remaining)
                    (cons module modules-rev))))))))))

(def (module-missing-imports closed-modules module-key imports-of
                             named-import? import-key)
  (let (available (make-hash-table))
    (for-each
     (lambda (module) (hash-put! available (module-key module) #t))
     closed-modules)
    (foldr append
           '()
           (map
            (lambda (module)
              (filter-map
               (lambda (import-value)
                 (and (named-import? import-value)
                      (let (key (import-key import-value))
                        (and (not (hash-key? available key))
                             (list (cons 'module (module-key module))
                                   (cons 'import key))))))
               (imports-of module)))
            closed-modules))))
