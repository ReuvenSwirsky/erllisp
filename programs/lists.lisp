; Demonstrate cons cells, car/cdr, list operations, and higher-order functions.

; Build a list manually with cons
(defn range (lo hi)
  (if (>= lo hi)
      nil
      (cons lo (range (+ lo 1) hi))))

; Sum a list recursively
(defn sum (lst)
  (if (null? lst)
      0
      (+ (car lst) (sum (cdr lst)))))

; Classic map implemented in pure Lisp
(defn my-map (f lst)
  (if (null? lst)
      nil
      (cons (f (car lst)) (my-map f (cdr lst)))))

; Classic filter implemented in pure Lisp
(defn my-filter (pred lst)
  (if (null? lst)
      nil
      (if (pred (car lst))
          (cons (car lst) (my-filter pred (cdr lst)))
          (my-filter pred (cdr lst)))))

; Fold-left (reduce)
(defn foldl (f acc lst)
  (if (null? lst)
      acc
      (foldl f (f acc (car lst)) (cdr lst))))

; --- Examples ---

(let nums (range 1 11)
  (begin
    (print nums)                                      ; (1 2 3 4 5 6 7 8 9 10)
    (print (sum nums))                                ; 55
    (print (my-map (fn (x) (* x x)) nums))            ; squares
    (print (my-filter (fn (x) (= (mod x 2) 0)) nums)) ; even numbers
    (print (foldl (fn (acc x) (+ acc x)) 0 nums))))   ; 55 via fold
