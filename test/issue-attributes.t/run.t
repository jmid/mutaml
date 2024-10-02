Let us try something:

  $ ls ../filter_dune_build.sh
  ../filter_dune_build.sh

Create a file with a deriving show attribute https://github.com/jmid/mutaml/issues/28
  $ cat > test.ml << EOF
  > type some_type = A | B [@@deriving show {with_path = false}]
  > type another_type = C | D of some_type [@@deriving show {with_path = false}]
  > ;;
  > assert (show_another_type C = "C")
  > EOF

Create the dune files:
  $ cat > dune-project << EOF
  > (lang dune 2.9)
  > EOF

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (preprocess (pps ppx_deriving.show))
  >  (instrumentation (backend mutaml))
  > )
  > EOF

Check that files were created as expected:
  $ ls dune* test.ml
  dune
  dune-project
  test.ml

Set seed and (full) mutation rate as environment variables, for repeatability
  $ export MUTAML_SEED=896745231
  $ export MUTAML_MUT_RATE=100

  $ ../filter_dune_build.sh ./test.exe --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts

  $ ls _build
  default
  log

  $ ls _build/default
  mutaml-mut-files.txt
  test.exe
  test.ml
  test.muts
  test.pp.ml

  $ mutaml-runner _build/default/test.exe
  read mut file test.muts
  Warning: No mutations were listed in test.muts
  Did not find any mutations across the files listed in mutaml-mut-files.txt
  [1]
