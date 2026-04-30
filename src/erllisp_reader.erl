-module(erllisp_reader).

-export([read/1, read_all/1]).

-spec read(string()) -> {ok, term()} | {error, term()}.
read(Input) when is_list(Input) ->
    case read_all(Input) of
        {ok, [AST]} ->
            {ok, AST};
        {ok, []} ->
            {error, empty_input};
        {ok, Exprs} ->
            {error, {trailing_expressions, Exprs}};
        Error ->
            Error
    end.

-spec read_all(string()) -> {ok, [term()]} | {error, term()}.
read_all(Input) when is_list(Input) ->
    case tokenize(Input) of
        {ok, Tokens} ->
            parse_exprs(Tokens, []);
        Error ->
            Error
    end.

parse_exprs([], Acc) ->
    {ok, lists:reverse(Acc)};
parse_exprs(Tokens, Acc) ->
    case parse_expr(Tokens) of
        {ok, AST, Rest} ->
            parse_exprs(Rest, [AST | Acc]);
        Error ->
            Error
    end.

tokenize(Input) ->
    tokenize(Input, normal, [], []).

tokenize([], normal, [], Acc) ->
    {ok, lists:reverse(Acc)};
tokenize([], normal, Curr, Acc) ->
    {ok, lists:reverse([lists:reverse(Curr) | Acc])};
tokenize([], string, _Curr, _Acc) ->
    {error, unclosed_string};
tokenize([$" | Rest], normal, Curr, Acc) ->
    Acc1 = case Curr of
        [] -> Acc;
        _ -> [lists:reverse(Curr) | Acc]
    end,
    tokenize(Rest, string, [], Acc1);
tokenize([$" | Rest], string, Curr, Acc) ->
    tokenize(Rest, normal, [], [{string, lists:reverse(Curr)} | Acc]);
tokenize([C | Rest], string, Curr, Acc) ->
    tokenize(Rest, string, [C | Curr], Acc);
tokenize([C | Rest], normal, Curr, Acc) when C =< 32 ->
    case Curr of
        [] -> tokenize(Rest, normal, [], Acc);
        _ -> tokenize(Rest, normal, [], [lists:reverse(Curr) | Acc])
    end;
tokenize([$( | Rest], normal, Curr, Acc) ->
    Acc1 = case Curr of
        [] -> Acc;
        _ -> [lists:reverse(Curr) | Acc]
    end,
    tokenize(Rest, normal, [], ["(" | Acc1]);
tokenize([$) | Rest], normal, Curr, Acc) ->
    Acc1 = case Curr of
        [] -> Acc;
        _ -> [lists:reverse(Curr) | Acc]
    end,
    tokenize(Rest, normal, [], [")" | Acc1]);
tokenize([$' | Rest], normal, Curr, Acc) ->
    Acc1 = case Curr of
        [] -> Acc;
        _ -> [lists:reverse(Curr) | Acc]
    end,
    tokenize(Rest, normal, [], [quote_tok | Acc1]);
tokenize([$` | Rest], normal, Curr, Acc) ->
    Acc1 = case Curr of
        [] -> Acc;
        _ -> [lists:reverse(Curr) | Acc]
    end,
    tokenize(Rest, normal, [], [quasiquote_tok | Acc1]);
tokenize([$,, $@ | Rest], normal, Curr, Acc) ->
    Acc1 = case Curr of
        [] -> Acc;
        _ -> [lists:reverse(Curr) | Acc]
    end,
    tokenize(Rest, normal, [], [unquote_splicing_tok | Acc1]);
tokenize([$, | Rest], normal, Curr, Acc) ->
    Acc1 = case Curr of
        [] -> Acc;
        _ -> [lists:reverse(Curr) | Acc]
    end,
    tokenize(Rest, normal, [], [unquote_tok | Acc1]);
tokenize([$; | Rest], normal, Curr, Acc) ->
    Acc1 = case Curr of
        [] -> Acc;
        _ -> [lists:reverse(Curr) | Acc]
    end,
    skip_comment(Rest, Acc1);
tokenize([C | Rest], normal, Curr, Acc) ->
    tokenize(Rest, normal, [C | Curr], Acc).

skip_comment([], Acc) ->
    {ok, lists:reverse(Acc)};
skip_comment([$\n | Rest], Acc) ->
    tokenize(Rest, normal, [], Acc);
skip_comment([_ | Rest], Acc) ->
    skip_comment(Rest, Acc).

parse_expr(["(" | Rest]) ->
    parse_list(Rest, []);
parse_expr([quote_tok | Rest]) ->
    case parse_expr(Rest) of
        {ok, Expr, Rest1} -> {ok, ['quote', Expr], Rest1};
        Error -> Error
    end;
parse_expr([quasiquote_tok | Rest]) ->
    case parse_expr(Rest) of
        {ok, Expr, Rest1} -> {ok, ['quasiquote', Expr], Rest1};
        Error -> Error
    end;
parse_expr([unquote_tok | Rest]) ->
    case parse_expr(Rest) of
        {ok, Expr, Rest1} -> {ok, ['unquote', Expr], Rest1};
        Error -> Error
    end;
parse_expr([unquote_splicing_tok | Rest]) ->
    case parse_expr(Rest) of
        {ok, Expr, Rest1} -> {ok, ['unquote-splicing', Expr], Rest1};
        Error -> Error
    end;
parse_expr([{string, S} | Rest]) ->
    {ok, {string, S}, Rest};
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
