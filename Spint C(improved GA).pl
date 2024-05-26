%Ensure that at least the best individual between the current population and the new population passes to the next population

% assignment(Id,TimeProcessing,TempConc/duedate,WeightPenalization/weight of penalty in case of delay).
assignment(t1,2,5,1).
assignment(t2,4,7,6).
assignment(t3,1,11,2).
assignment(t4,3,9,3).
assignment(t5,3,8,2).

% assignments(NAssignments).
assignments(5).

% parameterization
initialize:-
	write('number of new generations: '),read(NG),(retract(generations(_));true),asserta(generations(NG)),
	write('dimension of population: '),read(DP),(retract(populates(_));true),asserta(populates(DP)),
	write('probability of crossing (%):'), read(P1),PC is P1/100,(retract(prob_crossing(_));true),asserta(prob_crossing(PC)),
	write('probability of mutation (%):'), read(P2),PM is P2/100,(retract(prob_mutation(_));true),asserta(prob_mutation(PM)).

generate:-
	initialize,
	generate_population(Pop),
	write('Pop='),write(Pop),nl,
	population_assessment(Pop,PopAv),
	write('PopAv='),write(PopAv),nl,
	population_order(PopAv,PopOrd),
	generations(NG),
	generate_generation(0,NG,PopOrd).

generate_population(Pop):-
	populates(TamPop),
	assignments(NumT),
	findall(Assignment,assignment(Assignment,_,_,_),ListAssignments),
	generate_population(TamPop,ListAssignments,NumT,Pop).
generate_population(0,_,_,[]):-!.
generate_population(TamPop,ListAssignments,NumT,[Ind|Rest]):-
	TamPop1 is TamPop-1,
	generate_population(TamPop1,ListAssignments,NumT,Rest),
	generate_individual(ListAssignments,NumT,Ind),
	not(member(Ind,Rest)).
generate_population(TamPop,ListAssignments,NumT,L):-
	generate_population(TamPop,ListAssignments,NumT,L).

generate_individual([G],1,[G]):-!.
generate_individual(ListAssignments,NumT,[G|Rest]):-
	NumTemp is NumT + 1, % To use with random
	random(1,NumTemp,N),
	withdraw(N,ListAssignments,G,NewList),
	NumT1 is NumT-1,
	generate_individual(NewList,NumT1,Rest).

withdraw(1,[G|Rest],G,Rest).
withdraw(N,[G1|Rest],G,[G1|Rest1]):-
	N1 is N-1,
	withdraw(N1,Rest,G,Rest1).

population_assessment([],[]).
population_assessment([Ind|Rest],[Ind*V|Rest1]):-
	evaluate(Ind,V),
	population_assessment(Rest,Rest1).

evaluate(Seq,V):-
	evaluate(Seq,0,V).
evaluate([],_,0).
evaluate([T|Rest],Inst,V):-
	assignment(T,Last,Deadline,Pen),
	InstFim is Inst+Last,
	evaluate(Rest,InstFim,VRest),
	(
		(InstFim =< Deadline,!, VT is 0) ;
		(VT is (InstFim-Deadline)*Pen)
	),
	V is VT+VRest.

population_order(PopAv,PopAvOrd):-
	bsort(PopAv,PopAvOrd).

bsort([X],[X]):-!.
bsort([X|Xs],Ys):-
	bsort(Xs,Zs),
	bexchange([X|Zs],Ys).

bexchange([X],[X]):-!.
bexchange([X*VX,Y*VY|L1],[Y*VY|L2]):-
	VX>VY,!,
	bexchange([X*VX|L1],L2).
bexchange([X|L1],[X|L2]):-bexchange(L1,L2).

generate_generation(G,G,Pop):-!,
	write('generate '), write(G), write(':'), nl, write(Pop), nl.
generate_generation(N,G,Pop):-
	write('generate '), write(N), write(':'), nl, write(Pop), nl,
	crossing(Pop,NPop1),
	mutation(NPop1,NPop),
	population_assessment(NPop,NPopAv),
	population_order(NPopAv,NPopOrd),
	N1 is N+1,
	generate_generation(N1,G,NPopOrd).
generate_generation(N,NG,Pop):-
	N=:=NG,!.
generate_generation(N,NG,Pop):-
	N1 is N+1,
	random_permutation(Pop,PopShuffled),
	crossing(PopShuffled,NewPop),
	mutation(NewPop,NewPop1),
	populates(TamPop),
	assignments(NumT),
	findall(Assignment,assignment(Assignment,_,_,_),ListAssignments),
	generate_rest_population(TamPop,ListAssignments,NumT,NewPop1,NewPop2),
	population_assessment(NewPop2,NewPopAv),
	best_individual(Pop,BestInd,_),
	NewPop2 = [BestInd|_],
	population_order(NewPopAv,NewPopOrd),
	generate_generation(N1,NG,NewPopOrd).

generate_rest_population(TamPop,ListAssignments,NumT,NewPop,[Ind|NewPop1]):-
	TamPop > 0,
	generate_individual(ListAssignments,NumT,Ind),
	not(member(Ind,NewPop)),
	TamPop1 is TamPop - 1,
	generate_rest_population(TamPop1,ListAssignments,NumT,[Ind|NewPop],NewPop1).
generate_rest_population(0,_,_,NewPop,NewPop).

best_individual([Ind|Rest],BestInd,V):-
	evaluate(Ind,V),
	best_individual(Rest,Ind,V,BestInd).
best_individual([],BestInd,_,BestInd).
best_individual([Ind|Rest],CurrBestInd,CurrV,BestInd):-
	evaluate(Ind,V),
	V < CurrV,
	best_individual(Rest,Ind,V,BestInd).
best_individual([_|Rest],CurrBestInd,CurrV,BestInd):-
	best_individual(Rest,CurrBestInd,CurrV,BestInd).


generate_crossing_points(P1,P2):-
	generate_crossing_points1(P1,P2).

generate_crossing_points1(P1,P2):-
	assignments(N),
	NTemp is N+1,
	random(1,NTemp,P11),
	random(1,NTemp,P21),
	P11\==P21,!,
	((P11<P21,!,P1=P11,P2=P21);(P1=P21,P2=P11)).
generate_crossing_points1(P1,P2):-
	generate_crossing_points1(P1,P2).


crossing([],[]).
crossing([Ind*_],[Ind]).
crossing([Ind1*_,Ind2*_|Rest],[NInd1,NInd2|Rest1]):-
	generate_crossing_points(P1,P2),
	prob_crossing(Pcruz),random(0.0,1.0,Pc),
	((Pc =< Pcruz,!,
        cross(Ind1,Ind2,P1,P2,NInd1),
	  cross(Ind2,Ind1,P1,P2,NInd2)) ;
	(NInd1=Ind1,NInd2=Ind2)),
	crossing(Rest,Rest1).

fillin([],[]).
fillin([_|R1],[h|R2]):-
	fillin(R1,R2).

sublist(L1,I1,I2,L):-
	I1 < I2,!,
	sublist1(L1,I1,I2,L).
sublist(L1,I1,I2,L):-
	sublist1(L1,I2,I1,L).

sublist1([X|R1],1,1,[X|H]):-!,
	fillin(R1,H).
sublist1([X|R1],1,N2,[X|R2]):-!,
	N3 is N2 - 1,
	sublist1(R1,1,N3,R2).
sublist1([_|R1],N1,N2,[h|R2]):-
	N3 is N1 - 1,
	N4 is N2 - 1,
	sublist1(R1,N3,N4,R2).

rotate_right(L,K,L1):-
	assignments(N),
	T is N - K,
	rr(T,L,L1).

rr(0,L,L):-!.
rr(N,[X|R],R2):-
	N1 is N - 1,
	append(R,[X],R1),
	rr(N1,R1,R2).

deletes([],_,[]):-!.
deletes([X|R1],L,[X|R2]):-
	not(member(X,L)),!,
	deletes(R1,L,R2).
deletes([_|R1],L,R2):-
	deletes(R1,L,R2).

insert([],L,_,L):-!.
insert([X|R],L,N,L2):-
	assignments(T),
	((N>T,!,N1 is N mod T);N1 = N),
	insert1(X,N1,L,L1),
	N2 is N + 1,
	insert(R,L1,N2,L2).

insert1(X,1,L,[X|L]):-!.
insert1(X,N,[Y|L],[Y|L1]):-
	N1 is N-1,
	insert1(X,N1,L,L1).

cross(Ind1,Ind2,P1,P2,NInd11):-
	sublist(Ind1,P1,P2,Sub1),
	assignments(NumT),
	R is NumT-P2,
	rotate_right(Ind2,R,Ind21),
	deletes(Ind21,Sub1,Sub2),
	P3 is P2 + 1,
	insert(Sub2,Sub1,P3,NInd1),
	deletesh(NInd1,NInd11).

deletesh([],[]).

deletesh([h|R1],R2):-!,
	deletesh(R1,R2).

deletesh([X|R1],[X|R2]):-
	deletesh(R1,R2).

mutation([],[]).
mutation([Ind|Rest],[NInd|Rest1]):-
	prob_mutation(Pmut),
	random(0.0,1.0,Pm),
	((Pm < Pmut,!,mutation1(Ind,NInd));NInd = Ind),
	mutation(Rest,Rest1).

mutation1(Ind,NInd):-
	generate_crossing_points(P1,P2),
	mutation22(Ind,P1,P2,NInd).

mutation22([G1|Ind],1,P2,[G2|NInd]):-
	!, P21 is P2-1,
	mutation23(G1,P21,Ind,G2,NInd).
mutation22([G|Ind],P1,P2,[G|NInd]):-
	P11 is P1-1, P21 is P2-1,
	mutation22(Ind,P11,P21,NInd).

mutation23(G1,1,[G2|Ind],G2,[G1|Ind]):-!.
mutation23(G1,P,[G|Ind],G2,[G|NInd]):-
	P1 is P-1,
	mutation23(G1,P1,Ind,G2,NInd).
