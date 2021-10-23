open OUnit2

let tests = "Code test suite" >::: [
    "fac5" >:: (fun _ -> assert_equal 120 (Lib.fac 5));
    "sum5" >:: (fun _ -> assert_equal 15 (Lib.sum 5));
    "greetFinn" >:: (fun _ -> assert_equal "Hello, Finn" (Lib.greeting "Finn"));
    "pi-10mill" >:: (fun _ ->
                       let pi = Lib.pi 10_000 in
                       OUnit2.assert_bool "3.14 <= pi" (3.14 <= pi);
                       OUnit2.assert_bool "pi <= 3.143" (pi <= 3.143));
]

let () = run_test_tt_main tests
