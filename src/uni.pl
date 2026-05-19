:- initialization([random_card, file_read_write, lihat_kartu]).
% True when the game has started.
:- dynamic(started/0).
% The current player.
% currentPlayer(Player), Player:atom
:- dynamic(currentPlayer/1).
% The order of players.
% turnOrder(Order), Order:list = [Player|_], Player:atom
:- dynamic(turnOrder/1).
% Check if ambilKartu is called directly
:- dynamic(calledDirectly/0).
% Check which player has stated UNI
:- dynamic(stated_uni/1).
:- dynamic(playerWon/1).

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
    atom_concat('kartu_', Name, Temp),
    atom_concat(Temp, '.txt', FileName),
    write_file(FileName, Hand),
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
    asserta(currentPlayer(NextPlayer)).

cardEffect([_, Type]) :-
    currentPlayer(Player),
    turnOrder(Order),
    get_length(Order, PlayerAmount),
    ((Type == 'skip') ->
        get_index(Order, Player, Turn),
        NextTurn is (Turn+1) mod PlayerAmount,
        get_element(Order, NextTurn, NextPlayer),
        switchPlayer(Player, NextPlayer)
    );
    ((Type == 'reverse') ->
        reverse_list(Order, NewOrder),
        retract(turnOrder(Order)),
        asserta(turnOrder(NewOrder)),
        get_index(Order, Player, Turn),
        NextTurn is Turn+2 mod PlayerAmount,
        get_element(Order, NextTurn, NextPlayer),
        switchPlayer(Player, NextPlayer)
    );
    ((Type == 'draw_two') ->
        ambilKartuInternal, ambilKartuInternal,
        get_index(Order, Player, Turn),
        NextTurn is (Turn+1) mod PlayerAmount,
        get_element(Order, NextTurn, NextPlayer),
        switchPlayer(Player, NextPlayer)
    );
    ((Type == 'wild') ->
        format("Pilih warna:\n", []),
        read(NewColor),
        read_file('discard.txt', [_|SubDiscardPile]),
        write_file('discard.txt', [[NewColor|Type]|SubDiscardPile])
    );
    ((Type == 'wild_draw_four') ->
        ambilKartuInternal, ambilKartuInternal, ambilKartuInternal, ambilKartuInternal,
        format("Pilih warna:\n", []),
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
playCard(Idx) :-
    \+ started -> fail;
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

uni(I) :- 
    currentPlayer(Player),
    read_file(Player, Hand),
    get_length(Hand, Length),
    ((Length =:= 2) ->
        playCard(I),
        format("~w menyerukan UNI!\n", [Player]),
        asserta(stated_uni(Player))
    ;
        write('Perintah UNI tidak valid!'), nl,
        ambilKartu
    ).

tangkap(Nama) :-    
    currentPlayer(Player),
    read_file(Player, Hand),
    get_length(Hand, Length),
    ((stated_uni(Nama) ; Length > 1) -> 
    write('Perintah tangkap tidak valid!'), nl,
    ambilKartu; 
    (\+ stated_uni(Nama)) -> 
    giveCard(Nama), 
    giveCard(Nama),
    format("~w tertangkap tidak menyerukan UNI.\n", [Nama]),
    format("~w mendapatkan 2 kartu penalti.\n", [Nama])
    ).

ambilKartuInternal :-
    asserta(calledDirectly),
    ambilKartu,
    retract(calledDirectly).

ambilKartu :-
    currentPlayer(Player),
    read_file(Player, Hand),
    read_file('unused_cards.txt', Draw),
    splitDeck(Draw, 1, DrawnCard, RestDeck),
    append_list(Hand,DrawnCard,Result),
    write_file(Player, Result), 
    write_file('unused_cards.txt', RestDeck),
    format("~w mendapatkan kartu: ",[Player]),
    get_element(DrawnCard,0,Card),
    format("~w-~w\n",Card),
    (stated_uni(Player) -> retract(stated_uni(Player)) ; true),
    get_length(Draw, DrawSize),
    (DrawSize =:= 1 -> reshuffle; true),
    (calledDirectly -> true ;
        turnOrder(Order),
        get_length(Order, PlayerAmount),
        get_index(Order, Player, Turn),
        NextTurn is (Turn+1) mod PlayerAmount,
        get_element(Order, NextTurn, NextPlayer),
        switchPlayer(Player, NextPlayer),
        format("Giliran ~w.\n", [NextPlayer])
    ), !.

reshuffle :-
    read_file('discard.txt', Discard),
    splitDeck(Discard, 1, Top, Draw),
    shuffle(Draw, Reshuffled),
    write_file('unused_cards.txt',Reshuffled),
    write_file('discard.txt', Top).

giveCard(OtherPlayer) :-
    read_file(Player, Hand),
    read_file('unused_cards.txt', Draw),
    splitDeck(Draw, 1, DrawnCard, RestDeck),
    append_list(Hand,DrawnCard,Result),
    write_file(Player, Result), 
    write_file('unused_cards.txt', RestDeck).

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
    get_hand_file(CurrentPlayer, FileName),
    read_file(FileName, PlayerCards),
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
    get_hand_file(FirstPlayer, FirstFile),
    read_file(FirstFile, FirstCards),
    get_length(FirstCards, FirstLength),
    format("Jumlah kartu : ~w\n", [FirstLength]),
    get_index(Order, FirstPlayer, FirstTurn),
    SecondTurn is (FirstTurn+1) mod PlayerAmount,
    get_element(Order, SecondTurn, SecondPlayer), 
    format("\nNama pemain 2: ~w\n", [SecondPlayer]),
    get_hand_file(SecondPlayer, SecondFile),
    read_file(SecondFile, SecondCards),
    get_length(SecondCards, SecondLength),
    format("Jumlah kartu : ~w\n", [SecondLength]).
printPlayersInfo(3) :-
    turnOrder(Order), PlayerAmount = 3,
    currentPlayer(FirstPlayer),
    format("\nNama pemain 1: ~w\n", [FirstPlayer]),
    get_hand_file(FirstPlayer, FirstFile),
    read_file(FirstFile, FirstCards),
    get_length(FirstCards, FirstLength),
    format("Jumlah kartu : ~w\n", [FirstLength]),
    get_index(Order, FirstPlayer, TurnOne),
    SecondTurn is (TurnOne+1) mod PlayerAmount,
    get_element(Order, SecondTurn, SecondPlayer), 
    format("\nNama pemain 2: ~w\n", [SecondPlayer]),
    get_hand_file(SecondPlayer, SecondFile),
    read_file(SecondFile, SecondCards),
    get_length(SecondCards, SecondLength),
    format("Jumlah kartu : ~w\n", [SecondLength]),
    get_index(Order, SecondPlayer, TurnTwo),
    ThirdTurn is (TurnTwo+1) mod PlayerAmount,
    get_element(Order, ThirdTurn, ThirdPlayer), 
    format("\nNama pemain 3: ~w\n", [ThirdPlayer]),
    get_hand_file(ThirdPlayer, ThirdFile),
    read_file(ThirdFile, ThirdCards),
    get_length(ThirdCards, ThirdLength),
    format("Jumlah kartu : ~w\n", [ThirdLength]).
printPlayersInfo(4) :-
    turnOrder(Order), PlayerAmount = 4,
    currentPlayer(FirstPlayer),
    format("\nNama pemain 1: ~w\n", [FirstPlayer]),
    get_hand_file(FirstPlayer, FirstFile),
    read_file(FirstFile, FirstCards),
    get_length(FirstCards, FirstLength),
    format("Jumlah kartu : ~w\n", [FirstLength]),
    get_index(Order, FirstPlayer, TurnOne),
    SecondTurn is (TurnOne+1) mod PlayerAmount,
    get_element(Order, SecondTurn, SecondPlayer), 
    format("\nNama pemain 2: ~w\n", [SecondPlayer]),
    get_hand_file(SecondPlayer, SecondFile),
    read_file(SecondFile, SecondCards),
    get_length(SecondCards, SecondLength),
    format("Jumlah kartu : ~w\n", [SecondLength]),
    get_index(Order, SecondPlayer, TurnTwo),
    ThirdTurn is (TurnTwo+1) mod PlayerAmount,
    get_element(Order, ThirdTurn, ThirdPlayer), 
    format("\nNama pemain 3: ~w\n", [ThirdPlayer]),
    get_hand_file(ThirdPlayer, ThirdFile),
    read_file(ThirdFile, ThirdCards),
    get_length(ThirdCards, ThirdLength),
    format("Jumlah kartu : ~w\n", [ThirdLength]),
    get_index(Order, ThirdPlayer, TurnThree),
    FourthTurn is (TurnThree+1) mod PlayerAmount,
    get_element(Order, FourthTurn, FourthPlayer), 
    format("\nNama pemain 4: ~w\n", [FourthPlayer]),
    get_hand_file(FourthPlayer, FourthFile),
    read_file(FourthFile, FourthCards),
    get_length(FourthCards, FourthLength),
    format("Jumlah kartu : ~w\n", [FourthLength]).

endGame :-
    retract(started),
    format("Permainan selesai! ~w menghabiskan semua kartunya!\n\n", []),
    format("Berikut perhitungan poin sisa kartu.\n", []),
    turnOrder(Order),
    get_length(Order, PlayerAmount),
    ListScore = [],
    summary(Order, PlayerAmount, ListScore),
    format("\nUrutan pemenang:\n", []),
    ownSort(ListScore, SortedScore),
    winOrder(ListScore),
    [[Player, _]] = Top, 
    format("\n", []),
    format("Selamat, ~w, menjadi pemenang!\n",[Top]).

summary([Player | Rest], PlayerNum, ListScore) :-
    format("~w: ", [Player]),
    read_file(Player, Cards),
    printCards(Cards),
    format("= ", []),
    countCards(Cards, CardSum),
    format(" = ~d poin", [CardSum]),
    format("\n", []),
    Pair = [Player, CardSum],
    ownAppend(Pair, Tuple, ListScore),
    PlayerNum1 is PlayerNum - 1,
    summary(Rest, PlayerNum1, ListScore).

printCards([]) :-
    format("kartu habis", []), !.
printCards(Last) :-
    [Color | Type] = Last,
    format("~w-~w ", [Color, Type]).
printCards([Top | Rest]) :-
    [Color | Type] = Top,
    format("~w-~w + ", [Color, Type]),
    printCards(Rest).

countCards([], Sum) :-
    Sum is 0, !.

countCards(PlayerCards, _) :-
    countCardsH(PlayerCards, 0).

countCardsH(Last, Sum) :-
    (ownMember(Last, ['0']) -> Sum1 is Sum + 0, format("0", []));
    (ownMember(Last, ['1']) -> Sum1 is Sum + 1, format("1", []));
    (ownMember(Last, ['2']) -> Sum1 is Sum + 2, format("2", []));
    (ownMember(Last, ['3']) -> Sum1 is Sum + 3, format("3", []));
    (ownMember(Last, ['4']) -> Sum1 is Sum + 4, format("4", []));
    (ownMember(Last, ['5']) -> Sum1 is Sum + 5, format("5", []));
    (ownMember(Last, ['6']) -> Sum1 is Sum + 6, format("6", []));
    (ownMember(Last, ['7']) -> Sum1 is Sum + 7, format("7", []));
    (ownMember(Last, ['8']) -> Sum1 is Sum + 8, format("8", []));
    (ownMember(Last, ['9']) -> Sum1 is Sum + 9, format("9", []));
    (ownMember(Last, ['skip', 'reverse', 'draw_2']) -> Sum1 is Sum + 10, format("10", []));
    (ownMember(Last, ['wild', 'wild_draw_four']) -> Sum1 is Sum + 20, format("20", [])),
    Sum is Sum1.

countCardsH([Head | Rest], Sum) :-
    (ownMember(Head, ['0']) -> Sum1 is Sum + 0, format("0 + ", []));
    (ownMember(Head, ['1']) -> Sum1 is Sum + 1, format("1 + ", []));
    (ownMember(Head, ['2']) -> Sum1 is Sum + 2, format("2 + ", []));
    (ownMember(Head, ['3']) -> Sum1 is Sum + 3, format("3 + ", []));
    (ownMember(Head, ['4']) -> Sum1 is Sum + 4, format("4 + ", []));
    (ownMember(Head, ['5']) -> Sum1 is Sum + 5, format("5 + ", []));
    (ownMember(Head, ['6']) -> Sum1 is Sum + 6, format("6 + ", []));
    (ownMember(Head, ['7']) -> Sum1 is Sum + 7, format("7 + ", []));
    (ownMember(Head, ['8']) -> Sum1 is Sum + 8, format("8 + ", []));
    (ownMember(Head, ['9']) -> Sum1 is Sum + 9, format("9 + ", []));
    (ownMember(Head, ['skip', 'reverse', 'draw_2']) -> Sum1 is Sum + 10, format("10 + ", []));
    (ownMember(Head, ['wild', 'wild_draw_four']) -> Sum1 is Sum + 20, format("20 + ", [])),
    countCardsH(Rest, Sum1),
    Sum is Sum1.

winOrder([]).
winOrder(ListScore) :-
    ownSort(ListScore, Sorted),
    get_length(Sorted, Length),
    Length1 is Length + 1,
    winOrderH(Sorted, 1, Length1).

winOrderH([[Player, Score] | Rest], Index, Length) :-
    Index =< Length,
    format("~d. ~w (~d poin)\n", [Index, Player, Score]),
    Index1 is Index + 1,
    winOrderH(Rest, Index1, Length).

% Insertion sort
ownSort([], []).
ownSort(List, Sorted) :-
    iSort(List, [], Sorted).

iSort([], Acc, Acc).
iSort([Head | Tail], Acc, Sorted) :-
    insert(Head, Acc, NAcc),
    iSort(Tail, NAcc, Sorted).

insert(X, [Y | T], [Y | NT]) :-
    X > Y,
    insert(X, T, NT).
insert(X, [Y | T], [X, Y | T]) :-
    X =< Y.
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
