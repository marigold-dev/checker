type lqt = nat

[@inline] let lqt_scaling_factor_int = (1000000)
[@inline] let lqt_scaling_factor_nat = 1000000n

(* Basic arithmetic operations. *)
[@inline] let lqt_add (x: lqt) (y: lqt) = add_nat_nat x y
let lqt_sub (x: lqt) (y: lqt) =
  match is_nat (sub_nat_nat x y) with
  | Some n -> n
  | None -> (failwith internalError_LqtSubNegative : lqt)

[@inline] let lqt_min (x: lqt) (y: lqt) = if leq_nat_nat x y then x else y
[@inline] let lqt_max (x: lqt) (y: lqt) = if geq_nat_nat x y then x else y

[@inline] let lqt_zero = 0n
[@inline] let lqt_one = lqt_scaling_factor_nat

(* Conversions to/from other types. *)
[@inline] let lqt_of_denomination (amnt: nat) : lqt = amnt
[@inline] let lqt_to_denomination_int (amnt: lqt) : int = int amnt
[@inline] let lqt_to_denomination_nat (amnt: lqt) : nat = amnt

let lqt_of_fraction_ceil (x_num: int) (x_den: int) : lqt =

  if lt_int_int x_num ((0))
  then (failwith internalError_LqtOfFractionCeilNegative : lqt)
  else abs (cdiv_int_int (mul_int_int x_num lqt_scaling_factor_int) x_den)

let lqt_of_fraction_floor (x_num: int) (x_den: int) : lqt =

  if lt_int_int x_num ((0))
  then (failwith internalError_LqtOfFractionFloorNegative : lqt)
  else abs (fdiv_int_int (mul_int_int x_num lqt_scaling_factor_int) x_den)

[@inline] let lqt_scale (amnt: lqt) (fp: fixedpoint) =
  lqt_of_fraction_floor
    (mul_int_nat (fixedpoint_to_raw fp) amnt)
    (mul_int_int fixedpoint_scaling_factor_int lqt_scaling_factor_int)

[@inline] let geq_lqt_lqt = geq_nat_nat
[@inline] let leq_lqt_lqt = leq_nat_nat

[@inline] let lt_lqt_lqt = lt_nat_nat
[@inline] let gt_lqt_lqt = gt_nat_nat

[@inline] let eq_lqt_lqt = eq_nat_nat
