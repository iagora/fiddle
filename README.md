# Fiddle

<img src="image.png" alt="Fiddle logo">

> Fiddle é produto do meu tédio e um trabalho em progresso. Eu não vou manter o README atualizado no momento, porque eu to correndo atrás das features, e como está muito na infância, o branch main é onde se desenvolve também. Fiddle no momento é só um programa besta em OCaml pra pegar números que sejam possíveis CPFs, calcular os dígitos verificadores corretos, e calcular o hash do CPF. Como se fosse uma Rainbow Table de CPFs. Não é exatamente útil. 

### Ajustes e melhorias

O projeto ainda está em desenvolvimento:

- [x] Gerar dígitos verificadores.
- [x] Fazer o hash, e jogá-lo pra stdout.
- [x] Criar interface cli, ao invés de apenas receber stdin.
- [x] Opção de algoritmo de hash e comprimento.
- [x] Opção de hash chaveado ou MAC, via variável de ambiente `FIDDLE_SECRET_KEY`
- [ ] Busca reversa, a partir de um hash, encontre um CPF.
- [ ] Verificar se a entrada já está com os dígitos verificadores.
- [ ] Mask processor, com a capacidade de ditar qual formato o CPF se encontra `xxx.xxx.xxx-xx`, `xxxxxxxxx-xx` ou `xxxxxxxxxxx`
- [ ] Suportar busca através de hash table pré-computadas????

## 💻 Pré-requisitos

Antes de começar, verifique se você atendeu aos seguintes requisitos:

- `opam 5.2.0 / Cryptokit / Core / Core_unix`

## 🚀 Compilando Fiddle

Para rodar o Fiddle, siga estas etapas:

```
dune build 
```

Eu ainda tenho que escrever a funcionalidade de instalação

## 🎻 Usando Fiddle

Para usar Fiddle, siga estas etapas:

Teste123:
```
$ fiddle single 123456789
```
O resultado deve ser:

```
123456789-09	65ffb63cf915bb8919d61837aa335bb39f4e07065e772b326bfb8de79d60745e
```

Você pode listar os algoritmos de hash e mac disponíveis via:

```
$ fiddle list-algorithms
```

E selecionar o que deseja com

```
$ fiddle single 123456789 -hash sha512
```

Alguns algoritmos necessitam que se especifique o tamanho da saída:

```
$ fiddle single 123456789 -hash blake2b -length 64
```

Para utilizar hash chaveado ou mac:

```
$ export FIDDLE_SECRET_KEY="DmPBlJkhjvN0HxCKK9HrsiFLzIotZG9MT727xddLIzw="
$ fiddle single 123456789 -mac sha256
```

O fiddle também aceita input direto do standard input, através do modo `stdin`,
você pode por exemplo gerar um inferninho não comprimido:
```
$ seq 0 999999999 | fiddle stdin > rainbow_table.txt
```

Também tem paralelismo taco bell:

```
$ seq 200 | xargs -L 25 -P 8 fiddle multiple
```

## 📝 Licença

Esse projeto está sob licença. Veja o arquivo [LICENÇA](LICENSE.md) para mais detalhes.
