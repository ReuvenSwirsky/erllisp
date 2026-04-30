# Erlisp Manual

## 1. Overview

Erlisp is a small Lisp interpreter implemented in Erlang.

Current goals:
- Keep syntax small and predictable.
- Make experimentation easy from REPL and files.

## 2. Quick Start

1. Start shell:
   - rebar3 shell
2. Start REPL from Erlang shell:
   - erllisp_repl:start().
3. Enter expressions at prompt.

## 3. Data Types

Supported literal values:
- Integer: 0, 1, -42
- Boolean: true, false
- String: "hello"
- Symbol: x, total, fib-seq
- List form: (operator arg1 arg2 ...)

## 4. Core Evaluation Rules

- Integers, booleans, and strings evaluate to themselves.
- Symbols are looked up in environment maps.
- Lists are function/special-form calls.

## 5. Special Forms

### begin

Syntax:
- (begin expr1 expr2 ... exprN)

Evaluates expressions in order and returns the last value.

### if

Syntax:
- (if condition then-expr else-expr)

Condition must evaluate to true or false.

### let

Syntax:
- (let name value-expr body-expr)

Creates a local binding visible in body-expr.

### defn

Syntax:
- (defn name (param1 param2 ...) body-expr)

Defines a named function in the current scope.
Supports recursion.

### fn

Syntax:
- (fn (param1 param2 ...) body-expr)

Creates an anonymous function value.

### load

Syntax:
- (load "relative/or/absolute/path.lisp")
- (load programs/fib1000.lisp)

Reads the file, parses it as one Erlisp expression, and evaluates it.
Files may contain multiple top-level expressions; they are executed in order and the last value is returned.
Definitions from loaded files are retained in the current evaluation environment.

### describe

Syntax:
- (describe symbol)

Reports information about a symbol. The result is a tuple:
- {description, name, builtin, doc}
- {description, name, function, [{arity, N}, {params, Params}]}
- {description, name, value, Value}
- {description, name, unbound, undefined}

### source / source-fn

Syntax:
- (source symbol)
- (source-fn symbol)

Returns source information for a symbol:
- {source, name, form} for user-defined functions
- {source, name, builtin, doc} for builtins
- {source, name, not_function} for bound non-function values
- {source, name, unbound, undefined} when symbol is not bound

## 6. Built-in Functions

Arithmetic:
- (+ a b ...)
- (- a b ...)
- (* a b ...)
- (/ a b ...)

Comparisons:
- (= a b)
- (< a b)
- (> a b)

Output:
- (print x) -> prints x and returns x

## 7. Example Programs

Project includes loadable examples in programs/.

Print first 1000 Fibonacci numbers:
- (load "programs/fib1000.lisp")

Return fib(10):
- (load "programs/fib10.lisp")

## 8. REPL Commands

- :q
- quit

## 9. Current Limitations

- Reader does not support escaped characters in strings.
- Symbols are interned as Erlang atoms (not safe for untrusted code).
