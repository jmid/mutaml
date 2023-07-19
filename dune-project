(lang dune 3.0)

(name mutaml)

(generate_opam_files)

(formatting disabled)

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
  ppxlib
  ppx_yosjon_conv
  stdlib-random
  conf-timeout
  conf-which
  conf-diffutils
  (ounit2 :with-test)))
