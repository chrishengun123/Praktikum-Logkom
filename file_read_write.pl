read_card([Char|SubList], NewList, Card) :-
    ((Char == ",") -> Card = [], NewList = SubList);
    read_card(SubList, NewList, SubCard),
    (
        ((Char == "[") -> Card = SubCard);
        Card = [Char | SubCard]
    ).

read_cards(List, Cards) :- 
    (List = [] -> Cards = []);
    read_card(List, SubList, Card),
    read_cards(SubList, SubCards),
    Cards = [Card | SubCards].

read_file(Stream, Char, Chars) :-
    Char == end_of_file -> Chars = [];
    atom_codes(Char, StrChar),
    Chars = [Char | Rest],
    get_char(Stream, Next),
    read_file(Stream, Next, Rest).

read_file(File, Output) :-
    open(File, read, Stream),
    get_char(Stream, Char),
    read_file(Stream, Char, Data),
    read_cards(Data, Output),
    close(Stream).

write_file(File, Input) :-
    open(File, write, Stream),
    format(Stream, "~w", [Input]),
    close(Stream).

create_player_files([]).
create_player_files([Name | Rest]) :-
   atom_concat('kartu_', Name, Temp),
   atom_concat(Temp, '.txt', FileName),
   write_file(FileName, []),
   create_player_files(Rest).
