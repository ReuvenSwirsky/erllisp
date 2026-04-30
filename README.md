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
(describe +)
(source +)
```

Load and run the pure Lisp Fibonacci printer:

```lisp
(load "programs/fib1000.lisp")
```

It prints the first 1000 Fibonacci numbers, one per line.

## Load Program Files

You can load and execute Lisp files at runtime:

```lisp
(load "programs/fib1000.lisp")
```

Loaded files can now contain multiple top-level expressions; they are evaluated in order.

The repository includes:

- `programs/fib1000.lisp`
- `programs/fib10.lisp` (returns 55)

After loading, definitions remain available in the same session, so this works:

```lisp
(load "programs/fib10.lisp")
(describe fib)
(source fib)
(fib 11)
```

## Syntax Manual

See `docs/MANUAL.md`.
