let rec fac n = match n with
  | 0 -> 1
  | _ -> n * fac (n-1)

let rec sum n = match n with
  | 0 -> 0
  | _ -> n + sum (n-1)
