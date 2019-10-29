#define N 3

byte count_eating
chan req[N] = [1] of { mtype:philosopher, byte }
chan res[N] = [1] of { mtype:chopstick, byte }
mtype:philosopher = { request, release }
mtype:chopstick = { grant, forbid }

init {
    atomic {
        byte i = 0
        do
        :: (i < N - 1) ->
            run philosopher(i)
            run chopstick(i)
            i++
        :: else ->
            run altruist_philosopher(i)
            run chopstick(i)
            break
        od
    }
}

proctype philosopher(byte id) {
    byte next_id = (id + 1) % N
thinking:
    req[id] ! request, id
    if
        :: res[id] ? grant, id
        :: res[id] ? forbid, id ->
            goto thinking
    fi
choosing:
    req[next_id] ! request, id
    if
        :: atomic {
            res[id] ? grant, next_id ->
                count_eating++
        }
        :: res[id] ? forbid, next_id ->
            goto choosing
    fi
eating:
    atomic {
        count_eating--
        req[next_id] ! release, id
    }
    req[id] ! release, id
    goto thinking
}

proctype chopstick(byte id)
{
    byte master_id, requester_id
starting:
    req[id] ? request, master_id
    res[master_id] ! grant, id
    do
        :: req[id] ? release, master_id ->
            break
        :: req[id] ? request, requester_id ->
            res[requester_id] ! forbid, id
    od
    goto starting
}

proctype altruist_philosopher(byte id) {
    byte next_id = (id + 1) % N
thinking:
    req[id] ! request, id
    if
        :: res[id] ? grant, id
        :: res[id] ? forbid, id ->
            goto thinking
    fi
choosing:
    req[next_id] ! request, id
    if
        :: atomic {
            res[id] ? grant, next_id ->
                count_eating++
        }
        :: res[id] ? forbid, next_id ->
            req[id] ! release, id
            goto thinking
    fi
eating:
    atomic {
        count_eating--
        req[next_id] ! release, id
    }
    req[id] ! release, id
    goto thinking
}
