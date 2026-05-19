peek :- lihatKartu. % js to make it faster
/* THIS ONE WORKS, BUT IS NOT EXACTLY THE SAME AS THE EXAMPLE IN THE SPEK*/ 
lihatKartu :-
    (\+ started -> fail);
    currentPlayer(Player),
%    format("~w", [Cardfile]), for debug purposes
    read_file(Player, Cards),
    get_length(Cards, Length),
    format("~nBerikut kartu yang Anda miliki: ~n", []),
    printCards(1, Length, Cards).

printCards(_, _, []) :- !.
printCards(Index, Length, [Card | Rest]) :-
    Index =< Length,
    Index1 is Index + 1,
    format("~d. ~w-~w~n", [Index | Card]),
    printCards(Index1, Length, Rest).

tantang :-
    (\+ started -> fail);
    % get discard pile
    read_file('discard.txt', Discard),
    [[_|Type]|_] = Discard,
    (\+(Type == 'wild_draw_four')) -> format("Tidak bisa melakukan tantang.", []), fail;(
    % get the last player that played
    format("Tantangan dilakukan!~n", []),
    currentPlayer(Player),
    turnOrder(Order),
    get_length(Order, PlayerAmount),
    get_index(Order, Player, Turn),
    LastTurn is (Turn - 1) mod PlayerAmount,
    get_element(Order, LastTurn, LastPlayer),
    % read the last player's cards
    format("Memeriksa kartu ~w...", [LastPlayer]),
    read_file(LastPlayer, LastPlayerCards), 
    get_element(Discard, 1, LastCard),
    % get lastcard color and number/type
    [LastColor, LastType] = LastCard,
    hasSameColorOrType(Player, LastPlayer, LastPlayerCards, LastColor, LastType)),!.
% logic: tantangan berhasil
hasSameColorOrType(Player, LastPlayer, LastPlayerCards, LastColor, LastType) :- 
    (hasColor(LastPlayerCards, LastColor) ; hasType(LastPlayerCards, LastType)) -> 
    (format("Tantangan berhasil! ~w mendapatkan 4 kartu acak.", [LastPlayer]),
    switchPlayer(Player, LastPlayer),
    giveCard(LastPlayer),
    giveCard(LastPlayer),
    giveCard(LastPlayer),
    giveCard(LastPlayer),
    switchPlayer(LastPlayer, Player); true).
% tantangan gagal
hasSameColorOrType(Player, _LastPlayer, LastPlayerCards, LastColor, LastType) :- 
    (\+(hasColor(LastPlayerCards, LastColor)), \+(hasType(LastPlayerCards, LastType))) -> 
    (format("Tantangan gagal! ~w mendapatkan 6 kartu acak.", [Player]),
    giveCard(Player),
    giveCard(Player),
    giveCard(Player),
    giveCard(Player),
    giveCard(Player),
    giveCard(Player); true).

