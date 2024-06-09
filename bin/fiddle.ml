open Lib
open Core

let fiddle =
  Command.basic
    ~summary:"Fiddle is a tool to generate the hash or MAC of CPFs.\nUsage:"
    (let%map_open.Command inputs = anon (sequence ("cpf" %: string))
     and hash_algorithm =
       flag "-hash" ~aliases:[ "-h" ]
         (optional_with_default "sha256" string)
         ~doc:
           "HASH specify the hash algorithm. Use --list to see a list of \
            available algorithms."
     and mac_algorithm =
       flag "-mac" ~aliases:[ "-m" ] (optional string)
         ~doc:
           "MAC specify the MAC algorithm. Use --list to see a list of \
            available algorithms. Secret key must be in FIDDLE_SECRET_KEY env \
            var"
     and digest_length =
       flag "-length" ~aliases:[ "-l" ]
         (optional_with_default 512 int)
         ~doc:
           "LENGTH specify the digest length in bits for algorithms that have \
            varying length output"
     and list_algs =
       flag "--list" ~aliases:[ "--l" ] no_arg
         ~doc:"list algorithms available"
     in
     fun () ->
       let f =
         match (hash_algorithm, mac_algorithm) with
         | hash, None -> hash_a_cpf hash digest_length
         | _, Some mac -> mac_a_cpf mac digest_length
       in
       if list_algs then list_algorithms ()
       else if List.is_empty inputs then
         In_channel.fold_lines In_channel.stdin ~init:() ~f:(fun () line ->
             let number = Int.of_string line in
             f number)
       else
         List.iter inputs ~f:(fun cpf ->
             let number = Int.of_string cpf in
             f number))

(* Entry point of the program *)
let () = Command_unix.run fiddle
