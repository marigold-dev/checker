(* GENERATED BY generate-endpoints SCRIPT, DO NOT EDIT BY HAND *)

open CheckerTypes
open Checker

type lazy_function_id = Ligo.int

let[@inline] lazy_id_touch = Ligo.int_from_literal "0"
let[@inline] lazy_id_create_burrow = Ligo.int_from_literal "1"
let[@inline] lazy_id_deposit_tez = Ligo.int_from_literal "2"
let[@inline] lazy_id_withdraw_tez = Ligo.int_from_literal "3"
let[@inline] lazy_id_mint_kit = Ligo.int_from_literal "4"
let[@inline] lazy_id_burn_kit = Ligo.int_from_literal "5"
let[@inline] lazy_id_activate_burrow = Ligo.int_from_literal "6"
let[@inline] lazy_id_deactivate_burrow = Ligo.int_from_literal "7"
let[@inline] lazy_id_mark_for_liquidation = Ligo.int_from_literal "8"
let[@inline] lazy_id_touch_liquidation_slices = Ligo.int_from_literal "9"
let[@inline] lazy_id_cancel_liquidation_slice = Ligo.int_from_literal "10"
let[@inline] lazy_id_touch_burrow = Ligo.int_from_literal "11"
let[@inline] lazy_id_set_burrow_delegate = Ligo.int_from_literal "12"
let[@inline] lazy_id_make_permission = Ligo.int_from_literal "13"
let[@inline] lazy_id_invalidate_all_permissions = Ligo.int_from_literal "14"
let[@inline] lazy_id_buy_kit = Ligo.int_from_literal "15"
let[@inline] lazy_id_sell_kit = Ligo.int_from_literal "16"
let[@inline] lazy_id_add_liquidity = Ligo.int_from_literal "17"
let[@inline] lazy_id_remove_liquidity = Ligo.int_from_literal "18"
let[@inline] lazy_id_liquidation_auction_place_bid = Ligo.int_from_literal "19"
let[@inline] lazy_id_liquidation_auction_reclaim_bid = Ligo.int_from_literal "20"
let[@inline] lazy_id_liquidation_auction_claim_win = Ligo.int_from_literal "21"
let[@inline] lazy_id_receive_slice_from_burrow = Ligo.int_from_literal "22"
let[@inline] lazy_id_delegation_auction_place_bid = Ligo.int_from_literal "23"
let[@inline] lazy_id_delegation_auction_claim_win = Ligo.int_from_literal "24"
let[@inline] lazy_id_delegation_auction_reclaim_bid = Ligo.int_from_literal "25"

type lazy_function = checker * Ligo.bytes -> LigoOp.operation list * checker


(* BEGIN_LIGO
   let lazy_fun_touch (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_touch (checker, (Ligo.Bytes.unpack a : unit))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_create_burrow (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_create_burrow (checker, (Ligo.Bytes.unpack a : Ligo.key_hash option))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_deposit_tez (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_deposit_tez (checker, (Ligo.Bytes.unpack a : (permission_redacted_content option * burrow_id)))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_withdraw_tez (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_withdraw_tez (checker, (Ligo.Bytes.unpack a : (permission_redacted_content * Ligo.tez * burrow_id)))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_mint_kit (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_mint_kit (checker, (Ligo.Bytes.unpack a : (permission_redacted_content * burrow_id * kit)))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_burn_kit (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_burn_kit (checker, (Ligo.Bytes.unpack a : (permission_redacted_content option * burrow_id * kit)))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_activate_burrow (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_activate_burrow (checker, (Ligo.Bytes.unpack a : (permission_redacted_content * burrow_id)))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_deactivate_burrow (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_deactivate_burrow (checker, (Ligo.Bytes.unpack a : (permission_redacted_content * burrow_id)))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_mark_for_liquidation (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_mark_for_liquidation (checker, (Ligo.Bytes.unpack a : burrow_id))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_touch_liquidation_slices (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_touch_liquidation_slices (checker, (Ligo.Bytes.unpack a : leaf_ptr list))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_cancel_liquidation_slice (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_cancel_liquidation_slice (checker, (Ligo.Bytes.unpack a : (permission_redacted_content * leaf_ptr)))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_touch_burrow (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_touch_burrow (checker, (Ligo.Bytes.unpack a : burrow_id))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_set_burrow_delegate (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_set_burrow_delegate (checker, (Ligo.Bytes.unpack a : (permission_redacted_content * burrow_id * Ligo.key_hash option)))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_make_permission (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_make_permission (checker, (Ligo.Bytes.unpack a : (permission_redacted_content * burrow_id * rights)))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_invalidate_all_permissions (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_invalidate_all_permissions (checker, (Ligo.Bytes.unpack a : (permission_redacted_content * burrow_id)))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_buy_kit (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_buy_kit (checker, (Ligo.Bytes.unpack a : (kit * Ligo.timestamp)))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_sell_kit (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_sell_kit (checker, (Ligo.Bytes.unpack a : (kit * Ligo.tez * Ligo.timestamp)))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_add_liquidity (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_add_liquidity (checker, (Ligo.Bytes.unpack a : (kit * Ligo.nat * Ligo.timestamp)))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_remove_liquidity (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_remove_liquidity (checker, (Ligo.Bytes.unpack a : (Ligo.nat * Ligo.tez * kit * Ligo.timestamp)))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_liquidation_auction_place_bid (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_liquidation_auction_place_bid (checker, (Ligo.Bytes.unpack a : kit))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_liquidation_auction_reclaim_bid (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_liquidation_auction_reclaim_bid (checker, (Ligo.Bytes.unpack a : liquidation_auction_bid))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_liquidation_auction_claim_win (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_liquidation_auction_claim_win (checker, (Ligo.Bytes.unpack a : liquidation_auction_bid))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_receive_slice_from_burrow (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_receive_slice_from_burrow (checker, (Ligo.Bytes.unpack a : unit))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_delegation_auction_place_bid (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_delegation_auction_place_bid (checker, (Ligo.Bytes.unpack a : unit))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_delegation_auction_claim_win (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_delegation_auction_claim_win (checker, (Ligo.Bytes.unpack a : (delegation_auction_bid * Ligo.key_hash)))
   END_LIGO *)

(* BEGIN_LIGO
   let lazy_fun_delegation_auction_reclaim_bid (checker, params: checker * Ligo.bytes): LigoOp.operation list * checker =
    endpoint_delegation_auction_reclaim_bid (checker, (Ligo.Bytes.unpack a : delegation_auction_bid))
   END_LIGO *)

let callLazyFunction (checker: checker) (p: checker_params) (lookup: lazy_function_id -> lazy_function) : LigoOp.operation list * checker =
  (* BEGIN_LIGO
     let (fid, param) = match p with
       | Touch a -> (lazy_id_touch, Ligo.Bytes.pack (deticketify_touch a))
       | CreateBurrow a -> (lazy_id_create_burrow, Ligo.Bytes.pack (deticketify_create_burrow a))
       | DepositTez a -> (lazy_id_deposit_tez, Ligo.Bytes.pack (deticketify_deposit_tez a))
       | WithdrawTez a -> (lazy_id_withdraw_tez, Ligo.Bytes.pack (deticketify_withdraw_tez a))
       | MintKit a -> (lazy_id_mint_kit, Ligo.Bytes.pack (deticketify_mint_kit a))
       | BurnKit a -> (lazy_id_burn_kit, Ligo.Bytes.pack (deticketify_burn_kit a))
       | ActivateBurrow a -> (lazy_id_activate_burrow, Ligo.Bytes.pack (deticketify_activate_burrow a))
       | DeactivateBurrow a -> (lazy_id_deactivate_burrow, Ligo.Bytes.pack (deticketify_deactivate_burrow a))
       | MarkForLiquidation a -> (lazy_id_mark_for_liquidation, Ligo.Bytes.pack (deticketify_mark_for_liquidation a))
       | TouchLiquidationSlices a -> (lazy_id_touch_liquidation_slices, Ligo.Bytes.pack (deticketify_touch_liquidation_slices a))
       | CancelLiquidationSlice a -> (lazy_id_cancel_liquidation_slice, Ligo.Bytes.pack (deticketify_cancel_liquidation_slice a))
       | TouchBurrow a -> (lazy_id_touch_burrow, Ligo.Bytes.pack (deticketify_touch_burrow a))
       | SetBurrowDelegate a -> (lazy_id_set_burrow_delegate, Ligo.Bytes.pack (deticketify_set_burrow_delegate a))
       | MakePermission a -> (lazy_id_make_permission, Ligo.Bytes.pack (deticketify_make_permission a))
       | InvalidateAllPermissions a -> (lazy_id_invalidate_all_permissions, Ligo.Bytes.pack (deticketify_invalidate_all_permissions a))
       | BuyKit a -> (lazy_id_buy_kit, Ligo.Bytes.pack (deticketify_buy_kit a))
       | SellKit a -> (lazy_id_sell_kit, Ligo.Bytes.pack (deticketify_sell_kit a))
       | AddLiquidity a -> (lazy_id_add_liquidity, Ligo.Bytes.pack (deticketify_add_liquidity a))
       | RemoveLiquidity a -> (lazy_id_remove_liquidity, Ligo.Bytes.pack (deticketify_remove_liquidity a))
       | LiquidationAuctionPlaceBid a -> (lazy_id_liquidation_auction_place_bid, Ligo.Bytes.pack (deticketify_liquidation_auction_place_bid a))
       | LiquidationAuctionReclaimBid a -> (lazy_id_liquidation_auction_reclaim_bid, Ligo.Bytes.pack (deticketify_liquidation_auction_reclaim_bid a))
       | LiquidationAuctionClaimWin a -> (lazy_id_liquidation_auction_claim_win, Ligo.Bytes.pack (deticketify_liquidation_auction_claim_win a))
       | ReceiveSliceFromBurrow a -> (lazy_id_receive_slice_from_burrow, Ligo.Bytes.pack (deticketify_receive_slice_from_burrow a))
       | DelegationAuctionPlaceBid a -> (lazy_id_delegation_auction_place_bid, Ligo.Bytes.pack (deticketify_delegation_auction_place_bid a))
       | DelegationAuctionClaimWin a -> (lazy_id_delegation_auction_claim_win, Ligo.Bytes.pack (deticketify_delegation_auction_claim_win a))
       | DelegationAuctionReclaimBid a -> (lazy_id_delegation_auction_reclaim_bid, Ligo.Bytes.pack (deticketify_delegation_auction_reclaim_bid a))
     in (lookup fid) (checker, param)
     END_LIGO *)
  (* BEGIN_OCAML *)
  match p with
  | Touch a -> endpoint_touch (checker, (deticketify_touch a))
  | CreateBurrow a -> endpoint_create_burrow (checker, (deticketify_create_burrow a))
  | DepositTez a -> endpoint_deposit_tez (checker, (deticketify_deposit_tez a))
  | WithdrawTez a -> endpoint_withdraw_tez (checker, (deticketify_withdraw_tez a))
  | MintKit a -> endpoint_mint_kit (checker, (deticketify_mint_kit a))
  | BurnKit a -> endpoint_burn_kit (checker, (deticketify_burn_kit a))
  | ActivateBurrow a -> endpoint_activate_burrow (checker, (deticketify_activate_burrow a))
  | DeactivateBurrow a -> endpoint_deactivate_burrow (checker, (deticketify_deactivate_burrow a))
  | MarkForLiquidation a -> endpoint_mark_for_liquidation (checker, (deticketify_mark_for_liquidation a))
  | TouchLiquidationSlices a -> endpoint_touch_liquidation_slices (checker, (deticketify_touch_liquidation_slices a))
  | CancelLiquidationSlice a -> endpoint_cancel_liquidation_slice (checker, (deticketify_cancel_liquidation_slice a))
  | TouchBurrow a -> endpoint_touch_burrow (checker, (deticketify_touch_burrow a))
  | SetBurrowDelegate a -> endpoint_set_burrow_delegate (checker, (deticketify_set_burrow_delegate a))
  | MakePermission a -> endpoint_make_permission (checker, (deticketify_make_permission a))
  | InvalidateAllPermissions a -> endpoint_invalidate_all_permissions (checker, (deticketify_invalidate_all_permissions a))
  | BuyKit a -> endpoint_buy_kit (checker, (deticketify_buy_kit a))
  | SellKit a -> endpoint_sell_kit (checker, (deticketify_sell_kit a))
  | AddLiquidity a -> endpoint_add_liquidity (checker, (deticketify_add_liquidity a))
  | RemoveLiquidity a -> endpoint_remove_liquidity (checker, (deticketify_remove_liquidity a))
  | LiquidationAuctionPlaceBid a -> endpoint_liquidation_auction_place_bid (checker, (deticketify_liquidation_auction_place_bid a))
  | LiquidationAuctionReclaimBid a -> endpoint_liquidation_auction_reclaim_bid (checker, (deticketify_liquidation_auction_reclaim_bid a))
  | LiquidationAuctionClaimWin a -> endpoint_liquidation_auction_claim_win (checker, (deticketify_liquidation_auction_claim_win a))
  | ReceiveSliceFromBurrow a -> endpoint_receive_slice_from_burrow (checker, (deticketify_receive_slice_from_burrow a))
  | DelegationAuctionPlaceBid a -> endpoint_delegation_auction_place_bid (checker, (deticketify_delegation_auction_place_bid a))
  | DelegationAuctionClaimWin a -> endpoint_delegation_auction_claim_win (checker, (deticketify_delegation_auction_claim_win a))
  | DelegationAuctionReclaimBid a -> endpoint_delegation_auction_reclaim_bid (checker, (deticketify_delegation_auction_reclaim_bid a))
(* END_OCAML *)