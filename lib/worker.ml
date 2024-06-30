type parameters = {
  hash : string;
  mac : string option;
  length : int;
  mask : string;
  target : string option;
}

type config = { param : parameters; range : (int * int) option }
type msg = Msg of string | Proc of config | Quit
type task = Search | Inputs

module Worker = struct
type t = { pid : int; out_chan : out_channel }

  let worker_loop in_chan =
    let rec go f =
      let msg : msg = Marshal.from_channel in_chan in
      match msg with
      | Quit -> exit 0
      | Proc _ -> failwith "Worker already received its configuration"
      | Msg input ->
          match f input with
          | Some result -> Printf.printf "%s%!" result
          | None -> ();
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
          match load.param.target with
          | Some value -> (
              let open Core in
              match
                Cpf.digest_to_cpf fn load.param.mask (Option.value_exn load.range) value
                 
              with
              | Some result ->
                  Printf.printf "%s\n%!" result;
                  exit 0
              | None -> config ())
          | None -> go (Cpf.cpf_to_digest fn load.param.mask))
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

