Create dune and dune-project files:
  $ bash ../write_dune_files.sh


An simple record example
----------------------------------------------------------------------------

  $ cat > test.ml <<'EOF'
  > type t = { x: int; y: int }
  > 
  > let f = function
  >   | {x=v;y=0} -> v
  >   | {x=0;y=v} -> v
  >   | {x;y} -> x+y
  > EOF


  $ export MUTAML_SEED=896745231
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 50   GADTs enabled: true
  Created 3 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type t = {
    x: int ;
    y: int }
  let f =
    function
    | { x = v; y = 0 } when __MUTAML_MUTANT__ <> (Some "test:2") -> v
    | { x = 0; y = v } when __MUTAML_MUTANT__ <> (Some "test:1") -> v
    | { x; y } -> if __MUTAML_MUTANT__ = (Some "test:0") then x - y else x + y


