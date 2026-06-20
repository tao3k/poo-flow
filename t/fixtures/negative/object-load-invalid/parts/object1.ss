;;; -*- Gerbil -*-
;;; Boundary: included by ../objects.ss.
;;; This part deliberately declares an invalid TypeSpec.
;;; The fixture proves included object fragments are validated by the loader.

;;; This object intentionally references an unknown type so validation proves
;;; load! reports schema errors at the included fragment boundary.
;; : [PooFlowModuleObject]
(list
 (poo-flow-module-object
  'objects.fixture.invalid
  '()
  (list
   (poo-flow-module-field-contract
    'broken 'Unknown 'override #f '((scope . fixture))))
  '((namespace . objects.fixture)
    (domain . fixture))))
