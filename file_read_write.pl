read_file(Stream, Char, Chars) :-
    Char == end_of_file -> Chars = [];
    atom_codes(Char, StrChar),
    ((StrChar == "["; StrChar == "]"; StrChar == ",") -> Chars = Rest;
    Chars = [Char | Rest]),
    get_char(Stream, Next),
    read_file(Stream, Next, Rest).

read_file(File, Output) :-
    open(File, read, Stream),
    get_char(Stream, Char),
    read_file(Stream, Char, Output),
    close(Stream).

write_file(File, Input) :-
    open(File, write, Stream),
    format(Stream, "~w", [Input]),
    close(Stream).