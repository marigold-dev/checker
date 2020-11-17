open OUnit2

type fp = FixedPoint.t [@@deriving show]

let suite =
  "FixedPoint tests" >::: [
    "fixedpoint arithmetic" >::
    (fun _ ->
       let fp1 = FixedPoint.of_string "5.0" in
       let fp2 = FixedPoint.of_string "3.0" in
       let fp3 = FixedPoint.of_string "5.1234" in
       let fp4 = FixedPoint.of_string "5001.0" in
       let fp5 = FixedPoint.of_string "-40.0" in
       let fp6 = FixedPoint.of_string "0.1" in
       let two = FixedPoint.of_string "2" in
       assert_equal ~printer:show_fp (FixedPoint.of_string "1.1") (FixedPoint.exp fp6);
       assert_equal ~printer:show_fp (FixedPoint.of_string "8.0") FixedPoint.(fp1 + fp2);
       assert_equal ~printer:show_fp (FixedPoint.of_string "2.0") FixedPoint.(fp1 - fp2);
       assert_equal ~printer:show_fp (FixedPoint.of_string "15.0") FixedPoint.(fp1 * fp2);
       assert_equal ~printer:show_fp (FixedPoint.of_string "15.3702") FixedPoint.(fp3 * fp2);
       assert_equal ~printer:show_fp (FixedPoint.of_string "-204.936") FixedPoint.(fp3 * fp5);
       assert_equal ~printer:show_fp (FixedPoint.of_string "1.66666666") FixedPoint.(fp1 / fp2);
       assert_equal ~printer:show_fp (FixedPoint.of_string "-8.0") FixedPoint.(fp5 / fp1);
       assert_equal ~printer:show_fp (FixedPoint.of_string "1.7078") FixedPoint.(fp3 / fp2);
       assert_equal ~printer:show_fp (FixedPoint.of_string "-125.025") FixedPoint.(fp4 / fp5);
       assert_equal ~printer:show_fp (FixedPoint.of_string "4") (FixedPoint.pow two 2);
       assert_equal ~printer:show_fp (FixedPoint.of_string "2") (FixedPoint.pow two 1);
       assert_equal ~printer:show_fp (FixedPoint.of_string "1") (FixedPoint.pow fp5 0);
    );
  ]