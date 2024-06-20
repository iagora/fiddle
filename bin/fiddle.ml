open Lib
open Core

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
     and mask =
       flag "--mask" ~aliases:[ "-k" ] (optional string)
         ~doc:
           "MASK specify a mask as to guide the check insertion, and allow \
            permutations"
     and list_algs = flag "--list" no_arg ~doc:"list algorithms available"
     and value =
       flag "--unhash" ~aliases:[ "--ughh"; "-u" ] (optional string)
         ~doc:
           "HEX from a hex digest string find a CPF, we call this unhash as \
            joke, we shorten the flag to u, so it can also mean ughh"
     in
     fun () ->
       let fn =
         match (hash_algorithm, mac_algorithm) with
         | hash_alg, None -> hash hash_alg digest_length
         | _, Some mac_alg -> mac mac_alg digest_length
       in
       if list_algs then list_algorithms ()
       else
         match (mask, value) with
         | Some mask, Some value -> (
             try digest_to_cpf_with_mask fn mask value with
             | Invalid_argument msg ->
                 Printf.eprintf "Invalid Arguments: %s\n" msg
             | Failure msg -> Printf.eprintf "Error: %s\n" msg)
         | None, Some value -> (
             try digest_to_cpf fn value
             with Failure msg -> Printf.eprintf "Error: %s\n" msg)
         | Some mask, None ->
             if List.is_empty inputs then
               In_channel.fold_lines In_channel.stdin ~init:()
                 ~f:(fun () line ->
                   try cpf_to_digest_with_mask fn mask line with
                   | Invalid_argument msg ->
                       Printf.eprintf "Invalid Arguments: %s\n" msg
                   | Failure msg -> Printf.eprintf "Error: %s\n" msg)
             else
               List.iter inputs ~f:(fun cpf ->
                   try cpf_to_digest_with_mask fn mask cpf with
                   | Invalid_argument msg ->
                       Printf.eprintf "Invalid Arguments: %s\n" msg
                   | Failure msg -> Printf.eprintf "Error: %s\n" msg)
         | None, None ->
             if List.is_empty inputs then
               In_channel.fold_lines In_channel.stdin ~init:()
                 ~f:(fun () line ->
                   try Int.of_string line |> cpf_to_digest fn
                   with Failure msg -> Printf.eprintf "Error: %s\n" msg)
             else
               List.iter inputs ~f:(fun cpf ->
                   try Int.of_string cpf |> cpf_to_digest fn
                   with Failure msg -> Printf.eprintf "Error: %s\n" msg))

(*Entry point of the program *)
let () = Command_unix.run fiddle
