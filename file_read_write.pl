get_color_and_type_string([Char | SubCard], [Color, Type]) :- 
    (Char == "-" -> Color = [], Type = SubCard);
    card_name_to_card(SubCard, [SubColor, Type]),
    Color = [Char | SubColor].

% Converts the card name to usable card data.
card_name_to_card(CardName, [Color, Type]) :- 
    get_color_and_type_string(CardName, [Color,Type]).
    % atom_codes(Color, ColorStr),
    % atom_codes(Type, TypeStr).

% Returns the first card name in the list and removes it from the list.
read_card([Char | SubList], NewList, CardName) :-
    ((Char == ","; Char == "]") -> CardName = [], NewList = SubList);
    read_card(SubList, NewList, SubCardName),
    (
        ((Char == "[") -> CardName = SubCardName);
        CardName = [Char | SubCardName]
    ).

% Returns all the cards in the list.
read_cards(List, Cards) :- 
    (List == [] -> Cards = []);
    read_card(List, SubList, CardName),
    card_name_to_card(CardName, Card),
    read_cards(SubList, SubCards),
    Cards = [Card | SubCards].

get_hand_file(Player, File) :-
    atom_codes(Player, PlayerName),
    append("kartu_", PlayerName, FileNameNoTXT),
    append(FileNameNoTXT, ".txt", FileName),
    atom_codes(File, FileName).

read_file(Stream, Char, Chars) :-
    Char == end_of_file -> Chars = [];
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
    (Input == []);
    Input = [Card | SubInput].
    open(File, write, Stream),
    format(Stream, "~w-~w", [Card]),
    close(Stream),
    write_file(File, SubInput).

create_player_files([]).
create_player_files([Name | Rest]) :-
   atom_concat('kartu_', Name, Temp),
   atom_concat(Temp, '.txt', FileName),
   write_file(FileName, []),
   create_player_files(Rest).

read_pool(File, ListPool) :-
   read_file(File, ListPool).
