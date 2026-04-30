-module(erllisp).

-export([eval_string/1]).

-spec eval_string(string()) -> {ok, term()} | {error, term()}.
eval_string(Input) when is_list(Input) ->
    with_ok(fun() -> erllisp_reader:read(Input) end,
        fun(AST) -> erllisp_eval:eval(AST, #{}) end).

with_ok(F1, F2) ->
    case F1() of
        {ok, V1} ->
            case F2(V1) of
                {ok, V2} -> {ok, V2};
                Error2 -> Error2
            end;
        Error1 ->
            Error1
    end.
