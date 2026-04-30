# Erlisp Roadmap — Full Lisp Feature Parity

## Completed

- [x] Integer arithmetic: `+`, `-`, `*`, `/`
- [x] Booleans: `true`, `false`
- [x] Strings: `"hello"`
- [x] Symbols and lexical environments
- [x] `if` / `let` / `begin`
- [x] `defn` — named recursive functions
- [x] `fn` — anonymous closures
- [x] Comparisons: `=`, `<`, `>`
- [x] `print`
- [x] `load` — multi-form file loading with environment persistence
- [x] `describe` — symbol introspection
- [x] `source` / `source-fn` — Lisp-printed source form retrieval
- [x] REPL with persistent environment

---

## Phase 1 — Core Lisp Primitives (implement now)

### 1. nil / cons cells / list primitives

`nil` is the empty list. Proper cons pairs underpin all Lisp data structures.

Forms to add:
- `nil` literal → evaluates to `nil`
- `cons` builtin → `(cons head tail)`
- `car` builtin → first element of a pair/list
- `cdr` builtin → tail of a pair/list
- `list` builtin → `(list 1 2 3)` → cons chain
- `null?` / `pair?` / `list?` predicates

Printer: render cons chains as `(a b c)` or `(a . b)`.

### 2. Quote and quasiquote

Quote stops evaluation; quasiquote enables template expansion (essential for macros).

Reader sugar to add:
- `'x`  → `(quote x)`
- `` `x`` → `(quasiquote x)`
- `,x`  → `(unquote x)`
- `,@x` → `(unquote-splicing x)`

Evaluator special forms:
- `(quote expr)` → returns expr unevaluated
- `(quasiquote expr)` → evaluates unquote/unquote-splicing holes, returns rest literally
- `(quasiquote)` nesting must handle depth correctly

### 3. defmacro + macro expansion

Macros are functions that run at expand time on unevaluated AST and return new AST.

Forms to add:
- `(defmacro name (params...) body)` — defines a macro transformer
- Macro expansion pass runs before evaluation
- `macroexpand` / `macroexpand-1` for introspection

Expansion rule: when `(foo ...)` is evaluated and `foo` is bound to a macro, call the macro transformer with the raw argument forms, then evaluate the returned form.

---

## Phase 2 — Language Completeness

### 4. Variadic functions

Allow functions to collect extra arguments into a list.

Syntax (same as Common Lisp / Clojure):
- `(defn f (a b &rest args) body)` — `args` binds remaining arguments as a list

### 5. Tail-call optimization (TCO)

Erlang has a finite call stack. Without TCO, recursive Lisp programs will stack overflow.

Strategy: use a trampoline in the evaluator.
- Instead of a recursive Erlang call for tail positions, return `{tail_call, Fun, Args}`.
- The top-level eval loop bounces until a real value comes back.
- Self-tail-calls in `defn` and `fn` are the common case.

### 6. Multiple return values

Common Lisp / Scheme: `(values a b c)` + `(call-with-values producer consumer)`.

Simpler Clojure-style alternative: return a vector/list and destructure with `let`.

Decision: implement `values` / `receive-values` (simpler than full CL).

---

## Phase 3 — Ergonomics

### 7. `let*` and `letrec`

- `let*` — sequential bindings (each can see previous)
- `letrec` — mutually recursive local functions

### 8. `cond`

Multi-branch conditional:
```lisp
(cond
  ((= x 0) "zero")
  ((< x 0) "negative")
  (true    "positive"))
```

### 9. `and` / `or` (short-circuit)

### 10. `do` / `loop` — iterative looping without recursion

### 11. String builtins

- `str-length`, `str-concat`, `str-split`, `str-contains`, `number->string`, `string->number`

### 12. Exception handling

- `(try expr (catch e handler))` — maps to Erlang try/catch

### 13. `apply`

- `(apply f args-list)` — call function with a list as argument list

### 14. `map` / `filter` / `reduce`

Higher-order list operations.

---

## Phase 4 — Advanced

### 15. Namespaces / modules

Group definitions into named scopes. Load with `(require "module")`.

### 16. Tail calls across mutual recursion

Full proper tail calls, not just self-recursion.

### 17. Hygienic macros (syntax-rules style)

Pattern-based macros that don't accidentally capture free variables.

### 18. Continuations (`call/cc`)

Full Scheme-style first-class continuations. Very complex with Erlang stack model — may require CPS transform.

---

## Implementation Order

```
Phase 1 items (nil/cons, quote/quasiquote, defmacro) — foundational, do first
Phase 2 items (variadic, TCO) — correctness
Phase 3 items (let*, cond, and/or, string builtins, apply, map/filter) — ergonomics
Phase 4 items (namespaces, call/cc) — advanced
```
