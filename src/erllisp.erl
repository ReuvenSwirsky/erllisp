-module(erllisp).

-export([eval_string/1, eval_file/1, eval_string_with_env/2, eval_file_with_env/2]).

-spec eval_string(string()) -> {ok, term()} | {error, term()}.
eval_string(Input) when is_list(Input) ->
    case eval_string_with_env(Input, #{}) of
        {ok, Value, _Env2} -> {ok, Value};
        {error, _Reason} = Error -> Error
    end.

-spec eval_string_with_env(string(), map()) -> {ok, term(), map()} | {error, term()}.
eval_string_with_env(Input, Env) when is_list(Input), is_map(Env) ->
    with_ok(fun() -> parse_program(Input) end,
        fun(AST) -> erllisp_eval:eval_full(AST, Env) end).

-spec eval_file(string()) -> {ok, term()} | {error, term()}.
eval_file(Path) when is_list(Path) ->
    case eval_file_with_env(Path, #{}) of
        {ok, Value, _Env2} -> {ok, Value};
        {error, _Reason} = Error -> Error
    end.

-spec eval_file_with_env(string(), map()) -> {ok, term(), map()} | {error, term()}.
eval_file_with_env(Path, Env) when is_list(Path), is_map(Env) ->
    case file:read_file(Path) of
        {ok, Bin} ->
            eval_string_with_env(binary_to_list(Bin), Env);
        {error, Reason} ->
            {error, {file_read_error, Reason}}
    end.

with_ok(F1, F2) ->
    case F1() of
        {ok, V1} ->
            case F2(V1) of
                {ok, V2} -> {ok, V2};
                {ok, V2, V3} -> {ok, V2, V3};
                Error2 -> Error2
            end;
        Error1 ->
            Error1
    end.

parse_program(Input) ->
    case erllisp_reader:read_all(Input) of
        {ok, []} ->
            {error, empty_input};
        {ok, [Single]} ->
            {ok, Single};
        {ok, Exprs} ->
            {ok, ['begin' | Exprs]};
        Error ->
            Error
    end.
