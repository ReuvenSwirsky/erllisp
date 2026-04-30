; Demonstrate tail-call optimization with a large iteration count.
; Without TCO these would blow the Erlang call stack.

; Countdown — pure tail call, 1 million iterations
(defn countdown (n)
  (if (= n 0)
      'done
      (countdown (- n 1))))

(print (countdown 1000000))   ; done  — no stack overflow

; Tail-recursive sum of 1..N
(defn sum-to (n acc)
  (if (= n 0)
      acc
      (sum-to (- n 1) (+ acc n))))

(print (sum-to 1000000 0))    ; 500000500000

; Tail-recursive list builder using an accumulator, then reverse
(defn range-acc (lo hi acc)
  (if (>= lo hi)
      (reverse acc)
      (range-acc (+ lo 1) hi (cons lo acc))))

(defn range (lo hi)
  (range-acc lo hi nil))

(let r (range 1 11)
  (print r))   ; (1 2 3 4 5 6 7 8 9 10)

; Ackermann — not tail-recursive, but shows deep recursion still works
; (kept small to avoid exponential blowup)
(defn ackermann (m n)
  (if (= m 0)
      (+ n 1)
      (if (= n 0)
          (ackermann (- m 1) 1)
          (ackermann (- m 1) (ackermann m (- n 1))))))

(print (ackermann 3 6))   ; 509
