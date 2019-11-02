#define N 3

byte count_eating
chan req[N] = [N + 1] of { mtype:philosopher, byte }
chan res[N] = [2] of { mtype:chopstick, byte }
mtype:philosopher = { request, release }
mtype:chopstick = { grant, forbid }

init {
    atomic {
        byte i = 0
        do
        :: (i < N - 1) ->
            run philosopher(i)
            run chopstick(i)
            run check_req_buffer_len(i)
            run check_res_buffer_len(i)
            i++
        :: else ->
            run altruist_philosopher(i)
            run chopstick(i)
            run check_req_buffer_len(i)
            run check_res_buffer_len(i)
            break
        od
    }
}

proctype check_req_buffer_len(byte id) {
    byte max_len = 4
    atomic {
        !(len(req[id]) < max_len) ->
            assert(len(req[id]) < max_len)
    }
}

proctype check_res_buffer_len(byte id) {
    byte max_len = 2
    atomic {
        !(len(res[id]) < max_len) ->
            assert(len(res[id]) < max_len)
    }
}

proctype philosopher(byte id) {
    byte next_id = (id + 1) % N
    byte sender_id
thinking:
    req[id] ! request, id
    if
        :: res[id] ? grant, sender_id ->
            if
                :: sender_id == id ->
                    goto choosing
                :: else ->
                    goto thinking
            fi
        :: res[id] ? forbid, sender_id ->
            if
                :: sender_id == id ->
                    goto thinking
                :: else ->
                    goto thinking
            fi
    fi
choosing:
    req[next_id] ! request, id
    if
        :: res[id] ? grant, sender_id ->
            if
                :: atomic { sender_id == next_id ->
                    count_eating++
                }
                :: else ->
                    req[sender_id] ! release, id
                    goto choosing
            fi
        :: res[id] ? forbid, sender_id ->
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
    byte sender_id
thinking:
    req[id] ! request, id
    if
        :: res[id] ? grant, sender_id ->
            if
                :: sender_id == id ->
                    goto choosing
                :: else ->
                    goto thinking
            fi
        :: res[id] ? forbid, sender_id ->
            if
                :: sender_id == id ->
                    goto thinking
                :: else ->
                    goto thinking
            fi
    fi
choosing:
    req[next_id] ! request, id
    if
        :: res[id] ? grant, sender_id ->
            if
                :: atomic { sender_id == next_id ->
                    count_eating++
                }
                :: else ->
                    req[sender_id] ! release, id
                    req[id] ! release, id
                    goto thinking
            fi
        :: res[id] ? forbid, sender_id ->
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
