Create dune and dune-project files:
  $ bash write_dune_files.sh

Create a test.ml file with a few print M seed for randomized mutation
 M mutation threshold (chance/rate)
s:
  $ cat > test.ml <<'EOF'
  > let () = print_string (string_of_bool true)
  > let () = print_newline()
  > let () = print_int 5
  > let () = print_newline()
  > EOF

Confirm file creations
  $ ls dune* test.ml *.sh
  dune
  dune-project
  filter_dune_build.sh
  test.ml
  write_dune_files.sh


Set seed and (full) mutation rate as environment variables, for repeatability
  $ export MUTAML_SEED=896745231
  $ export MUTAML_MUT_RATE=100

Compile with instrumentation and filter result:
  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 2 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let () =
    print_string
      (string_of_bool
         (if __MUTAML_MUTANT__ = (Some "test:0") then false else true))
  let () = print_newline ()
  let () = print_int (if __MUTAML_MUTANT__ = (Some "test:1") then 6 else 5)
  let () = print_newline ()


  $ ls _build/default
  mutaml-mut-files.txt
  test.bc
  test.ml
  test.muts
  test.pp.ml


  $ _build/default/test.bc
  true
  5

  $ MUTAML_MUTANT="test:0" dune exec --no-build -- ./test.bc
  false
  5

  $ MUTAML_MUTANT="test:1" dune exec --no-build -- ./test.bc
  true
  6
