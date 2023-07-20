Tests mutation of arithmetic expressions

  $ bash ../write_dune_files.sh

Set seed and (full) mutation rate as environment variables, for repeatability
  $ export MUTAML_SEED=896745231
  $ export MUTAML_MUT_RATE=100


Test + 1:

  $ cat > test.ml <<'EOF'
  > let f x = x + 1;;
  > assert (f 5 = 6)
  > EOF

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
  
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

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
  
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

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
  
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

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
  
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

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
  
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

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let f x y = if __MUTAML_MUTANT__ = (Some "test:0") then x + y else x * y
  ;;assert ((f 6 5) = 30)

  $ dune exec --no-build ./test.bc



Test division mutation:

  $ cat > test.ml <<'EOF'
  > let f x y = x / y;;
  > assert (f 56 5 = 11)
  > EOF

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
  
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

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let f x y = if __MUTAML_MUTANT__ = (Some "test:0") then x / y else x mod y
  ;;assert ((f 56 6) = 2)

  $ dune exec --no-build ./test.bc

  $ MUTAML_MUTANT="test:0" dune exec --no-build ./test.bc
  Fatal error: exception Assert_failure("test.ml", 2, 0)
  [2]


--------------------------------------------------------------------------------

Test the evaluation order of arithmetic operands.

In OCaml the evaluation order of `a` and `b` in `a + b` in unspecified,
but in practice it is currently right-to-left.

We want to make sure that instrumented programs have the same evaluation
order as non-instrumented programs.

  $ cat > test.ml <<'EOF'
  > let f x y =
  >     (let () = print_endline "left" in x)
  >   + (let () = print_endline "right" in y);;
  > assert (f 5 6 = 11)
  > EOF

Remark on test.ml: we use `let () = print_endline ... in ...` instead of
`print_endline ... ; ...` because the latter form is itself mutated,
and we wanted to only check the arithmetic mutation. This property
may become false in the future if mutaml gets more mutation oprators.
If mutaml supported an attribute to explicitly disable mutations locally,
we should use it instead.

  $ ocaml test.ml
  right
  left

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let f x y =
    let __MUTAML_TMP0__ = let () = print_endline "right" in y in
    let __MUTAML_TMP1__ = let () = print_endline "left" in x in
    if __MUTAML_MUTANT__ = (Some "test:0")
    then __MUTAML_TMP1__ - __MUTAML_TMP0__
    else __MUTAML_TMP1__ + __MUTAML_TMP0__
  ;;assert ((f 5 6) = 11)

  $ dune exec --no-build ./test.bc
  right
  left

  $ MUTAML_MUTANT="test:0" dune exec --no-build ./test.bc
  right
  left
  Fatal error: exception Assert_failure("test.ml", 4, 0)
  [2]
