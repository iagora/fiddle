open Cryptokit;;

(* Function to calculate the CPF check digits *)
let calculate_cpf_digits cpf_base =
  (* Helper to calculate a single digit based on the cpf array and the weights *)
  let calc_digit weights cpf_numbers =
    let sum = List.fold_left2 (fun acc x weight -> acc + x * weight) 0 cpf_numbers weights in
    let remainder = sum mod 11 in
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
  let base_str = List.fold_left (fun acc x -> acc ^ string_of_int x) "" cpf_digits in
  Printf.sprintf "%s-%d%d" base_str d1 d2

(* Hash the CPF using Blake2b and print both hex and base64 encodings *)
let hash_and_print_cpf cpf_str =
  let hash = Hash.blake2b512 () in
  let digest = hash#add_string cpf_str; hash#result in
  let hex_encoded = transform_string (Hexa.encode ()) digest in
  let base64_encoded = transform_string (Base64.encode_compact ()) digest in
  Printf.printf "%s\tBlake2b: %s:%s\n" cpf_str hex_encoded base64_encoded


let calculate_a_cpf number () =
  let int_to_cpf_array n =
    Printf.sprintf "%09d" n
    |> String.to_seq
    |> List.of_seq
    |> List.map (fun c -> int_of_char c - int_of_char '0')
  in
  let cpf_base = int_to_cpf_array number in
  let digits = calculate_cpf_digits cpf_base in
  let cpf_str = cpf_list_to_string cpf_base digits in
    hash_and_print_cpf cpf_str


(* Entry point of the program *)
let () =
  try
    while true do
      let line = input_line stdin in
      let number = int_of_string line in
      calculate_a_cpf number ()
    done
  with End_of_file -> ()
  (* generate_all_cpf () *)

