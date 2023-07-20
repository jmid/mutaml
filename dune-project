(lang dune 3.0)

(name mutaml)

(formatting
 (enabled_for dune))

(generate_opam_files)

(package
 (name mutaml)
 (synopsis "A mutation tester for OCaml")
 (license "BSD-2-Clause")
 (description  
  "\| Mutaml is a mutation testing tool for OCaml.
  "\| It uses a ppxlib-based preprocessor to make a series of small
  "\| breaking changes to a program's source code and then runs
  "\| the program's testsuite for each of them to catch uncaught
  "\| misbehaviour.
  )
 (homepage "https://github.com/jmid/mutaml")
 (documentation "https://github.com/jmid/mutaml")
 (bug_reports "https://github.com/jmid/mutaml")
 (authors "Jan Midtgaard <mail@janmidtgaard.dk>")
 (maintainers "Jan Midtgaard <mail@janmidtgaard.dk>")
 (tags ("test" "mutation testing"))
 (depends
  (ocaml (>= 4.12.0))
  (ppxlib (and (>= 0.26.0) (< 0.28.0)))
  (ppx_yojson_conv (>= 0.14.0))
  stdlib-random
  conf-timeout
  conf-which
  conf-diffutils
  (ounit2 :with-test)))
