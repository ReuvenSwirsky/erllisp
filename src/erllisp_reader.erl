-module(erllisp_reader).

-export([read/1]).

-spec read(string()) -> {ok, term()} | {error, term()}.
read(Input) when is_list(Input) ->
    Tokens = tokenize(Input),
    case parse_expr(Tokens) of
        {ok, AST, []} ->
            {ok, AST};
        {ok, _AST, Rest} ->
            {error, {trailing_tokens, Rest}};
        Error ->
            Error
    end.

tokenize(Input) ->
    tokenize(Input, [], []).

tokenize([], [], Acc) ->
    lists:reverse(Acc);
tokenize([], Curr, Acc) ->
    lists:reverse([lists:reverse(Curr) | Acc]);
tokenize([C | Rest], Curr, Acc) when C =< 32 ->
    case Curr of
        [] -> tokenize(Rest, [], Acc);
        _ -> tokenize(Rest, [], [lists:reverse(Curr) | Acc])
    end;
tokenize([$( | Rest], Curr, Acc) ->
    Acc1 = case Curr of
        [] -> Acc;
        _ -> [lists:reverse(Curr) | Acc]
    end,
    tokenize(Rest, [], ["(" | Acc1]);
tokenize([$) | Rest], Curr, Acc) ->
    Acc1 = case Curr of
        [] -> Acc;
        _ -> [lists:reverse(Curr) | Acc]
    end,
    tokenize(Rest, [], [")" | Acc1]);
tokenize([C | Rest], Curr, Acc) ->
    tokenize(Rest, [C | Curr], Acc).

parse_expr(["(" | Rest]) ->
    parse_list(Rest, []);
parse_expr([Tok | Rest]) ->
    {ok, atom_or_number(Tok), Rest};
parse_expr([]) ->
    {error, unexpected_eof}.

parse_list([")" | Rest], Acc) ->
    {ok, lists:reverse(Acc), Rest};
parse_list([] , _Acc) ->
    {error, unclosed_list};
parse_list(Tokens, Acc) ->
    case parse_expr(Tokens) of
        {ok, Expr, Rest} ->
            parse_list(Rest, [Expr | Acc]);
        Error ->
            Error
    end.

atom_or_number("true") -> true;
atom_or_number("false") -> false;
atom_or_number(S) ->
    case string:to_integer(S) of
        {Int, ""} ->
            Int;
        _ ->
            list_to_atom(S)
    end.
