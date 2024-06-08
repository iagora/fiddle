open Base
open Stdio
open Cryptokit

let list_algorithms () =
  let hash_algorithms = 
      [
          "Hash algorithms:";
          "";
          "\tsha3";
          "\tkeccak";
          "\tsha2";
          "\tsha224";
          "\tsha256";
          "\tsha384";
          "\tsha512";
          "\tblake2b";
          "\tblake2b512";
          "\tblake2s";
          "\tblake2s256";
          "\tblake3";
          "\tblake3_256";
          "\tripemd160";
          "\tsha1";
          "\tmd5";
       ]
  in
  let mac_algorithms =
      [
          "MAC algorithms:";
          "";
          "\tsha256";
          "\tsha384";
          "\tsha512";
          "\tblake2b";
          "\tblake2b512";
          "\tblake2s";
          "\tblake2s256";
          "\tblake3";
          "\tblake3_256";
          "\tripemd160";
          "\tsiphash";
          "\tsiphash128";
          "\tsha1";
          "\tmd5";
      ]
  in
  List.iter ~f:(printf "%s\n") hash_algorithms;
  printf "\n";
  List.iter ~f:(printf "%s\n") mac_algorithms

(* Function to calculate the CPF check digits *)
let calculate_cpf_digits cpf_base =
  (* Helper to calculate a single digit based on the cpf array and the weights *)
  let calc_digit weights cpf_numbers =
    List.fold2_exn cpf_numbers weights ~init:0 ~f:(fun acc x weight -> acc + x * weight)
    |> fun sum -> let remainder = sum % 11 in
                 if remainder < 2 then 0 else 11 - remainder
  in
  (* Weights for the first and second check digits *)
  let weights_first = [10; 9; 8; 7; 6; 5; 4; 3; 2] in
  let weights_second = [11; 10; 9; 8; 7; 6; 5; 4; 3; 2] in
  (* Calculate the first check digit *)
  let first_digit = calc_digit weights_first cpf_base in
  (* Calculate the second check digit *)
  let complete_cpf = cpf_base @ [first_digit] in  (* Include first check digit in the list *)
  let second_digit = calc_digit weights_second complete_cpf in  (* Now using complete_cpf *)
  (first_digit, second_digit)

(* Convert integer list to CPF string *)
let cpf_list_to_string cpf_digits (d1, d2) =
  List.fold cpf_digits ~init:"" ~f:(fun acc x -> acc ^ Int.to_string x)
  |> fun base_str -> Printf.sprintf "%s-%d%d" base_str d1 d2

(* Hash the CPF using Blake2b and print both hex and base64 encodings *)
let hash_and_print cpf_str hash_algorithm digest_length  =
  let hash_function =
      match hash_algorithm with
      | "sha3" -> Hash.sha3 digest_length
      | "keccak" -> Hash.keccak digest_length
      | "sha2" -> Hash.sha2 digest_length
      | "sha224" -> Hash.sha224 ()
      | "sha256" -> Hash.sha256 ()
      | "sha384" -> Hash.sha384 ()
      | "sha512" -> Hash.sha512 ()
      | "blake2b" -> Hash.blake2b digest_length
      | "blake2b512" -> Hash.blake2b512 ()
      | "blake2s" -> Hash.blake2s digest_length
      | "blake2s256" -> Hash.blake2s256 ()
      | "blake3" -> Hash.blake3 digest_length
      | "blake3_256" -> Hash.blake3_256 ()
      | "ripemd160" -> Hash.ripemd160 ()
      | "sha1" -> Hash.sha1 ()
      | "md5" -> Hash.md5 ()
      | _ -> failwith "Unsupported hash algorithm"
  in
  let digest = hash_function#add_string cpf_str; hash_function#result in
  let hex_encoded = transform_string (Hexa.encode ()) digest in
  printf "%s\t%s\n" cpf_str hex_encoded 


let mac_and_print data algorithm length =
  let secret_key =
    match Sys.getenv "FIDDLE_SECRET_KEY" with
    | Some key -> transform_string (Base64.decode ()) key
    | None -> failwith "Environment variable MAC_SECRET_KEY must be set."
  in
  let mac =
    match algorithm with
    | "sha1" -> MAC.hmac_sha1 secret_key
    | "sha256" -> MAC.hmac_sha256 secret_key
    | "sha384" -> MAC.hmac_sha384 secret_key
    | "sha512" -> MAC.hmac_sha512 secret_key
    | "ripemd160" -> MAC.hmac_ripemd160 secret_key
    | "md5" -> MAC.hmac_md5 secret_key
    | "blake2b" -> MAC.blake2b length secret_key
    | "blake2b512" -> MAC.blake2b512 secret_key
    | "blake2s" -> MAC.blake2s length secret_key
    | "blake2s256" -> MAC.blake2s256 secret_key
    | "blake3" -> MAC.blake3 length secret_key
    | "blake3_256" -> MAC.blake3_256 secret_key
    | "siphash" -> MAC.siphash secret_key
    | "siphash128" -> MAC.siphash128 secret_key
    | _ -> failwith "Unsupported MAC algorithm"
  in
  let result = mac#add_string data; mac#result in
  let hex_encoded = transform_string (Hexa.encode ()) result in
  printf "%s\t%s\n" data hex_encoded


let hash_a_cpf hash_algorithm digest_length number =
  let int_to_cpf_array n =
    Printf.sprintf "%09d" n
    |> String.to_list
    |> List.map ~f:(fun c -> Char.to_int c - Char.to_int '0')
  in
  let cpf_base = int_to_cpf_array number in
  let digits = calculate_cpf_digits cpf_base in
  let cpf_str = cpf_list_to_string cpf_base digits in
    hash_and_print cpf_str hash_algorithm digest_length

let mac_a_cpf mac_algorithm digest_length number =
  let int_to_cpf_array n =
    Printf.sprintf "%09d" n
    |> String.to_list
    |> List.map ~f:(fun c -> Char.to_int c - Char.to_int '0')
  in
  let cpf_base = int_to_cpf_array number in
  let digits = calculate_cpf_digits cpf_base in
  let cpf_str = cpf_list_to_string cpf_base digits in
    mac_and_print cpf_str mac_algorithm digest_length
