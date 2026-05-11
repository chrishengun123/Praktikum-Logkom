:- initialization([random_card, file_read_write]).
% True when the game has started.
:- dynamic(started/0).
% The current player.
% currentPlayer(Player), Player:atom
:- dynamic(currentPlayer/1).
% The order of players.
% turnOrder(Order), Order:list = [Player|_], Player:atom
:- dynamic(turnOrder/1).

startGame :-
    started -> format("Permainan sudah dimulai. Gunakan \"exit\" untuk keluar dan memulai ulang.", []);
    format("\nMasukkan jumlah pemain: ", []),
    read(PlayerNum),
    validify(PlayerNum, ValidNum),
    format("\n", []),
    initPlayer(1, ValidNum, [], Players),
    generate_deck(1, 40, Deck),
    shuffle(Deck, ShuffledDeck),
    create_player_files(Players),
    format("\nUrutan pemain: ", []),
    shuffle(Players, [First | Rest]),
    printOrder([First | Rest]),
    format("\n", []),
    format("\nSetiap pemain mendapatkan 7 kartu acak.\n", []),
    dealCards(ShuffledDeck, Players, [Discard | Unused]),
    write_file('unused_cards.txt', Unused),
    write_file('discard.txt', [Discard]),
    format("\nKartu discard top: ~w\n", [Discard]),
    format("\nGiliran ~w", [First]),
    asserta(started),
    asserta(currentPlayer(First)),
    asserta(turnOrder([First | Rest])).

validify(PlayerNum, ValidNum) :-
    (PlayerNum > 4 ; PlayerNum < 2)
    ->  (format("\nMohon masukkan angka antara 2-4.", []),
         format("\nMasukkan jumlah pemain: ", []),
         read(NewNum),
         validify(NewNum, ValidNum)) ; 
    ValidNum = PlayerNum.

initPlayer(Index, PlayerNum, _, []) :- Index > PlayerNum, !.
initPlayer(Index, PlayerNum, Taken, [Name | Rest]) :-
    Index =< PlayerNum,
    format("Masukkan nama pemain ~d: ", [Index]),
    readUniqueName(Taken, Name),
    NextIndex is Index + 1,
    initPlayer(NextIndex, PlayerNum, [Name | Taken], Rest).

readUniqueName(Taken, Name) :-
    read(InputName),
    (member(InputName, Taken) ->
      format("Nama sudah digunakan. Masukkan nama lain: ", []),
      readUniqueName(Taken, Name)
    ;
      Name = InputName
    ).

printOrder([Player]) :- format("~w", [Player]), !.
printOrder([Player | Rest]) :-
    format("~w - ", [Player]),
    printOrder(Rest).

dealCards(Deck, Players, Unused) :-
    Handsize is 7,
    dealHands(Deck, Players, Handsize, Unused).

dealHands(Remaining, [], _, Remaining).
dealHands(Deck, [Name|Rest], HandSize, Remaining) :-
    splitDeck(Deck, HandSize, Hand, RestDeck),
    atom_concat('kartu_', Name, Temp),
    atom_concat(Temp, '.txt', FileName),
    write_file(FileName, Hand),
    dealHands(RestDeck, Rest, HandSize, Remaining).

splitDeck(Rest, 0, [], Rest) :- !.
splitDeck([Card|Deck], N, [Card|Hand], Rest) :-
    N1 is N - 1,
    splitDeck(Deck, N1, Hand, Rest).

switchPlayer(Player, NextPlayer) :- 
    retract(currentPlayer(Player)),
    assert(currentPlayer(NextPlayer)).

cardEffect([_, Type]) :-
    currentPlayer(Player),
    turnOrder(Order),
    get_length(Order, PlayerAmount),
    ((Type == "skip") ->
        get_index(Order, Player, Turn),
        NextTurn is (Turn+1) mod PlayerAmount,
        get_element(Order, NextTurn, NextPlayer),
        switchPlayer(Player, NextPlayer)
    );
    ((Type == "reverse") ->
        reverse(Order, NewOrder),
        retract(turnOrder(Order)),
        assert(turnOrder(NewOrder)),
        get_index(Order, Player, Turn),
        NextTurn is Turn+2 mod PlayerAmount,
        get_element(Order, NextTurn, NextPlayer),
        switchPlayer(Player, NextPlayer)
    );
    ((Type == "draw_2") ->
        ambilKartu, ambilKartu,
        get_index(Order, Player, Turn),
        NextTurn is (Turn+1) mod PlayerAmount,
        get_element(Order, NextTurn, NextPlayer),
        switchPlayer(Player, NextPlayer)
    );
    ((Type == "wild") ->
        format("Pilih warna:\n"),
        read(NewColor),
        read_file('discard.txt', [_|SubDiscardPile]),
        write_file('discard.txt', [[NewColor|Type]|SubDiscardPile])
    );
    ((Type == "wild_draw_4") ->
        ambilKartu, ambilKartu, ambilKartu, ambilKartu,
        format("Pilih warna:\n"),
        read(NewColor),
        read_file('discard.txt', [_|SubDiscardPile]),
        write_file('discard.txt', [[NewColor|Type]|SubDiscardPile]),
        get_index(Order, Player, Turn),
        NextTurn is (Turn+1) mod PlayerAmount,
        get_element(Order, NextTurn, NextPlayer),
        switchPlayer(Player, NextPlayer)
    );
    true.

% Plays the card at index I.
% I:int
playCard(I) :-
    \+ started -> fail;
    currentPlayer(Player),
    get_hand_file(Player, File),
    read_file(File, Cards),
    get_element(Cards, I, Card),
    [Color, Type] = Card,
    read_file('discard.txt', SubDiscardPile),
    [LastCard|_] = SubDiscardPile,
    [LastColor, LastType] = LastCard,
    (
    (((SubDiscardPile == []; Color == "black"; LastColor = "black";
    Color == LastColor; Type == LastType),
    \+ (Type == "wild", LastType == "wild"),
    \+ (Type == "wild_draw_4", LastType == "wild_draw_4")) ->
        delete_at(Cards, I, NewCards),
        DiscardPile = [Card | SubDiscardPile],
        write_file(File, NewCards),
        write_file('discard.txt', DiscardPile),
        format("~w memainkan kartu: ~w.\n", [Player, Card]),
        turnOrder(Order),
        get_length(Order, PlayerAmount),
        get_index(Order, Player, Turn),
        NextTurn is (Turn+1) mod PlayerAmount,
        get_element(Order, NextTurn, NextPlayer),
        switchPlayer(Player, NextPlayer),
        cardEffect(Card)
    );
        format("kartu ~w-~w tidak bisa dimainkan", Card)
    ).

mainkanKartu(I) :- playCard(I).

display_status :-
    \+ started -> fail;
    read_file('kartu_13525065.txt', Cards),
    get_length(Cards, Length),
    format("Banyak Kartu di Tangan: \n", []), write(Length),
    format("Kartumu: ~w\n", [Cards]).

lihatCommand :-
    format("\nAksi utama yang tersedia:\n", []),
    format("1. ambilKartu\n2. tantang\n", []),
    format("\nAksi pendukung yang tersedia:\n", []),
    format("1. lihatCommand\n2. lihatKartu\n3. cekInfo\n", []).

save :- true.
load :- true.

exit :-
    \+ started -> format("Permainan belum dimulai. Gunakan \"start\" untuk memulai.", []),
                  fail;
    read_file('kartu_13525065.txt', Cards),
    open('hasil_13525065.txt', write, Stream),
    (Cards = [] -> format(Stream, 'Status: Menang\n', []);
     format(Stream, "Status: Tidak Selesai\n", [])),
    format(Stream, "Sisa Kartu: ~w", [Cards]),
    format("Hasil permainan telah disimpan ke hasil_13525065.txt.\nSampai jumpa di meja kartu berikutnya.\n", []),
    close(Stream).
