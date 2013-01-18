SPIN=$(HOME)/au/verification/Spin/Src6.2.3/spin
MAX_DEPTH=10000
MEMLIM=2048

all: safety liveness fairness
	
pan.c: traffic_lights.pml
	$(SPIN) -a traffic_lights.pml

safety: pan.c
	##################
	###   SAFETY   ###
	gcc -DMEMLIM=$(MEMLIM) -O2 -DXUSAFE -DSAFETY -w -o pan pan.c
	./pan -m$(MAX_DEPTH) -N safety

liveness: pan.c
	#####################
	###   LIVENESS   ####
	# non-progress cycles
	gcc -DMEMLIM=1024 -O2 -DXUSAFE -DNP -w -o pan pan.c
	./pan -m$(MAX_DEPTH) -a -N liveness

fairness: pan.c
	####################
	###   FAIRNESS   ###
	gcc -DMEMLIM=1024 -O2 -DXUSAFE -w -o pan pan.c
	./pan -m$(MAX_DEPTH) -a -N fairness

# acceptance cycles
# gcc -DMEMLIM=1024 -O2 -DXUSAFE -w -o pan pan.c
