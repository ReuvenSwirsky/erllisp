(defn fib-loop (n a b)
	(if (= n 0)
			0
			(begin
				(print a)
				(fib-loop (- n 1) b (+ a b)))))

(fib-loop 1000 0 1)
