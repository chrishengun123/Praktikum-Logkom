peek :- lihatKartu. % js to make it faster
/* THIS ONE WORKS, BUT IS NOT EXACTLY THE SAME AS THE EXAMPLE IN THE SPEK*/ 
lihatKartu :-
    currentPlayer(Player),
    atom_concat('kartu_', Player, Temp),
    atom_concat(Temp, '.txt', Cardfile),
%    format("~w", [Cardfile]), for debug purposes
    read_file(Cardfile, Cards),
    get_length(Cards, Length),
    format("~nBerikut kartu yang Anda miliki: ~n", []),
    printCards(1, Length, Cards).


printCards(_, _, []) :- !.
printCards(Index, Length, [Card | Rest]) :-
    Index =< Length,
    Index1 is Index + 1,
    format("~d. ~w-~w~n", [Index | Card]),
    printCards(Index1, Length, Rest).
