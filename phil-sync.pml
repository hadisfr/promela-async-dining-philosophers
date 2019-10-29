#define N 3

byte count_eating;
chan com[N] = [0] of { mtype, byte };
mtype { req, release, grant };

init {
    atomic {
        byte i = 0;
        do
        :: (i < N - 1) ->
            run philosopher(i);
            run fork(i);
            i++;
        :: else ->
            run reset_philosopher(i);
            run fork(i);
            break;
        od;
    }
}

proctype philosopher(byte id) {
thinking:
    com[id] ! req, id;
choosing:
    atomic {
        com[(id + 1) % N] ! req, id ->
            count_eating++;
    };
eating:
    count_eating--;
    com[(id + 1) % N] ! release, id;
    com[id] ! release, id;
    goto thinking;
}

proctype fork(byte id)
{
    byte x;
starting:
    com[id] ? req, x;
    printf("process %d has been granted\n", x);
    com[id] ? release, x;
    goto starting;
}

proctype reset_philosopher(byte id) {
thinking:
    com[id] ! req, id;
choosing:
    if
    :: atomic {
        com[(id + 1) % N] ! req, id ->
            count_eating++;
    };
    :: else->
        com[id] ! release, id;
        goto thinking;
    fi;
eating:
    count_eating--;
    com[(id + 1) % N] ! release, id;
    com[id] ! release, id;
    goto thinking;
}
