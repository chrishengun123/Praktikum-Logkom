:- initialization([random_card, file_read_write]).
:- dynamic(started/0).

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
    asserta(started).

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

mainkanKartu(X) :- play_card(X).

playCard(X) :-
    \+ started -> fail;
    read_file('kartu.txt', Cards),
    pop_card(Cards, I, NewCards),
    write_file('kartu.txt', NewCards),
    format("Angka ~w dimainkan!\n", [Card]),
    NewCards == [] -> format("Selamat! Kamu menghabiskan semua kartumu. Kamu menang!!!\n", []);
    true.

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
    started(0) -> format("Permainan belum dimulai. Gunakan \"start\" untuk memulai.", []),
                  fail;
    read_file('kartu_13525065.txt', Cards),
    open('hasil_13525065.txt', write, Stream),
    (Cards = [] -> format(Stream, 'Status: Menang\n', []);
     format(Stream, "Status: Tidak Selesai\n", [])),
    format(Stream, "Sisa Kartu: ~w", [Cards]),
    format("Hasil permainan telah disimpan ke hasil_13525065.txt.\nSampai jumpa di meja kartu berikutnya.\n", []),
    close(Stream).
