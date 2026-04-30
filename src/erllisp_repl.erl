-module(erllisp_repl).

-export([start/0]).

start() ->
    io:format("erlisp>~n", []),
    loop().

loop() ->
    case io:get_line("erlisp> ") of
        eof ->
            ok;
        "\n" ->
            loop();
        Line ->
            Stripped = string:trim(Line),
            case Stripped of
                ":q" -> ok;
                "quit" -> ok;
                _ ->
                    print_eval(Stripped),
                    loop()
            end
    end.

print_eval(Str) ->
    case erllisp:eval_string(Str) of
        {ok, Value} -> io:format("~p~n", [Value]);
        {error, Reason} -> io:format("error: ~p~n", [Reason])
    end.
