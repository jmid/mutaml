Create dune and dune-project files:
  $ bash write_dune_files.sh


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
  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 50   GADTs enabled: true
  Created 3 mutations of test.ml
  Writing mutation info to test.muts
        ocamlc .test.eobjs/byte/dune__exe__Test.{cmi,cmo,cmt}
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type t = {
    x: int ;
    y: int }
  let f =
    function
    | { x = v; y = 0 } when __MUTAML_MUTANT__ <> (Some "test:2") -> v
    | { x = 0; y = v } when __MUTAML_MUTANT__ <> (Some "test:1") -> v
    | { x; y } -> if __MUTAML_MUTANT__ = (Some "test:0") then x - y else x + y


Parse tree of record example

  $ ocamlc -dparsetree test.ml
  [
    structure_item (test.ml[1,0+0]..[1,0+27])
      Pstr_type Rec
      [
        type_declaration "t" (test.ml[1,0+5]..[1,0+6]) (test.ml[1,0+0]..[1,0+27])
          ptype_params =
            []
          ptype_cstrs =
            []
          ptype_kind =
            Ptype_record
              [
                (test.ml[1,0+11]..[1,0+18])
                  Immutable
                  "x" (test.ml[1,0+11]..[1,0+12])                core_type (test.ml[1,0+14]..[1,0+17])
                    Ptyp_constr "int" (test.ml[1,0+14]..[1,0+17])
                    []
                (test.ml[1,0+19]..[1,0+25])
                  Immutable
                  "y" (test.ml[1,0+19]..[1,0+20])                core_type (test.ml[1,0+22]..[1,0+25])
                    Ptyp_constr "int" (test.ml[1,0+22]..[1,0+25])
                    []
              ]
          ptype_private = Public
          ptype_manifest =
            None
      ]
    structure_item (test.ml[3,29+0]..[6,84+16])
      Pstr_value Nonrec
      [
        <def>
          pattern (test.ml[3,29+4]..[3,29+5])
            Ppat_var "f" (test.ml[3,29+4]..[3,29+5])
          expression (test.ml[3,29+8]..[6,84+16])
            Pexp_function
            [
              <case>
                pattern (test.ml[4,46+4]..[4,46+13])
                  Ppat_record Closed
                  [
                    "x" (test.ml[4,46+5]..[4,46+6])
                      pattern (test.ml[4,46+7]..[4,46+8])
                        Ppat_var "v" (test.ml[4,46+7]..[4,46+8])
                    "y" (test.ml[4,46+9]..[4,46+10])
                      pattern (test.ml[4,46+11]..[4,46+12])
                        Ppat_constant PConst_int (0,None)
                  ]
                expression (test.ml[4,46+17]..[4,46+18])
                  Pexp_ident "v" (test.ml[4,46+17]..[4,46+18])
              <case>
                pattern (test.ml[5,65+4]..[5,65+13])
                  Ppat_record Closed
                  [
                    "x" (test.ml[5,65+5]..[5,65+6])
                      pattern (test.ml[5,65+7]..[5,65+8])
                        Ppat_constant PConst_int (0,None)
                    "y" (test.ml[5,65+9]..[5,65+10])
                      pattern (test.ml[5,65+11]..[5,65+12])
                        Ppat_var "v" (test.ml[5,65+11]..[5,65+12])
                  ]
                expression (test.ml[5,65+17]..[5,65+18])
                  Pexp_ident "v" (test.ml[5,65+17]..[5,65+18])
              <case>
                pattern (test.ml[6,84+4]..[6,84+9])
                  Ppat_record Closed
                  [
                    "x" (test.ml[6,84+5]..[6,84+6]) ghost
                      pattern (test.ml[6,84+5]..[6,84+6])
                        Ppat_var "x" (test.ml[6,84+5]..[6,84+6])
                    "y" (test.ml[6,84+7]..[6,84+8]) ghost
                      pattern (test.ml[6,84+7]..[6,84+8])
                        Ppat_var "y" (test.ml[6,84+7]..[6,84+8])
                  ]
                expression (test.ml[6,84+13]..[6,84+16])
                  Pexp_apply
                  expression (test.ml[6,84+14]..[6,84+15])
                    Pexp_ident "+" (test.ml[6,84+14]..[6,84+15])
                  [
                    <arg>
                    Nolabel
                      expression (test.ml[6,84+13]..[6,84+14])
                        Pexp_ident "x" (test.ml[6,84+13]..[6,84+14])
                    <arg>
                    Nolabel
                      expression (test.ml[6,84+15]..[6,84+16])
                        Pexp_ident "y" (test.ml[6,84+15]..[6,84+16])
                  ]
            ]
      ]
  ]
  
