(* ************************************************************************* *)
(*                               FixedPoint                                  *)
(* ************************************************************************* *)
module FixedPoint : sig
  type t

  val scaling_factor : Int64.t

  (* Basic arithmetic operations. TODO: delete division, or at least limit it. *)
  val add : t -> t -> t
  val sub : t -> t -> t
  val mul : t -> t -> t
  val div : t -> t -> t
  val rem : t -> t -> t

  val zero : t
  val one : t

  (* Conversions to/from other types. *)
  val of_float : float -> t (* TODO: Delete this one. *)
  val to_float : t -> float (* TODO: Delete this one. *)

  (* CAUTION: These expose the internal representation. *)
  val of_int64 : int64 -> t
  val to_int64 : t -> int64

  (* Pretty printing functions *)
  val pp : t -> Format.formatter -> unit
end =
struct
  type t = Int64.t
  let scaling_factor = 100000000L
  let scaling_exponent = 8

  (* Basic arithmetic operations. TODO: delete division, or at least limit it. *)
  let add x y =
    assert (x >= 0L);
    assert (y >= 0L);
    assert (not (x > Int64.sub Int64.max_int y)); (* Overflow *)
    assert (not (y > Int64.sub Int64.max_int x)); (* Overflow *)
    Int64.add x y

  let sub x y =
    assert (y >= 0L);
    assert (x >= y);
    Int64.sub x y

  let mul x y =
    assert (x >= 0L);
    assert (y >= 0L);
    if (x == 0L || y == 0L) then
      0L
    else (
      assert (not (x > Int64.div Int64.max_int y)); (* Overflow *)
      assert (not (y > Int64.div Int64.max_int x)); (* Overflow *)
      Int64.div (Int64.mul x y) scaling_factor
    )

  let div x y =
    assert (x >= 0L);
    assert (y >= 0L);
    assert (y > 0L); (* Overflow *)
    Int64.mul (Int64.div x y) scaling_factor

  let rem x y =
    assert (x >= 0L);
    assert (y >= 0L);
    assert (y > 0L); (* Overflow *)
    Int64.rem x y

  let zero = 0L
  let one = scaling_factor

  (* Conversions to/from other types. *)
  let of_float amount = (* TODO: lossy *)
    let upper = Int64.of_float amount in
    let lower = Int64.of_float ((amount -. Int64.to_float upper) *. Int64.to_float scaling_factor) in
    Int64.add (Int64.mul upper scaling_factor) lower

  let to_float amount = (* TODO: lossy *)
    (Int64.to_float amount) /. Int64.to_float scaling_factor

  let of_int64 t = t
  let to_int64 t = t

  (* Pretty printing functions *)
  let pp amount ppf =
    let zfill s width =
      let to_fill = width - (String.length s) in
      if to_fill <= 0
      then s
      else (String.make to_fill '0') ^ s in

    Format.fprintf ppf "%s.%s"
      (Int64.to_string (Int64.div amount scaling_factor))
      (zfill (Int64.to_string (Int64.rem amount scaling_factor)) scaling_exponent)
end
