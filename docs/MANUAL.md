# Erlisp Manual

## 1. Overview

Erlisp is a Lisp interpreter implemented in Erlang. It supports closures, macros,
tail-call optimization, variadic functions, and a persistent-environment REPL.

## 2. Quick Start

```bash
rebar3 shell --apps erllisp
```
```erlang
1> erllisp_repl:start().
```
```lisp
erlisp> (defn square (n) (* n n))
square
erlisp> (square 7)
49
erlisp> :q
```

## 3. Data Types

| Type | Examples |
|------|---------|
| Integer | `0`, `1`, `-42` |
| Boolean | `true`, `false` |
| String | `"hello"` |
| Symbol | `x`, `total`, `fib-seq` |
| Nil | `nil` — the empty list and falsy value |
| List | `(1 2 3)`, built with `cons` or `list` |
| Function | created by `fn` or `defn` |

Integers, booleans, strings, and `nil` are self-evaluating.
Symbols are looked up in the environment.
Lists are function or special-form calls.

## 4. Special Forms

### begin

```lisp
(begin expr1 expr2 ... exprN)
```

Evaluates each expression in order; returns the value of the last one.

### if

```lisp
(if condition then-expr else-expr)
(if condition then-expr)          ; else branch returns nil
```

`nil` and `false` are falsy; everything else is truthy.

### let

```lisp
(let name value-expr body-expr)
```

Binds `name` to the result of `value-expr` inside `body-expr`.

### let*

```lisp
(let* ((a 1) (b (+ a 1))) body-expr)
```

Sequential bindings — each binding can reference the ones before it.

### defn

```lisp
(defn name (param1 param2 ...) body-expr)
(defn name (param1 &rest rest) body-expr)  ; variadic
```

Defines a named function in the current environment. Supports self-recursion.
With `&rest`, trailing arguments are collected into a list bound to `rest`.

### fn

```lisp
(fn (param1 param2 ...) body-expr)
(fn (param1 &rest rest) body-expr)
```

Creates an anonymous closure. Captures the environment at the point of creation.

### set!

```lisp
(set! name value-expr)
```

Updates an existing binding in the current environment.

### quote

```lisp
'expr
(quote expr)
```

Returns `expr` unevaluated. `'(a b c)` → the list `(a b c)`.

### quasiquote

```lisp
`(a ,b ,@c)
```

Like `quote`, but `,expr` unquotes (evaluates) a single expression and
`,@expr` splices a list into the surrounding form.

```lisp
(let x 2
  `(1 ,x 3))      ; → (1 2 3)

(let xs '(2 3)
  `(1 ,@xs 4))    ; → (1 2 3 4)
```

### defmacro

```lisp
(defmacro name (param1 param2 ...) body-expr)
```

Defines a macro. When `(name ...)` is called, the body runs with the raw
(unevaluated) argument forms bound to the parameters. The result is then
evaluated in the caller's environment.

```lisp
(defmacro when (cond body)
  `(if ,cond ,body nil))

(when (> x 0) (print x))
```

### load

```lisp
(load "path/to/file.lisp")
```

Reads, parses, and evaluates all top-level forms in the file.
Definitions are added to the current environment.
Returns `t` on success.

Errors are reported as human-readable messages:
```lisp
erlisp> (load "missing.lisp")
error: file not found: missing.lisp
```

### describe

```lisp
(describe symbol)
```

Returns a description tuple for the symbol:
- `(description name builtin doc)`
- `(description name function ((arity N) (params (p1 p2))))`
- `(description name macro ((arity N) (params (p1 p2))))`
- `(description name value Value)`
- `(description name unbound nil)`

### source / source-fn

```lisp
(source symbol)    ; prints the source form, returns ok
(source-fn symbol) ; returns the source form as a string
```

## 5. Built-in Functions

### Arithmetic

| Form | Description |
|------|-------------|
| `(+ a b ...)` | Sum |
| `(- a b ...)` | Subtract left to right; `(- n)` negates |
| `(* a b ...)` | Product |
| `(/ a b ...)` | Integer division left to right |
| `(mod a b)` | Remainder |

### Comparisons

| Form | Description |
|------|-------------|
| `(= a b)` | Equal |
| `(< a b)` | Less than |
| `(> a b)` | Greater than |
| `(<= a b)` | Less than or equal |
| `(>= a b)` | Greater than or equal |

### Logic

| Form | Description |
|------|-------------|
| `(not x)` | Logical not — `nil` and `false` → `true` |
| `(and a b ...)` | Returns last truthy value or `false` |
| `(or a b ...)` | Returns first truthy value or `false` |

### List Operations

| Form | Description |
|------|-------------|
| `(cons head tail)` | Prepend to a list |
| `(car list)` | First element |
| `(cdr list)` | All but first element; `(cdr '(x))` → `nil` |
| `(list a b ...)` | Construct a list |
| `(null? x)` | `true` if `x` is `nil` |
| `(pair? x)` | `true` if `x` is a non-empty list |
| `(list? x)` | `true` if `x` is `nil` or a proper list |
| `(length list)` | Number of elements |
| `(append a b)` | Concatenate two lists |
| `(reverse list)` | Reverse a list |
| `(map fn list)` | Apply `fn` to each element, return new list |
| `(filter fn list)` | Keep elements where `fn` returns truthy |
| `(apply fn args-list)` | Call `fn` with elements of `args-list` as arguments |

### Type Predicates

`(number? x)`, `(string? x)`, `(symbol? x)`, `(fn? x)`

### Output

| Form | Description |
|------|-------------|
| `(print x)` | Print `x` as Lisp, return `x` |
| `(println x)` | Print `x` followed by newline, return `nil` |

### String Helpers

| Form | Description |
|------|-------------|
| `(str a b ...)` | Concatenate values as strings |
| `(number->string n)` | Integer to string |
| `(string->number s)` | String to integer, or `false` if invalid |

## 6. Tail-Call Optimization

All tail positions are optimized via a trampoline:
- The `then`/`else` branches of `if`
- The last expression of `begin`
- The body of `defn` and `fn`

This means loops written as tail-recursive functions never overflow the stack:

```lisp
(defn loop (n)
  (if (= n 0) 'done (loop (- n 1))))

(loop 1000000)  ; → done
```

## 7. Example Programs

| File | Description |
|------|-------------|
| `programs/fib10.lisp` | Returns fib(10) |
| `programs/fib1000.lisp` | Prints first 1000 Fibonacci numbers |
| `programs/lists.lisp` | cons, range, map, filter, fold |
| `programs/macros.lisp` | defmacro, quasiquote templates, when/unless |
| `programs/variadic.lisp` | &rest, apply, map, filter |
| `programs/tco_demo.lisp` | Tail-call countdown (1M iterations), Ackermann |

```lisp
erlisp> (load "programs/lists.lisp")
(1 2 3 4 5 6 7 8 9 10)
55
(1 4 9 16 25 36 49 64 81 100)
(2 4 6 8 10)
55
t
```

## 8. REPL Commands

| Input | Effect |
|-------|--------|
| Any Lisp expression | Evaluate and print result |
| `:q` or `quit` | Exit the REPL |

The REPL preserves all definitions between expressions in the same session.
Use `load` to bring in definitions from files.

## 9. Error Messages

The REPL shows human-readable errors rather than raw Erlang terms:

| Situation | Message |
|-----------|---------|
| File not found | `error: file not found: path.lisp` |
| Permission denied | `error: permission denied: path.lisp` |
| Unbound symbol | `error: unbound symbol: foo` |
| Wrong arg count | `error: wrong number of arguments: expected 2, got 3` |
| Not a function | `error: 42 is not a function` |
| car of nil | `error: car of nil` |
| Division by zero | `error: division by zero` |

## 10. Current Limitations

- No `try`/`catch` yet — errors propagate back to the REPL (Phase 3).
- No `cond` yet — use nested `if` in the meantime.
- No `letrec` — mutually recursive local functions not yet supported.
- Symbols are interned as Erlang atoms (not safe for untrusted input at scale).
- No character or floating-point types.
