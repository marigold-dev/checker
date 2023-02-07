#include "../src/ligo.mligo"
#include "../src/error.mligo"
#include "../src/common.mligo"



let test_min_int = 
  let r = min_int 4 2 in
  assert(r = 2)

let test_max_int = 
  let r = max_int 4 2 in
  assert(r = 4)

let test_neg_int = 
  let r = neg_int 4 in
  assert(r = -4)

// 5 * 2 * 2 * 2 = 40
let test_pow_rec = 
  let r = pow_rec (5, 2, 3n) in
  assert(r = 40)

//let () = Test.log ("expected", r) in

let test_pow_int_nat =  
  let () = assert((pow_int_nat 3 0n) = 1) in
  let () = assert((pow_int_nat 3 1n) = 3) in
  assert((pow_int_nat 3 2n) = 9) 

let test_cdiv_int_int_fails_when_denominator_is_zero = 
  let r = (cdiv_int_int 1 0) in
  assert_fail(r = 0)
