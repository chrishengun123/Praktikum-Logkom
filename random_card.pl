get_element(List, Index, Element) :-
    (Index == 0,!, [Element|_] = List);
    (SubIndex is Index-1, [_|SubList] = List, get_element(SubList, SubIndex, Element)).

get_index(List, Element, Index) :-
    ([Element|_] = List,!, Index == 0);
    [_|SubList] = List,
    (
    (SubList = [],!, Index == -1);
    (get_index(SubList, Element, SubIndex), Index is SubIndex+1)
    ).

delete_at(List, Index, NewList) :-
    (Index == 0,!, [_|NewList] = List);
    (SubIndex is Index-1, [Element|SubList] = List, delete_at(SubList, SubIndex, NewSubList), NewList = [Element|NewSubList]).

get_length([_|Sub], Length) :- 
    (Sub == [],!, Length is 1);
    (get_length(Sub, SubLength), Length is SubLength+1).

pop_random_card(Cards, NewCards, Card) :-
    get_length(Cards, Length),
random(0, Length, RNG),
    get_element(Cards, RNG, Card),
    delete_at(Cards, RNG, NewCards).

pop_card(Cards, I, NewCards, Card) :- 
    get_element(Cards, I, Card),
    delete_at(Cards, I, NewCards).

shuffle([], []).
shuffle(List, [Elem | Shuffled]) :-
    get_length(List, Len),
    random(0, Len, Index),
    get_element(List, Index, Elem),
    delete_at(List, Index, Rest),
    shuffle(Rest, Shuffled).

generate_deck(N, N, [N]) :- !.
generate_deck(Current, Max, [Current | Rest]) :-
    Next is Current + 1,
    generate_deck(Next, Max, Rest).
