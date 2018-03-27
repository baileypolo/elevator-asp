% INSERT NAMES AND EMAIL ADDRESSES OF YOUR GROUP MEMBERS:

% beschäftigt 

agent(elevator(1)).
floor(1).
floor(2).
floor(3).
init(at(elevator(1),2)).
init(request(call(up),1)).

#include <incmode>. % built-in incremental mode of clingo

#program base. % static rules go below

thing(X,t) :- X<t, X>0, floor(X). 

#program step(t). % actions, effects, and minimization go below


test(t) :- .


#program check(t). % fulfillment of all requests can, e.g., be checked as follows
:- query(t), t<10.

#show thing/2.
