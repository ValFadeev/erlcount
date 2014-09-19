-module(wordcount).
-export([wordcount/1]).

%% Open file and process lines if opened successfully
wordcount(Fname) ->
    case file:open(Fname, [read, raw, binary]) of
  {ok, Fd} ->
     process_lines(Fd);
  {error, Reason} ->
     {error, Reason}
    end.

process_lines(File) ->
    process_lines(File, []).
    
process_lines(File, Tuples) ->
    case file:read_line(File) of
        {ok, Line} ->
            process_lines(File, lists:append(Tuples, mapper(Line)));
        eof ->
	        lists:reverse(reducer(lists:sort(Tuples)))
	end.

%% Mapper code    
mapper(Line) ->
    [{W,1} || W <- parse_line(Line)].

%% convert binary to string
parse_line(Bin) -> 
    parse_line(binary_to_list(Bin), strip).

%% remove heading and trailing spaces
parse_line(Str, Op) when Op == strip ->
    parse_line(string:strip(Str), lower);
%% cast to lowercase
parse_line(Str, Op) when Op == lower ->
    parse_line(string:to_lower(Str), clean);
%% remove non-alphanumeric characters
parse_line(Str, Op) when Op == clean ->
    parse_line(re:replace(Str, "[^A-Za-z0-9 ]", "", [global,{return,list}]), split);
%% tokenise
parse_line(Str, Op) when Op == split ->
    re:split(Str, " ", [{return,list}]).

%% Reducer code 
reducer([{Word, Count}|Rest]) ->
    reducer(Rest,[], Count, Word).

%% if the list of tuples is empty add the current word/count pair to output and return
reducer([],Output,Count,Word) -> [{Word,Count}|Output];

%% skip empty words
reducer([{[], _}|Rest], Output, CurrentCount, CurrentWord) ->
    reducer(Rest, Output, CurrentCount, CurrentWord);

%% if new word is the same as current word increment count
reducer([{NewWord, NewCount}|Rest], Output, CurrentCount, NewWord) ->
    reducer(Rest, Output, CurrentCount+NewCount, NewWord);

%% if a new word is encountered push current word and its count to the output
reducer([{NewWord, NewCount}|Rest], Output, CurrentCount, LastWord) ->
    reducer(Rest, [{LastWord, CurrentCount}|Output], NewCount, NewWord).
