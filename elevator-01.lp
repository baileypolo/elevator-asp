% INSERT NAMES AND EMAIL ADDRESSES OF YOUR GROUP MEMBERS:

% beschäftigt 

#const floors = 3.
#const agents = 1.
#const start1 = 2.

agent(elevator(1)).
floor(1).
floor(2).
floor(3).
init(at(elevator(1),2)).
init(request(call(up),1)).

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
goal(go_to(CF,NF,GF,DE,E), t) :- go_to(CF,NF,GF,DE,E,t), go_to(PF,CF,GF,DE,E,t-1), (DE)!=(-1), (PF)!=(GF). 

go_to(CF,NF,GF,0,E,t) :- go_to(CF,NF,GF,0,E), not service(GF).
go_to(CF,NF,GF,0,E,t) :- go_to(CF,NF,GF,E,E), not dropped(GF, E).



1 = {goal(go_to(CF,NF,GF,DE,E),t):
holds(at(elevator(E),CF),t-1),
go_to(CF, NF, GF, DE, E, t)
%,(goal(go_to(_,_,GF,0),E',_), agent(elevator(E')), (E')=(E),DE=0), 				% don't pick up another elevators task
%not(DE=0, served(GF)),											% don't target a served floor
%not(DE=E, dropped(GF,E))										% don't drop off twice
} :- agent(elevator(E)), not goal(go_to(_),E,t-1).

1 = {goal(go_to(CF,NF,GF,DE),E,t):
holds(at(elevator(E),CF),t-1),
go_to(CF, NF, GF, DE, E, t)
%,not(DE=0, elevator(E'), E'=E, goal(go_to(_,_,GF,0),E',_)), 	% don't pick up another elevators task
%not(DE=0, served(GF)),										% don't target a served floor
%not(DE=E, dropped(GF,E))									% don't drop off twice
} :- agent(elevator(E)), goal(go_to(CF,CF,CF,DE),E,t-1), DE!=-1.


% elevator serves 
do(elevator(E),serve,t) :- goal(go_to(GF, GF, GF, 0),E,t).
do(elevator(E),serve,t) :- goal(go_to(GF, GF, GF, E),E,t).
%served(F) :- do(elevator(E),serve,t), holds(at(elevator(E),F),t).
service(F) :- goal(go_to(_,_,F,_,_,_)).
dropped(F,E) :- do(elevator(E),serve,t), holds(at(elevator(E),F),t),holds(request(deliver(E),F),t-1). 

% elevator moves
do(elevator(E),move(1),t) :- goal(go_to(CF, NF, _, DE),E,t), DE != -1, NF-CF = 1.
do(elevator(E),move(-1),t) :- goal(go_to(CF, NF, _, DE),E,t), DE != -1, NF-CF = -1.

% relocate elevators
holds(at(elevator(E),NF),t) :- goal(go_to(_, NF, _, _),E,t).

% keep unserved pickups and deliveries
holds(request(call(C),F),t) :- holds(request(call(C),F),t-1), not served(F).
holds(request(deliver(E),F),t) :- holds(request(deliver(E),F),t-1), not dropped(F,E).


#minimize {1 : do(X)}.
 
%#show do(A,X,t) : do(A,X,t). % output atoms indicating actions

#program check(t). % fulfillment of all requests can, e.g., be checked as follows
:- query(t), holds(request(_,_),t).

%#show holds(X,t) : holds(X,t). % output atoms indicating states

#show holds/2.
#show do/3.
% :- query(t), holds(request(R,F),t).
