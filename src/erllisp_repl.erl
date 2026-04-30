-module(erllisp_repl).

-export([start/0]).

start() ->
    io:format("erlisp>~n", []),
    loop(#{}).

loop(Env) ->
    case io:get_line("erlisp> ") of
        eof ->
            ok;
        "\n" ->
            loop(Env);
        Line ->
            Stripped = string:trim(Line),
            case Stripped of
                ":q" -> ok;
                "quit" -> ok;
                _ ->
                    Env1 = print_eval(Stripped, Env),
                    loop(Env1)
            end
    end.

print_eval(Str, Env) ->
    case erllisp:eval_string_with_env(Str, Env) of
        {ok, Value, Env1} ->
            io:format("~p~n", [Value]),
            Env1;
        {error, Reason} ->
            io:format("error: ~p~n", [Reason]),
            Env
    end.
