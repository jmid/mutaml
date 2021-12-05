Tests mutation of arithmetic expressions

  $ bash write_dune_files.sh

Set seed and (full) mutation rate as environment variables, for repeatability
  $ export MUTAML_SEED=896745231
  $ export MUTAML_MUT_RATE=100


Test + 1:

  $ cat > test.ml <<'EOF'
  > let f x = x + 1;;
  > assert (f 5 = 6)
  > EOF

  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
        ocamlc .test.eobjs/byte/dune__exe__Test.{cmi,cmo,cmt}
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let f x = if __MUTAML_MUTANT__ = (Some "test:0") then x else x + 1
  ;;assert ((f 5) = 6)

Check that instrumentation hasn't changed the program's behaviour
  $ dune exec --no-build ./test.bc

And that mutation has changed it as expected
  $ MUTAML_MUTANT="test:0" dune exec --no-build ./test.bc
  Fatal error: exception Assert_failure("test.ml", 2, 0)
  [2]



Test - 1:

  $ cat > test.ml <<'EOF'
  > let f x = x - 1;;
  > assert (f 5 = 4)
  > EOF

  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
        ocamlc .test.eobjs/byte/dune__exe__Test.{cmi,cmo,cmt}
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let f x = if __MUTAML_MUTANT__ = (Some "test:0") then x else x - 1
  ;;assert ((f 5) = 4)

  $ dune exec --no-build ./test.bc

  $ MUTAML_MUTANT="test:0" dune exec --no-build ./test.bc
  Fatal error: exception Assert_failure("test.ml", 2, 0)
  [2]



Test 1 +:

  $ cat > test.ml <<'EOF'
  > let f x = 1 + x;;
  > assert (f 5 = 6)
  > EOF

  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
        ocamlc .test.eobjs/byte/dune__exe__Test.{cmi,cmo,cmt}
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let f x = if __MUTAML_MUTANT__ = (Some "test:0") then x else 1 + x
  ;;assert ((f 5) = 6)

  $ dune exec --no-build ./test.bc

  $ MUTAML_MUTANT="test:0" dune exec --no-build ./test.bc
  Fatal error: exception Assert_failure("test.ml", 2, 0)
  [2]



Test addition:

  $ cat > test.ml <<'EOF'
  > let f x y = x + y;;
  > assert (f 5 6 = 11)
  > EOF

  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
        ocamlc .test.eobjs/byte/dune__exe__Test.{cmi,cmo,cmt}
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let f x y = if __MUTAML_MUTANT__ = (Some "test:0") then x - y else x + y
  ;;assert ((f 5 6) = 11)

  $ dune exec --no-build ./test.bc

  $ MUTAML_MUTANT="test:0" dune exec --no-build ./test.bc
  Fatal error: exception Assert_failure("test.ml", 2, 0)
  [2]

--------------------------------------------------------------------------------

Parse tree of simple arithmetic:

  $ ocamlc -dparsetree test.ml
  [
    structure_item (test.ml[1,0+0]..[1,0+17])
      Pstr_value Nonrec
      [
        <def>
          pattern (test.ml[1,0+4]..[1,0+5])
            Ppat_var "f" (test.ml[1,0+4]..[1,0+5])
          expression (test.ml[1,0+6]..[1,0+17]) ghost
            Pexp_fun
            Nolabel
            None
            pattern (test.ml[1,0+6]..[1,0+7])
              Ppat_var "x" (test.ml[1,0+6]..[1,0+7])
            expression (test.ml[1,0+8]..[1,0+17]) ghost
              Pexp_fun
              Nolabel
              None
              pattern (test.ml[1,0+8]..[1,0+9])
                Ppat_var "y" (test.ml[1,0+8]..[1,0+9])
              expression (test.ml[1,0+12]..[1,0+17])
                Pexp_apply
                expression (test.ml[1,0+14]..[1,0+15])
                  Pexp_ident "+" (test.ml[1,0+14]..[1,0+15])
                [
                  <arg>
                  Nolabel
                    expression (test.ml[1,0+12]..[1,0+13])
                      Pexp_ident "x" (test.ml[1,0+12]..[1,0+13])
                  <arg>
                  Nolabel
                    expression (test.ml[1,0+16]..[1,0+17])
                      Pexp_ident "y" (test.ml[1,0+16]..[1,0+17])
                ]
      ]
    structure_item (test.ml[2,20+0]..[2,20+19])
      Pstr_eval
      expression (test.ml[2,20+0]..[2,20+19])
        Pexp_assert
        expression (test.ml[2,20+7]..[2,20+19])
          Pexp_apply
          expression (test.ml[2,20+14]..[2,20+15])
            Pexp_ident "=" (test.ml[2,20+14]..[2,20+15])
          [
            <arg>
            Nolabel
              expression (test.ml[2,20+8]..[2,20+13])
                Pexp_apply
                expression (test.ml[2,20+8]..[2,20+9])
                  Pexp_ident "f" (test.ml[2,20+8]..[2,20+9])
                [
                  <arg>
                  Nolabel
                    expression (test.ml[2,20+10]..[2,20+11])
                      Pexp_constant PConst_int (5,None)
                  <arg>
                  Nolabel
                    expression (test.ml[2,20+12]..[2,20+13])
                      Pexp_constant PConst_int (6,None)
                ]
            <arg>
            Nolabel
              expression (test.ml[2,20+16]..[2,20+18])
                Pexp_constant PConst_int (11,None)
          ]
  ]
  
--------------------------------------------------------------------------------

Test subtraction mutation:

  $ cat > test.ml <<'EOF'
  > let f x y = x - y;;
  > assert (f 6 5 = 1)
  > EOF

  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
        ocamlc .test.eobjs/byte/dune__exe__Test.{cmi,cmo,cmt}
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let f x y = if __MUTAML_MUTANT__ = (Some "test:0") then x + y else x - y
  ;;assert ((f 6 5) = 1)

  $ dune exec --no-build ./test.bc

  $ MUTAML_MUTANT="test:0" dune exec --no-build ./test.bc
  Fatal error: exception Assert_failure("test.ml", 2, 0)
  [2]



Test multiplication mutation:

  $ cat > test.ml <<'EOF'
  > let f x y = x * y;;
  > assert (f 6 5 = 30)
  > EOF

  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
        ocamlc .test.eobjs/byte/dune__exe__Test.{cmi,cmo,cmt}
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let f x y = if __MUTAML_MUTANT__ = (Some "test:0") then x + y else x * y
  ;;assert ((f 6 5) = 30)

  $ dune exec --no-build ./test.bc



Test division mutation:

  $ cat > test.ml <<'EOF'
  > let f x y = x / y;;
  > assert (f 56 5 = 11)
  > EOF

  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
        ocamlc .test.eobjs/byte/dune__exe__Test.{cmi,cmo,cmt}
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let f x y = if __MUTAML_MUTANT__ = (Some "test:0") then x mod y else x / y
  ;;assert ((f 56 5) = 11)

  $ dune exec --no-build ./test.bc

  $ MUTAML_MUTANT="test:0" dune exec --no-build ./test.bc
  Fatal error: exception Assert_failure("test.ml", 2, 0)
  [2]



Test modulo mutation:

  $ cat > test.ml <<'EOF'
  > let f x y = x mod y;;
  > assert (f 56 6 = 2)
  > EOF

  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
        ocamlc .test.eobjs/byte/dune__exe__Test.{cmi,cmo,cmt}
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let f x y = if __MUTAML_MUTANT__ = (Some "test:0") then x / y else x mod y
  ;;assert ((f 56 6) = 2)

  $ dune exec --no-build ./test.bc

  $ MUTAML_MUTANT="test:0" dune exec --no-build ./test.bc
  Fatal error: exception Assert_failure("test.ml", 2, 0)
  [2]
