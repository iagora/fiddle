# Nome do projeto

<img src="image.png" alt="Fiddle logo">

> Fiddle é produto do meu tédio. No momento é só um programa besta em OCaml pra pegar números que sejam possíveis CPFs, calcular os dígitos verificadores corretos, e calcular o hash do CPF. Como se fosse uma Rainbow Table de CPFs. Não é exatamente útil. 

### Ajustes e melhorias

O projeto ainda está em desenvolvimento:

- [x] Gerar dígitos verificadores.
- [x] Fazer o hash, e jogá-lo pra stdout.
- [ ] Criar interface cli, ao invés de apenas receber stdin.
- [ ] Criar man, e help.

## 💻 Pré-requisitos

Antes de começar, verifique se você atendeu aos seguintes requisitos:

- `opam 4.13 / Cryptokit `

## 🚀 Compilando Fiddle

Para compilar o Fiddle, siga estas etapas:

```
ocamlfind ocamlopt -package cryptokit -linkpkg fiddle.ml -o fiddle
```


## ☕ Usando Fiddle

Para usar Fiddle, siga estas etapas:

Teste123:
```
echo 123456789 | ./fiddle > rainbow_table.txt
```
O resultado deve ser 123456789-09

Inferninho não comprimido:
```
seq 0 999999999 | ./fiddle > rainbow_table.txt
```

## 📝 Licença

Esse projeto está sob licença. Veja o arquivo [LICENÇA](LICENSE.md) para mais detalhes.
