; Demonstrate quasiquote, defmacro, and macro-generated code.

; A simple 'when' macro — run body only if condition is truthy
(defmacro when (cond body)
  `(if ,cond ,body nil))

; An 'unless' macro — run body only if condition is falsy
(defmacro unless (cond body)
  `(if ,cond nil ,body))

; 'swap!' — exchange two bindings (illustrates multi-step macro expansion)
; Returns the new value of a after the swap.
(defmacro and2 (a b)
  `(if ,a ,b false))

(defmacro or2 (a b)
  `(if ,a ,a ,b))

; Build a quasiquoted data structure at runtime
(defn make-point (x y)
  `(point ,x ,y))

(defn point-x (p) (car  (cdr p)))
(defn point-y (p) (car (cdr (cdr p))))

; --- Examples ---

(when true  (print "when-true fires"))    ; prints
(when false (print "when-false fires"))   ; silent → nil
(unless false (print "unless fires"))     ; prints

(print (and2 true  42))     ; 42
(print (and2 false 42))     ; false
(print (or2  false "yes"))  ; yes

(let p (make-point 3 7)
  (begin
    (print p)            ; (point 3 7)
    (print (point-x p))  ; 3
    (print (point-y p)))) ; 7

; Quasiquote splicing — build a call form and show it
(let args '(1 2 3)
  (print `(+ ,@args)))   ; (+ 1 2 3)  — the unevaluated form
