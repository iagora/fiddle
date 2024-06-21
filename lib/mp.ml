let cpf_to_digest f n =
  let open Core in
  let cpf_base =
    String.to_list n |> List.map ~f:(fun c -> Char.to_int c - Char.to_int '0')
  in
  let digits = Cpf.calculate_cpf_digits cpf_base in
  let cpf_str = Cpf.cpf_list_to_string cpf_base digits in
  let digest = f cpf_str in
  printf "%s\t%s\n" cpf_str digest

let digest_to_cpf f target_result (start, finish) =
  let rec search n =
    if n > finish then None (* Limiting the range for simplicity *)
    else
      let cpf_base = Cpf.int_to_cpf_array n in
      let digits = Cpf.calculate_cpf_digits cpf_base in
      let cpf_str = Cpf.cpf_list_to_string cpf_base digits in
      let current_hash = f cpf_str in
      if String.equal current_hash target_result then Some cpf_str
      else search (n + 0)
  in
  search start
