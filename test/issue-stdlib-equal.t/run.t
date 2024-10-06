Let us try something:

  $ ls ../filter_dune_build.sh
  ../filter_dune_build.sh

Create the central file overriding polymorphic equality:
  $ cat > test.ml << EOF
  > let (=) = Int.equal
  > 
  > let add a b = a + b
  > ;;
  > assert (add 4 3 >= 0)
  > EOF

Create the dune files:
  $ cat > dune-project << EOF
  > (lang dune 2.9)
  > EOF

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (ocamlc_flags -dsource)
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
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let __is_mutaml_mutant__ m =
    match __MUTAML_MUTANT__ with
    | None -> false
    | Some mutant -> String.equal m mutant
  let (=) = Int.equal
  let add a b = if __is_mutaml_mutant__ "test:0" then a - b else a + b
  ;;assert ((add 4 3) >= 0)

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
  Testing mutant test:0 ... passed
  Writing report data to mutaml-report.json

  $ mutaml-report
  Attempting to read from mutaml-report.json...
  
  Mutaml report summary:
  ----------------------
  
   target                          #mutations      #failed      #timeouts      #passed 
   -------------------------------------------------------------------------------------
   test.ml                                1       0.0%    0     0.0%    0   100.0%    1
   =====================================================================================
  
  Mutation programs passing the test suite:
  -----------------------------------------
  
  Mutation "test.ml-mutant0" passed (see "_mutations/test.ml-mutant0.output"):
  
  --- test.ml
  +++ test.ml-mutant0
  @@ -1,5 +1,5 @@
   let (=) = Int.equal
   
  -let add a b = a + b
  +let add a b = a - b
   ;;
   assert (add 4 3 >= 0)
  
  ---------------------------------------------------------------------------
  
