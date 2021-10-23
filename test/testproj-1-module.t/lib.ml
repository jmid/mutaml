let rec fac n = match n with
  | 0 -> 1
  | _ -> n * fac (n-1)

let rec sum n = match n with
  | 0 -> 0
  | _ -> n + sum (n-1)

let greeting s = "Hello, " ^ s

(* Monte Carlo simulation

   inside   ~   pi * r * r
  --------  ~   ----------    with r=1
   total            4

=> pi ~ 4 * inside / total
*)

let pi total =
  let rec loop n inside =
    if n = 0 then
      4. *. (float_of_int inside /. float_of_int total)
    else
      let x = 1.0 -. Random.float 2.0 in
      let y = 1.0 -. Random.float 2.0 in
      if x *. x +. y *. y <= 1.
      then loop (n-1) (inside+1)
      else loop (n-1) (inside)
  in
  loop total 0
