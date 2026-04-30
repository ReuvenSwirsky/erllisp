-module(erllisp_tests).

-include_lib("eunit/include/eunit.hrl").

add_test() ->
    ?assertEqual({ok, 6}, erllisp:eval_string("(+ 1 2 3)")).

nested_math_test() ->
    ?assertEqual({ok, 8}, erllisp:eval_string("(* 4 (+ 1 1))")).

if_test() ->
    ?assertEqual({ok, 10}, erllisp:eval_string("(if true 10 20)")).

let_test() ->
    ?assertEqual({ok, 7}, erllisp:eval_string("(let x 3 (+ x 4))")).

defn_recursion_test() ->
    Program =
        "(begin "
        "(defn fib (n) (if (< n 2) n (+ (fib (- n 1)) (fib (- n 2))))) "
        "(fib 10))",
    ?assertEqual({ok, 55}, erllisp:eval_string(Program)).

print_builtin_test() ->
    ?assertEqual({ok, 42}, erllisp:eval_string("(print 42)")).

string_literal_test() ->
    ?assertEqual({ok, "hello"}, erllisp:eval_string("\"hello\" ")).

multi_form_input_test() ->
    ?assertEqual({ok, 7},
        erllisp:eval_string("(defn inc (n) (+ n 1)) (inc 6)")).

load_file_test() ->
    ?assertEqual({ok, t},
        erllisp:eval_string("(load \"programs/fib10.lisp\")")).

describe_builtin_test() ->
    ?assertMatch({ok, {description, '+', builtin, _}},
        erllisp:eval_string("(describe +)")).

describe_function_test() ->
    Program =
        "(defn inc (n) (+ n 1)) "
        "(describe inc)",
    ?assertEqual({ok, {description, inc, function, [{arity, 1}, {params, [n]}]}},
        erllisp:eval_string(Program)).

source_function_test() ->
    Program =
        "(defn inc (n) (+ n 1)) "
        "(source-fn inc)",
    ?assertEqual({ok, "(defn inc (n) (+ n 1))"},
        erllisp:eval_string(Program)).

source_fn_alias_test() ->
    Program =
        "(defn inc (n) (+ n 1)) "
        "(source inc)",
    ?assertEqual({ok, ok},
        erllisp:eval_string(Program)).

load_persists_definitions_test() ->
    ?assertEqual({ok, 89},
        erllisp:eval_string("(load \"programs/fib10.lisp\") (fib 11)")).

%% --- Phase 1 features ---

quote_test() ->
    ?assertEqual({ok, [a, b, c]}, erllisp:eval_string("'(a b c)")).

quote_atom_test() ->
    ?assertEqual({ok, foo}, erllisp:eval_string("'foo")).

nil_test() ->
    ?assertEqual({ok, nil}, erllisp:eval_string("nil")).

quasiquote_test() ->
    ?assertEqual({ok, [1, 2, 3]},
        erllisp:eval_string("`(1 ,(+ 1 1) 3)")).

quasiquote_splicing_test() ->
    ?assertEqual({ok, [1, 2, 3, 4]},
        erllisp:eval_string("(let xs '(2 3) `(1 ,@xs 4))")).

cons_test() ->
    ?assertEqual({ok, [1, 2, 3]},
        erllisp:eval_string("(cons 1 (cons 2 (cons 3 nil)))")).

car_test() ->
    ?assertEqual({ok, 10},
        erllisp:eval_string("(car (list 10 20 30))")).

cdr_test() ->
    ?assertEqual({ok, [20, 30]},
        erllisp:eval_string("(cdr (list 10 20 30))")).

list_test() ->
    ?assertEqual({ok, [1, 2, 3]},
        erllisp:eval_string("(list 1 2 3)")).

null_test() ->
    ?assertEqual({ok, true}, erllisp:eval_string("(null? nil)")).

null_false_test() ->
    ?assertEqual({ok, false}, erllisp:eval_string("(null? (list 1))")).

pair_test() ->
    ?assertEqual({ok, true}, erllisp:eval_string("(pair? (list 1 2))")).

variadic_test() ->
    Program = "(defn first-two (a b &rest _) (+ a b)) (first-two 10 20 30 40)",
    ?assertEqual({ok, 30}, erllisp:eval_string(Program)).

variadic_rest_test() ->
    Program = "(defn sum-all (x &rest xs) (if (null? xs) x (+ x (car xs)))) (sum-all 3 4)",
    ?assertEqual({ok, 7}, erllisp:eval_string(Program)).

defmacro_test() ->
    Program = "(defmacro my-and (a b) (list 'if a b false)) (my-and true 42)",
    ?assertEqual({ok, 42}, erllisp:eval_string(Program)).

let_star_test() ->
    ?assertEqual({ok, 3},
        erllisp:eval_string("(let* ((a 1) (b 2)) (+ a b))")).

tco_test() ->
    %% Tail-recursive countdown — would stack-overflow without TCO
    Program =
        "(defn count (n) "
        "  (if (= n 0) 'done (count (- n 1)))) "
        "(count 100000)",
    ?assertEqual({ok, done}, erllisp:eval_string(Program)).
