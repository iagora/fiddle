# Nome do projeto

<img src="image.png" alt="Fiddle logo">

> Fiddle é produto do meu tédio. No momento é só um programa besta em OCaml pra pegar números que sejam possíveis CPFs, calcular os dígitos verificadores corretos, e calcular o hash do CPF. Como se fosse uma Rainbow Table de CPFs. Não é exatamente útil. 

### Ajustes e melhorias

O projeto ainda está em desenvolvimento:

- [x] Gerar dígitos verificadores.
- [x] Fazer o hash, e jogá-lo pra stdout.
- [ ] Criar interface cli, ao invés de apenas receber stdin.
- [ ] Opção de algoritmo de hash e comprimento.
- [ ] Busca reversa, a partir de um hash, encontre um CPF.

## 💻 Pré-requisitos

Antes de começar, verifique se você atendeu aos seguintes requisitos:

- `opam 4.13 / Cryptokit / Core`

## 🚀 Compilando Fiddle

Para rodar o Fiddle, siga estas etapas:

```
dune exec fiddle
```


## ☕ Usando Fiddle

Para usar Fiddle, siga estas etapas:

Teste123:
```
echo 123456789 | dune exec fiddle > rainbow_table.txt
```
O resultado deve ser:

```
123456789-09    afa3f197d6d9bc55b26d0827aae1d64e651a2014f434d0de31ab33b906a1da4547b38ebc226c241b6852272f9bbf1a0c1d0eb3ea8438e37534f351de07a70d75
```

Inferninho não comprimido:
```
seq 0 999999999 | dune exec fiddle > rainbow_table.txt
```

## 📝 Licença

Esse projeto está sob licença. Veja o arquivo [LICENÇA](LICENSE.md) para mais detalhes.
