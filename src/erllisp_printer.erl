-module(erllisp_printer).

-export([form_to_string/1, val_to_string/1]).

%% Convert an internal AST form back to readable Lisp source text.
-spec form_to_string(term()) -> string().
form_to_string(nil)   -> "nil";
form_to_string(true)  -> "true";
form_to_string(false) -> "false";
form_to_string(Int) when is_integer(Int) ->
    integer_to_list(Int);
form_to_string({string, S}) ->
    "\"" ++ S ++ "\"";
form_to_string(Atom) when is_atom(Atom) ->
    atom_to_list(Atom);
form_to_string([]) ->
    "nil";
form_to_string(List) when is_list(List) ->
    "(" ++ string:join([form_to_string(E) || E <- List], " ") ++ ")";
form_to_string({cons, H, T}) ->
    "(" ++ form_to_string(H) ++ " . " ++ form_to_string(T) ++ ")";
form_to_string({user_fun, Name, _, _, _, _, _}) ->
    "#<function " ++ atom_to_list(coerce_name(Name)) ++ ">";
form_to_string({user_fun, Name, _, _, _, _}) ->
    "#<function " ++ atom_to_list(coerce_name(Name)) ++ ">";
form_to_string({macro, Name, _, _, _, _}) ->
    "#<macro " ++ atom_to_list(Name) ++ ">";
form_to_string(Other) ->
    io_lib:format("~p", [Other]).

%% Convert a runtime value to a human-readable Lisp string.
-spec val_to_string(term()) -> string().
val_to_string(nil)   -> "nil";
val_to_string(true)  -> "true";
val_to_string(false) -> "false";
val_to_string(ok)    -> "ok";
val_to_string(Int) when is_integer(Int) ->
    integer_to_list(Int);
val_to_string(S) when is_list(S) ->
    %% Could be a string (list of chars) or a proper Lisp list.
    case is_string(S) of
        true  -> S;
        false -> "(" ++ string:join([val_to_string(E) || E <- S], " ") ++ ")"
    end;
val_to_string(Atom) when is_atom(Atom) ->
    atom_to_list(Atom);
val_to_string({cons, H, T}) ->
    "(" ++ val_to_string(H) ++ " . " ++ val_to_string(T) ++ ")";
val_to_string({user_fun, Name, _, _, _, _, _}) ->
    "#<function " ++ atom_to_list(coerce_name(Name)) ++ ">";
val_to_string({user_fun, Name, _, _, _, _}) ->
    "#<function " ++ atom_to_list(coerce_name(Name)) ++ ">";
val_to_string({macro, Name, _, _, _, _}) ->
    "#<macro " ++ atom_to_list(Name) ++ ">";
val_to_string({string, S}) ->
    "\"" ++ S ++ "\"";
val_to_string(Other) ->
    io_lib:format("~p", [Other]).

coerce_name(undefined) -> anonymous;
coerce_name(Name)      -> Name.

is_string([]) -> false;
is_string(S)  -> lists:all(fun(C) -> is_integer(C) andalso C >= 0 andalso C =< 1114111 end, S).

