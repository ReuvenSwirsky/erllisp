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
