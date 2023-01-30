(* Automatically generated by checker_tools.builder. DO NOT EDIT DIRECTLY! *)

(* open Common *)
(* open FixedPoint *)

(** Calculate the current target based on the current quantity, the current
    index, and the current price of kit in tok.
    {[
      target_{i+1} = FLOOR (q_{i+1} * index_{i+1} / kit_in_tok_{i+1})
    ]}
*)
[@inline] let compute_current_target (current_q: fixedpoint) (current_index: fixedpoint) (current_kit_in_tok: ratio) : fixedpoint =
  let { num = num; den = den; } = current_kit_in_tok in
  fixedpoint_of_ratio_floor
    (make_ratio
       (mul_int_int
          den
          (mul_int_int
             (fixedpoint_to_raw current_q)
             (fixedpoint_to_raw current_index)
          )
       )
       (mul_int_int
          num
          (mul_int_int
             fixedpoint_scaling_factor_int
             fixedpoint_scaling_factor_int
          )
       )
    )