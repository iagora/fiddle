open Core
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

let int_to_cpf_array n =
  Printf.sprintf "%09d" n |> String.to_list
  |> List.map ~f:(fun c -> Char.to_int c - Char.to_int '0')

(* Function to calculate the CPF check digits *)
let calculate_cpf_digits cpf_base =
  (* Helper to calculate a single digit based on the cpf array and the weights *)
  let calc_digit weights cpf_numbers =
    List.fold2_exn cpf_numbers weights ~init:0 ~f:(fun acc x weight ->
        acc + (x * weight))
    |> fun sum ->
    let remainder = sum % 11 in
    if remainder < 2 then 0 else 11 - remainder
  in
  (* Weights for the first and second check digits *)
  let weights_first = [ 10; 9; 8; 7; 6; 5; 4; 3; 2 ] in
  let weights_second = [ 11; 10; 9; 8; 7; 6; 5; 4; 3; 2 ] in
  (* Calculate the first check digit *)
  let first_digit = calc_digit weights_first cpf_base in
  (* Calculate the second check digit *)
  let complete_cpf = cpf_base @ [ first_digit ] in
  (* Include first check digit in the list *)
  let second_digit = calc_digit weights_second complete_cpf in
  (* Now using complete_cpf *)
  (first_digit, second_digit)

(* Convert integer list to CPF string *)
let cpf_list_to_string cpf_digits (d1, d2) =
  List.fold cpf_digits ~init:"" ~f:(fun acc x -> acc ^ Int.to_string x)
  |> fun base_str -> Printf.sprintf "%s-%d%d" base_str d1 d2

(* Hash hex encodings *)
let hash algorithm digest_length data =
  let hash_function =
    match algorithm with
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
  let digest =
    hash_function#add_string data;
    hash_function#result
  in
  transform_string (Hexa.encode ()) digest

let mac algorithm length data =
  let secret_key =
    match Sys.getenv "FIDDLE_SECRET_KEY" with
    | Some key -> transform_string (Base64.decode ()) key
    | None -> failwith "Environment variable FIDDLE_SECRET_KEY must be set."
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
  let result =
    mac#add_string data;
    mac#result
  in
  transform_string (Hexa.encode ()) result

let digest_to_cpf f target_result =
  let rec search n =
    if n > 999999999 then None (* Limiting the range for simplicity *)
    else
      let cpf_base = int_to_cpf_array n in
      let digits = calculate_cpf_digits cpf_base in
      let cpf_str = cpf_list_to_string cpf_base digits in
      let current_hash = f cpf_str in
      if String.equal current_hash target_result then Some cpf_str
      else search (n + 1)
  in
  let cpf =
    match search 0 with
    | Some data -> data
    | None -> failwith "Couldn't find CPF with matching digest"
  in
  printf "%s\n" cpf

let cpf_to_digest f number =
  let cpf_base = int_to_cpf_array number in
  let digits = calculate_cpf_digits cpf_base in
  let cpf_str = cpf_list_to_string cpf_base digits in
  let digest = f cpf_str in
  printf "%s\t%s\n" cpf_str digest

let cpf_to_digest_with_mask f mask input =
  let flag = ref false in
  let rec process_mask idx_in idx_mask check_digits acc =
    if idx_mask >= String.length mask then
      List.rev acc (* End of mask, return accumulated result *)
    else if idx_in >= String.length input then
      invalid_arg "Input is shorter than the mask."
    else
      let a, b = check_digits in
      let x = char_of_int (a + int_of_char '0') in
      let y = char_of_int (b + int_of_char '0') in
      let mask_char = mask.[idx_mask] in
      match mask_char with
      | '?' ->
          (* Escape sequence handling *)
          if idx_mask + 1 < String.length mask then
            let open Char in
            let next_char = mask.[idx_mask + 1] in
            match next_char with
            | '?' ->
                if input.[idx_in] <> next_char then
                  invalid_arg "Inputs don't correspond with mask"
                else
                  process_mask (idx_in + 1) (idx_mask + 2) check_digits
                    ('?' :: acc) (* Literal '?' *)
            | 'x' | 'y' ->
                if input.[idx_in] <> next_char then
                  invalid_arg "Inputs don't correspond with mask"
                else
                  process_mask (idx_in + 1) (idx_mask + 2) check_digits
                    (next_char :: acc) (* Literal 'x' or 'y' *)
            | c when Char.is_digit c ->
                if input.[idx_in] <> c then
                  invalid_arg "Inputs don't correspond with mask"
                else
                  process_mask (idx_in + 1) (idx_mask + 2) check_digits
                    (next_char :: acc) (* Literal numeric digits *)
            | _ -> invalid_arg "Invalid mask format after '?'"
          else invalid_arg "Mask ends with unescaped '?'"
      | 'x' ->
          let open Char in
          if input.[idx_in] <> x && input.[idx_in] <> 'x' then flag := true;
          if input.[idx_in] = 'x' then
            process_mask (idx_in + 1) (idx_mask + 1) check_digits (x :: acc)
          else
            process_mask (idx_in + 1) (idx_mask + 1) check_digits
              (input.[idx_in] :: acc)
      | 'y' ->
          let open Char in
          if input.[idx_in] <> y && input.[idx_in] <> 'y' then flag := true;
          if input.[idx_in] = 'y' then
            process_mask (idx_in + 1) (idx_mask + 1) check_digits (y :: acc)
          else
            process_mask (idx_in + 1) (idx_mask + 1) check_digits
              (input.[idx_in] :: acc)
      | '1' .. '9' ->
          (* Direct mapping from input based on mask *)
          process_mask (idx_in + 1) (idx_mask + 1) check_digits
            (input.[idx_in] :: acc)
      | _ as c ->
          let open Char in
          if input.[idx_in] <> c then
            invalid_arg "Inputs don't correspond with mask"
          else
            process_mask (idx_in + 1) (idx_mask + 1) check_digits
              (input.[idx_in] :: acc)
    (* Ignore other characters in mask *)
  in
  let extracted =
    let rec process mask_idx input_idx prev_char acc =
      if mask_idx >= String.length mask then acc
      else
        let mask_char = mask.[mask_idx] in
        let new_acc =
          if
            Char.is_digit mask_char || Char.equal mask_char 'x'
            || Char.equal mask_char 'y'
          then
            match prev_char with
            | Some '?' -> acc (* Skip the digit if the previous char was '?' *)
            | _ ->
                if input_idx < String.length input then
                  (mask_char, input.[input_idx]) :: acc
                else acc
          else acc
        in
        let next_mask_idx, next_input_idx =
          let open Char in
          if mask_char = '?' then
            if Option.value prev_char ~default:'0' = '?' then
              (mask_idx + 1, input_idx + 1) (* ?? case: move both indices *)
            else (mask_idx + 1, input_idx) (* Single ?: skip mask index only *)
          else (mask_idx + 1, input_idx + 1)
          (* Normal case: move both indices *)
        in
        process next_mask_idx next_input_idx (Some mask_char) new_acc
    in
    let filtered_chars = process 0 0 None [] in
    let sorted_chars =
      List.sort ~compare:(fun (a, _) (b, _) -> Char.compare a b) filtered_chars
    in
    let result_chars =
      List.filter_map sorted_chars ~f:(fun (char, digit) ->
          if Char.is_digit char then Some digit else None)
    in
    String.of_char_list result_chars
  in
  let cpf_base =
    String.to_list extracted
    |> List.map ~f:(fun c -> Char.to_int c - Char.to_int '0')
  in
  let check_digits = calculate_cpf_digits cpf_base in
  let cpf_digits = process_mask 0 0 check_digits [] in
  let cpf = String.of_char_list cpf_digits in
  let digest = f cpf in
  let ast = if !flag then "*" else "" in
  let x, y = check_digits in
  printf "%s-%d%d%s\t%s\t%s\n" extracted x y ast cpf digest

let digest_to_cpf_with_mask f mask target_result =
  let mappings =
    String.to_list mask
    |> List.filter ~f:(fun char -> Char.is_digit char)
    |> List.mapi ~f:(fun idx char -> (char, idx))
    |> List.sort ~compare:(fun (a, _) (b, _) -> Char.compare a b)
    |> List.map ~f:(fun (_, idx) -> idx)
  in
  let rec search n =
    if n > 999999999 then None (* Limiting the range for simplicity *)
    else
      let input = Printf.sprintf "%09d" n in
      let rec process_mask idx_in idx_mask check_digits acc =
        if idx_mask >= String.length mask then
          List.rev acc (* End of mask, return accumulated result *)
        else if idx_in > String.length input then
          invalid_arg "Input is shorter than the mask."
        else
          let a, b = check_digits in
          let x = char_of_int (a + int_of_char '0') in
          let y = char_of_int (b + int_of_char '0') in
          let mask_char = mask.[idx_mask] in
          match mask_char with
          | '?' ->
              (* Escape sequence handling *)
              if idx_mask + 1 < List.length mappings then
                let next_char = mask.[idx_mask + 1] in
                match next_char with
                | '?' | 'x' | 'y' ->
                    process_mask idx_in (idx_mask + 2) check_digits
                      (next_char :: acc)
                    (* Literal '?' *)
                | c when Char.is_digit c ->
                    process_mask idx_in (idx_mask + 2) check_digits
                      (next_char :: acc)
                    (* Literal numeric digits *)
                | _ -> invalid_arg "Invalid mask format after '?'"
              else invalid_arg "Mask ends with unescaped '?'"
          | 'x' -> process_mask idx_in (idx_mask + 1) check_digits (x :: acc)
          | 'y' -> process_mask idx_in (idx_mask + 1) check_digits (y :: acc)
          | '1' .. '9' ->
              (* Direct mapping from input based on mask *)
              let idx = Option.value_exn (List.nth mappings idx_in) in
              process_mask (idx_in + 1) (idx_mask + 1) check_digits
                (input.[idx] :: acc)
          | _ as c -> process_mask idx_in (idx_mask + 1) check_digits (c :: acc)
        (* Ignore other characters in mask *)
      in
      (* Extracting characters and mapping them to their positions *)
      let cpf_base = int_to_cpf_array n in
      let check_digits = calculate_cpf_digits cpf_base in
      let cpf_digits = process_mask 0 0 check_digits [] in
      let cpf_str = String.of_char_list cpf_digits in
      let digest = f cpf_str in
      if String.equal digest target_result then Some (cpf_str, check_digits)
      else search (n + 1)
  in
  let cpf, check =
    match search 0 with
    | Some data -> data
    | None -> failwith "Couldn't find CPF with matching digest"
  in
  let extracted =
    String.to_list mask
    |> List.mapi ~f:(fun idx char -> (char, cpf.[idx]))
    |> List.filter ~f:(fun (char, _) ->
           Char.is_digit char || Char.equal char 'x' || Char.equal char 'y')
    |> List.sort ~compare:(fun (a, _) (b, _) -> Char.compare a b)
    |> List.filter_map ~f:(fun (char, digit) ->
           if Char.is_digit char then Some digit else None)
    |> String.of_char_list
  in
  let x, y = check in
  printf "%s-%d%d\n" extracted x y
