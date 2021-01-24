open OUnit2
open FixedPoint

type tz = Ligo.tez [@@deriving show]
type fp = fixedpoint[@@deriving show]

let suite =
  "TezTests" >::: [
    "tez arithmetic" >::
    (fun _ ->
       assert_equal ~printer:show_tz
         (Ligo.tez_from_literal "8_000_000mutez")
         (Ligo.add_tez_tez (Ligo.tez_from_literal "5_000_000mutez") (Ligo.tez_from_literal "3_000_000mutez"));
       assert_equal ~printer:show_tz
         (Ligo.tez_from_literal "2_000_000mutez")
         (Ligo.sub_tez_tez (Ligo.tez_from_literal "5_000_000mutez") (Ligo.tez_from_literal "3_000_000mutez"));
       assert_equal
         ~printer:show_tz
         (Ligo.tez_from_literal "5_000_000mutez")
         (max (Ligo.tez_from_literal "5_000_000mutez") (Ligo.tez_from_literal "3_000_000mutez"));
       assert_equal
         ~printer:(fun x -> x)
         "50309951mutez"
         (show_tz (Ligo.tez_from_literal "50_309_951mutez"));
    )
  ]
