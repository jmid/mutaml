Let us try something:

  $ ls
  filter_dune_build.sh
  run.t

Create the central file with initial newline characters:
  $ cat > test.ml <<'EOF'
  > 
  > 
  > (* here's a comment *)
  > 
  > let add a b = a + b
  > ;;
  > assert (add 4 3 >= 0)
  > EOF

Create the dune files:
  $ echo "(lang dune 2.9)" > dune-project

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (ocamlc_flags -dsource)
  >  (instrumentation (backend mutaml))
  > )
  > EOF

Check that files were created as expected:
  $ ls
  dune
  dune-project
  filter_dune_build.sh
  run.t
  test.ml

Set seed and (full) mutation rate as environment variables, for repeatability
  $ export MUTAML_SEED=896745231
  $ export MUTAML_MUT_RATE=100

  $ bash filter_dune_build.sh ./test.exe --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: false
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
        ocamlc .test.eobjs/byte/dune__exe__Test.{cmi,cmo,cmt}
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let add a b = if __MUTAML_MUTANT__ = (Some "test:0") then a - b else a + b
  ;;assert ((add 4 3) >= 0)

  $ ls
  _build
  dune
  dune-project
  filter_dune_build.sh
  run.t
  test.ml

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
  @@ -2,6 +2,6 @@
   
   (* here's a comment *)
   
  -let add a b = a + b
  +let add a b = a - b
   ;;
   assert (add 4 3 >= 0)
  
  ---------------------------------------------------------------------------
  




  $ ls _mutations
  test.ml-mutant0
  test.muts-mutant0.output


Here's an example of a manual diff from the console:

  $ diff -u --label "test.ml" -u test.ml --label "test.ml-mutant0" _mutations/test.ml-mutant0
  --- test.ml
  +++ test.ml-mutant0
  @@ -2,6 +2,6 @@
   
   (* here's a comment *)
   
  -let add a b = a + b
  +let add a b = a - b
   ;;
   assert (add 4 3 >= 0)
  [1]
