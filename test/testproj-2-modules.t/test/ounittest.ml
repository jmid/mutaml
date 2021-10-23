(* These tests use OUnit *)
open OUnit2

let tests = "Code test suite" >::: [
    "fac5" >:: (fun _ -> assert_equal 120 (Lib1.fac 5));
    "sum5" >:: (fun _ -> assert_equal 15 (Lib2.sum 5));
    (*"fac-equal" >:: (fun _ -> assert_equal (Lib1.fac 5) (Lib2.fac 5));*)
]

let () = run_test_tt_main tests
