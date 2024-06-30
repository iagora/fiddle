type t = {
  hash : string;
  mac : string option;
  length : int;
  mask : string;
  target : string option;
  np : int;
}

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

let handle_search workers =
  let open Worker in
  let rec wait_for_completion () =
    match Unix.wait () with
    | pid, WEXITED 0 -> Some pid
    | _ -> wait_for_completion ()
  in
  match wait_for_completion () with
  | Some pid -> Array.iter (fun (w: Worker.t) -> if w.pid <> pid then Worker.kill w) workers
  | None -> ()

let handle_inputs workers =
  let open Core in
  let open Worker in
  let current_worker = ref 0 in
  In_channel.fold_lines In_channel.stdin ~init:() ~f:(fun () line ->
      Worker.send workers.(!current_worker) (Msg line);
      current_worker := (!current_worker + 1) mod Array.length workers;
      ());
  Array.iter workers ~f:(fun w -> Worker.send w Quit);
  Array.iter workers ~f:(fun w -> Worker.wait w)

let fiddle params = 
  let open Worker in
  let n_cpus = Util.cpu_count () in
  if params.np > n_cpus then
    invalid_arg "Creating more processes than CPUs available is not allowed"
  else
    let worker_config : parameters = {
        hash = params.hash;
        mac = params.mac;
        length = params.length;
        mask = params.mask;
        target = params.target;
    } in
    let task_type, tasks =
      match params.target with
      | Some _ ->
          let t = Search in
          let procs = calculate_ranges params.np in
          let l =
            List.map
              (fun (x, y) -> Proc { param = worker_config; range = Some (x, y) })
              procs
          in
          (t, l)
      | None ->
          let t = Inputs in
          let l =
            List.init params.np (fun _ -> Proc { param = worker_config; range = None })
          in
          (t, l)
    in
    let workers = Array.init params.np (fun _ -> Worker.mk ()) in
    List.iteri
      (fun idx t ->
        let w = workers.(idx) in
        Worker.send w t)
      tasks;
    match task_type with
    | Search -> handle_search workers
    | Inputs -> handle_inputs workers
