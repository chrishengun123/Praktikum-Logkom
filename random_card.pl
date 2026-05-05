get_element(List, Index, Element) :-
    (Index == 0,!, [Element|_] = List);
    (SubIndex is Index-1, [_|SubList] = List, get_element(SubList, SubIndex, Element)).

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