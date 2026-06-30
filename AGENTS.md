# POO Flow Project Rules

## Core Invariants

- Public extension and module APIs must be 100% POO-native. Expose Gerbil POO objects, prototype composition, slot operators, and object extension helpers as the normal path.
- Prefer functional programming style in the Scheme control plane. Flow composition should be expressed as pure values and functional combinators first; side effects belong behind explicit runtime or Marlin handoff boundaries.
- Funflow is here to anchor that functional route. The project core is POO + functional programming, and new features must preserve that direction.
- Do not make raw alist DSLs, record DSLs, ad hoc patch languages, or raw `(lambda (self super) ...)` compute hooks the ordinary user interface. Advanced escape hatches may exist only behind named POO-native or functional helpers.
- Follow the current project programming style in `docs/10-19-design/10.06-poo-module-system/44-current-project-programming-style.org`. Use Gerbil declarative macros, procedural macros, and bounded compile-time metaprogramming for repeated internal POO object families, contract projections, and manifest declarations when they expand to ordinary POO-native or functional code.
