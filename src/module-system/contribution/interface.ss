;;; Public downstream boundary; POO Flow remains the sole core package.
(import :clan/poo/object
        :poo-flow/src/module-system/profile-composition/interface
        :poo-flow/src/utilities/functional
        "objects.ss")
(export .o .ref .mix .extend .slot? object?
        use-composition poo-flow-composition-profiles
        poo-flow-map poo-flow-append-map poo-flow-all? poo-flow-any?
        (import: "objects.ss"))
