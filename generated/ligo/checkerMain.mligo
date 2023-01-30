(* open CheckerEntrypoints *)
(* open CheckerTypes *)
(* open Checker *)
(* open Fa2Interface *)
(* open Error *)
(* open Common *)
(* open GetOracleEntrypoint *)

(* We can not serialize all of our parameters, since `Balance_of` contains a `contract`. So, we split
 * up parameters we can not serialize here.
*)
type strict_params =
  | Balance_of of fa2_balance_of_param
  | Transfer of fa2_transfer list

type checker_params =
  | LazyParams of lazy_params
  | StrictParams of strict_params

type params =
  | DeployFunction of (lazy_function_id * bytes)
  | DeployMetadata of bytes
  | SealContract of external_contracts
  | CheckerEntrypoint of checker_params

(*
This is only for convenience, to actually create the storage just craft it manually by:

```
(Pair {} (Pair {} (Right "some_addr")))
```
*)

let initial_wrapper (addr: address) =
  { lazy_functions = (Big_map.empty: (lazy_function_id, bytes) big_map)
  ; metadata = (Big_map.empty: (string, bytes) big_map)
  ; deployment_state = Unsealed addr
  }

(* BEGIN_LIGO *)
   let get_lazy_function (fnMap : lazy_function_map) (fnId: lazy_function_id) : lazy_function =
   match Big_map.find_opt fnId fnMap with
   | Some bytes -> begin
      match (Bytes.unpack bytes : lazy_function option) with
      | Some f -> f
      | None -> (failwith error_GetLazyFunctionUnpackFailure : lazy_function)
    end
   | None -> (failwith error_GetLazyFunctionMissingFunction : lazy_function)
   (* END_LIGO *)

let main (op, state: params * wrapper): operation list * wrapper =
  let _ = ensure_no_tez_given () in

  let { lazy_functions = lazy_functions; metadata = metadata; deployment_state = deployment_state } = state in

  let ops, lazy_functions, metadata, deployment_state = match deployment_state with
    | Unsealed deployer ->
      begin if Tezos.sender = deployer then
          begin match op with
            | DeployFunction p ->
              let lfi, bs = p in
              let lazy_functions =
                match Big_map.find_opt lfi lazy_functions with
                | None -> Big_map.add lfi bs lazy_functions
                | Some prev -> Big_map.add lfi (Bytes.concat prev bs) lazy_functions in
              (([]: operation list), lazy_functions, metadata, Unsealed deployer)
            | DeployMetadata bs ->
              let metadata =
                match Big_map.find_opt "m" metadata with
                | None -> Big_map.add "m" bs metadata
                | Some prev -> Big_map.add "m" (Bytes.concat prev bs) metadata in
              (([]: operation list), lazy_functions, metadata, Unsealed deployer)
            | SealContract external_contracts ->
              (* check if the given oracle, collateral_fa2, and ctez contracts have the entrypoints we need *)
              let _ = get_oracle_entrypoint external_contracts in
              let _ = get_transfer_collateral_fa2_entrypoint external_contracts in
              let _ = get_transfer_ctok_fa2_entrypoint external_contracts in
              let _ = get_ctez_cfmm_price_entrypoint external_contracts in

              (* emit a touch operation to checker *)
              let touchOp =
                match (Tezos.get_entrypoint_opt "%touch" Tezos.self_address: unit contract option) with
                | Some c -> Tezos.transaction () (0mutez) c
                | None -> (failwith ((-4)) : operation) in

              (* initialize checker state *)
              let checker = initial_checker external_contracts in

              (* add the metadata boilerplate *)
              (* Python: b"tezos-storage:m".hex() *)
              let metadata_url = 0x74657a6f732d73746f726167653a6d in
              let metadata = Big_map.add "" metadata_url metadata in

              ([touchOp], lazy_functions, metadata, Sealed checker)
            | CheckerEntrypoint _ ->
              (* Note: disabling coverage for the unreported but accessed right-hand side;
               * accessibility is sufficiently marked on the pattern itself. *)
              ((failwith error_ContractNotDeployed (* [@coverage off] *)): operation list * lazy_function_map * (string, bytes) big_map * deployment_state)
          end
        else
          (* Note: disabling coverage for the unreported but accessed right-hand side;
           * accessibility is sufficiently marked on the pattern itself. *)
          ((failwith error_UnauthorisedCaller (* [@coverage off] *)): operation list * lazy_function_map * (string, bytes) big_map * deployment_state)
      end
    | Sealed checker ->
      let ops, checker =
        match op with
        | DeployFunction _ ->
          (* Note: disabling coverage for the unreported but accessed right-hand side;
           * accessibility is sufficiently marked on the pattern itself. *)
          ((failwith error_ContractAlreadyDeployed (* [@coverage off] *)): operation list * checker)
        | SealContract _ ->
          (* Note: disabling coverage for the unreported but accessed right-hand side;
           * accessibility is sufficiently marked on the pattern itself. *)
          ((failwith error_ContractAlreadyDeployed (* [@coverage off] *)): operation list * checker)
        | DeployMetadata _ ->
          (* Note: disabling coverage for the unreported but accessed right-hand side;
           * accessibility is sufficiently marked on the pattern itself. *)
          ((failwith error_ContractAlreadyDeployed (* [@coverage off] *)): operation list * checker)
          (* [@coverage off] *)
        | CheckerEntrypoint op -> begin
            match op with
            | StrictParams op -> begin
                match op with
                | Balance_of p -> strict_entrypoint_balance_of (checker, p)
                | Transfer p -> strict_entrypoint_transfer (checker, p)
              end
            | LazyParams op ->
              (* BEGIN_LIGO *)
                 let fid, params = lazyParamsToLazyFunctionId op in
                 (get_lazy_function lazy_functions fid) (checker, params)
                 (* END_LIGO *)
              (* BEGIN_OCAML   
              runLazyParams op checker
                 END_OCAML *)
          end in
      (ops, lazy_functions, metadata, Sealed checker)
  in
  (ops, { lazy_functions = lazy_functions; metadata = metadata; deployment_state = deployment_state })
