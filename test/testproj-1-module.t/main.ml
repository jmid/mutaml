let print_usage_and_exit () =
  let () = Printf.printf "Usage: %s something somenumber\n" (Sys.argv.(0)) in
  exit 1

let _ =
  if Array.length Sys.argv != 3
  then
    print_usage_and_exit ()
  else
    try
      let s = Sys.argv.(1) in
      let i = int_of_string Sys.argv.(2) in
      let () = Printf.printf "%s\n" (Lib.greeting s) in
      let () = Printf.printf "Factorial of %i is %i\n" i (Lib.fac i) in
      let () = Printf.printf "Sum of 1+...+%i is %i\n" i (Lib.sum i) in
      let () = Random.self_init () in
      let () = Printf.printf "Pi approximation: %f\n" (Lib.pi (i * 1_000_000)) in
      ()
    with (Failure _) ->
      print_usage_and_exit ()

