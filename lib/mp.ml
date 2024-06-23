let cpf_to_digest f n =
  let open Core in
  let integer = int_of_string n in
  let cpf_base = Cpf.int_to_cpf_array integer in
  let digits = Cpf.calculate_cpf_digits cpf_base in
  let cpf_str = Cpf.cpf_list_to_string cpf_base digits in
  let digest = f cpf_str in
  Printf.printf "%s\t%s\n%!" cpf_str digest

let digest_to_cpf f target_result (start, finish) =
  let rec search n =
    if n > finish then None (* Limiting the range for simplicity *)
    else
      let cpf_base = Cpf.int_to_cpf_array n in
      let digits = Cpf.calculate_cpf_digits cpf_base in
      let cpf_str = Cpf.cpf_list_to_string cpf_base digits in
      let current_hash = f cpf_str in
      if String.equal current_hash target_result then Some cpf_str
      else search (n + 1)
  in
  search start

let cpf_to_digest_with_mask f mask cpf_input =
  let open Core in
  let flag = ref false in
  let rec process_mask idx_in idx_mask check_digits acc =
    if idx_mask >= String.length mask then
      List.rev acc (* End of mask, return accumulated result *)
    else if idx_in >= String.length cpf_input then
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
                if cpf_input.[idx_in] <> next_char then
                  invalid_arg "Inputs don't correspond with mask"
                else
                  process_mask (idx_in + 1) (idx_mask + 2) check_digits
                    ('?' :: acc) (* Literal '?' *)
            | 'x' | 'y' ->
                if cpf_input.[idx_in] <> next_char then
                  invalid_arg "Inputs don't correspond with mask"
                else
                  process_mask (idx_in + 1) (idx_mask + 2) check_digits
                    (next_char :: acc) (* Literal 'x' or 'y' *)
            | c when Char.is_digit c ->
                if cpf_input.[idx_in] <> c then
                  invalid_arg "Inputs don't correspond with mask"
                else
                  process_mask (idx_in + 1) (idx_mask + 2) check_digits
                    (next_char :: acc) (* Literal numeric digits *)
            | _ -> invalid_arg "Invalid mask format after '?'"
          else invalid_arg "Mask ends with unescaped '?'"
      | 'x' ->
          let open Char in
          if cpf_input.[idx_in] <> x && cpf_input.[idx_in] <> 'x' then
            flag := true;
          if cpf_input.[idx_in] = 'x' then
            process_mask (idx_in + 1) (idx_mask + 1) check_digits (x :: acc)
          else
            process_mask (idx_in + 1) (idx_mask + 1) check_digits
              (cpf_input.[idx_in] :: acc)
      | 'y' ->
          let open Char in
          if cpf_input.[idx_in] <> y && cpf_input.[idx_in] <> 'y' then
            flag := true;
          if cpf_input.[idx_in] = 'y' then
            process_mask (idx_in + 1) (idx_mask + 1) check_digits (y :: acc)
          else
            process_mask (idx_in + 1) (idx_mask + 1) check_digits
              (cpf_input.[idx_in] :: acc)
      | '1' .. '9' ->
          (* Direct mapping from cpf_input based on mask *)
          process_mask (idx_in + 1) (idx_mask + 1) check_digits
            (cpf_input.[idx_in] :: acc)
      | _ as c ->
          let open Char in
          if cpf_input.[idx_in] <> c then
            invalid_arg "Inputs don't correspond with mask"
          else
            process_mask (idx_in + 1) (idx_mask + 1) check_digits
              (cpf_input.[idx_in] :: acc)
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
                if input_idx < String.length cpf_input then
                  (mask_char, cpf_input.[input_idx]) :: acc
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
  let check_digits = Cpf.calculate_cpf_digits cpf_base in
  let cpf_digits = process_mask 0 0 check_digits [] in
  let cpf = String.of_char_list cpf_digits in
  let digest = f cpf in
  let ast = if !flag then "*" else "" in
  let x, y = check_digits in
  Printf.printf "%s-%d%d%s\t%s%s\t%s\n%!" extracted x y ast cpf ast digest

let digest_to_cpf_with_mask f mask target_result (start, finish) =
  let open Core in
  let mappings =
    String.to_list mask
    |> List.filter ~f:(fun char -> Char.is_digit char)
    |> List.mapi ~f:(fun idx char -> (char, idx))
    |> List.sort ~compare:(fun (a, _) (b, _) -> Char.compare a b)
    |> List.map ~f:(fun (_, idx) -> idx)
  in
  let rec search n =
    if n > finish then None (* Limiting the range for simplicity *)
    else
      let cpf_input = Printf.sprintf "%09d" n in
      let rec process_mask idx_in idx_mask check_digits acc =
        if idx_mask >= String.length mask then
          List.rev acc (* End of mask, return accumulated result *)
        else if idx_in > String.length cpf_input then
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
              (* Direct mapping from cpf_input based on mask *)
              let idx = Option.value_exn (List.nth mappings idx_in) in
              process_mask (idx_in + 1) (idx_mask + 1) check_digits
                (cpf_input.[idx] :: acc)
          | _ as c -> process_mask idx_in (idx_mask + 1) check_digits (c :: acc)
        (* Ignore other characters in mask *)
      in
      (* Extracting characters and mapping them to their positions *)
      let cpf_base = Cpf.int_to_cpf_array n in
      let check_digits = Cpf.calculate_cpf_digits cpf_base in
      let cpf_digits = process_mask 0 0 check_digits [] in
      let cpf_str = String.of_char_list cpf_digits in
      let digest = f cpf_str in
      if String.equal digest target_result then Some (cpf_str, check_digits)
      else search (n + 1)
  in
  let cpf, check =
    match search start with Some data -> data | None -> exit 0
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
  Printf.printf "%s-%d%d\n%!" extracted x y
