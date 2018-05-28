:- use_module(library(clpfd)).


:- dynamic tooth/3.
:- dynamic crownTip/2.
:- dynamic rootTip/2.
:- dynamic torque/2.
:- dynamic rotate/2.
:- dynamic translateX/2.
:- dynamic translateY/2.
:- dynamic extrude/2.
:- dynamic intrude/2.

% Assumptions:

% 1. M1: Crown Tipping, M2: Root Tipping and M3: Torquing, can be 
%    performed only in frontal(XZ) plane.

% 2. M4: Rotation, M5: translateY, M6: Extrusion/ Intrusion can only 
%    happen if a tooth is unblocked on BOTH THE SIDES.

% 3. For Crown Tipping, Root Tipping and Torqueing we ignore the 
%    block on the side where the tooth is already tipped. We just 
%    check for the block on the side where it needs to be tipped so 
%    as to get it to the desired alignment.

%--------------------------------------------------------------------
%---------------------------- NOTATIONS -----------------------------
%--------------------------------------------------------------------

% tooth(ToothNo, [M1,M2,M3,M4,[X,Y],M6],[Bl,Br]).

% fix/2: fixes tooth I with a Fix for each Movement (from M1 to M6),
% with Bl and Br as blocking from left & right neighbor respectively.

% NeighborLeft(I-1) : Current(I) : NeighborRight(I+1)

%--------------------------------------------------------------------
%---------------------- FIXING WITH BLOCKING ------------------------
%--------------------------------------------------------------------

% fixNeighbor: Gives the Fix for the neighbor Ngbr of tooth Current.
fixNeighbor(Ngbr, Current, Fix) :-
	(Ngbr #> Current ->
		fix(Ngbr, right, Fix);
		fix(Ngbr, left, Fix)).

% fix/3: Fixes right neighbor Ngbr (of Current) considering the fact
% that Ngbr is not being blocked by Current (left neighbor of Ngbr).
fix(Ngbr, right, Fix) :-
	retract(tooth(Ngbr, [M1,M2,M3,M4,[X,Y],M6], [_,Br])),
	assert(tooth(Ngbr, [M1,M2,M3,M4,[X,Y],M6], [0,Br])),
	fix(Ngbr, Fix).

% fix/3: Fixes left neighbor Ngbr (of Current) considering the fact
% that Ngbr is not being blocked by Current (right neighbor of Ngbr).
fix(Ngbr, left, Fix) :-
	retract(tooth(Ngbr, [M1,M2,M3,M4,[X,Y],M6], [Bl,_])),
	assert(tooth(Ngbr, [M1,M2,M3,M4,[X,Y],M6], [Bl,0])),
	fix(Ngbr, Fix).

%--------------------------------------------------------------------

% If blocked left or right, then FIX THE BLOCKING NEIGHBOR(S).

% Case 1: when blocked on both the sides.
fix(I, Fix) :-
	tooth(I,[M1,M2,M3,M4,[X,Y],M6],[1,1]),
	flatten([M1,M2,M3,M4,[X,Y],M6],Mvr), Mvr ins -10..10,
	I #> 1, I #< 16, %I shouldn't be at extremes
	L #= I-1, R #= I+1,  %L and R is left and right neighbor

	fixNeighbor(L,I,FixL), fixNeighbor(R,I,FixR), %fix the neighbors

	retract(tooth(I,[M1,M2,M3,M4,[X,Y],M6],[1,1])),
	%retract that the tooth is blocked
	assert(tooth(I,[M1,M2,M3,M4,[X,Y],M6],[0,0])),
	%assert that the tooth is unblocked

	fix(I, FixI), %Now fix the tooth
	flatten([FixL,FixR,FixI],Fix).

% Case 2: when blocked on the right side.
fix(I, Fix) :-
	tooth(I,[M1,M2,M3,M4,[X,Y],M6],[0,1]),
	flatten([M1,M2,M3,M4,[X,Y],M6],Mvr), Mvr ins -10..10,
	I #> 0, I #< 16, %I shouldn't be at right extreme
	R #= I+1,  %R is right neighbor

	fixNeighbor(R,I,FixR), %fix the neighbor

	retract(tooth(I,[M1,M2,M3,M4,[X,Y],M6],[0,1])),
	%retract that the tooth is blocked
	assert(tooth(I,[M1,M2,M3,M4,[X,Y],M6],[0,0])),
	%assert that the tooth is unblocked

	fix(I, FixI), %Now fix the tooth
	flatten([FixR,FixI],Fix).

% Case 3: when blocked on the left side.
fix(I, Fix) :-
	tooth(I,[M1,M2,M3,M4,[X,Y],M6],[1,0]),
	flatten([M1,M2,M3,M4,[X,Y],M6],Mvr), Mvr ins -10..10,
	I #> 1, I #< 17, %I shouldn't be at left extreme
	L #= I-1,  %L is left neighbor

	fixNeighbor(L,I,FixL), %fix the neighbor

	retract(tooth(I,[M1,M2,M3,M4,[X,Y],M6],[1,0])),
	%retract that the tooth is blocked
	assert(tooth(I,[M1,M2,M3,M4,[X,Y],M6],[0,0])),
	%assert that the tooth is unblocked

	fix(I, FixI), %Now fix the tooth
	flatten([FixL,FixI],Fix).

%--------------------------------------------------------------------
%-------------------- FIXING WITHOUT BLOCKINGS ----------------------
%--------------------------------------------------------------------

% Here, fix(ToothNo, Fix) possible only when Fix can be performed
% without any possible blocking, be it left or right or both.

%--------------- Crown Tipping ------------------
% M1: Crown Tipping
% Case 1: If M1 > 0, and no blocking by right neighbor.
fix(I, Fix) :-
	tooth(I,[M1,M2,M3,M4,[X,Y],M6],[Bl,0]),
	flatten([M1,M2,M3,M4,[X,Y],M6],Mvr), Mvr ins -10..10,
	M1 #> 0, negative(M1,M),
	retract(tooth(I,[M1,M2,M3,M4,[X,Y],M6],[Bl,0])),
	assert(tooth(I,[0,M2,M3,M4,[X,Y],M6],[Bl,0])),
	FixI = crownTip(I,M),
	(disfigured(I) -> fix(I, FixN), flatten([FixI, FixN], Fix);
		Fix = FixI).

% Case 2: If M1 < 0, and no blocking by left neighbor.
fix(I, Fix) :-
	tooth(I,[M1,M2,M3,M4,[X,Y],M6],[0,Br]),
	flatten([M1,M2,M3,M4,[X,Y],M6],Mvr), Mvr ins -10..10,
	M1 #< 0, negative(M1,M),
	retract(tooth(I,[M1,M2,M3,M4,[X,Y],M6],[0,Br])),
	assert(tooth(I,[0,M2,M3,M4,[X,Y],M6],[0,Br])),
	FixI = crownTip(I,M),
	(disfigured(I) -> fix(I, FixN), flatten([FixI, FixN], Fix);
		Fix = FixI).

%---------------- Root Tipping ------------------
% M2: Root Tipping
% Case 1: If M2 > 0, and no blocking by left neighbor.
fix(I, Fix) :-
	tooth(I,[M1,M2,M3,M4,[X,Y],M6],[0,Br]),
	flatten([M1,M2,M3,M4,[X,Y],M6],Mvr), Mvr ins -10..10,
	M2 #> 0, negative(M2,M), %Fix = rootTip(I,M),
	retract(tooth(I,[M1,M2,M3,M4,[X,Y],M6],[0,Br])),
	assert(tooth(I,[M1,0,M3,M4,[X,Y],M6],[0,Br])),
	FixI = rootTip(I,M),
	(disfigured(I) -> fix(I, FixN), flatten([FixI, FixN], Fix);
		Fix = FixI).

% Case 2: If M2 < 0, and no blocking by right neighbor.
fix(I, Fix) :-
	tooth(I,[M1,M2,M3,M4,[X,Y],M6],[Bl,0]),
	flatten([M1,M2,M3,M4,[X,Y],M6],Mvr), Mvr ins -10..10,
	M2 #< 0, negative(M2,M), %Fix = rootTip(I,M),
	retract(tooth(I,[M1,M2,M3,M4,[X,Y],M6],[Bl,0])),
	assert(tooth(I,[M1,0,M3,M4,[X,Y],M6],[Bl,0])),
	FixI = rootTip(I,M),
	(disfigured(I) -> fix(I, FixN), flatten([FixI, FixN], Fix);
		Fix = FixI).

%------------------ Torquing --------------------
% M3: Torquing
% Only if both the neighbors are not blocking.
fix(I, Fix) :-
	tooth(I,[M1,M2,M3,M4,[X,Y],M6],[0,0]),
	flatten([M1,M2,M3,M4,[X,Y],M6],Mvr), Mvr ins -10..10,
	M3 #\= 0, negative(M3,M),
	retract(tooth(I,[M1,M2,M3,M4,[X,Y],M6],[0,0])),
	assert(tooth(I,[M1,M2,0,M4,[X,Y],M6],[0,0])),
	FixI = torque(I,M),
	(disfigured(I) -> fix(I, FixN), flatten([FixI, FixN], Fix);
		Fix = FixI).

%------------------ Rotation --------------------
% M4: Rotation
% Can be blocked by both left and right neighbor!
% If unblocked on both sides, then rotation possible for tooth I.
fix(I, Fix) :-
	tooth(I,[M1,M2,M3,M4,[X,Y],M6],[0,0]),
	flatten([M1,M2,M3,M4,[X,Y],M6],Mvr), Mvr ins -10..10,
	M4 #\= 0, negative(M4,M),
	retract(tooth(I,[M1,M2,M3,M4,[X,Y],M6],[0,0])),
	assert(tooth(I,[M1,M2,M3,0,[X,Y],M6],[0,0])),
	FixI = rotate(I,M),
	(disfigured(I) -> fix(I, FixN), flatten([FixI, FixN], Fix);
		Fix = FixI).

%----------------- TranslateX -------------------
% M5: Translation X
% Case 1: Can be blocked by left neighbor if X > 0.
% So, would translateX only if unblocked on left side.
fix(I, Fix) :-
	tooth(I,[M1,M2,M3,M4,[X,Y],M6],[0,Br]),
	flatten([M1,M2,M3,M4,[X,Y],M6],Mvr), Mvr ins -10..10,
	X #> 0, negative(X,M),
	retract(tooth(I,[M1,M2,M3,M4,[X,Y],M6],[0,Br])),
	assert(tooth(I,[M1,M2,M3,M4,[0,Y],M6],[0,Br])),
	FixI = translateX(I,M),
	(disfigured(I) -> fix(I, FixN), flatten([FixI, FixN], Fix);
		Fix = FixI).

% M5: Translation X
% Case 2: Can be blocked by right neighbor if X < 0.
% So, would translateX only if unblocked on right side.
fix(I, Fix) :-
	tooth(I,[M1,M2,M3,M4,[X,Y],M6],[Bl,0]),
	flatten([M1,M2,M3,M4,[X,Y],M6],Mvr), Mvr ins -10..10,
	X #< 0, negative(X,M),
	retract(tooth(I,[M1,M2,M3,M4,[X,Y],M6],[Bl,0])),
	assert(tooth(I,[M1,M2,M3,M4,[0,Y],M6],[Bl,0])),
	FixI = translateX(I,M),
	(disfigured(I) -> fix(I, FixN), flatten([FixI, FixN], Fix);
		Fix = FixI).

%----------------- TranslateY -------------------
% M5: Translation Y
% Can be blocked by both left and right neighbor!
% So, would translateY only if unblocked on both the sides.
fix(I, Fix) :-
	tooth(I,[M1,M2,M3,M4,[X,Y],M6],[0,0]),
	flatten([M1,M2,M3,M4,[X,Y],M6],Mvr), Mvr ins -10..10,
	Y #\= 0, negative(Y,M),
	retract(tooth(I,[M1,M2,M3,M4,[X,Y],M6],[0,0])),
	assert(tooth(I,[M1,M2,M3,M4,[X,0],M6],[0,0])),
	FixI = translateY(I,M),
	(disfigured(I) -> fix(I, FixN), flatten([FixI, FixN], Fix);
		Fix = FixI).

%------------ Extrusion/ Intrusion --------------
% M6: Extrusion/Intrusion
% Can be blocked by both left and right neighbor!
% So, would intrude or extrude only if unblocked on both the sides.
fix(I, Fix) :-
	tooth(I,[M1,M2,M3,M4,[X,Y],M6],[0,0]),
	flatten([M1,M2,M3,M4,[X,Y],M6],Mvr), Mvr ins -10..10,
	M6 #< 0, negative(M6,M),
	retract(tooth(I,[M1,M2,M3,M4,[X,Y],M6],[0,0])),
	assert(tooth(I,[M1,M2,M3,M4,[X,Y],0],[0,0])),
	FixI = extrude(I,M),
	(disfigured(I) -> fix(I, FixN), flatten([FixI, FixN], Fix);
		Fix = FixI).

fix(I, Fix) :-
	tooth(I,[M1,M2,M3,M4,[X,Y],M6],[0,0]),
	flatten([M1,M2,M3,M4,[X,Y],M6],Mvr), Mvr ins -10..10,
	M6 #> 0,
	retract(tooth(I,[M1,M2,M3,M4,[X,Y],M6],[0,0])),
	assert(tooth(I,[M1,M2,M3,M4,[X,Y],0],[0,0])),
	FixI = intrude(I,M6),
	(disfigured(I) -> fix(I, FixN), flatten([FixI, FixN], Fix);
		Fix = FixI).

%-------------- EXTRA PREDICATES ----------------
% Neg #= negative of N
negative(N,Neg) :- Neg #= -1 * N.

% writes the List [H|T].
writeList([]) :- nl.
writeList([H|T]) :- write(H), write(' '), writeList(T).

% tooth(I,_,_) is disfigured.
disfigured(I) :-
	tooth(I,[M1,M2,M3,M4,[X,Y],M6],_),
	I #< 17, I #> 0, flatten([M1,M2,M3,M4,[X,Y],M6], Mv),
	sumlist(Mv, Sum), Sum #\= 0.

% unique(L1,L2): L2 is list of all distinct values in L1.
unique([], []).
unique([H|T], R) :-
	member(H,T), unique(T,R).
unique([H|T], [H|R]) :-
	\+ member(H,T), unique(T,R).

%--------------------------------------------------------------------
%------------------------------ MAIN --------------------------------
%--------------------------------------------------------------------

search :-
	findall(Fix, fix(_,Fix), Bag),
	flatten(Bag, Sequence), length(Sequence, S),
	(S #> 0 -> writeList(Sequence);
		write('No need to see the Doctor!'), nl).

%--------------------------------------------------------------------
%----------------------------- STATES -------------------------------
%--------------------------------------------------------------------
% state1: example of a state of a jaw having 16 teeth,
% with no fixing required.
state1 :-
	retractall(tooth(_,_,_)),
	assert(tooth(1,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(2,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(3,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(4,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(5,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(6,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(7,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(8,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(9,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(10,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(11,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(12,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(13,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(14,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(15,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(16,[0, 0, 0, 0, [0, 0], 0], [0, 0])).

% state2: example of a state of a jaw having 16 teeth,
% with one crooked tooth at 8, without any blocking.
state2 :-
	retractall(tooth(_,_,_)),
	assert(tooth(1,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(2,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(3,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(4,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(5,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(6,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(7,[0, 0, 0, 0, [0, 0], 0], [0, 0])),

	% tooth 8 has it's crown tipped by factor 4 in some direction.
	assert(tooth(8,[4, 0, 0, 0, [0, 0], 0], [0, 0])),

	assert(tooth(9,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(10,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(11,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(12,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(13,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(14,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(15,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(16,[0, 0, 0, 0, [0, 0], 0], [0, 0])).

% state3: example of a state of a jaw having 16 teeth,
% with 8 independent crooked teeth, without any blocking.
state3 :-
	retractall(tooth(_,_,_)),
	assert(tooth(1,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(2,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(3,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(4,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(5,[0, 0, 0, 0, [-2, 0], 0], [0, 0])),
	assert(tooth(6,[0, 0, -1, 0, [0, 0], 0], [0, 0])),
	assert(tooth(7,[0, -3, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(8,[4, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(9,[0, 0, 0, -2, [0, 0], 0], [0, 0])),
	assert(tooth(10,[0, 0, 0, 0, [1, 0], 0], [0, 0])),
	assert(tooth(11,[0, 0, 0, 0, [0, -3], 0], [0, 0])),
	assert(tooth(12,[0, 0, 0, 0, [0, 0], -4], [0, 0])),
	assert(tooth(13,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(14,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(15,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(16,[0, 0, 0, 0, [0, 0], 0], [0, 0])).

% state4: example of a state of a jaw having 16 teeth,
% with crooked teeth at 7 & 8, and
% with a blocking from left neighbor(7) to 8.
state4 :-
	retractall(tooth(_,_,_)),
	assert(tooth(1,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(2,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(3,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(4,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(5,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(6,[0, 0, 0, 0, [0, 0], 0], [0, 0])),

	% 7 is occupying some space of tooth 8's desired position,
	% 7 is moved to right by 2. And thus, blocking 8.
	% 8 is out of the jawline.
	% It has moved inside (translated in Y or lingualized) by 4.
	assert(tooth(7,[0, 0, 0, 0, [2, 0], 0], [0, 0])),
	assert(tooth(8,[0, 0, 0, 0, [0, 4], 0], [1, 0])),

	assert(tooth(9,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(10,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(11,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(12,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(13,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(14,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(15,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(16,[0, 0, 0, 0, [0, 0], 0], [0, 0])).

% state5: example of a state of a jaw having 16 teeth,
% with one crooked teeth at 7, 8 & 9,
% with a blocking from left(7) and right(9) neighbor to the tooth 8.
state5 :-
	retractall(tooth(_,_,_)),
	assert(tooth(1,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(2,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(3,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(4,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(5,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(6,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	% 7 is occupying some space of tooth 8's desired position,
	% 7 is moved to right by 2. And thus, blocking 8.
	% 8 is out of the jawline.
	% It has moved inside (translated in Y or lingualized) by 4.
	assert(tooth(7,[0, 0, 0, 0, [2, 0], 0], [0, 0])),
	assert(tooth(8,[0, 0, 0, 0, [0, 4], 0], [1, 1])),
	% like 7, 9 is moved to left by 2.
	assert(tooth(9,[0, 0, 0, 0, [-2, 0], 0], [0, 0])),

	assert(tooth(10,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(11,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(12,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(13,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(14,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(15,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(16,[0, 0, 0, 0, [0, 0], 0], [0, 0])).

% state6: example of a state of a jaw having 16 teeth, similar to 
% state5, but with one more independent triplet like 7,8,9.
state6 :-
	retractall(tooth(_,_,_)),
	assert(tooth(1,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(2,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(3,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(4,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(5,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(6,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	% 8(transY) blocked by 7(transX) and 9(transX)
	assert(tooth(7,[0, 0, 0, 0, [2, 0], 0], [0, 0])),
	assert(tooth(8,[0, 0, 0, 0, [0, 4], 0], [1, 1])),
	assert(tooth(9,[0, 0, 0, 0, [-2, 0], 0], [0, 0])),

	assert(tooth(10,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	% 12(rotate) blocked by 11(crownTip) and 13(rootTip)
	assert(tooth(11,[-3, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(12,[0, 0, 0, 4, [0, 0], 0], [1, 1])),
	assert(tooth(13,[0, -2, 0, 0, [0, 0], 0], [0, 0])),

	assert(tooth(14,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(15,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(16,[0, 0, 0, 0, [0, 0], 0], [0, 0])).

% state7: example of a state of a jaw having 16 teeth,
% 4 blocks 5,5 blocks 6,6 blocks 7,7 blocks 8 and 9 blocks 8.
% 5, 6, 7 have multiple defects.
state7 :-
	retractall(tooth(_,_,_)),
	assert(tooth(1,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(2,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(3,[0, 0, 0, 0, [0, 0], 0], [0, 0])),

	assert(tooth(4,[0, 0, 0, 0, [2, 0], 0], [0, 0])),
	assert(tooth(5,[0, 0, 0, 0, [2, 1], 0], [1, 0])),
	assert(tooth(6,[0, -1, 0, 0, [2, 2], 0], [1, 0])),
	assert(tooth(7,[0, 0, 0, 0, [2, 3], 0], [1, 0])),
	assert(tooth(8,[0, 0, 0, 0, [0, 4], 0], [1, 1])),

	assert(tooth(9,[0, 0, 0, 0, [-2, 0], 0], [0, 0])),
	assert(tooth(10,[0, 0, 0, 0, [0, 0], 0], [0, 0])),

	assert(tooth(11,[-3, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(12,[0, 0, 0, 4, [0, 0], 0], [1, 1])),
	assert(tooth(13,[0, -2, 0, 0, [0, 0], 0], [0, 0])),

	assert(tooth(14,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(15,[0, 0, 0, 0, [0, 0], 0], [0, 0])),
	assert(tooth(16,[0, 0, 0, 0, [0, 0], 0], [0, 0])).

%--------------------------------------------------------------------
