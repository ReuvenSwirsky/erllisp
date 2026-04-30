# Erlisp

A Lisp interpreter implemented as an Erlang OTP application.

## Requirements

- Erlang/OTP 25+
- rebar3

## Quick Start

```bash
rebar3 shell --apps erllisp
```

Then start the REPL:

```erlang
1> erllisp_repl:start().
```

```lisp
erlisp> (+ 1 2 3)
6
erlisp> (defn square (n) (* n n))
square
erlisp> (square 12)
144
erlisp> (load "programs/lists.lisp")
t
erlisp> :q
```

## Run Tests

```bash
rebar3 eunit
```

## Language Features

| Feature | Example |
|---------|---------|
| Arithmetic | `(+ 1 (* 3 4))` |
| Booleans | `(if (< x 0) 'negative 'positive)` |
| Strings | `"hello"` |
| `nil` / lists | `(cons 1 (cons 2 nil))` → `(1 2)` |
| Quote | `'(a b c)` |
| Quasiquote | `` `(1 ,(+ 1 1) 3) `` → `(1 2 3)` |
| Named functions | `(defn fib (n) (if (< n 2) n (+ (fib (- n 1)) (fib (- n 2)))))` |
| Anonymous functions | `(fn (x) (* x x))` |
| Closures | `(let add (fn (x) (fn (y) (+ x y))) ((add 3) 4))` |
| Variadic args | `(defn sum (&rest xs) (foldl (fn (a b) (+ a b)) 0 xs))` |
| Macros | `(defmacro when (c b) \`(if ,c ,b nil))` |
| `let` / `let*` | `(let* ((a 1) (b (+ a 1))) b)` |
| `begin` | `(begin (print 1) (print 2) 3)` |
| `map` / `filter` | `(map (fn (x) (* x x)) '(1 2 3 4 5))` |
| `apply` | `(apply + '(1 2 3))` |
| Tail-call optimization | Recursive loops over millions of iterations without stack overflow |
| Introspection | `(describe fib)` `(source fib)` |
| File loading | `(load "programs/lists.lisp")` → `t` |

## Example Programs

| File | Contents |
|------|----------|
| `programs/fib10.lisp` | Returns fib(10) = 55 |
| `programs/fib1000.lisp` | Prints first 1000 Fibonacci numbers |
| `programs/lists.lisp` | cons/car/cdr, range, map, filter, fold |
| `programs/macros.lisp` | defmacro, quasiquote templates, when/unless |
| `programs/variadic.lisp` | &rest, apply, map, filter |
| `programs/tco_demo.lisp` | Tail-call countdown (1M), sum (1M), Ackermann |

Load any of them from the REPL:

```lisp
erlisp> (load "programs/tco_demo.lisp")
```

Or from the Erlang shell:

```erlang
erllisp:eval_file("programs/lists.lisp").
```

## Error Messages

The REPL shows human-readable errors:

```lisp
erlisp> (load "missing.lisp")
error: file not found: missing.lisp

erlisp> (foo 1 2)
error: unbound symbol: foo

erlisp> (car nil)
error: car of nil
```

## Syntax Manual

See [`docs/MANUAL.md`](docs/MANUAL.md) for the full language reference.
