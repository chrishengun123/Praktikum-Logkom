:- initialization([random_card, file_read_write, lihat_kartu_dan_tantang]).
% True when the game has started.
:- dynamic(started/0).
% The current player.
% currentPlayer(Player), Player:atom
:- dynamic(currentPlayer/1).
% The order of players.
% turnOrder(Order), Order:list = [Player|_], Player:atom
:- dynamic(turnOrder/1).
% Check which player has stated UNI
:- dynamic(stated_uni/1).
:- dynamic(playerWon/1).
:- dynamic(skipped/0).
:- dynamic(calledInternally/0).

startGame :-
    started -> format("Permainan sudah dimulai. Gunakan \"exit\" untuk keluar dan memulai ulang.", []);
    format("\nMasukkan jumlah pemain: ", []),
    read(PlayerNum),
    % Validify input of PlayerNum
    validify(PlayerNum, ValidNum),
    format("\n", []),
    % Inputs each player and validifies it at the same time
    initPlayer(1, ValidNum, [], Players),
    % Read deck from pool.txt
    read_file('pool.txt', Deck),
    % Shuffles deck (works with lists)
    shuffle(Deck, ShuffledDeck),
    % Generate each players decks
    create_player_files(Players),
    format("\nUrutan pemain: ", []),
    % Pseudorandom (?) shuffle player turn order
    shuffle(Players, [First | Rest]),
    % Prints the order with the format Name - Name - Name - Name
    printOrder([First | Rest]),
    format("\n", []),
    format("\nSetiap pemain mendapatkan 7 kartu acak.\n", []),
    % Deals cards from the shuffled deck to each player
    dealCards(ShuffledDeck, Players, Remaining),
    findStartingDiscard(Remaining, Discard, Unused),
    % Remaining cards get put into unused and the first one is for the discard pile
    write_file('unused_cards.txt', Unused),
    write_file('discard.txt', [Discard]),
    format("\nKartu discard top: ~w-~w\n", Discard),
    format("\nGiliran ~w", [First]),
    % Make started true, currentPlayer to the first player, and turn order the same as the shuffled order
    asserta(started),
    asserta(currentPlayer(First)),
    asserta(turnOrder([First | Rest])), !.

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
    (ownMember(InputName, Taken) ->
      format("Nama sudah digunakan. Masukkan nama lain: ", []),
      readUniqueName(Taken, Name)
    ;
      Name = InputName
    ).

printOrder([Player]) :- format("~w", [Player]), !.
printOrder([Player | Rest]) :-
    format("~w - ", [Player]),
    printOrder(Rest).

printCard([Num]) :- isNumCard(Num), format("~w",[Num]), !.
printCard([Name | Rest]) :- 
    \+ isNumCard(Name), format("~w-",[Name]), 
    printCard(Rest).

dealCards(Deck, Players, Unused) :-
    Handsize is 7,
    dealHands(Deck, Players, Handsize, Unused).

dealHands(Remaining, [], _, Remaining).
dealHands(Deck, [Name|Rest], HandSize, Remaining) :-
    splitDeck(Deck, HandSize, Hand, RestDeck),
    write_file(Name, Hand),
    write_file(Name, Hand),
    dealHands(RestDeck, Rest, HandSize, Remaining).

splitDeck(Rest, 0, [], Rest) :- !.
splitDeck([Card|Deck], N, [Card|Hand], Rest) :-
    N1 is N - 1,
    splitDeck(Deck, N1, Hand, Rest).

isNumCard([_, Type]) :-
    ownMember(Type, ['0','1','2','3','4','5','6','7','8','9']).

findStartingDiscard([Card | Rest], Card, Rest) :- 
    isNumCard(Card), !.
findStartingDiscard([Card | Rest], Discard, [Card | Unused]) :-
    findStartingDiscard(Rest, Discard, Unused).

switchPlayer(Player, NextPlayer) :- 
    retract(currentPlayer(Player)),
    asserta(currentPlayer(NextPlayer)),
    (skipped -> retract(skipped) ; true).

cardEffect([_, Type]) :-
    currentPlayer(Player),
    turnOrder(Order),
    get_length(Order, PlayerAmount),
    ((Type == 'skip') ->
        write('Pemain berikutnya kehilangan giliran.'),nl,
        get_index(Order, Player, Turn),
        NextTurn is (Turn+1) mod PlayerAmount,
        get_element(Order, NextTurn, NextPlayer),
        switchPlayer(Player, NextPlayer),
        format("Giliran ~w\n.", [NextPlayer])
    );
    ((Type == 'reverse') ->
        currentPlayer(Player),
        turnOrder(Order),
        get_length(Order, PlayerAmount),
        reverse_list(Order, NewOrder),
        retract(turnOrder(Order)),
        asserta(turnOrder(NewOrder)),
        get_index(Order, Player, Turn),
        NextTurn is (Turn+2) mod PlayerAmount,
        get_element(Order, NextTurn, NextPlayer),
        switchPlayer(Player, NextPlayer),
        write('Giliran berubah arah.'), nl,
        format("Giliran ~w.\n",[NextPlayer])
    );
    ((Type == 'draw_2') ->
        currentPlayer(Player),
        turnOrder(Order),
        get_length(Order, PlayerAmount),
        ambilKartuInternal, ambilKartuInternal,
        format("~w mendapatkan 2 kartu acak.\n", [Player]),
        get_index(Order, Player, Turn),
        NextTurn is (Turn+1) mod PlayerAmount,
        get_element(Order, NextTurn, NextPlayer),
        switchPlayer(Player, NextPlayer),
        format("Giliran ~w\n.", [NextPlayer])
    );
    ((Type == 'wild') ->
        format("Pilih warna:\n", []),
        read(NewColor),
        format("Warna aktif sekarang: ~w", [NewColor]),
        read_file('discard.txt', [_|SubDiscardPile]),
        write_file('discard.txt', [[NewColor, Type]|SubDiscardPile]),
        format("Giliran ~w\n.", [Player])
    );
    ((Type == 'wild_draw_four') ->
        currentPlayer(Player),
        format("~w mendapatkan 4 kartu acak.\n", [Player]),
        format("Pilih warna: ", []),
        read(NewColor),
        format("Warna aktif sekarang: ~w", [NewColor]),
        format("Giliran ~w\n.", [Player]),
        read_file('discard.txt', [_|SubDiscardPile]),
        write_file('discard.txt', [[NewColor, Type]|SubDiscardPile]),
        asserta(skipped)
    );
    true.

check_reverse([_, Type]) :-
    (Type == 'reverse' -> write('It is a reverse'); write('It is something else')).

% Plays the card at index I.
% I:int
playCard(Idx) :-
    skipped -> format("giliranmu diskip",[]);
    \+ started -> format("permainan belum mulai",[]);
    currentPlayer(Player),
    read_file(Player, Cards),
    I is Idx-1,
    get_element(Cards, I, Card),
    [Color, Type] = Card,
    read_file('discard.txt', SubDiscardPile),
    [LastCard|_] = SubDiscardPile,
    [LastColor, LastType] = LastCard,
    (
    (((SubDiscardPile == []; Color == 'black';
    Color == LastColor; Type == LastType),
    \+ (Type == 'wild', LastType == 'wild'),
    \+ (Type == 'wild_draw_four', LastType == 'wild_draw_four'),
    \+ (Type == 'wild', LastType == 'wild_draw_four')),
    \+ (Type == 'wild_draw_four', LastType == 'wild') ->
        delete_at(Cards, I, NewCards),
        DiscardPile = [Card | SubDiscardPile],
        write_file(Player, NewCards),
        write_file('discard.txt', DiscardPile),
        format("~w memainkan kartu: ", [Player]),
        format("~w-~w.\n", Card),
        (stated_uni(Player) -> format("~w menyerukan UNI!\n", [Player]) ; true),
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

mainkanKartu(I) :- playCard(I), !.

uni(I) :- 
    currentPlayer(Player),
    read_file(Player, Hand),
    get_length(Hand, Length),
    ((Length =:= 2) ->
        asserta(stated_uni(Player)),
        playCard(I)
    ;
        format("Perintah UNI tidak valid. ~w mendapatkan 1 kartu penalti.\n", [Player]),
        ambilKartuInternal,
        turnOrder(Order),
        get_length(Order, PlayerAmount),
        get_index(Order, Player, Turn),
        NextTurn is (Turn+1) mod PlayerAmount,
        get_element(Order, NextTurn, NextPlayer),
        switchPlayer(Player, NextPlayer),
        format("Giliran ~w.\n", [NextPlayer])
    ), !.

tangkap(Nama) :-    
    read_file(Nama, LastHand), 
    get_length(LastHand, Length),
    currentPlayer(Player),
    turnOrder(Order),
    get_length(Order, PlayerAmount),
    ((stated_uni(Nama) ; Length > 1) -> 
    format("Perintah tangkap tidak valid. ~w mendapatkan 1 kartu penalti.\n", [Player]),
    ambilKartuInternal; 
    (\+ stated_uni(Nama)) -> 
    switchPlayer(Player, Nama),
    ambilKartuInternal, ambilKartuInternal,
    format("~w tertangkap tidak menyerukan UNI.\n", [Nama]),
    format("~w mendapatkan 2 kartu penalti.\n", [Nama]),
    switchPlayer(Nama, Player)
    ),
    currentPlayer(Player),
    turnOrder(Order),
    get_length(Order, PlayerAmount),
    get_index(Order, Player, Turn),
    NextTurn is (Turn+1) mod PlayerAmount,
    get_element(Order, NextTurn, NextPlayer),
    switchPlayer(Player, NextPlayer),
    format("Giliran ~w.\n", [NextPlayer]), !.

% take a card and change the current player
ambilKartu :-
    currentPlayer(Player),
    read_file(Player, Hand),
    read_file('pool.txt', Draw),
    shuffle(Draw, ShuffledDeck),
    splitDeck(ShuffledDeck, 1, DrawnCard, _),
    append_list(Hand,DrawnCard,Result),
    write_file(Player, Result), 
    (stated_uni(Player) -> retract(stated_uni(Player)) ; true),
    (calledInternally -> true ; 
    format("~w mendapatkan kartu: ",[Player]),
    get_element(DrawnCard,0,Card),
    [Color, Type] = Card,
    format("~w-~w\n", [Color, Type]),
    turnOrder(Order),
    get_length(Order, PlayerAmount),
    get_index(Order, Player, Turn),
    NextTurn is (Turn+1) mod PlayerAmount,
    get_element(Order, NextTurn, NextPlayer),
    switchPlayer(Player, NextPlayer),
    format("Giliran ~w.\n", [NextPlayer])),
    !.

ambilKartuInternal :-
    asserta(calledInternally),
    ambilKartu,
    retract(calledInternally).

display_status :-
    \+ started -> fail;
    read_file('kartu_13525065.txt', Cards),
    get_length(Cards, Length),
    format("Banyak Kartu di Tangan: \n", []), write(Length),
    format("Kartumu: ~w\n", [Cards]).

lihatCommand :-
    format("\nAksi utama yang tersedia:\n", []),
    read_file('discard.txt', DiscardPile),
    [[LastColor, LastType] | _] = DiscardPile,
    currentPlayer(CurrentPlayer),
    read_file(CurrentPlayer, PlayerCards),
    (LastType == 'wild_draw_four' -> format("1. ambilKartu\n2. tantang", []); true),
    (LastType == 'draw_2' -> format("1. ambilKartu", []); true),
    ((hasColor(PlayerCards, LastColor) ; hasType(PlayerCards, LastType)) -> format("1. mainkanKartu", []) ; format("1. ambilKartu", [])),
    format("\n", []),
    format("\nAksi pendukung yang tersedia:\n", []),
    format("1. lihatCommand\n2. lihatKartu\n3. cekInfo\n", []).

hasColor([[Color , _] | _], Color) :- !.
hasColor([_ | Rest], Color) :-
  hasColor(Rest, Color).

hasType([[_ , Type] | _], Type) :- !.
hasType([_ | Rest], Type) :-
  hasType(Rest, Type).

ownMember(X, [X | _]).
ownMember(X, [_ | Tail]) :-
  ownMember(X, Tail).

cekInfo :- 
    read_file('discard.txt', Discard),
    [Top | _] = Discard,
    format("\nKartu discard top: ~w-~w.\n", Top),
    turnOrder(Order),
    format("\nUrutan pemain: ",[]),
    printOrder(Order),
    format(".\n",[]),
    get_length(Order, PlayerAmount),
    printPlayersInfo(PlayerAmount).

printPlayersInfo(2) :-
    turnOrder(Order), PlayerAmount = 2,
    currentPlayer(FirstPlayer),
    format("\nNama pemain 1: ~w\n", [FirstPlayer]),
    read_file(FirstPlayer, FirstCards),
    get_length(FirstCards, FirstLength),
    format("Jumlah kartu : ~w\n", [FirstLength]),
    get_index(Order, FirstPlayer, FirstTurn),
    SecondTurn is (FirstTurn+1) mod PlayerAmount,
    get_element(Order, SecondTurn, SecondPlayer), 
    format("\nNama pemain 2: ~w\n", [SecondPlayer]),
    read_file(SecondPlayer, SecondCards),
    get_length(SecondCards, SecondLength),
    format("Jumlah kartu : ~w\n", [SecondLength]).
printPlayersInfo(3) :-
    turnOrder(Order), PlayerAmount = 3,
    currentPlayer(FirstPlayer),
    format("\nNama pemain 1: ~w\n", [FirstPlayer]),
    read_file(FirstPlayer, FirstCards),
    get_length(FirstCards, FirstLength),
    format("Jumlah kartu : ~w\n", [FirstLength]),
    get_index(Order, FirstPlayer, TurnOne),
    SecondTurn is (TurnOne+1) mod PlayerAmount,
    get_element(Order, SecondTurn, SecondPlayer), 
    format("\nNama pemain 2: ~w\n", [SecondPlayer]),
    read_file(SecondPlayer, SecondCards),
    get_length(SecondCards, SecondLength),
    format("Jumlah kartu : ~w\n", [SecondLength]),
    get_index(Order, SecondPlayer, TurnTwo),
    ThirdTurn is (TurnTwo+1) mod PlayerAmount,
    get_element(Order, ThirdTurn, ThirdPlayer), 
    format("\nNama pemain 3: ~w\n", [ThirdPlayer]),
    read_file(ThirdPlayer, ThirdCards),
    get_length(ThirdCards, ThirdLength),
    format("Jumlah kartu : ~w\n", [ThirdLength]).
printPlayersInfo(4) :-
    turnOrder(Order), PlayerAmount = 4,
    currentPlayer(FirstPlayer),
    format("\nNama pemain 1: ~w\n", [FirstPlayer]),
    read_file(FirstPlayer, FirstCards),
    get_length(FirstCards, FirstLength),
    format("Jumlah kartu : ~w\n", [FirstLength]),
    get_index(Order, FirstPlayer, TurnOne),
    SecondTurn is (TurnOne+1) mod PlayerAmount,
    get_element(Order, SecondTurn, SecondPlayer), 
    format("\nNama pemain 2: ~w\n", [SecondPlayer]),
    read_file(SecondPlayer, SecondCards),
    get_length(SecondCards, SecondLength),
    format("Jumlah kartu : ~w\n", [SecondLength]),
    get_index(Order, SecondPlayer, TurnTwo),
    ThirdTurn is (TurnTwo+1) mod PlayerAmount,
    get_element(Order, ThirdTurn, ThirdPlayer), 
    format("\nNama pemain 3: ~w\n", [ThirdPlayer]),
    read_file(ThirdPlayer, ThirdCards),
    get_length(ThirdCards, ThirdLength),
    format("Jumlah kartu : ~w\n", [ThirdLength]),
    get_index(Order, ThirdPlayer, TurnThree),
    FourthTurn is (TurnThree+1) mod PlayerAmount,
    get_element(Order, FourthTurn, FourthPlayer), 
    format("\nNama pemain 4: ~w\n", [FourthPlayer]),
    read_file(FourthPlayer, FourthCards),
    get_length(FourthCards, FourthLength),
    format("Jumlah kartu : ~w\n", [FourthLength]).

endGame :-
    retract(started),
    turnOrder(Order),
    get_length(Order, PlayerNum),
    sumCount(Order, [], ListScore),
    ownSort(ListScore, SortedScore),
    [[Player, _] | _] = SortedScore, 
    format("Permainan selesai! ~w menghabiskan semua kartunya!\n\n", [Player]),
    format("Berikut perhitungan poin sisa kartu.\n", []),
    summary(Order, ListScore),
    format("\nUrutan pemenang:\n", []),
    ownSort(ListScore, SortedScore),
    winOrder(SortedScore, PlayerNum),
    [[Player, _] | _] = SortedScore, 
    format("\n", []),
    format("Selamat, ~w, menjadi pemenang!\n",[Player]).

sumCount([], Acc, Acc).
sumCount([Player | Rest], Acc, ListScore) :-
    read_file(Player, Cards),
    countCards(Cards, CardSum),
    ownAppend([[Player, CardSum]], Acc, NewListScore),
    sumCount(Rest, NewListScore, ListScore).

summary([], _).
summary([Player | Rest], ListScore) :-
    format("~w: ", [Player]),
    read_file(Player, Cards),
    printCards(Cards),
    format("= ", []),
    printValues(Cards),
    countCards(Cards, CardSum),
    format(" = ~d poin", [CardSum]),
    format("\n", []),
    Pair = [Player, CardSum],
    ownAppend([Pair], ListScore, NewListScore),
    summary(Rest, NewListScore).

printValues([Last]) :-
    cardValue(Last, Value),
    format("~w", [Value]).
printValues([Card | Rest]) :-
    Rest \= [],
    cardValue(Card, Value),
    format("~w + ", [Value]),
    printValues(Rest).

printCards([]) :-
    format("kartu habis", []), !.
printCards([Last]) :-
    [Color , Type] = Last,
    format("~w-~w ", [Color, Type]).
printCards([Top | Rest]) :-
    Rest \= [],
    [Color , Type] = Top,
    format("~w-~w + ", [Color, Type]),
    printCards(Rest).

countCards([], 0).
countCards([Card | Rest], Total) :-
    cardValue(Card, V),
    countCards(Rest, SubTotal),
    Total is V + SubTotal.

cardValue([_, Type], V) :-
  ( Type == '0' -> V = 1
    ; ownMember(Type, ['1','2','3','4','5','6','7','8','9']) ->
        name(Type, [Code]), V is Code - 0'0
    ; ownMember(Type, ['skip','reverse','draw_2']) -> V = 10
    ; ownMember(Type, ['wild','wild_draw_four']) -> V = 20
    ; V = 0
    ).

winOrder(ListScore, Length) :-
    winOrderH(ListScore, 1, Length).

winOrderH([], _, _).
winOrderH([[Player, Score] | Rest], Index, Length) :-
    Index =< Length,
    format("~d. ~w (~d poin)\n", [Index, Player, Score]),
    Index1 is Index + 1,
    winOrderH(Rest, Index1, Length).

% Insertion sort
ownSort(List, Sorted) :-
    iSort(List, [], Sorted).

iSort([], Acc, Acc).
iSort([Head | Tail], Acc, Sorted) :-
    insert(Head, Acc, NAcc),
    iSort(Tail, NAcc, Sorted).

insert([P1, S1], [[P2, S2] | T], [[P2, S2] | NT]) :-
    S1 > S2,
    insert([P1, S1], T, NT).
insert([P1, S1], [[P2, S2] | T], [[P1, S1], [P2, S2] | T]) :-
    S1 =< S2.
insert(X, [], [X]).

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
