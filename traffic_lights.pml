#define SW 0
#define WE 1
#define NS 2
#define ES 3
#define WN 4
#define DIRECTION_COUNT 5

#define GREEN true
#define RED false

#define LOCK(mutex) mutex ! true;
#define UNLOCK(mutex) mutex ? true;

typedef Direction {
	chan mutex = [1] of {bool}
	byte conflictCount;
	byte conflicts[DIRECTION_COUNT];
};

Direction directions[DIRECTION_COUNT];
bool lightState[DIRECTION_COUNT];
bool hasTraffic[DIRECTION_COUNT];

proctype trafficProc(byte id) {
	endpoint:
	do
	:: !hasTraffic[id] ->
		progress:
		hasTraffic[id] = true;
	:: hasTraffic[id] && lightState[id] == GREEN ->
		hasTraffic[id] = false;
	od
}

proctype lightProc(byte id) {
	endpoint:
	do
	:: hasTraffic[id] ->
		LOCK(directions[id].mutex);
		int i = 0;
		do
		:: i < directions[id].conflictCount ->
			LOCK(directions[directions[id].conflicts[i]].mutex);
			i = i + 1;
		:: !(i < directions[id].conflictCount) -> break;
		od;

		lightState[id] = GREEN;

		!hasTraffic[id];
		
		lightState[id] = RED;

		i = directions[id].conflictCount - 1;
		do
		:: i > 0 ->
			UNLOCK(directions[directions[id].conflicts[i]].mutex);
			i = i - 1;
		:: !(i > 0) -> break;
		od;
		UNLOCK(directions[id].mutex);
	od
}

#define FOR_ALL_DIRECTIONS(DO) \
	DO(SW); \
	DO(WE); \
	DO(NS); \
	DO(ES); \
	DO(WN);


#define INIT_DIRECTION(DIR, CONFLICT_COUNT, C0, C1, C2, C3) \
	lightState[DIR] = RED; \
	hasTraffic[DIR] = false; \
	directions[DIR].conflictCount = CONFLICT_COUNT; \
	directions[DIR].conflicts[0] = C0; \
	directions[DIR].conflicts[1] = C1; \
	directions[DIR].conflicts[2] = C2; \
	directions[DIR].conflicts[3] = C3;

init {
	INIT_DIRECTION(SW, 4, WE, NS, ES, WN);
	INIT_DIRECTION(WE, 3, SW, NS, ES, 0);
	INIT_DIRECTION(NS, 3, SW, WE, WN, 0);
	INIT_DIRECTION(ES, 2, SW, WE, 0, 0);
	INIT_DIRECTION(WN, 2, SW, NS, 0, 0);

	FOR_ALL_DIRECTIONS(run trafficProc)
	FOR_ALL_DIRECTIONS(run lightProc)
}

#define IS_RED(D1) (lightState[D1] == RED)
#define IS_GREEN(D1) (lightState[D1] == GREEN)

#define ANY_IS_GREEN2(D1, D2) (IS_GREEN(D1) || IS_GREEN(D2))
#define ANY_IS_GREEN3(D1, D2, D3) (IS_GREEN(D1) || ANY_IS_GREEN2(D2, D3))
#define ANY_IS_GREEN4(D1, D2, D3, D4) (IS_GREEN(D1) || ANY_IS_GREEN3(D2, D3, D4))

#define SAFETY_FOR2(DIR, D1, D2) ([] !(IS_GREEN(DIR) && ANY_IS_GREEN2(D1, D2)))
#define SAFETY_FOR3(DIR, D1, D2, D3) ([] !(IS_GREEN(DIR) && ANY_IS_GREEN3(D1, D2, D3)))
#define SAFETY_FOR4(DIR, D1, D2, D3, D4) ([] !(IS_GREEN(DIR) && ANY_IS_GREEN4(D1, D2, D3, D4)))

ltl safety {
	SAFETY_FOR4(SW, WE, NS, ES, WN)
	&& SAFETY_FOR3(WE, SW, NS, ES)
	&& SAFETY_FOR3(NS, SW, WE, WN)
	&& SAFETY_FOR2(ES, SW, WE)
	&& SAFETY_FOR2(WN, SW, NS)
}

#define LIVENESS_FOR(DIR) ([] (hasTraffic[DIR] && (IS_RED(DIR)) -> <> (IS_GREEN(DIR))))

ltl liveness {
	 LIVENESS_FOR(SW) && LIVENESS_FOR(WE) && LIVENESS_FOR(NS) && LIVENESS_FOR(ES) && LIVENESS_FOR(WN);
}

#define FAIRNESS_FOR(DIR) [] <> !(IS_GREEN(DIR) && hasTraffic[DIR])

ltl fairness {
	FAIRNESS_FOR(SW) && FAIRNESS_FOR(WE) && FAIRNESS_FOR(NS) && FAIRNESS_FOR(ES) && FAIRNESS_FOR(WN)
}
