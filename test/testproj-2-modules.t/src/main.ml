let print_usage_and_exit () =
  let () = Printf.printf "Usage: %s somenumber\n" (Sys.argv.(0)) in
  exit 1

let _ =
  if Array.length Sys.argv != 2
  then
    print_usage_and_exit ()
  else
    try
      let i = int_of_string Sys.argv.(1) in
      let () = Printf.printf "Factorial of %i is %i\n" i (Lib1.fac i) in
      let () = Printf.printf "Sum of 1+...+%i is %i\n" i (Lib2.sum i) in
      ()
    with (Failure _) ->
      print_usage_and_exit ()

