;;; -*- Gerbil -*-
;;; Boundary: included by ../objects.ss; not compiled as a package module.

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
