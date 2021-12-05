Create dune and dune-project files:
  $ bash write_dune_files.sh

Make an .ml-file:
  $ cat > test.ml <<'EOF'
  > let foo = match Sys.word_size with
  >   | 32 -> 32
  >   | _  -> assert false
  > EOF

---------------------------------------------------------------
Quick interlude:  This can be useful to observe the parse tree:
---------------------------------------------------------------

  $ ocamlc -dparsetree test.ml
  [
    structure_item (test.ml[1,0+0]..[3,48+22])
      Pstr_value Nonrec
      [
        <def>
          pattern (test.ml[1,0+4]..[1,0+7])
            Ppat_var "foo" (test.ml[1,0+4]..[1,0+7])
          expression (test.ml[1,0+10]..[3,48+22])
            Pexp_match
            expression (test.ml[1,0+16]..[1,0+29])
              Pexp_ident "Sys.word_size" (test.ml[1,0+16]..[1,0+29])
            [
              <case>
                pattern (test.ml[2,35+4]..[2,35+6])
                  Ppat_constant PConst_int (32,None)
                expression (test.ml[2,35+10]..[2,35+12])
                  Pexp_constant PConst_int (32,None)
              <case>
                pattern (test.ml[3,48+4]..[3,48+5])
                  Ppat_any
                expression (test.ml[3,48+10]..[3,48+22])
                  Pexp_assert
                  expression (test.ml[3,48+17]..[3,48+22])
                    Pexp_construct "false" (test.ml[3,48+17]..[3,48+22])
                    None
            ]
      ]
  ]
  
----------------------------------------------------------------------------------
Test mutation of the 'assert false':
----------------------------------------------------------------------------------

Set seed and (full) mutation rate as environment variables, for repeatability
  $ export MUTAML_SEED=896745231
  $ export MUTAML_MUT_RATE=100

  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
        ocamlc .test.eobjs/byte/dune__exe__Test.{cmi,cmo,cmt}
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let foo =
    match Sys.word_size with
    | 32 -> if __MUTAML_MUTANT__ = (Some "test:0") then 33 else 32
    | _ -> assert false


----------------------------------------------------------------------------------
Test mutation of another 'assert' form:
----------------------------------------------------------------------------------

Make an .ml-file:
  $ cat > test.ml <<'EOF'
  > let foo = match Sys.word_size with
  >   | 32 -> 32
  >   | _  -> assert (1>0); 0
  > EOF

  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 3 mutations of test.ml
  Writing mutation info to test.muts
        ocamlc .test.eobjs/byte/dune__exe__Test.{cmi,cmo,cmt}
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let foo =
    match Sys.word_size with
    | 32 -> if __MUTAML_MUTANT__ = (Some "test:0") then 33 else 32
    | _ ->
        (if __MUTAML_MUTANT__ = (Some "test:2") then () else assert (1 > 0);
         if __MUTAML_MUTANT__ = (Some "test:1") then 1 else 0)


  $ MUTAML_MUTANT="test:0" dune exec --no-build -- ./test.bc

  $ MUTAML_MUTANT="test:1" dune exec --no-build -- ./test.bc


----------------------------------------------------------------------------------
Test mutation of two asserts:
----------------------------------------------------------------------------------

Make an .ml-file:
  $ cat > test.ml <<'EOF'
  > let () =
  >   let tmp = true = not false in
  >   assert tmp
  > let () =
  >   let tmp = String.length " " = 1 + String.length "" in
  >   assert tmp
  > EOF


  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 4 mutations of test.ml
  Writing mutation info to test.muts
        ocamlc .test.eobjs/byte/dune__exe__Test.{cmi,cmo,cmt}
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let () =
    let tmp =
      (if __MUTAML_MUTANT__ = (Some "test:0") then false else true) =
        (not (if __MUTAML_MUTANT__ = (Some "test:1") then true else false)) in
    assert tmp
  let () =
    let tmp =
      (String.length (if __MUTAML_MUTANT__ = (Some "test:2") then "" else " "))
        =
        (let __MUTAML_TMP0__ = String.length "" in
         if __MUTAML_MUTANT__ = (Some "test:3")
         then __MUTAML_TMP0__
         else 1 + __MUTAML_TMP0__) in
    assert tmp


Check that running it doesn't fail when run like this

  $ _build/default/test.bc

or like this:

  $ dune exec --no-build ./test.bc


These should all fail however:

  $ MUTAML_MUTANT="test:0" dune exec --no-build ./test.bc
  Fatal error: exception Assert_failure("test.ml", 3, 2)
  [2]

  $ MUTAML_MUTANT="test:1" dune exec --no-build ./test.bc
  Fatal error: exception Assert_failure("test.ml", 3, 2)
  [2]

  $ MUTAML_MUTANT="test:2" dune exec --no-build ./test.bc
  Fatal error: exception Assert_failure("test.ml", 6, 2)
  [2]

  $ MUTAML_MUTANT="test:3" dune exec --no-build ./test.bc
  Fatal error: exception Assert_failure("test.ml", 6, 2)
  [2]
