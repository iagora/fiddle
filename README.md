# 🎻 fiddle

<img src="image.png" alt="Fiddle logo">

> fiddle is a product of my boredom and a work in progress. I won't keep the README updated at the moment because I'm focusing on features, and since it's still in its infancy, the main branch is where development happens too. Currently, Fiddle is just a simple OCaml program to generate possible CPF numbers, calculate the correct check digits, and compute the hash of the CPF. It's like a Rainbow Table of CPFs. Not exactly useful.

## Adjustments and improvements

The project is still in development:

- [x] Option for hash algorithm and length.
- [x] Option for keyed hash or MAC, via the `FIDDLE_SECRET_KEY` environment variable.
- [x] Reverse search, find a CPF from a hash.
- [x] Verify if the input already has check digits, just confirm if they are correct.
- [x] Mask processor, with the ability to dictate which format the CPF should use `xxx.xxx.xxx-xx`, `xxxxxxxxx-xx`, `xxxxxxxxxxx` and so on.
- [ ] Support search through pre-computed hash tables

## 💻 Prerequisites

Before starting, make sure you have met the following requirements:

- `opam 5.2.0+flambda`
- `dune`
- `cryptokit`
- `Core`
- `Core_unix`

## 🚀 Compiling fiddle

To compile fiddle, follow these steps:

$ dune build

I still need to write the installation functionality, generate a release, and so on.

## 🎻 Using fiddle

# Basics

To use fiddle, follow these steps:

Test123:

``` bash
$ echo 123456789 | fiddle
```
The result should be:

``` bash
123456789-09  65ffb63cf915bb8919d61837aa335bb39f4e07065e772b326bfb8de79d60745e
```

fiddle can process more than one CPF.

``` bash
$ echo "123456789\n987654321" | fiddle
```

or

``` bash
$ echo "123456789 987654321" | tr " " "\n" | fiddle
```

The important thing is each value should be separated by a `newline`. Which means you can run:

``` bash
$ seq 10000 | fiddle
```

You can list the available hash and mac algorithms via:

``` bash
$ fiddle --list
```

And select the desired one with `-h` or `--hash`.

``` bash
$ echo 123456789 | fiddle -h sha512
```

Some algorithms require specifying the output length:

``` bash
$ echo 123456789 | fiddle --hash blake2b --length 64
```

To use a keyed hash or mac, the `FIDDLE_SECRET_KEY` environment variable must contain a base64 secret key. An algorithm must be selected with the `-m` or `--mac` flag:

``` bash
$ export FIDDLE_SECRET_KEY="DmPBlJkhjvN0HxCKK9HrsiFLzIotZG9MT727xddLIzw="
$ echo 123456789 | fiddle --mac sha256
```

As a ~~joke~~ treat, there's also a reverse search, which can be triggered via the `-u` flag, short for `--ughh`, or `--unhash`, your choice because 🎉🗳️*DEMOCRACY*🗳️🎉:

``` bash
$ fiddle -h md5 -u 823e99bf5f87df225fe8ce4c46340b73
```

Which will result in: `000000003-53`.

There is also Taco Bell parallelism, but it's not working properly at the moment:

``` bash
$ seq 200 | xargs -L 25 -P 8 fiddle
```

# Masks

`fiddle` also comes with `mascaml`, and supports masks. `mascaml` is a maskprocessor, that works similar to `hashcat`'s.
Say for example, that whoever decide to make a database indexing by CPF hashes, decided to avoid pre-computed hashtables
by adding other things to the string, or say permute the order of the digits. `mascaml` can generate all the combinations of
CPFs with a mask like

``` bash
$ mascaml ")(?d?d?dun?d?d?dhash?d?d?d-xy"
```

This would generate all values from `)(000un000hash000-xy` until  `)(999un999hash999-xy`.
`fiddle` can take these inputs, through its own mask support:

``` bash
$ fiddle --mask ")(987un654hash321-xy"
```

It recognizes `x` and `y` as the placement for the check digits, respectively. And takes the numbered digits as the ordering.
So, say that `mascaml` generates the input value `)(001un671hash540-xy`, fiddle knows that there is a permutation where this actually
corresponds to the CPF `045176100` and that `x` and `y` are supposed to be the check digits, which it calculates and places appropriately
before calculating the hash. So it'd take the hash of `)(001un671hash540-63`, as `63` are the check digits for `045176100`.
So you could generate a table for all these mangled CPFs with a command like:

``` bash
$ mascaml ")(?d?d?dun?d?d?dhash?d?d?d-xy" | fiddle --mask ")(987un654hash321-xy"
```
Which would generate the following output:

```bash
000000000-00	)(000un000hash000-00	ed6f912a42fa32b108dcaf8aca0e9b1c349e3494f162c3937c179e495fdbc98b
100000000-19	)(000un000hash001-19	69937cc5287b4dc33259cec10a525dfb88d959022495badea1739d35dc099ba5
200000000-27	)(000un000hash002-27	1de87d04d043f7919b7d4f4101282269406632a0400978e7c876991c82a89091
300000000-35	)(000un000hash003-35	2b2e5fc782383e1e122df23a44189804d9fbc5ac7cb1d6a80121504414f89194
400000000-43	)(000un000hash004-43	9ec6093c1d6b6dc00edbb4096035c6a0f7d052b7e3cafbb9c47697946ccc898e
500000000-51	)(000un000hash005-51	b41d1e0b082d1ee9298c2e9030611904cbf5bf33284ea32c14f9ca5791d6c47c
600000000-60	)(000un000hash006-60	bd43a887d71b7144844ad91174a26398b09644efce3714f6760deb4fec6994ff
700000000-78	)(000un000hash007-78	e40b5dd2f20484b472c0c1a5d108a415e7443188765180e902f221350ac0c8ed
800000000-86	)(000un000hash008-86	3aab0d646b2160bf5b95bc2b0a5e22972089c708fe3f9f56108a0f64b3b82b54
900000000-94	)(000un000hash009-94	1b5a69678cd29073c44c3dda1616aeffd7be17347af355ffe6cbf896b61f08b1
.               .                       .
.               .                       .
.               .                       .
```

In case the input instead of having `x` and `y`, has the check digits, fiddle will consider the values provided over the calculated ones, but will output a `*` to indicate an error in case the check digits presented do not match the calculated ones.

Say, `fiddle --mask ")(987un654hash321-xy"` takes instead of `)(001un671hash540-xy` or `)(001un671hash540-63` (which has the correct check digits), it receives `)(001un671hash540-91`,
instead of outputting:

``` bash
045176100-63	)(001un671hash540-63	36ec01cc8c1df9f2b99c1f6b896eab611180d0ffc7cdda2009441f4aab2a6b44
```

It will output:

``` bash
045176100-63*	)(001un671hash540-91	5166741dd0b1b797e2bba6f27b2a1436c5e13fef5f225ea7666743f08d321a0e
```


## 📝 License

This project is licensed. See the [LICENSE](LICENSE.md) file for more details.
