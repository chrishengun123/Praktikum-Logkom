:- import('random_card.pl')
:- dynamic(started/0)

start :-
    started(1) -> format("Permainan sudah dimulai. Gunakan \"exit\" untuk keluar dan memulai ulang.", []);
    read_file('kartu_13525065.txt', Cards),
    format("Selamat datang di meja kartu! Habiskan semua kartumu :D\n", []),
    format("Kartumu: ~w\n", [Cards]),
    asserta(started).

play_card :-
    started(0) -> fail;
    read_file('kartu_13525065.txt', Cards),
    pop_random_card(Cards, NewCards, Card),
    write_file('kartu_13525065.txt', NewCards),
    format("Angka ~w dimainkan!\n", [Card]),
    NewCards == [] -> format("Selamat! Kamu menghabiskan semua kartumu. Kamu menang!!!\n", []);
    true.

display_status :-
    started(0) -> fail;
    read_file('kartu_13525065.txt', Cards),
    get_length(Cards, Length),
    format("Banyak Kartu di Tangan: \n", []), write(Length),
    format("Kartumu: ~w\n", [Cards]).

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