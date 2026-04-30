-module(run_examples).
-export([main/1]).
main(_) ->
    Files = ["programs/lists.lisp", "programs/macros.lisp",
             "programs/variadic.lisp", "programs/tco_demo.lisp"],
    lists:foreach(fun(F) ->
        io:format("~n=== ~s ===~n", [F]),
        case erllisp:eval_file(F) of
            {ok, _} -> ok;
            {error, E} -> io:format("ERROR: ~p~n", [E])
        end
    end, Files).
