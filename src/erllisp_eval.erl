-module(erllisp_eval).

-export([eval/2, eval_full/2, eval_with_env/2]).

%% ---------------------------------------------------------------------------
%% Public API
%% ---------------------------------------------------------------------------

-spec eval(term(), map()) -> {ok, term()} | {error, term()}.
eval(Expr, Env) ->
    trampoline(eval_with_env(Expr, Env)).

trampoline({ok, Value, _Env}) ->
    {ok, Value};
trampoline({tail, Expr, Env}) ->
    trampoline(eval_with_env(Expr, Env));
trampoline({error, _} = Err) ->
    Err.

%% Like trampoline but preserves the final Env.
eval_full(Expr, Env) ->
    trampoline_env(eval_with_env(Expr, Env)).

trampoline_env({ok, V, Env}) ->
    {ok, V, Env};
trampoline_env({tail, Expr, Env}) ->
    trampoline_env(eval_with_env(Expr, Env));
trampoline_env({error, _} = Err) ->
    Err.

-spec eval_with_env(term(), map()) -> {ok, term(), map()} | {tail, term(), map()} | {error, term()}.

%% ---------------------------------------------------------------------------
%% Self-evaluating atoms
%% ---------------------------------------------------------------------------

eval_with_env(nil, Env) ->
    {ok, nil, Env};
eval_with_env(Int, Env) when is_integer(Int) ->
    {ok, Int, Env};
eval_with_env({string, S}, Env) when is_list(S) ->
    {ok, S, Env};
eval_with_env(true, Env) ->
    {ok, true, Env};
eval_with_env(false, Env) ->
    {ok, false, Env};
eval_with_env(Symbol, Env) when is_atom(Symbol) ->
    case maps:find(Symbol, Env) of
        {ok, V} -> {ok, V, Env};
        error   -> {error, {unbound_symbol, Symbol}}
    end;

%% ---------------------------------------------------------------------------
%% Special forms
%% ---------------------------------------------------------------------------

eval_with_env(['quote', Expr], Env) ->
    {ok, Expr, Env};

eval_with_env(['quasiquote', Expr], Env) ->
    case expand_quasiquote(Expr, Env) of
        {ok, V} -> {ok, V, Env};
        Error   -> Error
    end;

eval_with_env(['if', Cond, Then, Else], Env) ->
    case trampoline(eval_with_env(Cond, Env)) of
        {ok, nil}   -> {tail, Else, Env};
        {ok, false} -> {tail, Else, Env};
        {ok, _}     -> {tail, Then, Env};
        Error       -> Error
    end;

eval_with_env(['if', Cond, Then], Env) ->
    case trampoline(eval_with_env(Cond, Env)) of
        {ok, nil}   -> {ok, nil, Env};
        {ok, false} -> {ok, nil, Env};
        {ok, _}     -> {tail, Then, Env};
        Error       -> Error
    end;

eval_with_env(['let', Name, ValueExpr, Body], Env) when is_atom(Name) ->
    case trampoline(eval_with_env(ValueExpr, Env)) of
        {ok, Value} ->
            {tail, Body, maps:put(Name, Value, Env)};
        Error ->
            Error
    end;

eval_with_env(['let*', Bindings, Body], Env) when is_list(Bindings) ->
    case bind_let_star(Bindings, Env) of
        {ok, Env1} -> {tail, Body, Env1};
        Error      -> Error
    end;

eval_with_env(['begin' | Exprs], Env) ->
    eval_sequence(Exprs, Env);

eval_with_env(['defn', Name, Params, Body], Env)
    when is_atom(Name), is_list(Params) ->
    case parse_params(Params) of
        {ok, Fixed, Rest} ->
            SourceForm = ['defn', Name, Params, Body],
            Fun = {user_fun, Name, Fixed, Rest, Body, Env, SourceForm},
            {ok, Name, maps:put(Name, Fun, Env)};
        Error -> Error
    end;

eval_with_env(['fn', Params, Body], Env) when is_list(Params) ->
    case parse_params(Params) of
        {ok, Fixed, Rest} ->
            SourceForm = ['fn', Params, Body],
            {ok, {user_fun, undefined, Fixed, Rest, Body, Env, SourceForm}, Env};
        Error -> Error
    end;

eval_with_env(['defmacro', Name, Params, Body], Env)
    when is_atom(Name), is_list(Params) ->
    case parse_params(Params) of
        {ok, Fixed, Rest} ->
            Macro = {macro, Name, Fixed, Rest, Body, Env},
            {ok, Name, maps:put(Name, Macro, Env)};
        Error -> Error
    end;

eval_with_env(['set!', Name, ValueExpr], Env) when is_atom(Name) ->
    case trampoline(eval_with_env(ValueExpr, Env)) of
        {ok, Value} -> {ok, Value, maps:put(Name, Value, Env)};
        Error       -> Error
    end;

eval_with_env(['describe', Name], Env) when is_atom(Name) ->
    {ok, describe_symbol(Name, Env), Env};
eval_with_env(['source', Name], Env) when is_atom(Name) ->
    case source_string(Name, Env) of
        {ok, Str} ->
            io:format("~s~n", [Str]),
            {ok, ok, Env};
        Error -> Error
    end;
eval_with_env(['source-fn', Name], Env) when is_atom(Name) ->
    case source_string(Name, Env) of
        {ok, Str} -> {ok, Str, Env};
        Error     -> Error
    end;
eval_with_env(['load', {string, Path}], Env) ->
    case erllisp:eval_file_with_env(Path, Env) of
        {ok, V, Env1} -> {ok, V, Env1};
        Error         -> Error
    end;
eval_with_env(['load', Path], Env) when is_atom(Path) ->
    case erllisp:eval_file_with_env(atom_to_list(Path), Env) of
        {ok, V, Env1} -> {ok, V, Env1};
        Error         -> Error
    end;

%% ---------------------------------------------------------------------------
%% Function / macro calls
%% ---------------------------------------------------------------------------

eval_with_env([Op | Args], Env) when is_atom(Op) ->
    %% Check for macro before evaluating arguments
    case maps:find(Op, Env) of
        {ok, {macro, _Name, Fixed, Rest, Body, ClosureEnv}} ->
            case bind_args(Fixed, Rest, Args) of
                {ok, CallEnv} ->
                    %% Macro: expand (run transformer on raw AST), then eval result
                    Expanded = trampoline(eval_with_env(Body,
                                  maps:merge(ClosureEnv, CallEnv))),
                    case Expanded of
                        {ok, Form} -> eval_with_env(Form, Env);
                        Error      -> Error
                    end;
                Error -> Error
            end;
        _ ->
            eval_call(Op, Args, Env)
    end;

eval_with_env([FnExpr | Args], Env) ->
    %% Higher-order: evaluate the operator
    case trampoline(eval_with_env(FnExpr, Env)) of
        {ok, {user_fun, Name, Fixed, Rest, Body, ClosureEnv, _Src}} ->
            apply_user_fun(Name, Fixed, Rest, Body, ClosureEnv, eval_list(Args, Env), Env);
        {ok, {user_fun, Name, Fixed, Rest, Body, ClosureEnv}} ->
            apply_user_fun(Name, Fixed, Rest, Body, ClosureEnv, eval_list(Args, Env), Env);
        {ok, Other} ->
            {error, {not_callable, Other}};
        Error -> Error
    end;

eval_with_env(Other, _Env) ->
    {error, {cannot_eval, Other}}.

%% ---------------------------------------------------------------------------
%% Sequences / let*
%% ---------------------------------------------------------------------------

eval_sequence([], Env) ->
    {ok, nil, Env};
eval_sequence([Expr], Env) ->
    eval_with_env(Expr, Env);
eval_sequence([Expr | Rest], Env) ->
    case trampoline_env(eval_with_env(Expr, Env)) of
        {ok, _, Env1} -> eval_sequence(Rest, Env1);
        Error         -> Error
    end.

bind_let_star([], Env) ->
    {ok, Env};
bind_let_star([[Name, ValExpr] | Rest], Env) when is_atom(Name) ->
    case trampoline(eval_with_env(ValExpr, Env)) of
        {ok, V} -> bind_let_star(Rest, maps:put(Name, V, Env));
        Error   -> Error
    end;
bind_let_star([Bad | _], _Env) ->
    {error, {invalid_let_binding, Bad}}.

%% ---------------------------------------------------------------------------
%% Quasiquote expansion
%% ---------------------------------------------------------------------------

expand_quasiquote(['unquote', Expr], Env) ->
    trampoline(eval_with_env(Expr, Env));
expand_quasiquote(List, Env) when is_list(List) ->
    expand_qq_list(List, Env, []);
expand_quasiquote(Atom, _Env) ->
    {ok, Atom}.

expand_qq_list([], _Env, Acc) ->
    {ok, lists:reverse(Acc)};
expand_qq_list([['unquote-splicing', Expr] | Rest], Env, Acc) ->
    case trampoline(eval_with_env(Expr, Env)) of
        {ok, Items} when is_list(Items) ->
            expand_qq_list(Rest, Env, lists:reverse(Items) ++ Acc);
        {ok, nil} ->
            expand_qq_list(Rest, Env, Acc);
        {ok, Other} ->
            {error, {splice_not_a_list, Other}};
        Error -> Error
    end;
expand_qq_list([H | T], Env, Acc) ->
    case expand_quasiquote(H, Env) of
        {ok, V} -> expand_qq_list(T, Env, [V | Acc]);
        Error   -> Error
    end.

%% ---------------------------------------------------------------------------
%% Parameter parsing (fixed + optional &rest)
%% ---------------------------------------------------------------------------

parse_params(Params) ->
    parse_params(Params, []).

parse_params([], Fixed) ->
    {ok, lists:reverse(Fixed), none};
parse_params(['&rest', RestParam], Fixed) when is_atom(RestParam) ->
    {ok, lists:reverse(Fixed), RestParam};
parse_params([P | Rest], Fixed) when is_atom(P) ->
    parse_params(Rest, [P | Fixed]);
parse_params([Bad | _], _) ->
    {error, {invalid_param, Bad}}.

%% ---------------------------------------------------------------------------
%% Call dispatch
%% ---------------------------------------------------------------------------

eval_call(Op, Args, Env) ->
    case eval_list(Args, Env) of
        {ok, Vals} ->
            case maps:find(Op, Env) of
                {ok, {user_fun, Name, Fixed, Rest, Body, ClosureEnv, _Src} = Fun} ->
                    _ = Fun,
                    apply_user_fun(Name, Fixed, Rest, Body, ClosureEnv, {ok, Vals}, Env);
                {ok, {user_fun, Name, Fixed, Rest, Body, ClosureEnv} = Fun} ->
                    _ = Fun,
                    apply_user_fun(Name, Fixed, Rest, Body, ClosureEnv, {ok, Vals}, Env);
                _ ->
                    case apply_builtin(Op, Vals) of
                        {ok, V} -> {ok, V, Env};
                        Error   -> Error
                    end
            end;
        Error -> Error
    end.

eval_list(Exprs, Env) ->
    eval_list(Exprs, Env, []).

eval_list([], _Env, Acc) ->
    {ok, lists:reverse(Acc)};
eval_list([H | T], Env, Acc) ->
    case trampoline(eval_with_env(H, Env)) of
        {ok, V} -> eval_list(T, Env, [V | Acc]);
        Error   -> Error
    end.

%% ---------------------------------------------------------------------------
%% User function application
%% ---------------------------------------------------------------------------

apply_user_fun(Name, Fixed, RestParam, Body, ClosureEnv, ArgsResult, CallerEnv) ->
    case ArgsResult of
        {ok, Vals} ->
            case bind_args(Fixed, RestParam, Vals) of
                {ok, BindEnv} ->
                    %% Inject self-reference for recursion
                    SelfEnv =
                        case Name of
                            undefined -> ClosureEnv;
                            _ ->
                                Fun = {user_fun, Name, Fixed, RestParam, Body,
                                       ClosureEnv,
                                       ['defn', Name,
                                        case RestParam of
                                            none -> Fixed;
                                            R    -> Fixed ++ ['&rest', R]
                                        end, Body]},
                                maps:put(Name, Fun, ClosureEnv)
                        end,
                    CallEnv = maps:merge(SelfEnv, BindEnv),
                    case eval_with_env(Body, CallEnv) of
                        {ok, V, _}    -> {ok, V, CallerEnv};
                        {tail, E, CE} -> trampoline_in_caller(E, CE, CallerEnv);
                        Error         -> Error
                    end;
                Error -> Error
            end;
        Error -> Error
    end.

trampoline_in_caller(Expr, CallEnv, CallerEnv) ->
    case trampoline(eval_with_env(Expr, CallEnv)) of
        {ok, V}   -> {ok, V, CallerEnv};
        Error     -> Error
    end.

bind_args(Fixed, RestParam, Vals) ->
    NFixed = length(Fixed),
    NVals  = length(Vals),
    case RestParam of
        none when NVals =:= NFixed ->
            {ok, bind_params(Fixed, Vals, #{})};
        none ->
            {error, {arity_mismatch, NFixed, NVals}};
        _ when NVals >= NFixed ->
            {FixedVals, RestVals} = lists:split(NFixed, Vals),
            Env1 = bind_params(Fixed, FixedVals, #{}),
            {ok, maps:put(RestParam, RestVals, Env1)};
        _ ->
            {error, {arity_mismatch_at_least, NFixed, NVals}}
    end.

bind_params([], [], Env) ->
    Env;
bind_params([P | PT], [V | VT], Env) ->
    bind_params(PT, VT, maps:put(P, V, Env)).

all_atoms(List) ->
    lists:all(fun is_atom/1, List).

%% ---------------------------------------------------------------------------
%% Introspection helpers
%% ---------------------------------------------------------------------------

describe_symbol(Name, Env) ->
    case maps:find(Name, Env) of
        {ok, {user_fun, _N, Fixed, Rest, _Body, _CE, _Src}} ->
            Arity = length(Fixed),
            Params = case Rest of none -> Fixed; R -> Fixed ++ ['&rest', R] end,
            {description, Name, function, [{arity, Arity}, {params, Params}]};
        {ok, {user_fun, _N, Fixed, none, _Body, _CE}} ->
            {description, Name, function, [{arity, length(Fixed)}, {params, Fixed}]};
        {ok, {macro, _N, Fixed, Rest, _Body, _CE}} ->
            Arity = length(Fixed),
            Params = case Rest of none -> Fixed; R -> Fixed ++ ['&rest', R] end,
            {description, Name, macro, [{arity, Arity}, {params, Params}]};
        {ok, Value} ->
            {description, Name, value, Value};
        error ->
            case is_builtin(Name) of
                true  -> {description, Name, builtin, builtin_doc(Name)};
                false -> {description, Name, unbound, undefined}
            end
    end.

source_string(Name, Env) ->
    case maps:find(Name, Env) of
        {ok, {user_fun, _N, _Fixed, _Rest, _Body, _CE, Source}} ->
            {ok, erllisp_printer:form_to_string(Source)};
        {ok, {macro, MName, Fixed, Rest, Body, _CE}} ->
            Params = case Rest of none -> Fixed; R -> Fixed ++ ['&rest', R] end,
            {ok, erllisp_printer:form_to_string(['defmacro', MName, Params, Body])};
        {ok, _Value} ->
            {error, {source_not_available, Name, not_a_function}};
        error ->
            case is_builtin(Name) of
                true  -> {ok, builtin_doc(Name)};
                false -> {error, {unbound_symbol, Name}}
            end
    end.

is_builtin(Name) ->
    lists:member(Name, ['+', '*', '-', '/', 'mod', '=', '<', '>', '<=', '>=',
                        'not', 'and', 'or',
                        'print', 'println',
                        'cons', 'car', 'cdr', 'list',
                        'null?', 'pair?', 'list?',
                        'number?', 'string?', 'symbol?', 'fn?',
                        'length', 'append', 'reverse', 'map', 'filter',
                        'apply',
                        'str', 'number->string', 'string->number']).

builtin_doc('+')    -> "(+ a b ...)";
builtin_doc('*')    -> "(* a b ...)";
builtin_doc('-')    -> "(- a b ...)";
builtin_doc('/')    -> "(/ a b ...)";
builtin_doc('mod')  -> "(mod a b)";
builtin_doc('=')    -> "(= a b)";
builtin_doc('<')    -> "(< a b)";
builtin_doc('>')    -> "(> a b)";
builtin_doc('<=')   -> "(<= a b)";
builtin_doc('>=')   -> "(>= a b)";
builtin_doc('not')  -> "(not x)";
builtin_doc('and')  -> "(and a b ...)";
builtin_doc('or')   -> "(or a b ...)";
builtin_doc('print')   -> "(print x)";
builtin_doc('println') -> "(println x)";
builtin_doc('cons')    -> "(cons head tail)";
builtin_doc('car')     -> "(car pair)";
builtin_doc('cdr')     -> "(cdr pair)";
builtin_doc('list')    -> "(list a b ...)";
builtin_doc('null?')   -> "(null? x)";
builtin_doc('pair?')   -> "(pair? x)";
builtin_doc('list?')   -> "(list? x)";
builtin_doc('number?') -> "(number? x)";
builtin_doc('string?') -> "(string? x)";
builtin_doc('symbol?') -> "(symbol? x)";
builtin_doc('fn?')     -> "(fn? x)";
builtin_doc('length')  -> "(length list)";
builtin_doc('append')  -> "(append list1 list2)";
builtin_doc('reverse') -> "(reverse list)";
builtin_doc('map')     -> "(map fn list)";
builtin_doc('filter')  -> "(filter fn list)";
builtin_doc('apply')   -> "(apply fn args-list)";
builtin_doc('str')              -> "(str x ...)";
builtin_doc('number->string')   -> "(number->string n)";
builtin_doc('string->number')   -> "(string->number s)";
builtin_doc(_)                  -> "".

%% ---------------------------------------------------------------------------
%% Builtins
%% ---------------------------------------------------------------------------

apply_builtin('+', Vals) ->
    numeric_fold(fun(A, B) -> A + B end, 0, Vals);
apply_builtin('*', Vals) ->
    numeric_fold(fun(A, B) -> A * B end, 1, Vals);
apply_builtin('-', [H | T]) when is_integer(H) ->
    case T of
        [] -> {ok, -H};
        _  ->
            case ensure_ints(T) of
                ok    -> {ok, lists:foldl(fun(A, B) -> B - A end, H, T)};
                Error -> Error
            end
    end;
apply_builtin('/', [H | T]) when is_integer(H) ->
    case ensure_ints_nonzero(T) of
        ok    -> {ok, lists:foldl(fun(A, B) -> B div A end, H, T)};
        Error -> Error
    end;
apply_builtin('mod', [A, B]) when is_integer(A), is_integer(B), B =/= 0 ->
    {ok, A rem B};
apply_builtin('=',  [A, B]) -> {ok, A =:= B};
apply_builtin('<',  [A, B]) when is_integer(A), is_integer(B) -> {ok, A < B};
apply_builtin('>',  [A, B]) when is_integer(A), is_integer(B) -> {ok, A > B};
apply_builtin('<=', [A, B]) when is_integer(A), is_integer(B) -> {ok, A =< B};
apply_builtin('>=', [A, B]) when is_integer(A), is_integer(B) -> {ok, A >= B};
apply_builtin('not', [false]) -> {ok, true};
apply_builtin('not', [nil])   -> {ok, true};
apply_builtin('not', [_])     -> {ok, false};
apply_builtin('and', Vals) ->
    {ok, lists:last([V || V <- Vals, V =/= false, V =/= nil] ++
                    [lists:last([false | [V || V <- Vals, V =:= false orelse V =:= nil]])])};
apply_builtin('or', []) -> {ok, false};
apply_builtin('or', Vals) ->
    case [V || V <- Vals, V =/= false, V =/= nil] of
        [First | _] -> {ok, First};
        []          -> {ok, false}
    end;
apply_builtin('print', [V]) ->
    io:format("~s~n", [erllisp_printer:val_to_string(V)]),
    {ok, V};
apply_builtin('println', [V]) ->
    io:format("~s~n", [erllisp_printer:val_to_string(V)]),
    {ok, nil};
%% cons / car / cdr / list
apply_builtin('cons', [H, T]) when is_list(T) ->
    {ok, [H | T]};
apply_builtin('cons', [H, nil]) ->
    {ok, [H]};
apply_builtin('cons', [H, T]) ->
    {ok, {cons, H, T}};
apply_builtin('car', [[H | _]]) ->
    {ok, H};
apply_builtin('car', [{cons, H, _}]) ->
    {ok, H};
apply_builtin('car', [nil]) ->
    {error, car_of_nil};
apply_builtin('cdr', [[_ | T]]) ->
    {ok, case T of [] -> nil; _ -> T end};
apply_builtin('cdr', [{cons, _, T}]) ->
    {ok, T};
apply_builtin('cdr', [nil]) ->
    {error, cdr_of_nil};
apply_builtin('list', Vals) ->
    {ok, Vals};
apply_builtin('null?', [nil])  -> {ok, true};
apply_builtin('null?', [[]])   -> {ok, true};
apply_builtin('null?', [_])    -> {ok, false};
apply_builtin('pair?', [[_|_]])        -> {ok, true};
apply_builtin('pair?', [{cons,_,_}])   -> {ok, true};
apply_builtin('pair?', [_])            -> {ok, false};
apply_builtin('list?', [nil])          -> {ok, true};
apply_builtin('list?', [L]) when is_list(L) -> {ok, true};
apply_builtin('list?', [_])            -> {ok, false};
apply_builtin('number?', [V])  -> {ok, is_integer(V)};
apply_builtin('string?', [V])  -> {ok, is_list(V) andalso V =/= nil};
apply_builtin('symbol?', [V])  -> {ok, is_atom(V) andalso V =/= nil andalso V =/= true andalso V =/= false};
apply_builtin('fn?', [V])      -> {ok, is_tuple(V) andalso element(1,V) =:= user_fun};
%% List operations
apply_builtin('length', [nil])          -> {ok, 0};
apply_builtin('length', [L]) when is_list(L) -> {ok, length(L)};
apply_builtin('append', [nil, B])       -> {ok, B};
apply_builtin('append', [A, nil])       -> {ok, A};
apply_builtin('append', [A, B]) when is_list(A), is_list(B) -> {ok, A ++ B};
apply_builtin('reverse', [nil])         -> {ok, nil};
apply_builtin('reverse', [L]) when is_list(L) -> {ok, lists:reverse(L)};
apply_builtin('map', [Fun, nil]) when is_tuple(Fun) -> {ok, nil};
apply_builtin('map', [Fun, List]) when is_list(List) ->
    map_fn(Fun, List, []);
apply_builtin('filter', [Fun, nil]) when is_tuple(Fun) -> {ok, nil};
apply_builtin('filter', [Fun, List]) when is_list(List) ->
    filter_fn(Fun, List, []);
apply_builtin('apply', [Fun, nil]) ->
    apply_builtin('apply', [Fun, []]);
apply_builtin('apply', [Fun, Args]) when is_list(Args) ->
    case Fun of
        {user_fun, Name, Fixed, Rest, Body, ClosureEnv, _Src} ->
            trampoline_to_ok(
                apply_user_fun(Name, Fixed, Rest, Body, ClosureEnv, {ok, Args}, #{}));
        {user_fun, Name, Fixed, Rest, Body, ClosureEnv} ->
            trampoline_to_ok(
                apply_user_fun(Name, Fixed, Rest, Body, ClosureEnv, {ok, Args}, #{}));
        _ -> {error, {not_callable, Fun}}
    end;
%% String helpers
apply_builtin('str', Vals) ->
    {ok, lists:concat([erllisp_printer:val_to_string(V) || V <- Vals])};
apply_builtin('number->string', [N]) when is_integer(N) ->
    {ok, integer_to_list(N)};
apply_builtin('string->number', [S]) when is_list(S) ->
    case string:to_integer(S) of
        {N, ""} -> {ok, N};
        _       -> {ok, false}
    end;
apply_builtin(Name, Args) ->
    {error, {unknown_or_invalid_builtin, Name, Args}}.

map_fn(_Fun, [], Acc) ->
    {ok, lists:reverse(Acc)};
map_fn(Fun, [H | T], Acc) ->
    case apply_fn(Fun, [H]) of
        {ok, V} -> map_fn(Fun, T, [V | Acc]);
        Error   -> Error
    end.

filter_fn(_Fun, [], Acc) ->
    {ok, lists:reverse(Acc)};
filter_fn(Fun, [H | T], Acc) ->
    case apply_fn(Fun, [H]) of
        {ok, false} -> filter_fn(Fun, T, Acc);
        {ok, nil}   -> filter_fn(Fun, T, Acc);
        {ok, _}     -> filter_fn(Fun, T, [H | Acc]);
        Error       -> Error
    end.

apply_fn({user_fun, Name, Fixed, Rest, Body, ClosureEnv, _Src}, Args) ->
    trampoline_to_ok(apply_user_fun(Name, Fixed, Rest, Body, ClosureEnv, {ok, Args}, #{}));
apply_fn({user_fun, Name, Fixed, Rest, Body, ClosureEnv}, Args) ->
    trampoline_to_ok(apply_user_fun(Name, Fixed, Rest, Body, ClosureEnv, {ok, Args}, #{}));
apply_fn(Other, _) ->
    {error, {not_callable, Other}}.

trampoline_to_ok({ok, V, _})  -> {ok, V};
trampoline_to_ok({ok, V})     -> {ok, V};
trampoline_to_ok({tail,E,Env})-> trampoline_to_ok(trampoline(eval_with_env(E, Env)));
trampoline_to_ok(Error)       -> Error.

%% ---------------------------------------------------------------------------
%% Numeric helpers
%% ---------------------------------------------------------------------------

numeric_fold(Fun, Init, Vals) ->
    case ensure_ints(Vals) of
        ok    -> {ok, lists:foldl(Fun, Init, Vals)};
        Error -> Error
    end.

ensure_ints(Vals) ->
    case lists:all(fun is_integer/1, Vals) of
        true  -> ok;
        false -> {error, non_integer_argument}
    end.

ensure_ints_nonzero(Vals) ->
    case ensure_ints(Vals) of
        ok ->
            case lists:any(fun(V) -> V =:= 0 end, Vals) of
                true  -> {error, division_by_zero};
                false -> ok
            end;
        Error -> Error
    end.
