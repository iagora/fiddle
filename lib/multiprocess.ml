type parameters = {
  hash : string;
  mac : string option;
  length : int;
  mask_s : string option;
  target : string option;
}

type config = { param : parameters; range : (int * int) option }
type msg = Msg of string | Proc of config | Quit

let cpu_count () =
  try
    match Sys.os_type with
    | "Win32" -> int_of_string (Sys.getenv "NUMBER_OF_PROCESSORS")
    | _ -> (
        let i = Unix.open_process_in "getconf _NPROCESSORS_ONLN" in
        let close () = ignore (Unix.close_process_in i) in
        let ib = Scanf.Scanning.from_channel i in
        try
          Scanf.bscanf ib "%d" (fun n ->
              close ();
              n)
        with e ->
          close ();
          raise e)
  with
  | Not_found | Sys_error _ | Failure _ | Scanf.Scan_failure _ | End_of_file
  | Unix.Unix_error (_, _, _)
  ->
    1

let calculate_ranges n_workers =
  (* Define the total search space *)
  let total_space = 999999999 in

  (* Calculate the size of each worker's range *)
  let range_size = total_space / n_workers in

  (* Function to calculate start and stop for each worker *)
  let rec assign_ranges worker_id ranges =
    if worker_id >= n_workers then List.rev ranges
    else
      let start = worker_id * range_size in
      let stop =
        if worker_id = n_workers - 1 then total_space
        else ((worker_id + 1) * range_size) - 1
      in
      assign_ranges (worker_id + 1) ((start, stop) :: ranges)
  in
  assign_ranges 0 []

module Worker = struct
  let worker_loop in_chan =
    let config () =
      let rec go f n_done =
        let msg : msg = Marshal.from_channel in_chan in
        match msg with
        | Quit -> exit 0
        | Proc _ -> failwith "Worker already received its configuration"
        | Msg input ->
            f input;
            go f (n_done + 1)
      in
      let msg : msg = Marshal.from_channel in_chan in
      match msg with
      | Quit -> exit 0
      | Msg _ -> failwith "Worker has not received its configurations yet."
      | Proc load -> (
          let fn =
            match (load.param.hash, load.param.mac) with
            | hash_alg, None -> Crypto.hash hash_alg load.param.length
            | _, Some mac_alg -> Crypto.mac mac_alg load.param.length
          in
          match (load.param.mask_s, load.param.target) with
          | Some _, Some _ -> failwith "Unimplemented"
          | None, Some value ->
              let open Core in
              Mp.digest_to_cpf fn value (Option.value_exn load.range)
          | None, None -> go (Mp.cpf_to_digest fn) 0
          | _ -> failwith "Unimplemented")
    in
    config ()

  let mk () =
    let in_fd, out_fd = Unix.pipe () in
    let pid = Unix.fork () in
    if pid = 0 then (
      Unix.close out_fd;
      let in_ch = Unix.in_channel_of_descr in_fd in
      worker_loop in_ch |> ignore;
      failwith "Unreachable")
    else (
      Unix.close in_fd;
      let out_ch = Unix.out_channel_of_descr out_fd in
      out_ch)

  let send out_ch (msg : msg) =
    Marshal.to_channel out_ch msg [];
    flush out_ch
end

let fiddle params np =
  let n_cpus = cpu_count () in
  if np > n_cpus then
    invalid_arg "Creating more processes than CPUs available is not allowed";
  let tasks =
    match (params.mask_s, params.target) with
    | Some _, Some _ ->
        let procs = calculate_ranges np in
        List.map
          (fun (x, y) -> Proc { param = params; range = Some (x, y) })
          procs
    | Some _, None -> failwith "not ready"
    | None, Some _ -> 
        let procs = calculate_ranges np in
        List.map
          (fun (x, y) -> Proc { param = params; range = Some (x, y) })
          procs
    | None, None -> failwith "not ready"
  in
  let workers = Array.init np (fun _ -> Worker.mk ()) in
  let seed = 42 in
  Random.init seed;
  List.iteri
    (fun idx t ->
      let w = workers.(idx) in
      Worker.send w t)
    tasks;
  Array.iter (fun w -> Worker.send w Quit) workers
