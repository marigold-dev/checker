open OUnit2
open TestCommon
open Ratio
open Kit
open Cfmm
open Tickets
open CfmmTypes
open Error

let property_test_count = 100

(* Issue an arbitrary amount of kit (checker-issued) *)
let arb_positive_kit_token = QCheck.map kit_issue TestArbitrary.arb_positive_kit

(* Compute the current price of kit in tez, as estimated using the ratio of tez and kit
 * currently in the cfmm contract. *)
let cfmm_kit_in_tez (u: cfmm) =
  div_ratio (ratio_of_tez u.tez) (kit_to_ratio u.kit)

(* Compute the current product of kit and tez, using the current contents of the cfmm
 * contract. *)
let cfmm_kit_times_tez (u: cfmm) =
  mul_ratio (ratio_of_tez u.tez) (kit_to_ratio u.kit)

(* Reveal the current number of liquidity tokens extant. *)
let cfmm_liquidity_tokens_extant (u: cfmm) = u.lqt

let eq_cfmm (u1: cfmm) (u2: cfmm) : bool =
  Ligo.eq_tez_tez u1.tez u2.tez
  && kit_compare u1.kit u2.kit = 0
  && Ligo.eq_nat_nat u1.lqt u2.lqt
  && eq_ratio_ratio u1.kit_in_tez_in_prev_block u2.kit_in_tez_in_prev_block
  && Ligo.eq_nat_nat u1.last_level u2.last_level

(* amount > 0xtz *)
(* max_kit_deposited = CEIL{kit * amount / tez} *)
(* min_lqt_minted = FLOOR{lqt * amount / tez} *)
(* NB: some values are fixed *)
let make_inputs_for_add_liquidity_to_succeed_no_accrual =
  QCheck.map
    (* NOTE: this could still give us tough numbers I think. The liquidity created can be zero for example. *)
    (fun ((tez, kit, lqt, cfmm), amount) ->
       let pending_accrual = (Ligo.tez_from_literal "0mutez") in
       let max_kit_deposited =
         let { num = x_num; den = x_den; } =
           mul_ratio (kit_to_ratio kit) (make_ratio (Common.tez_to_mutez amount) (Common.tez_to_mutez tez)) in
         kit_of_fraction_ceil x_num x_den
       in
       let min_lqt_minted =
         let { num = x_num; den = x_den; } =
           mul_ratio (ratio_of_nat lqt) (make_ratio (Common.tez_to_mutez amount) (Common.tez_to_mutez tez)) in
         fraction_to_nat_floor x_num x_den
       in
       let deadline = Ligo.add_timestamp_int !Ligo.Tezos.now (Ligo.int_from_literal "1") in (* always one second later *)
       (cfmm, amount, pending_accrual, max_kit_deposited, min_lqt_minted, deadline)
    )
    (QCheck.pair (arbitrary_non_empty_cfmm one_ratio !Ligo.Tezos.level) TestArbitrary.arb_positive_tez)

(* NB: some values are fixed *)
let make_inputs_for_remove_liquidity_to_succeed =
  QCheck.map
    (* NOTE: this could still give us tough numbers I think. *)
    (fun ((tez, kit, lqt, cfmm), factor) ->
       let amount = (Ligo.tez_from_literal "0mutez") in

       let lqt_to_burn =
         let { num = x_num; den = x_den; } =
           div_ratio (ratio_of_nat lqt) (ratio_of_int (Ligo.int_from_literal (string_of_int factor))) in
         fraction_to_nat_floor x_num x_den
       in

       (* let lqt_to_burn = if lqt_to_burn = Ligo.int_from_literal 0 then Ligo.int_from_literal 1 else lqt_to_burn in *)

       let lqt_burned = lqt_to_burn in
       let min_tez_withdrawn =
         let { num = x_num; den = x_den; } =
           div_ratio (mul_ratio (ratio_of_tez tez) (ratio_of_nat lqt_to_burn)) (ratio_of_nat lqt) in
         fraction_to_tez_floor x_num x_den
       in
       let min_kit_withdrawn =
         let { num = x_num; den = x_den; } =
           div_ratio (mul_ratio (kit_to_ratio kit) (ratio_of_nat lqt_to_burn)) (ratio_of_nat lqt) in
         kit_of_fraction_floor x_num x_den
       in

       (* NOTE: We cannot just factor down the number of liquidity tokens
        * extant for this operation. When we remove liquidity we round the
        * amounts of kit and tez to return towards zero; they might end up
        * being zero because of this, which would make remove_liquidity fail.
        * We make the generator thus ensure that at least 1mukit and 1mutez
        * will be returned. *)
       let lqt_burned, min_tez_withdrawn, min_kit_withdrawn =
         if lqt_to_burn = Ligo.nat_from_literal "0n" || min_tez_withdrawn = (Ligo.tez_from_literal "0mutez") || min_kit_withdrawn = kit_zero then
           let lqt_to_burn =
             let least_kit_percentage = (div_ratio (kit_to_ratio (kit_of_mukit (Ligo.nat_from_literal "1n"))) (kit_to_ratio kit)) in
             let least_tez_percentage = make_ratio (Common.tez_to_mutez (Ligo.tez_from_literal "1mutez")) (Common.tez_to_mutez tez) in
             let as_q = (mul_ratio (ratio_of_nat lqt) (max_ratio least_kit_percentage least_tez_percentage)) in
             Option.get (Ligo.is_nat (Common.cdiv_int_int as_q.num as_q.den)) in
           let lqt_burned = lqt_to_burn in
           let min_tez_withdrawn =
             let { num = x_num; den = x_den; } =
               div_ratio (mul_ratio (ratio_of_tez tez) (ratio_of_nat lqt_to_burn)) (ratio_of_nat lqt) in
             fraction_to_tez_floor x_num x_den
           in
           let min_kit_withdrawn =
             let { num = x_num; den = x_den; } =
               div_ratio (mul_ratio (kit_to_ratio kit) (ratio_of_nat lqt_to_burn)) (ratio_of_nat lqt) in
             kit_of_fraction_floor x_num x_den
           in
           (lqt_burned, min_tez_withdrawn, min_kit_withdrawn)
         else
           lqt_burned, min_tez_withdrawn, min_kit_withdrawn in

       let deadline = Ligo.add_timestamp_int !Ligo.Tezos.now (Ligo.int_from_literal "1") in (* always one second later *)
       (cfmm, amount, lqt_burned, min_tez_withdrawn, min_kit_withdrawn, deadline)
    )
    (QCheck.pair (arbitrary_non_empty_cfmm one_ratio !Ligo.Tezos.level) QCheck.pos_int)

(* TODO: Write down for which inputs are the cfmm functions to succeed and
 * test the corresponding edge cases. *)

(* ************************************************************************* *)
(*                     buy_kit (property-based tests)                        *)
(* ************************************************************************* *)

(* If successful, cfmm_buy_kit always increases the ratio of
 * total_tez/total_kit, since it adds tez and removes kit. *)
let test_buy_kit_increases_price =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_buy_kit_increases_price"
    ~count:property_test_count
    make_inputs_for_buy_kit_to_succeed
  @@ fun (cfmm, amount, min_kit_expected, deadline) ->
  let _bought_kit, new_cfmm =
    cfmm_buy_kit cfmm amount min_kit_expected deadline in
  gt_ratio_ratio (cfmm_kit_in_tez new_cfmm) (cfmm_kit_in_tez cfmm)

(* If successful, cfmm_buy_kit always increases the product
 * total_tez * total_kit, because of the fees. *)
let test_buy_kit_increases_product =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_buy_kit_increases_product"
    ~count:property_test_count
    make_inputs_for_buy_kit_to_succeed
  @@ fun (cfmm, amount, min_kit_expected, deadline) ->
  let _bought_kit, new_cfmm =
    cfmm_buy_kit cfmm amount min_kit_expected deadline in
  gt_ratio_ratio (cfmm_kit_times_tez new_cfmm) (cfmm_kit_times_tez cfmm)

(* Successful or not, cfmm_buy_kit should never affect the number of
 * liquidity tokens extant. *)
let test_buy_kit_does_not_affect_liquidity =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_buy_kit_does_not_affect_liquidity"
    ~count:property_test_count
    make_inputs_for_buy_kit_to_succeed
  @@ fun (cfmm, amount, min_kit_expected, deadline) ->
  let _bought_kit, new_cfmm =
    cfmm_buy_kit cfmm amount min_kit_expected deadline in
  cfmm_liquidity_tokens_extant new_cfmm = cfmm_liquidity_tokens_extant cfmm

(* If successful, cfmm_buy_kit respects min_kit_expected. *)
let test_buy_kit_respects_min_kit_expected =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_buy_kit_respects_min_kit_expected"
    ~count:property_test_count
    make_inputs_for_buy_kit_to_succeed
  @@ fun (cfmm, amount, min_kit_expected, deadline) ->
  let bought_kit, _new_cfmm =
    cfmm_buy_kit cfmm amount min_kit_expected deadline in
  bought_kit >= min_kit_expected

(* If successful, cfmm_buy_kit doesn't lose kit.
 * Note that, because kits are isomorphic to naturals,
 * this also means that cfmm_buy_kit doesn't return more kit than cfmm had. *)
let test_buy_kit_preserves_kit =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_buy_kit_preserves_kit"
    ~count:property_test_count
    make_inputs_for_buy_kit_to_succeed
  @@ fun (cfmm, amount, min_kit_expected, deadline) ->
  let bought_kit, new_cfmm =
    cfmm_buy_kit cfmm amount min_kit_expected deadline in
  cfmm.kit = kit_add new_cfmm.kit bought_kit

(* If successful, cfmm_buy_kit doesn't lose tez. *)
let test_buy_kit_preserves_tez =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_buy_kit_preserves_tez"
    ~count:property_test_count
    make_inputs_for_buy_kit_to_succeed
  @@ fun (cfmm, amount, min_kit_expected, deadline) ->
  let _bought_kit, new_cfmm =
    cfmm_buy_kit cfmm amount min_kit_expected deadline in
  Ligo.add_tez_tez cfmm.tez amount = new_cfmm.tez

(* ************************************************************************* *)
(*                          buy_kit (unit tests)                             *)
(* ************************************************************************* *)

let buy_kit_unit_test =
  "buy kit unit test" >:: fun _ ->
    Ligo.Tezos.reset ();
    let cfmm : cfmm =
      cfmm_make_for_test
        ~tez:(Ligo.tez_from_literal "10_000_000mutez")
        ~kit:(kit_of_mukit (Ligo.nat_from_literal "5_000_000n"))
        ~lqt:(Ligo.nat_from_literal "1n")
        ~kit_in_tez_in_prev_block:one_ratio
        ~last_level:(Ligo.nat_from_literal "0n")
    in

    let expected_returned_kit = kit_of_mukit (Ligo.nat_from_literal "453_636n") in
    let expected_updated_cfmm : cfmm =
      cfmm_make_for_test
        ~tez:(Ligo.tez_from_literal "11_000_000mutez")
        ~kit:(kit_of_mukit (Ligo.nat_from_literal "4_546_364n"))
        ~lqt:(Ligo.nat_from_literal "1n")
        ~kit_in_tez_in_prev_block:(ratio_of_int (Ligo.int_from_literal "2"))
        ~last_level:(Ligo.nat_from_literal "1n")
    in

    (* Low expectations and on time (lax): pass *)
    Ligo.Tezos.reset ();
    Ligo.Tezos.new_transaction ~seconds_passed:1 ~blocks_passed:1 ~sender:alice_addr ~amount:(Ligo.tez_from_literal "0mutez");
    let returned_kit, updated_cfmm =
      cfmm_buy_kit
        cfmm
        (Ligo.tez_from_literal "1_000_000mutez")
        (kit_of_mukit (Ligo.nat_from_literal "1n"))
        (Ligo.timestamp_from_seconds_literal 10) in
    assert_equal ~printer:show_kit expected_returned_kit returned_kit;
    assert_equal ~printer:show_cfmm ~cmp:eq_cfmm expected_updated_cfmm updated_cfmm;

    (* Low expectations and on time (tight): pass *)
    Ligo.Tezos.reset ();
    Ligo.Tezos.new_transaction ~seconds_passed:1 ~blocks_passed:1 ~sender:alice_addr ~amount:(Ligo.tez_from_literal "0mutez");
    let returned_kit, updated_cfmm =
      cfmm_buy_kit
        cfmm
        (Ligo.tez_from_literal "1_000_000mutez")
        (kit_of_mukit (Ligo.nat_from_literal "453_636n"))
        (Ligo.timestamp_from_seconds_literal 2) in
    assert_equal ~printer:show_kit expected_returned_kit returned_kit;
    assert_equal ~printer:show_cfmm ~cmp:eq_cfmm expected_updated_cfmm updated_cfmm;

    (* High expectations but on time (tight): fail *)
    Ligo.Tezos.reset ();
    Ligo.Tezos.new_transaction ~seconds_passed:1 ~blocks_passed:1 ~sender:alice_addr ~amount:(Ligo.tez_from_literal "0mutez");
    assert_raises
      (Failure (Ligo.string_of_int error_BuyKitPriceFailure))
      (fun () ->
         cfmm_buy_kit
           cfmm
           (Ligo.tez_from_literal "1_000_000mutez")
           (kit_of_mukit (Ligo.nat_from_literal "453_637n"))
           (Ligo.timestamp_from_seconds_literal 2)
      );

    (* Low expectations but too late (tight): fail *)
    Ligo.Tezos.reset ();
    Ligo.Tezos.new_transaction ~seconds_passed:1 ~blocks_passed:1 ~sender:alice_addr ~amount:(Ligo.tez_from_literal "0mutez");
    assert_raises
      (Failure (Ligo.string_of_int error_CfmmTooLate))
      (fun () ->
         cfmm_buy_kit
           cfmm
           (Ligo.tez_from_literal "1_000_000mutez")
           (kit_of_mukit (Ligo.nat_from_literal "453_636n"))
           (Ligo.timestamp_from_seconds_literal 1)
      );

    (* No tez given: fail *)
    Ligo.Tezos.reset ();
    Ligo.Tezos.new_transaction ~seconds_passed:1 ~blocks_passed:1 ~sender:alice_addr ~amount:(Ligo.tez_from_literal "0mutez");
    assert_raises
      (Failure (Ligo.string_of_int error_BuyKitNoTezGiven))
      (fun () ->
         cfmm_buy_kit
           cfmm
           (Ligo.tez_from_literal "0mutez")
           (kit_of_mukit (Ligo.nat_from_literal "1n"))
           (Ligo.timestamp_from_seconds_literal 10)
      );

    (* No kit expected: fail *)
    Ligo.Tezos.reset ();
    Ligo.Tezos.new_transaction ~seconds_passed:1 ~blocks_passed:1 ~sender:alice_addr ~amount:(Ligo.tez_from_literal "0mutez");
    assert_raises
      (Failure (Ligo.string_of_int error_BuyKitTooLowExpectedKit))
      (fun () ->
         cfmm_buy_kit
           cfmm
           (Ligo.tez_from_literal "1mutez")
           (kit_of_mukit (Ligo.nat_from_literal "0n"))
           (Ligo.timestamp_from_seconds_literal 10)
      )

(* ************************************************************************* *)
(*                     sell_kit (property-based tests)                       *)
(* ************************************************************************* *)

(* If successful, cfmm_sell_kit always decreases the ratio of
 * total_tez/total_kit, since it removes tez and adds kit. *)
let test_sell_kit_decreases_price =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_sell_kit_decreases_price"
    ~count:property_test_count
    make_inputs_for_sell_kit_to_succeed
  @@ fun (cfmm, tez_amount, kit_amount, min_tez_expected, deadline) ->
  let _bought_tez, new_cfmm =
    cfmm_sell_kit cfmm tez_amount kit_amount min_tez_expected deadline in
  lt_ratio_ratio (cfmm_kit_in_tez new_cfmm) (cfmm_kit_in_tez cfmm)

(* If successful, cfmm_sell_kit always increases the product
 * total_tez * total_kit, because of the fees. *)
let test_sell_kit_increases_product =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_sell_kit_increases_product"
    ~count:property_test_count
    make_inputs_for_sell_kit_to_succeed
  @@ fun (cfmm, tez_amount, kit_amount, min_tez_expected, deadline) ->
  let _bought_tez, new_cfmm =
    cfmm_sell_kit cfmm tez_amount kit_amount min_tez_expected deadline in
  gt_ratio_ratio (cfmm_kit_times_tez new_cfmm) (cfmm_kit_times_tez cfmm)

(* Successful or not, cfmm_sell_kit should never affect the number of
 * liquidity tokens extant. *)
let test_sell_kit_does_not_affect_liquidity =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_sell_kit_does_not_affect_liquidity"
    ~count:property_test_count
    make_inputs_for_sell_kit_to_succeed
  @@ fun (cfmm, tez_amount, kit_amount, min_tez_expected, deadline) ->
  let _bought_tez, new_cfmm =
    cfmm_sell_kit cfmm tez_amount kit_amount min_tez_expected deadline in
  cfmm_liquidity_tokens_extant new_cfmm = cfmm_liquidity_tokens_extant cfmm

(* If successful, cfmm_sell_kit respects min_tez_expected. *)
let test_sell_kit_respects_min_tez_expected =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_sell_kit_respects_min_tez_expected"
    ~count:property_test_count
    make_inputs_for_sell_kit_to_succeed
  @@ fun (cfmm, tez_amount, kit_amount, min_tez_expected, deadline) ->
  let bought_tez, _new_cfmm =
    cfmm_sell_kit cfmm tez_amount kit_amount min_tez_expected deadline in
  bought_tez >= min_tez_expected

(* If successful, selling kit preserves kit. *)
let test_sell_kit_preserves_kit =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_sell_kit_preserves_kit"
    ~count:property_test_count
    make_inputs_for_sell_kit_to_succeed
  @@ fun (cfmm, tez_amount, kit_amount, min_tez_expected, deadline) ->
  let _bought_tez, new_cfmm =
    cfmm_sell_kit cfmm tez_amount kit_amount min_tez_expected deadline in
  new_cfmm.kit = kit_add cfmm.kit kit_amount

(* If successful, selling kit preserves tez. *)
let test_sell_kit_preserves_tez =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_sell_kit_preserves_tez"
    ~count:property_test_count
    make_inputs_for_sell_kit_to_succeed
  @@ fun (cfmm, tez_amount, kit_amount, min_tez_expected, deadline) ->
  let bought_tez, new_cfmm =
    cfmm_sell_kit cfmm tez_amount kit_amount min_tez_expected deadline in
  Ligo.add_tez_tez new_cfmm.tez bought_tez = cfmm.tez

(* ************************************************************************* *)
(*                          sell_kit (unit tests)                            *)
(* ************************************************************************* *)

let sell_kit_unit_test =
  "sell kit" >:: fun _ ->
    Ligo.Tezos.reset ();
    let cfmm : cfmm =
      cfmm_make_for_test
        ~tez:(Ligo.tez_from_literal "10_000_000mutez")
        ~kit:(kit_of_mukit (Ligo.nat_from_literal "5_000_000n"))
        ~lqt:(Ligo.nat_from_literal "1n")
        ~kit_in_tez_in_prev_block:one_ratio
        ~last_level:(Ligo.nat_from_literal "0n")
    in
    let expected_returned_tez = Ligo.tez_from_literal "1_663_333mutez" in
    let expected_updated_cfmm : cfmm =
      cfmm_make_for_test
        ~tez:(Ligo.tez_from_literal "8_336_667mutez")
        ~kit:(kit_of_mukit (Ligo.nat_from_literal "6_000_000n"))
        ~lqt:(Ligo.nat_from_literal "1n")
        ~kit_in_tez_in_prev_block:(ratio_of_int (Ligo.int_from_literal "2"))
        ~last_level:(Ligo.nat_from_literal "1n")
    in

    (* Low expectations and on time (lax): pass *)
    Ligo.Tezos.reset ();
    Ligo.Tezos.new_transaction ~seconds_passed:1 ~blocks_passed:1 ~sender:alice_addr ~amount:(Ligo.tez_from_literal "0mutez");
    let returned_tez, updated_cfmm =
      cfmm_sell_kit
        cfmm
        (Ligo.tez_from_literal "0mutez")
        kit_one
        (Ligo.tez_from_literal "1mutez")
        (Ligo.timestamp_from_seconds_literal 10) in
    assert_equal ~printer:Ligo.string_of_tez expected_returned_tez returned_tez;
    assert_equal ~printer:show_cfmm ~cmp:eq_cfmm expected_updated_cfmm updated_cfmm;

    (* Low expectations and on time (tight): pass *)
    Ligo.Tezos.reset ();
    Ligo.Tezos.new_transaction ~seconds_passed:1 ~blocks_passed:1 ~sender:alice_addr ~amount:(Ligo.tez_from_literal "0mutez");
    let returned_tez, updated_cfmm =
      cfmm_sell_kit
        cfmm
        (Ligo.tez_from_literal "0mutez")
        kit_one
        (Ligo.tez_from_literal "1_663_333mutez")
        (Ligo.timestamp_from_seconds_literal 2) in
    assert_equal ~printer:Ligo.string_of_tez expected_returned_tez returned_tez;
    assert_equal ~printer:show_cfmm ~cmp:eq_cfmm expected_updated_cfmm updated_cfmm;

    (* High expectations but on time (tight): fail *)
    Ligo.Tezos.reset ();
    Ligo.Tezos.new_transaction ~seconds_passed:1 ~blocks_passed:1 ~sender:alice_addr ~amount:(Ligo.tez_from_literal "0mutez");
    assert_raises
      (Failure (Ligo.string_of_int error_SellKitPriceFailure))
      (fun () ->
         cfmm_sell_kit
           cfmm
           (Ligo.tez_from_literal "0mutez")
           kit_one
           (Ligo.tez_from_literal "1_663_334mutez")
           (Ligo.timestamp_from_seconds_literal 2)
      );

    (* Low expectations but too late (tight): fail *)
    Ligo.Tezos.reset ();
    Ligo.Tezos.new_transaction ~seconds_passed:1 ~blocks_passed:1 ~sender:alice_addr ~amount:(Ligo.tez_from_literal "0mutez");
    assert_raises
      (Failure (Ligo.string_of_int error_CfmmTooLate))
      (fun () ->
         cfmm_sell_kit
           cfmm
           (Ligo.tez_from_literal "0mutez")
           kit_one
           (Ligo.tez_from_literal "1_663_333mutez")
           (Ligo.timestamp_from_seconds_literal 1)
      );

    (* No kit given: fail *)
    Ligo.Tezos.reset ();
    Ligo.Tezos.new_transaction ~seconds_passed:1 ~blocks_passed:1 ~sender:alice_addr ~amount:(Ligo.tez_from_literal "0mutez");
    assert_raises
      (Failure (Ligo.string_of_int error_SellKitNoKitGiven))
      (fun () ->
         cfmm_sell_kit
           cfmm
           (Ligo.tez_from_literal "0mutez")
           (kit_of_mukit (Ligo.nat_from_literal "0n"))
           (Ligo.tez_from_literal "1_663_333mutez")
           (Ligo.timestamp_from_seconds_literal 10)
      );

    (* No tez expected: fail *)
    Ligo.Tezos.reset ();
    Ligo.Tezos.new_transaction ~seconds_passed:1 ~blocks_passed:1 ~sender:alice_addr ~amount:(Ligo.tez_from_literal "0mutez");
    assert_raises
      (Failure (Ligo.string_of_int error_SellKitTooLowExpectedTez))
      (fun () ->
         cfmm_sell_kit
           cfmm
           (Ligo.tez_from_literal "0mutez")
           kit_one
           (Ligo.tez_from_literal "0mutez")
           (Ligo.timestamp_from_seconds_literal 10)
      );

    (* Some tez transferred: fail *)
    Ligo.Tezos.reset ();
    Ligo.Tezos.new_transaction ~seconds_passed:1 ~blocks_passed:1 ~sender:alice_addr ~amount:(Ligo.tez_from_literal "0mutez");
    assert_raises
      (Failure (Ligo.string_of_int error_SellKitNonEmptyAmount))
      (fun () ->
         cfmm_sell_kit
           cfmm
           (Ligo.tez_from_literal "10mutez")
           kit_one
           (Ligo.tez_from_literal "100mutez")
           (Ligo.timestamp_from_seconds_literal 10)
      )

(* ************************************************************************* *)
(*             add_liquidity (non-first) (property-based tests)              *)
(* ************************************************************************* *)

(* If successful, cfmm_add_liquidity never increases the ratio of
 * total_tez/total_kit (might leave it where it is or decrease it), since it
 * always rounds up the kit it keeps in the contract. If amount is a multiple
 * of the tez in the cfmm contract, then the price should remain the same,
 * hence the lack of strict monotonicity. *)
let test_add_liquidity_might_decrease_price =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_add_liquidity_might_decrease_price"
    ~count:property_test_count
    make_inputs_for_add_liquidity_to_succeed_no_accrual
  @@ fun (cfmm, amount, pending_accrual, max_kit_deposited, min_lqt_minted, deadline) ->
  let _bought_liquidity, _bought_kit, new_cfmm =
    cfmm_add_liquidity cfmm amount pending_accrual max_kit_deposited min_lqt_minted deadline in
  leq_ratio_ratio (cfmm_kit_in_tez new_cfmm) (cfmm_kit_in_tez cfmm)

(* If successful, cfmm_add_liquidity always increases the product
 * total_tez * total_kit, because we add both tez and kit. *)
let test_add_liquidity_increases_product =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_add_liquidity_increases_product"
    ~count:property_test_count
    make_inputs_for_add_liquidity_to_succeed_no_accrual
  @@ fun (cfmm, amount, pending_accrual, max_kit_deposited, min_lqt_minted, deadline) ->
  let _bought_liquidity, _bought_kit, new_cfmm =
    cfmm_add_liquidity cfmm amount pending_accrual max_kit_deposited min_lqt_minted deadline in
  gt_ratio_ratio (cfmm_kit_times_tez new_cfmm) (cfmm_kit_times_tez cfmm)

(* If successful, cfmm_add_liquidity always increases the liquidity;
 * that's what it's supposed to do. *)
let test_add_liquidity_increases_liquidity =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_add_liquidity_increases_liquidity"
    ~count:property_test_count
    make_inputs_for_add_liquidity_to_succeed_no_accrual
  @@ fun (cfmm, amount, pending_accrual, max_kit_deposited, min_lqt_minted, deadline) ->
  let _bought_liquidity, _bought_kit, new_cfmm =
    cfmm_add_liquidity cfmm amount pending_accrual max_kit_deposited min_lqt_minted deadline in
  cfmm_liquidity_tokens_extant new_cfmm > cfmm_liquidity_tokens_extant cfmm

(* If successful, cfmm_add_liquidity always deposits some kit,
 * implying kit_to_return = max_kit_deposited - kit_deposited < max_kit_deposited. *)
let test_add_liquidity_kit_to_return_lt_max_kit_deposited =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_add_liquidity_kit_to_return_lt_max_kit_deposited"
    ~count:property_test_count
    make_inputs_for_add_liquidity_to_succeed_no_accrual
  @@ fun (cfmm, amount, pending_accrual, max_kit_deposited, min_lqt_minted, deadline) ->
  let _bought_liquidity, kit_to_return, _new_cfmm =
    cfmm_add_liquidity cfmm amount pending_accrual max_kit_deposited min_lqt_minted deadline in
  kit_to_return < max_kit_deposited

(* If successful, cfmm_add_liquidity does not produce less kit than min_lqt_minted *)
let test_add_liquidity_respects_min_lqt_minted =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_add_liquidity_respects_min_lqt_minted"
    ~count:property_test_count
    make_inputs_for_add_liquidity_to_succeed_no_accrual
  @@ fun (cfmm, amount, pending_accrual, max_kit_deposited, min_lqt_minted, deadline) ->
  let lqt_minted, _bought_kit, _new_cfmm =
    cfmm_add_liquidity cfmm amount pending_accrual max_kit_deposited min_lqt_minted deadline in
  lqt_minted >= min_lqt_minted

(* If successful, cfmm_add_liquidity does not produce less kit than min_lqt_minted *)
let test_add_liquidity_respects_max_kit_deposited =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_add_liquidity_respects_max_kit_deposited"
    ~count:property_test_count
    make_inputs_for_add_liquidity_to_succeed_no_accrual
  @@ fun (cfmm, amount, pending_accrual, max_kit_deposited, min_lqt_minted, deadline) ->
  let _lqt_minted, _bought_kit, new_cfmm =
    cfmm_add_liquidity cfmm amount pending_accrual max_kit_deposited min_lqt_minted deadline in
  new_cfmm.kit <= kit_add cfmm.kit max_kit_deposited

(* ************************************************************************* *)
(*                 add_liquidity (non-first) (unit tests)                    *)
(* ************************************************************************* *)

let add_liquidity_unit_test =
  "add liquidity unit test" >:: fun _ ->
    Ligo.Tezos.reset ();
    let cfmm : cfmm =
      cfmm_make_for_test
        ~tez:(Ligo.tez_from_literal "8_336_667mutez")
        ~kit:(kit_of_mukit (Ligo.nat_from_literal "6_000_000n"))
        ~lqt:(Ligo.nat_from_literal "1n")
        ~kit_in_tez_in_prev_block:one_ratio
        ~last_level:(Ligo.nat_from_literal "0n")
    in
    let expected_returned_liquidity = Ligo.nat_from_literal "2n" in
    let expected_returned_kit = kit_of_mukit (Ligo.nat_from_literal "5_605_758n") in
    let expected_updated_cfmm : cfmm =
      cfmm_make_for_test
        ~tez:(Ligo.tez_from_literal "28_336_667mutez")
        ~kit:(kit_of_mukit (Ligo.nat_from_literal "20_394_242n"))
        ~lqt:(Ligo.nat_from_literal "3n")
        ~kit_in_tez_in_prev_block:one_ratio
        ~last_level:(Ligo.nat_from_literal "0n")
    in

    let returned_liquidity, returned_kit, updated_cfmm =
      cfmm_add_liquidity
        cfmm
        (Ligo.tez_from_literal "20_000_000mutez")
        (Ligo.tez_from_literal "0mutez")
        (kit_of_mukit (Ligo.nat_from_literal "20_000_000n"))
        (Ligo.nat_from_literal "2n")
        (Ligo.timestamp_from_seconds_literal 1) in
    assert_equal ~printer:Ligo.string_of_nat expected_returned_liquidity returned_liquidity;
    assert_equal ~printer:show_kit expected_returned_kit returned_kit;
    assert_equal ~printer:show_cfmm ~cmp:eq_cfmm expected_updated_cfmm updated_cfmm

let test_add_liquidity_failures =
  "add liquidity failure conditions" >:: fun _ ->
    Ligo.Tezos.reset ();
    let cfmm =
      cfmm_make_for_test
        ~tez:(Ligo.tez_from_literal "1000_000_000mutez")
        ~kit:(kit_of_mukit (Ligo.nat_from_literal "5000_000_000n"))
        ~lqt:(Ligo.nat_from_literal "1000n")
        ~kit_in_tez_in_prev_block:one_ratio
        ~last_level:(Ligo.nat_from_literal "0n") in
    assert_raises
      (Failure (Ligo.string_of_int error_AddLiquidityNoTezGiven))
      (fun () ->
         cfmm_add_liquidity
           cfmm
           (Ligo.tez_from_literal "0mutez")
           (Ligo.tez_from_literal "0mutez")
           (kit_of_mukit (Ligo.nat_from_literal "20_000_000n"))
           (Ligo.nat_from_literal "2n")
           (Ligo.timestamp_from_seconds_literal 1)
      );
    assert_raises
      (Failure (Ligo.string_of_int error_AddLiquidityNoKitGiven))
      (fun () ->
         cfmm_add_liquidity
           cfmm
           (Ligo.tez_from_literal "1mutez")
           (Ligo.tez_from_literal "0mutez")
           (kit_of_mukit (Ligo.nat_from_literal "0n"))
           (Ligo.nat_from_literal "2n")
           (Ligo.timestamp_from_seconds_literal 1)
      );
    assert_raises
      (Failure (Ligo.string_of_int error_AddLiquidityNoLiquidityToBeAdded))
      (fun () ->
         cfmm_add_liquidity
           cfmm
           (Ligo.tez_from_literal "1mutez")
           (Ligo.tez_from_literal "0mutez")
           (kit_of_mukit (Ligo.nat_from_literal "1n"))
           (Ligo.nat_from_literal "0n")
           (Ligo.timestamp_from_seconds_literal 1)
      )

(* ************************************************************************* *)
(*                 remove_liquidity (property-based tests)                   *)
(* ************************************************************************* *)

(* If successful, cfmm_remove_liquidity always decreases the product
 * total_tez * total_kit, because we remove both tez and kit. *)
(* NOTE: That is not entirely true, because when we remove liquidity we round
 * the amounts of kit and tez to return towards zero; they might end up being
 * zero because of this. BUT, in these cases cfmm_remove_liquidity should
 * thrown an error, so this property is expected to hold indeed, when
 * remove_liquidity succeeds. *)
let test_remove_liquidity_decreases_product =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_remove_liquidity_decreases_product"
    ~count:property_test_count
    make_inputs_for_remove_liquidity_to_succeed
  @@ fun (cfmm, amount, lqt_burned, min_tez_withdrawn, min_kit_withdrawn, deadline) ->
  let _withdrawn_tez, _withdrawn_kit, new_cfmm =
    cfmm_remove_liquidity cfmm amount lqt_burned min_tez_withdrawn min_kit_withdrawn deadline in
  leq_ratio_ratio (cfmm_kit_times_tez new_cfmm) (cfmm_kit_times_tez cfmm)

(* If successful, cfmm_remove_liquidity always decreases the liquidity;
 * that's what it's supposed to do. *)
let test_remove_liquidity_decreases_liquidity =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_remove_liquidity_decreases_liquidity"
    ~count:property_test_count
    make_inputs_for_remove_liquidity_to_succeed
  @@ fun (cfmm, amount, lqt_burned, min_tez_withdrawn, min_kit_withdrawn, deadline) ->
  let _withdrawn_tez, _withdrawn_kit, new_cfmm =
    cfmm_remove_liquidity cfmm amount lqt_burned min_tez_withdrawn min_kit_withdrawn deadline in
  cfmm_liquidity_tokens_extant new_cfmm < cfmm_liquidity_tokens_extant cfmm

(* If successful, cfmm_remove_liquidity removes at least min_tez_withdrawn tez. *)
let test_remove_liquidity_respects_min_tez_withdrawn =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_remove_liquidity_respects_min_tez_withdrawn"
    ~count:property_test_count
    make_inputs_for_remove_liquidity_to_succeed
  @@ fun (cfmm, amount, lqt_burned, min_tez_withdrawn, min_kit_withdrawn, deadline) ->
  let withdrawn_tez, _withdrawn_kit, _new_cfmm =
    cfmm_remove_liquidity cfmm amount lqt_burned min_tez_withdrawn min_kit_withdrawn deadline in
  withdrawn_tez >= min_tez_withdrawn

(* If successful, cfmm_remove_liquidity removes at least min_kit_withdrawn kit. *)
let test_remove_liquidity_respects_min_kit_withdrawn =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_remove_liquidity_respects_min_kit_withdrawn"
    ~count:property_test_count
    make_inputs_for_remove_liquidity_to_succeed
  @@ fun (cfmm, amount, lqt_burned, min_tez_withdrawn, min_kit_withdrawn, deadline) ->
  let _withdrawn_tez, withdrawn_kit, _new_cfmm =
    cfmm_remove_liquidity cfmm amount lqt_burned min_tez_withdrawn min_kit_withdrawn deadline in
  withdrawn_kit >= min_kit_withdrawn

(* If successful, cfmm_remove_liquidity removes no more tez than it had. *)
let test_remove_liquidity_respects_tez_limit =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_remove_liquidity_respects_tez_limit"
    ~count:property_test_count
    make_inputs_for_remove_liquidity_to_succeed
  @@ fun (cfmm, amount, lqt_burned, min_tez_withdrawn, min_kit_withdrawn, deadline) ->
  let withdrawn_tez, _withdrawn_kit, _new_cfmm =
    cfmm_remove_liquidity cfmm amount lqt_burned min_tez_withdrawn min_kit_withdrawn deadline in
  withdrawn_tez <= cfmm.tez

(* If successful, cfmm_remove_liquidity removes no more kit than it had. *)
let test_remove_liquidity_respects_kit_limit =
  qcheck_to_ounit
  @@ QCheck.Test.make
    ~name:"test_remove_liquidity_respects_kit_limit"
    ~count:property_test_count
    make_inputs_for_remove_liquidity_to_succeed
  @@ fun (cfmm, amount, lqt_burned, min_tez_withdrawn, min_kit_withdrawn, deadline) ->
  let _withdrawn_tez, withdrawn_kit, _new_cfmm =
    cfmm_remove_liquidity cfmm amount lqt_burned min_tez_withdrawn min_kit_withdrawn deadline in
  withdrawn_kit <= cfmm.kit

(* ************************************************************************* *)
(*                 remove_liquidity (unit tests)                             *)
(* ************************************************************************* *)

let test_remove_liquidity_failures =
  "remove liquidity failure conditions" >:: fun _ ->
    Ligo.Tezos.reset ();
    let cfmm =
      cfmm_make_for_test
        ~tez:(Ligo.tez_from_literal "1000_000_000mutez")
        ~kit:(kit_of_mukit (Ligo.nat_from_literal "5000_000_000n"))
        ~lqt:(Ligo.nat_from_literal "1000n")
        ~kit_in_tez_in_prev_block:one_ratio
        ~last_level:(Ligo.nat_from_literal "0n") in
    let (liq, _kit, cfmm) =
      cfmm_add_liquidity
        cfmm
        (Ligo.tez_from_literal "101_000_000mutez")
        (Ligo.tez_from_literal "10_000_000mutez")
        (kit_of_mukit (Ligo.nat_from_literal "500_000_000n"))
        (Ligo.nat_from_literal "1n")
        (Ligo.timestamp_from_seconds_literal 1) in
    assert_raises
      (Failure (Ligo.string_of_int error_RemoveLiquidityNonEmptyAmount))
      (fun () ->
         cfmm_remove_liquidity
           cfmm
           (Ligo.tez_from_literal "1mutez")
           liq
           (Ligo.tez_from_literal "1mutez")
           (kit_of_mukit (Ligo.nat_from_literal "1n"))
           (Ligo.timestamp_from_seconds_literal 100)
      );
    assert_raises
      (Failure (Ligo.string_of_int error_RemoveLiquidityNoLiquidityBurned))
      (fun () ->
         cfmm_remove_liquidity
           cfmm
           (Ligo.tez_from_literal "0mutez")
           (Ligo.nat_from_literal "0n")
           (Ligo.tez_from_literal "1mutez")
           (kit_of_mukit (Ligo.nat_from_literal "1n"))
           (Ligo.timestamp_from_seconds_literal 100)
      );
    assert_raises
      (Failure (Ligo.string_of_int error_RemoveLiquidityNoTezWithdrawnExpected))
      (fun () ->
         cfmm_remove_liquidity
           cfmm
           (Ligo.tez_from_literal "0mutez")
           liq
           (Ligo.tez_from_literal "0mutez")
           (kit_of_mukit (Ligo.nat_from_literal "1n"))
           (Ligo.timestamp_from_seconds_literal 100)
      );
    assert_raises
      (Failure (Ligo.string_of_int error_RemoveLiquidityNoKitWithdrawnExpected))
      (fun () ->
         cfmm_remove_liquidity
           cfmm
           (Ligo.tez_from_literal "0mutez")
           liq
           (Ligo.tez_from_literal "1mutez")
           (kit_of_mukit (Ligo.nat_from_literal "0n"))
           (Ligo.timestamp_from_seconds_literal 100)
      )

(* ************************************************************************* *)
(*                 liquidity when accruals are pending                       *)
(* ************************************************************************* *)

let pending_tez_deposit_test =
  "set pending tez deposit" >::
  (fun _ ->
     Ligo.Tezos.reset ();
     let cfmm =
       cfmm_make_for_test
         ~tez:(Ligo.tez_from_literal "1000_000_000mutez")
         ~kit:(kit_of_mukit (Ligo.nat_from_literal "5000_000_000n"))
         ~lqt:(Ligo.nat_from_literal "1000n")
         ~kit_in_tez_in_prev_block:one_ratio
         ~last_level:(Ligo.nat_from_literal "0n") in
     (* let cfmm = set_pending_accrued_tez cfmm (Ligo.tez_from_literal "1_000_000mutez") in *)

     let (liq, _kit, cfmm) =
       cfmm_add_liquidity
         cfmm
         (Ligo.tez_from_literal "101_000_000mutez")
         (Ligo.tez_from_literal "10_000_000mutez")
         (kit_of_mukit (Ligo.nat_from_literal "500_000_000n"))
         (Ligo.nat_from_literal "1n")
         (Ligo.timestamp_from_seconds_literal 1) in
     let (tez, kit, _) =
       cfmm_remove_liquidity cfmm
         (Ligo.tez_from_literal "0mutez")
         liq
         (Ligo.tez_from_literal "1mutez")
         (kit_of_mukit (Ligo.nat_from_literal "1n"))
         (Ligo.timestamp_from_seconds_literal 100) in
     assert_equal ~printer:show_kit (kit_of_mukit (Ligo.nat_from_literal "500_000_000n")) kit;
     assert_equal ~printer:Ligo.string_of_tez (Ligo.tez_from_literal "100_090_909mutez") tez;
  )

let suite =
  "Cfmm tests" >::: [
    (* buy_kit *)
    buy_kit_unit_test;
    test_buy_kit_increases_price;
    test_buy_kit_increases_product;
    test_buy_kit_does_not_affect_liquidity;
    test_buy_kit_respects_min_kit_expected;
    test_buy_kit_preserves_kit;
    test_buy_kit_preserves_tez;

    (* sell_kit *)
    sell_kit_unit_test;
    test_sell_kit_decreases_price;
    test_sell_kit_increases_product;
    test_sell_kit_does_not_affect_liquidity;
    test_sell_kit_respects_min_tez_expected;
    test_sell_kit_preserves_kit;
    test_sell_kit_preserves_tez;

    (* add_liquidity (first) *)
    (* TODO: add unit tests and property-based random tests *)

    (* add_liquidity (non-first) *)
    add_liquidity_unit_test;
    test_add_liquidity_failures;
    test_add_liquidity_might_decrease_price;
    test_add_liquidity_increases_product;
    test_add_liquidity_increases_liquidity;
    test_add_liquidity_kit_to_return_lt_max_kit_deposited;
    test_add_liquidity_respects_min_lqt_minted;
    test_add_liquidity_respects_max_kit_deposited;

    (* remove liquidity *)
    (* TODO: add unit tests *)
    test_remove_liquidity_failures;
    test_remove_liquidity_decreases_product;
    test_remove_liquidity_decreases_liquidity;
    test_remove_liquidity_respects_min_tez_withdrawn;
    test_remove_liquidity_respects_min_kit_withdrawn;
    test_remove_liquidity_respects_tez_limit;
    test_remove_liquidity_respects_kit_limit;

    pending_tez_deposit_test;
  ]