;;; -*- Gerbil -*-
;;; Boundary: included by ../objects.ss.
;;; This part is loaded through object practice macros, not package compile.
;;; The fixture proves valid included fragments keep their declared identity.

;;; This object is a valid load! fragment used to prove included object parts
;;; preserve field contracts and metadata.
;; : [PooFlowModuleObject]
(list
 (poo-flow-module-object
  'objects.fixture.loaded
  '()
  (list
   (poo-flow-module-field-contract
    'title 'String 'override "loaded" '((scope . fixture)))
   (poo-flow-module-field-contract
    'tags '(List Symbol) 'append '() '((scope . fixture))))
  '((namespace . objects.fixture)
    (domain . fixture))))
