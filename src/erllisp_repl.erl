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
            io:format("~s~n", [erllisp_printer:val_to_string(Value)]),
            Env1;
        {error, Reason} ->
            io:format("error: ~s~n", [format_error(Reason)]),
            Env
    end.

format_error({file_not_found, Path}) ->
    io_lib:format("file not found: ~s", [Path]);
format_error({file_permission_denied, Path}) ->
    io_lib:format("permission denied: ~s", [Path]);
format_error({file_read_error, Reason}) ->
    io_lib:format("could not read file: ~p", [Reason]);
format_error({unbound_symbol, Name}) ->
    io_lib:format("unbound symbol: ~s", [Name]);
format_error({arity_mismatch, Expected, Got}) ->
    io_lib:format("wrong number of arguments: expected ~p, got ~p", [Expected, Got]);
format_error({arity_mismatch_at_least, Min, Got}) ->
    io_lib:format("wrong number of arguments: expected at least ~p, got ~p", [Min, Got]);
format_error({not_callable, Val}) ->
    io_lib:format("~s is not a function", [erllisp_printer:val_to_string(Val)]);
format_error({unknown_or_invalid_builtin, Name, _}) ->
    io_lib:format("unknown function: ~s", [Name]);
format_error(non_integer_argument) ->
    "expected a number";
format_error(division_by_zero) ->
    "division by zero";
format_error(car_of_nil) ->
    "car of nil";
format_error(cdr_of_nil) ->
    "cdr of nil";
format_error(empty_input) ->
    "empty input";
format_error({cannot_eval, V}) ->
    io_lib:format("cannot evaluate: ~p", [V]);
format_error(Other) ->
    io_lib:format("~p", [Other]).
