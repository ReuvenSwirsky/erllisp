# Erlisp

A tiny Lisp interpreter implemented as an Erlang OTP application.

## Requirements

- Erlang/OTP 25+
- rebar3

## Run

```bash
rebar3 shell
```

Then in the Erlang shell:

```erlang
erllisp_repl:start().
```

## Test

```bash
rebar3 eunit
```

## Example

```lisp
(+ 1 2 3)
(* 4 (+ 1 1))
(if true 10 20)
```
