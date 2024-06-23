type parameters = {
  hash : string;
  mac : string option;
  length : int;
  mask : string option;
  target : string option;
}

type config = { param : parameters; range : (int * int) option }
type msg = Msg of string | Proc of config | Quit
type task = Search | Inputs

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

type t = { pid : int; out_chan : out_channel }

module Worker = struct
  let worker_loop in_chan =
    let rec go f =
      let msg : msg = Marshal.from_channel in_chan in
      match msg with
      | Quit -> exit 0
      | Proc _ -> failwith "Worker already received its configuration"
      | Msg input ->
          f input;
          go f
    in
    let rec config () =
      match Marshal.from_channel in_chan with
      | Quit -> exit 0
      | Msg _ -> failwith "Worker has not received its configurations yet."
      | Proc load -> (
          let fn =
            match (load.param.hash, load.param.mac) with
            | hash_alg, None -> Crypto.hash hash_alg load.param.length
            | _, Some mac_alg -> Crypto.mac mac_alg load.param.length
          in
          match (load.param.mask, load.param.target) with
          | Some mask, Some value -> (
              let open Core in
              match
                Mp.digest_to_cpf_with_mask fn mask value
                  (Option.value_exn load.range)
              with
              | Some result ->
                  Printf.printf "%s\n%!" result;
                  exit 0
              | None -> config ())
          | None, Some value -> (
              let open Core in
              match Mp.digest_to_cpf fn value (Option.value_exn load.range) with
              | Some result ->
                  Printf.printf "%s\n%!" result;
                  exit 0
              | None -> config ())
          | None, None -> go (Mp.cpf_to_digest fn)
          | Some mask, None -> go (Mp.cpf_to_digest_with_mask fn mask))
    in
    config ()

  let mk () =
    let in_fd, out_fd = Unix.pipe () in
    match Unix.fork () with
    | 0 ->
        Unix.close out_fd;
        let in_ch = Unix.in_channel_of_descr in_fd in
        worker_loop in_ch |> ignore;
        exit 1
    | pid ->
        Unix.close in_fd;
        let out_chan = Unix.out_channel_of_descr out_fd in
        { pid; out_chan }

  let send { pid; out_chan } (msg : msg) =
    Marshal.to_channel out_chan msg [];
    let _ = pid in
    flush out_chan

  let kill { pid; _ } = Unix.kill pid Sys.sigkill
  let wait { pid; _ } = Unix.waitpid [] pid |> ignore
end

let handle_search workers =
  let rec wait_for_completion () =
    match Unix.wait () with
    | pid, WEXITED 0 -> Some pid
    | _ -> wait_for_completion ()
  in
  match wait_for_completion () with
  | Some pid -> Array.iter (fun w -> if w.pid <> pid then Worker.kill w) workers
  | None -> ()

let handle_inputs workers =
  let open Core in
  let current_worker = ref 0 in
  In_channel.fold_lines In_channel.stdin ~init:() ~f:(fun () line ->
      Worker.send workers.(!current_worker) (Msg line);
      current_worker := (!current_worker + 1) mod Array.length workers;
      ());
  Array.iter workers ~f:(fun w -> Worker.send w Quit);
  Array.iter workers ~f:(fun w -> Worker.wait w)

let fiddle params np =
  let n_cpus = cpu_count () in
  if np > n_cpus then
    invalid_arg "Creating more processes than CPUs available is not allowed"
  else
    let task_type, tasks =
      match params.target with
      | Some _ ->
          let t = Search in
          let procs = calculate_ranges np in
          let l =
            List.map
              (fun (x, y) -> Proc { param = params; range = Some (x, y) })
              procs
          in
          (t, l)
      | None ->
          let t = Inputs in
          let l =
            List.init np (fun _ -> Proc { param = params; range = None })
          in
          (t, l)
    in
    let workers = Array.init np (fun _ -> Worker.mk ()) in
    List.iteri
      (fun idx t ->
        let w = workers.(idx) in
        Worker.send w t)
      tasks;
    match task_type with
    | Search -> handle_search workers
    | Inputs -> handle_inputs workers
