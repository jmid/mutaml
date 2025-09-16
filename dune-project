(lang dune 3.18)

(name mutaml)

(formatting
 (enabled_for dune))

(generate_opam_files)

(package
 (name mutaml)
 (synopsis "A mutation tester for OCaml")
 (license "BSD-2-Clause")
 (version "0.3")
 (description  
  "\| Mutaml is a mutation testing tool for OCaml.
  "\| It uses a ppxlib-based preprocessor to make a series of small
  "\| breaking changes to a program's source code and then runs
  "\| the program's testsuite for each of them to catch uncaught
  "\| misbehaviour.
  )
 (source (github jmid/mutaml))
 (documentation "https://github.com/jmid/mutaml")
 (authors "Jan Midtgaard <mail@janmidtgaard.dk>")
 (maintainers "Jan Midtgaard <mail@janmidtgaard.dk>")
 (tags ("test" "mutation testing"))
 (depends
  (ocaml (>= 4.12.0))
  (ppxlib (>= 0.28.0))
  (ppx_yojson_conv (>= v0.14.0))
  stdlib-random
  conf-timeout
  conf-diffutils
  ;; transitive lower versions to avoid CI errors
  (ocaml-compiler-libs (>= v0.12.0))
  (ppx_derivers (>= 1.2.1))
  (yojson (>= 2.0.0))
  (ppx_deriving :with-test)
  (ounit2 :with-test))
 (maintenance_intent "(latest)")
)
