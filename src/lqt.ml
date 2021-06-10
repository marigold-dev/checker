open Common

type lqt = Ligo.nat

let[@inline] lqt_decimal_digits = Ligo.nat_from_literal "6n"
let[@inline] lqt_scaling_factor_int = Ligo.int_from_literal "1_000_000"
let[@inline] lqt_scaling_factor_nat = Ligo.nat_from_literal "1_000_000n"

(* Basic arithmetic operations. *)
let[@inline] lqt_add (x: lqt) (y: lqt) = Ligo.add_nat_nat x y
let lqt_sub (x: lqt) (y: lqt) =
  match Ligo.is_nat (Ligo.sub_nat_nat x y) with
  | Some n -> n
  | None -> (failwith "Lqt.lqt_sub: negative" : lqt)

let[@inline] lqt_zero = Ligo.nat_from_literal "0n"
let[@inline] lqt_one = lqt_scaling_factor_nat

(* Conversions to/from other types. *)
let[@inline] lqt_of_denomination (amnt: Ligo.nat) : lqt = amnt
let[@inline] lqt_to_denomination_int (amnt: lqt) : Ligo.int = Ligo.int amnt
let[@inline] lqt_to_denomination_nat (amnt: lqt) : Ligo.nat = amnt

let lqt_of_fraction_ceil (x_num: Ligo.int) (x_den: Ligo.int) : lqt =
  assert (Ligo.gt_int_int x_den (Ligo.int_from_literal "0"));
  if Ligo.lt_int_int x_num (Ligo.int_from_literal "0")
  then (failwith "Lqt.lqt_of_fraction_ceil: negative" : lqt)
  else Ligo.abs (cdiv_int_int (Ligo.mul_int_int x_num lqt_scaling_factor_int) x_den)

let lqt_of_fraction_floor (x_num: Ligo.int) (x_den: Ligo.int) : lqt =
  assert (Ligo.gt_int_int x_den (Ligo.int_from_literal "0"));
  if Ligo.lt_int_int x_num (Ligo.int_from_literal "0")
  then (failwith "Lqt.lqt_of_fraction_floor: negative" : lqt)
  else Ligo.abs (fdiv_int_int (Ligo.mul_int_int x_num lqt_scaling_factor_int) x_den)

(* BEGIN_OCAML *)
open Ratio
let[@inline] lqt_to_ratio (amnt: lqt) : ratio = make_real_unsafe (Ligo.int amnt) lqt_scaling_factor_int

let lqt_compare x y = compare_nat x y

let show_lqt amnt =
  let zfill s width = match Stdlib.(width - (String.length s)) with
    | to_fill when to_fill <= 0 -> s
    | to_fill -> (String.make to_fill '0') ^ s
  in
  let as_string =
    if lqt_decimal_digits = Ligo.nat_from_literal "0n" then
      Ligo.string_of_nat amnt
    else
      let d, r = Option.get (Ligo.ediv_nat_nat amnt lqt_scaling_factor_nat) in
      let lqt_decimal_digits = Stdlib.int_of_string (Ligo.string_of_nat lqt_decimal_digits) in (* little hacky *)
      (Ligo.string_of_nat d) ^ "." ^ zfill (Ligo.string_of_nat r) lqt_decimal_digits
  in as_string ^ "lqt"

let pp_lqt ppf amnt = Format.fprintf ppf "%s" (show_lqt amnt)
(* END_OCAML *)