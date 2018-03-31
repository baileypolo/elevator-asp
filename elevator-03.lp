% INSERT NAMES AND EMAIL ADDRESSES OF YOUR GROUP MEMBERS:

% beschäftigt 

#include <incmode>. % built-in incremental mode of clingo
#include "instances/instance-02_3-1.lp". 

#program base. % static rules go below

%new plan: assign every request to an elevator, then fill those requests by [elevator -> closest extreme -> furthest extreme]

assignment(request(deliver(E),F),E) :- agent(elevator(E)), holds(request(deliver(E),F),0).
1 = {assignment(request(call(D),F),E) : agent(elevator(E))} :- holds(request(call(D),F),0).

assignment(request(X,F),E,-1, |SF-F|) :- assignment(request(X,F),E), init(at(elevator(E),SF)), (SF)>(F).
assignment(request(X,F),E, 0, 0		) :- assignment(request(X,F),E), init(at(elevator(E),SF)), (SF)=(F).
assignment(request(X,F),E, 1, |SF-F|) :- assignment(request(X,F),E), init(at(elevator(E),SF)), (SF)<(F).

%not_under_extreme(F,E) :- assignment(request(_,F),E,-1,D), assignment(request(_,F'),E,-1,D'), (D)<(D').
%not_over_extreme(F,E) :- assignment(request(_,F),E,1,D), assignment(request(_,F'),E,1,D'), (D)<(D').
%under_extreme(F,E,D) :- assignment(request(_,F),E,-1,D), not not_under_extreme(F,E).
%over_extreme(F,E,D) :- assignment(request(_,F),E,1,D), not not_over_extreme(F,E).

not_extreme(F,E,I) :- assignment(request(_,F),E,I,D), assignment(request(_,F'),E,I,D'), (D)<(D').
extreme(F,E,I,D) :- assignment(request(_,F),E,I,D), not not_extreme(F,E,I).

max_extreme(F,E,I) :- extreme(F,E,I,D), extreme(F',E,I',D'), (I)!=(I'), D'<D.
1{max_extreme(F'',E,I''):extreme(F'',E,I'',_)}1 :- extreme(F,E,I,D), extreme(F',E,I',D'), (I)!=(I'), D'=D.

min_extreme(F,E,I) :- extreme(F,E,I,_), not max_extreme(F,E,I). 


%max_extreme(OF,E,OD) :- over_extreme(OF,E,OD), under_extreme(UF,E,UD), OD>UD. 
%max_extreme(UF,E,UD) :- over_extreme(OF,E,OD), under_extreme(UF,E,UD), OD<UD. 
%max_extreme(F,E,D) :- over_extreme(F,E,D), not under_extreme(_,E,_). 
%max_extreme(F,E,D) :- not over_extreme(_,E,_), under_extreme(F,E,D). 

%min_extreme(F,E,1) :- over_extreme(F,E,D), not max_extreme(F,E,_). 
%min_extreme(F,E,-1) :- under_extreme(F,E,D), not max_extreme(F,E,_). 

%no_extreme(F,E) :- assignment(_,E,0,0), init(at(elevator(E),F)), not assignment(_,E,1,_), not assignment(_,E,-1,_).

reached_min(E,0) :- not min_extreme(_,E,_), agent(elevator(E)).

holds(at(elevator(E),CF),0) :- init(at(elevator(E),CF)).
holds(request(deliver(E),GF),0) :- init(request(deliver(E),GF)).
holds(request(call(D),CF),0) :- init(request(call(D),CF)).

#program step(t). % actions, effects, and minimization go below

% update served list
%served(F,E,t) :- served(F,E,t-1). 

% elevator serves 
do(elevator(E),serve,t) :- assignment(request(_,F),E,D,_), do(elevator(E),move(D),t-1), holds(at(elevator(E),F),t-1).

remove_request(holds(request(call(C),F),t)) 	:- do(elevator(_),serve,t), 
holds(at(elevator(E),F),t), holds(request(call(C),F),t-1).

remove_request(holds(request(deliver(E),F),t))	:- do(elevator(E),serve,t), 
holds(at(elevator(E),F),t), holds(request(deliver(E),F),t-1).

%served(F,E,t+1) :- do(elevator(E),serve,t), holds(at(elevator(E),F),t).

% elevator moves
do(elevator(E),move(D),t) :- not do(elevator(E),serve,t), not reached_min(E,t), min_extreme(GF,E,D).
do(elevator(E),move(D),t) :- not do(elevator(E),serve,t), reached_min(E,t), max_extreme(GF,E,D).

%elevator updates
holds(at(elevator(E),F),t) :- holds(at(elevator(E),F),t-1), not do(elevator(E),move(_),t).
holds(at(elevator(E),F+D),t) :- holds(at(elevator(E),F),t-1), do(elevator(E),move(D),t).

reached_min(E,t) :- reached_min(E,t-1).
reached_min(E,t) :- min_extreme(F,E,_), holds(at(elevator(E),F),t).

% keep unserved pickups and deliveries
holds(request(call(C),F),t) :- holds(request(call(C),F),t-1), not remove_request(holds(request(call(C),F),t)).
holds(request(deliver(E),F),t) :- holds(request(deliver(E),F),t-1), not remove_request(holds(request(deliver(E),F),t)).

#minimize{ 1, t : holds(_, t) }.
#minimize{ 1,E,t : do(E, move(_), t) }.

#program check(t). % fulfillment of all requests can, e.g., be checked as follows
:- query(t), holds(request(_,_),t).


#show holds/2.
#show do/3.
