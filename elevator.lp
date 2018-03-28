% INSERT NAMES AND EMAIL ADDRESSES OF YOUR GROUP MEMBERS:

% beschäftigt 

agent(elevator(1)).
agent(elevator(2)).
floor(1).
floor(2).
floor(3).
floor(4).
floor(5).
init(at(elevator(1),1)).
init(at(elevator(2),2)).
init(request(deliver(2),3)).
init(request(call(up),3)).
init(request(call(down),5)).
init(request(call(down),4)).

#include <incmode>. % built-in incremental mode of clingo

#program base. % static rules go below

% GF = goal floor ; CF = current floor ; NF = next floor ; D = direction ; E = Elevator

adjacent(F1,F2) :- floor(F1), floor(F2), |F1-F2| = 1.
holds(at(elevator(E),CF),0) :- init(at(elevator(E),CF)).
holds(request(deliver(E),GF),0) :- init(request(deliver(E),GF)).
holds(request(call(D),CF),0) :- init(request(call(D),CF)).

% go to drop off
go_to(CF, NF, GF, E, E) :- floor(CF), floor(NF), init(request(deliver(E),GF)), adjacent(CF,NF), |CF-GF| > |NF-GF|.
go_to(GF, GF, GF, E, E) :- init(request(deliver(E),GF)).

% go to pickup with elevator "zero", any elevator can pick up
go_to(CF, NF, GF, 0, E) :- floor(CF), floor(NF), init(request(call(_),GF)), adjacent(CF,NF), |CF-GF| > |NF-GF|, agent(elevator(E)).
go_to(GF, GF, GF, 0, E) :- init(request(_,GF)), agent(elevator(E)).

% elevator stops without serving when DE = -1
go_to(CF, CF, CF, -1, E) :- floor(CF), agent(elevator(E)).

#program step(t). % actions, effects, and minimization go below

% DE = designated elevator task; E for specific elevator delivery, 0 for any elevator to pick up, -1 for stopping

% chain deterministic path together once its been picked
path(go_to(CF,NF,GF,DE,E), t) :- go_to(CF,NF,GF,DE,E), path(go_to(PF,CF,GF,DE,E),t-1), (DE)!=(-1), (PF)!=(GF). 

% option atoms are the remaining possible useful moves to any elevator anywhere
option(go_to(CF,NF,GF,0,E),t) :- go_to(CF,NF,GF,0,E), not service(GF).

option(go_to(CF,NF,GF,E,E),t) :- go_to(CF,NF,GF,E,E), not dropped(GF, E).

1{path(go_to(CF,NF,GF,DE,E),t):
holds(at(elevator(E),CF),t-1),
option(go_to(CF,NF,GF,DE,E),t)
}1 :- agent(elevator(E)), not path(go_to(_,_,_,_,E),t-1).

1{path(go_to(CF,NF,GF,DE',E),t):
holds(at(elevator(E),CF),t-1),
option(go_to(CF,NF,GF,DE',E),t),
(DE') != (-1)
%}1 :- agent(elevator(E)), path(go_to(CF,CF,CF,DE,E),t-1), DE!=-1.
}1 :- agent(elevator(E)), do(elevator(E), serve, t-1).


% elevator serves 
do(elevator(E),serve,t) :- path(go_to(GF, GF, GF, 0, E),t).
do(elevator(E),serve,t) :- path(go_to(GF, GF, GF, E, E),t).
served(F,t) :- do(elevator(E),serve,t), holds(at(elevator(E),F),t).
served(F,t) :- served(F,t-1).
service(F) :- path(go_to(_,_,F,_,_),t).
dropped(F,E,t) :- do(elevator(E),serve,t), holds(at(elevator(E),F),t), holds(request(deliver(E),F),t-1). 
dropped(F,E,t) :- dropped(F,E,t-1).

% elevator moves
do(elevator(E),move(1),t) :- path(go_to(CF, NF, _, DE, E),t), DE != -1, NF-CF = 1.
do(elevator(E),move(-1),t) :- path(go_to(CF, NF, _, DE, E),t), DE != -1, NF-CF = -1.

% relocate elevators
holds(at(elevator(E),NF),t) :- path(go_to(_, NF, _, _, E),t).

% keep unserved pickups and deliveries
holds(request(call(C),F),t) :- holds(request(call(C),F),t-1), not served(F,t).
holds(request(deliver(E),F),t) :- holds(request(deliver(E),F),t-1), not dropped(F,E,t).


#minimize {1 : do(_,_,_)}.


#program check(t). % fulfillment of all requests can, e.g., be checked as follows
:- query(t), holds(request(_,_),t).
%:- query(t), t<10.

#show holds/2.
#show do/3.
%#show go_to/5.
%#show path/2.
%#show service/1.
%#show dropped/2.
%#show test/1.
