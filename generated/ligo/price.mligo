(* open Cfmm *)
(* open CfmmTypes *)
(* open Common *)
(* open Error *)
(* open CheckerTypes *)

(* If COLLATERAL = TEZ then
 *   KIT/CHF = TEZ/CHF (from index)
 *           * CTEZ/TEZ (from ctez)
 *           * KIT/CTEZ (from cfmm)
*)
[@inline] let calculate_kit_in_tok
    (state_cfmm: cfmm)
    (state_last_ctez_in_tez: ratio option)
    (state_external_contracts: external_contracts)
  : (ratio * operation list) =
  (* 1. Get the price of kit in ctez from the cfmm. To avoid having cfmm users
   *    trying to manipulate the price, we use the last price of kit in ctez
   *    observed, not the one in the current block. *)
  let { num = num_ctez; den = den_kit; } = cfmm_kit_in_ctok_in_prev_block state_cfmm in
  (* 2. Get the price of ctez in tez from storage (last observed). Use tez/ctez
   *    = 1 as the default price if none was observed. *)
  let { num = num_tez; den = den_ctez; } = match state_last_ctez_in_tez with
    | None -> one_ratio
    | Some price -> price in
  (* 3. kit_in_tez = kit_in_ctez * ctez_in_tez *)
  let price =
    { num = mul_int_int num_ctez num_tez;
      den = mul_int_int den_kit den_ctez;
    } in

  (* Create an operation to ask the ctez cfmm to send updated values. Emit
   * this operation next to the one requesting prices from oracles, at the
   * end, so that the system parameters do not change between touching
   * different slices. *)
  let op_ctez_price =
    let cb = match (Tezos.get_entrypoint_opt "%receive_ctez_marginal_price" (Tezos.get_self_address ()) : ((nat * nat) contract) option) with
      | Some cb -> cb
      | None -> (failwith error_GetEntrypointOptFailureReceiveCtezMarginalPrice : (nat * nat) contract) in
    Tezos.transaction
      cb
      (0mutez)
      (get_ctez_cfmm_price_entrypoint state_external_contracts) in

  (price, [op_ctez_price])