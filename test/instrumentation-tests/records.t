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
  let __is_mutaml_mutant__ m =
    match __MUTAML_MUTANT__ with
    | None -> false
    | Some mutant -> String.equal m mutant
  type t = {
    x: int ;
    y: int }
  let f =
    function
    | { x = v; y = 0 } when not (__is_mutaml_mutant__ "test:2") -> v
    | { x = 0; y = v } when not (__is_mutaml_mutant__ "test:1") -> v
    | { x; y } -> if __is_mutaml_mutant__ "test:0" then x - y else x + y


