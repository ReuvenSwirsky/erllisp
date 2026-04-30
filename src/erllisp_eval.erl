-module(erllisp_eval).

-export([eval/2]).

-spec eval(term(), map()) -> {ok, term()} | {error, term()}.
eval(Int, _Env) when is_integer(Int) ->
    {ok, Int};
eval(true, _Env) ->
    {ok, true};
eval(false, _Env) ->
    {ok, false};
eval(Symbol, Env) when is_atom(Symbol) ->
    case maps:find(Symbol, Env) of
        {ok, V} -> {ok, V};
        error -> {error, {unbound_symbol, Symbol}}
    end;
eval(['if', Cond, Then, Else], Env) ->
    case eval(Cond, Env) of
        {ok, true} -> eval(Then, Env);
        {ok, false} -> eval(Else, Env);
        {ok, Other} -> {error, {non_boolean_condition, Other}};
        Error -> Error
    end;
eval(['let', Name, ValueExpr, Body], Env) when is_atom(Name) ->
    case eval(ValueExpr, Env) of
        {ok, Value} ->
            eval(Body, maps:put(Name, Value, Env));
        Error ->
            Error
    end;
eval([Op | Args], Env) when is_atom(Op) ->
    eval_call(Op, Args, Env);
eval(Other, _Env) ->
    {error, {cannot_eval, Other}}.

eval_call(Op, Args, Env) ->
    case eval_args(Args, Env, []) of
        {ok, Vals} ->
            apply_builtin(Op, Vals);
        Error ->
            Error
    end.

eval_args([], _Env, Acc) ->
    {ok, lists:reverse(Acc)};
eval_args([H | T], Env, Acc) ->
    case eval(H, Env) of
        {ok, V} -> eval_args(T, Env, [V | Acc]);
        Error -> Error
    end.

apply_builtin('+', Vals) ->
    numeric_fold(fun(A, B) -> A + B end, 0, Vals);
apply_builtin('*', Vals) ->
    numeric_fold(fun(A, B) -> A * B end, 1, Vals);
apply_builtin('-', [H | T]) when is_integer(H) ->
    case ensure_ints(T) of
        ok -> {ok, lists:foldl(fun(A, B) -> B - A end, H, T)};
        Error -> Error
    end;
apply_builtin('/', [H | T]) when is_integer(H) ->
    case ensure_ints_nonzero(T) of
        ok -> {ok, lists:foldl(fun(A, B) -> B div A end, H, T)};
        Error -> Error
    end;
apply_builtin('=', [A, B]) ->
    {ok, A =:= B};
apply_builtin('<', [A, B]) when is_integer(A), is_integer(B) ->
    {ok, A < B};
apply_builtin('>', [A, B]) when is_integer(A), is_integer(B) ->
    {ok, A > B};
apply_builtin(Name, Args) ->
    {error, {unknown_or_invalid_builtin, Name, Args}}.

numeric_fold(Fun, Init, Vals) ->
    case ensure_ints(Vals) of
        ok -> {ok, lists:foldl(Fun, Init, Vals)};
        Error -> Error
    end.

ensure_ints(Vals) ->
    case lists:all(fun is_integer/1, Vals) of
        true -> ok;
        false -> {error, non_integer_argument}
    end.

ensure_ints_nonzero(Vals) ->
    case ensure_ints(Vals) of
        ok ->
            case lists:any(fun(V) -> V =:= 0 end, Vals) of
                true -> {error, division_by_zero};
                false -> ok
            end;
        Error ->
            Error
    end.
