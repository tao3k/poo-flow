;;; -*- Gerbil -*-
;;; Reusable indexed POO family layout for large, stable object families.

(import (only-in :clan/poo/object .o .ref))

(export #t)

;; : (-> (Listof Symbol) Alist)
(def (poo-index-slots slot-names)
  (let loop ((rest slot-names) (index 0) (slots-rev '()))
    (if (null? rest)
      (reverse slots-rev)
      (loop (cdr rest)
            (+ index 1)
            (cons (cons (car rest) index) slots-rev)))))

;; : (-> Symbol Symbol (Listof Symbol) POOObject)
(def (poo-indexed-family family-name source-tag slot-names)
  (let* ((slot-vector-value (list->vector slot-names))
         (slot-index-value (poo-index-slots slot-names))
         (slot-count-value (vector-length slot-vector-value)))
    (.o (kind 'poo-indexed-family)
        (name family-name)
        (source source-tag)
        (slots slot-vector-value)
        (slot-index slot-index-value)
        (slot-count slot-count-value))))

;; : (-> POOObject Symbol (Maybe Fixnum))
(def (poo-indexed-family-slot-index family-object slot-name)
  (let (entry (assoc slot-name (.ref family-object 'slot-index)))
    (if entry (cdr entry) #f)))

;; : (-> POOObject (Listof Any) POOObject)
(def (poo-indexed-family-object family-object values)
  (let* ((values-vector-value (list->vector values))
         (slot-count-value (.ref family-object 'slot-count)))
    (if (= (vector-length values-vector-value) slot-count-value)
      (.o (kind 'poo-indexed-family-object)
          (family family-object)
          (values values-vector-value))
      (error "indexed family object value count mismatch"
             (vector-length values-vector-value)
             slot-count-value))))

;; : (-> POOObject POOObject Symbol Any Any)
(def (poo-indexed-family-ref family-object object slot-name default-value)
  (let (index-value
        (poo-indexed-family-slot-index family-object slot-name))
    (if (and index-value (eq? (.ref object 'family) family-object))
      (vector-ref (.ref object 'values) index-value)
      default-value)))

;; : (-> POOObject Symbol Symbol POOObject)
(def (poo-indexed-family-named-slot-lens family-object
                                          slot-name
                                          descriptor-name)
  (let (index-value
        (poo-indexed-family-slot-index family-object slot-name))
    (.o (kind 'poo-indexed-family-slot-lens)
        (family family-object)
        (slot slot-name)
        (name descriptor-name)
        (index index-value))))

;; : (-> POOObject Symbol POOObject)
(def (poo-indexed-family-slot-lens family-object slot-name)
  (poo-indexed-family-named-slot-lens
   family-object
   slot-name
   slot-name))

;; : (-> POOObject (Listof Pair) Vector)
(def (poo-indexed-family-lenses family-object specs)
  (list->vector
   (let loop ((rest specs) (lenses-rev '()))
     (if (null? rest)
       (reverse lenses-rev)
       (let* ((spec (car rest))
              (slot-name (car spec))
              (descriptor-name (cdr spec)))
         (loop (cdr rest)
               (cons (poo-indexed-family-named-slot-lens
                      family-object
                      slot-name
                      descriptor-name)
                     lenses-rev)))))))

;; : (-> POOObject POOObject Any Any)
(def (poo-indexed-family-slot-lens-ref lens object default-value)
  (if (eq? (.ref object 'family) (.ref lens 'family))
    (vector-ref (.ref object 'values) (.ref lens 'index))
    default-value))

;; : (-> POOObject POOObject Vector Procedure Vector)
(def (poo-indexed-family-project-descriptors family-object
                                             object
                                             lenses
                                             descriptor-builder)
  (let (count (vector-length lenses))
    (let loop ((index 0) (descriptors-rev '()))
      (if (= index count)
        (list->vector (reverse descriptors-rev))
        (let* ((lens (vector-ref lenses index))
               (descriptor-name (.ref lens 'name))
               (value (poo-indexed-family-slot-lens-ref
                       lens
                       object
                       #f)))
          (loop (+ index 1)
                (cons (descriptor-builder family-object
                                          descriptor-name
                                          value)
                      descriptors-rev)))))))

;; : (-> POOObject POOObject Vector Vector)
(def (poo-indexed-family-project-objects family-object object lenses)
  (poo-indexed-family-project-descriptors
   family-object
   object
   lenses
   (lambda (family descriptor-name value)
     (.o (kind 'poo-indexed-family-descriptor)
         (family family)
         (name descriptor-name)
         (value value)))))
