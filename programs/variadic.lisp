; Demonstrate variadic functions, apply, map, and filter builtins.

; Variadic sum — takes any number of arguments
(defn sum-list (lst)
  (if (null? lst)
      0
      (+ (car lst) (sum-list (cdr lst)))))

(defn sum (&rest nums)
  (sum-list nums))

(print (sum))            ; 0
(print (sum 1 2 3))      ; 6
(print (sum 10 20 30))   ; 60

; Printf-style: format a message with variadic values
(defn log-values (label &rest vals)
  (begin
    (print label)
    (map (fn (v) (print v)) vals)))

(log-values "numbers:" 1 2 3)

; Collect-then-process pattern
(defn squares (&rest ns)
  (map (fn (n) (* n n)) ns))

(print (squares 1 2 3 4 5))  ; (1 4 9 16 25)

; apply lets you call a function with a runtime-assembled argument list
(let args (list 10 20 30)
  (print (apply (fn (a b c) (+ a b c)) args)))    ; 60

; filter with an anonymous predicate
(let evens (filter (fn (n) (= (mod n 2) 0)) (list 1 2 3 4 5 6 7 8))
  (print evens))   ; (2 4 6 8)
