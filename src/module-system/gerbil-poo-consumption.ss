(import (only-in :clan/poo/object
                 .o
                 .@
                 .ref
                 object?
                 object<-alist))

(export +poo-flow-gerbil-poo-provider-label+
        +poo-flow-gerbil-poo-resolution-receipt-label+
        +poo-flow-gerbil-poo-required-api+
        poo-flow-gerbil-poo-consumption-prototype
        poo-flow-gerbil-poo-consumption-manifest
        poo-flow-gerbil-poo-api-closed?)

(def +poo-flow-gerbil-poo-provider-label+
  "//scheme:gerbil_poo_package")

(def +poo-flow-gerbil-poo-resolution-receipt-label+
  "@gerbil_poo_sources//:source_resolution_receipt")

(def +poo-flow-gerbil-poo-required-api+
  '(.o .@ .ref object? object<-alist))

(def poo-flow-gerbil-poo-consumption-prototype
  (object<-alist '((kind . gerbil-poo-consumption))))

(def (poo-flow-gerbil-poo-consumption-manifest)
  (object<-alist
   `((kind . gerbil-poo-consumption)
     (provider-label . ,+poo-flow-gerbil-poo-provider-label+)
     (source-resolution-receipt-label
      . ,+poo-flow-gerbil-poo-resolution-receipt-label+)
     (required-api . ,+poo-flow-gerbil-poo-required-api+))))

(def (poo-flow-gerbil-poo-api-closed? observed-api)
  (and (= (length observed-api)
          (length +poo-flow-gerbil-poo-required-api+))
       (let loop ((required +poo-flow-gerbil-poo-required-api+))
         (or (null? required)
             (and (member (car required) observed-api)
                  (loop (cdr required)))))))
