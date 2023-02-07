#include "../src/main.mligo"

let rec init (x, y : int * int list) : (int list) =
  if x = 0 then y else init (x-1, 1 :: y)

let apply_times f n e = 
  let a = init(n, []) in
  let () = Test.log ("expected", a) in
  let doit (acc, _i : int * int) : int = f acc in
  List.fold_left doit e a


let test = 
  let a = apply_times (fun x -> x + 10) 10 0 in
  let () = Test.log ("a", a) in
  ()
