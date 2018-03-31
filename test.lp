% INSERT NAMES AND EMAIL ADDRESSES OF YOUR GROUP MEMBERS:

% beschäftigt 


#include <incmode>. % built-in incremental mode of clingo

#program base. % static rules go below

a(1) :-.

#program step(t). % actions, effects, and minimization go below

thing(t,N) :- step(t), N := t*t.

a(N) :- N = #count { a(C) : thing(C,_) }.

#program check(t). % fulfillment of all requests can, e.g., be checked as follows
:- query(t), t<10.

#show thing/1.
#show a/1.