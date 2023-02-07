#include "../src/main.mligo"

let test_scaling_factor_int = 
  let x = pow_int_nat (10) lqt_decimal_digits in
  assert(x = lqt_scaling_factor_int)

let test_scaling_factor_nat = 
  let x = int lqt_scaling_factor_nat in
  assert(x = lqt_scaling_factor_int)

let test_lqt_add = 
  let a = lqt_of_denomination(5_000_000n) in
  let b = lqt_of_denomination(3_000_000n) in
  let r = lqt_of_denomination(8_000_000n) in
  assert(lqt_add a b = r)

let test_subtract =
  let a = lqt_of_denomination(5_000_000n) in
  let b = lqt_of_denomination(3_000_000n) in
  let r = lqt_of_denomination (2_000_000n) in
  assert(lqt_sub a b = r)

// TODO: WE NEED ASSERT_RAISES IN LIGO
//let test_assert_raises_LqtSubNegative

let test_fractions_ceil = 
  assert((lqt_of_fraction_ceil (1) (3)) = (lqt_of_denomination 333_334n))

let test_fractions_floor = 
  assert((lqt_of_fraction_floor (1) (3)) = (lqt_of_denomination 333_333n))

