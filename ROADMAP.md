# Erlisp Roadmap — Full Lisp Feature Parity

## Completed

- [x] Integer arithmetic: `+`, `-`, `*`, `/`, `mod`
- [x] Booleans: `true`, `false`
- [x] Strings: `"hello"`
- [x] Symbols and lexical environments
- [x] `if` (2- and 3-branch) / `let` / `begin`
- [x] `defn` — named recursive functions
- [x] `fn` — anonymous closures
- [x] Comparisons: `=`, `<`, `>`, `<=`, `>=`
- [x] `print` / `println`
- [x] `load` — multi-form file loading with environment persistence
- [x] `describe` — symbol introspection
- [x] `source` / `source-fn` — Lisp-printed source form retrieval
- [x] REPL with persistent environment
- [x] `;` line comments

### Phase 1 ✅ — Core Lisp Primitives

- [x] `nil` literal — the empty list / falsy value
- [x] `cons` / `car` / `cdr` / `list` / `null?` / `pair?` / `list?`
- [x] Printer: cons chains render as `(a b c)` or `(a . b)`
- [x] `'x` quote sugar, `` `x `` quasiquote, `,x` unquote, `,@x` unquote-splicing
- [x] `(quote expr)` / `(quasiquote expr)` special forms
- [x] `defmacro` — macro transformer on raw AST, result re-evaluated in caller env
- [x] `set!` — mutate binding in current env

### Phase 2 ✅ — Language Completeness

- [x] Variadic functions: `(defn f (a &rest rest) body)`
- [x] Tail-call optimization — trampoline; `if`/`begin`/function-body tail positions bounce
- [x] `let*` — sequential bindings
- [x] `not` / `and` / `or` builtins
- [x] `apply` — `(apply f args-list)`
- [x] `map` / `filter` — higher-order list operations
- [x] `length` / `append` / `reverse`
- [x] `str` / `number->string` / `string->number`
- [x] `number?` / `string?` / `symbol?` / `fn?` type predicates

---

## Phase 3 — Ergonomics (next up)

### 1. `cond`

Multi-branch conditional sugar:
```lisp
(cond
  ((= x 0) 'zero)
  ((< x 0) 'negative)
  (true    'positive))
```
Can be implemented as a macro over nested `if`.

### 2. `letrec`

Mutually recursive local functions — bindings all visible to each other's bodies:
```lisp
(letrec ((even? (fn (n) (if (= n 0) true  (odd?  (- n 1)))))
         (odd?  (fn (n) (if (= n 0) false (even? (- n 1))))))
  (even? 10))
```

### 3. `do` / `loop-recur`

Iterative looping without explicit recursion:
```lisp
(do ((i 0 (+ i 1))
     (acc 0 (+ acc i)))
    ((= i 10) acc))
```

### 4. `when` / `unless` macros

```lisp
(when (> x 0) (print x) x)
(unless (null? xs) (car xs))
```

### 5. String builtins

- `str-length` — `(str-length "hello")` → 5
- `str-concat` — alias for `str`
- `str-split` — `(str-split "a,b,c" ",")` → `("a" "b" "c")`
- `str-contains` / `str-starts-with` / `str-ends-with`

### 6. Exception handling

```lisp
(try
  (/ 1 0)
  (catch e (print e) 'error))
```
Maps to Erlang `try/catch`.

### 7. `macroexpand` / `macroexpand-1`

Introspect macro expansion without evaluating the result — essential for debugging macros.

---

## Phase 4 — Advanced

### 8. Namespaces / modules

Group definitions into named scopes. Load with `(require "module")`.

### 9. Proper tail calls across mutual recursion

Currently TCO only covers self-tail calls and simple tail positions. Full proper tail calls
across mutually-recursive functions require continuation-passing or first-class trampolines
shared across function boundaries.

### 10. Hygienic macros (`syntax-rules` style)

Pattern-based macros that don't accidentally capture free variables.

### 11. Continuations (`call/cc`)

Full Scheme-style first-class continuations. Very complex with Erlang stack model —
likely requires a CPS transform of the entire evaluator.

---

## Implementation Order

```
Phase 3 items — cond/letrec/do/when/unless, strings, exceptions, macroexpand
Phase 4 items — namespaces, full TCO, call/cc (advanced, lower priority)
```
