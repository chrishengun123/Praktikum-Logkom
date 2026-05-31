:- dynamic(tmpDiscardType/1).
:- dynamic(tmpActiveColor/1).

loadGame :-
  format("Masukkan nama file yang akan dimuat: ", []),
  read(FileName),
  format("\n", []),
  name(FileName, FileCodes),
  ownAppend(FileCodes, ".txt", FullFileCodes),
  name(FullFileName, FullFileCodes),
  open(FullFileName, read, Stream),
  resetState,
  read(Stream, First),
  applyAll(Stream, First),
  close(Stream),
  finalizeDiscard,
  asserta(started),
  currentPlayer(LastPlayer),
  format("\nStatus permainan berhasil dimuat dari ~w.txt.", [FileName]),
  format("\nMelanjutkan giliran ~w.\n", [LastPlayer]).

resetState :-
  retractAllX(started),
  retractAllX(currentPlayer(_)),
  retractAllX(turnOrder(_)),
  retractAllX(stated_uni(_)),
  retractAllX(lastCard(_)),
  retractAllX(skipped),
  retractAllX(tmpDiscardType(_)),
  retractAllX(tmpActiveColor(_)).

retractAllX(X) :- retract(X), fail.
retractAllX(_).

applyAll(_, end_of_file) :- !.
applyAll(Stream, Term) :-
  applyTerm(Term),
  read(Stream, Next),
  applyAll(Stream, Next).

% Parser
applyTerm(Key:Value) :-
  ( Key == urutan_pemain -> asserta(turnOrder(Value));
    Key == giliran -> asserta(currentPlayer(Value));
    Key == warna_aktif -> asserta(tmpActiveColor(Value));
    Key == status_UNI -> assertUni(Value);
    Key == arah_permainan -> true; /* NOTE: add arah_permainan dynamic in uni.pl */
    Key == discard_top -> Value = _-Type, asserta(tmpDiscardType(Type));
    Key = kartu(Name) -> normalizeCards(Value, N), write_file(Name, N);
    true
  ).

assertUni([]).
assertUni([Player | Rest]) :-
  asserta(stated_uni(Player)),
  assertUni(Rest).

finalizeDiscard :-
  tmpActiveColor(Color),
  tmpDiscardType(RawType),
  fixType(RawType, Type),
  Card = [Color, Type],
  asserta(lastCard(Card)).

normalizeCards([], []).
normalizeCards([Color-Type | Rest], [[Color, FType] | NRest]) :-
  fixType(Type, FType),
  normalizeCards(Rest, NRest).

fixType(T, A) :-
  intToAtom(T, A), !,
fixType(T, T).

intToAtom(0, '0').
intToAtom(1, '1').
intToAtom(2, '2').
intToAtom(3, '3').
intToAtom(4, '4').
intToAtom(5, '5').
intToAtom(6, '6').
intToAtom(7, '7').
intToAtom(8, '8').
intToAtom(9, '9').
