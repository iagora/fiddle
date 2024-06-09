open Lib
open Core
open Cryptokit

let fiddle =
  Command.basic
    ~summary:"Fiddle is a tool to generate the hash or MAC of CPFs.\nUsage:"
    (let%map_open.Command inputs = anon (sequence ("cpf" %: string))
     and hash_algorithm =
       flag "--hash" ~aliases:[ "-h" ]
         (optional_with_default "sha256" string)
         ~doc:
           "HASH specify the hash algorithm. Use --list to see a list of \
            available algorithms."
     and mac_algorithm =
       flag "--mac" ~aliases:[ "-m" ] (optional string)
         ~doc:
           "MAC specify the MAC algorithm. Use --list to see a list of \
            available algorithms. Secret key must be in FIDDLE_SECRET_KEY env \
            var"
     and digest_length =
       flag "--length" ~aliases:[ "-l" ]
         (optional_with_default 512 int)
         ~doc:
           "LENGTH specify the digest length in bits for algorithms that have \
            varying length output"
     and list_algs = flag "--list" no_arg ~doc:"list algorithms available"
     and value =
       flag "--unhash" ~aliases:[ "--ughh"; "-u" ] (optional string)
         ~doc:
           "HEX from a hex digest string find a CPF, we call this unhash as \
            joke, we shorten the flag to u, so it can also mean ughh"
     in
     fun () ->
       let secret_key =
         match Sys.getenv "FIDDLE_SECRET_KEY" with
         | Some key -> transform_string (Base64.decode ()) key
         | None ->
             failwith "Environment variable FIDDLE_SECRET_KEY must be set."
       in
       let f =
         match (hash_algorithm, mac_algorithm) with
         | hash_alg, None -> hash hash_alg digest_length
         | _, Some mac_alg -> mac secret_key mac_alg digest_length
       in
       if list_algs then list_algorithms ()
       else if Option.is_some value then
         Option.value value ~default:"" |> digest_to_cpf f
       else if List.is_empty inputs then
         In_channel.fold_lines In_channel.stdin ~init:() ~f:(fun () line ->
             Int.of_string line |> cpf_to_digest f)
       else
         List.iter inputs ~f:(fun cpf -> Int.of_string cpf |> cpf_to_digest f))

(* Entry point of the program *)
let () = Command_unix.run fiddle
