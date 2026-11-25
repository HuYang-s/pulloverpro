#include "../Shared/POGestureWire.h"
#include <notify.h>
#include <unistd.h>
#include <sys/wait.h>
#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
int main(void) {
    char state[160], event[160];
    snprintf(state,sizeof state,"com.johndie.pulloverpro.test.%d.state",getpid());
    snprintf(event,sizeof event,"com.johndie.pulloverpro.test.%d.event",getpid());
    int pipes[2];assert(pipe(pipes)==0);
    pid_t child=fork();assert(child>=0);
    if(child==0) {
        close(pipes[1]); char c; if(read(pipes[0],&c,1)!=1)_exit(2);
        int st,et; uint64_t raw=0;
        if(notify_register_check(state,&st)||notify_register_check(event,&et)||notify_get_state(st,&raw))_exit(3);
        POHostGeometry g=POUnpackHost(raw);if(g.session!=1234||fabs(g.scale-0.5)>0.0001)_exit(4);
        uint64_t msg=POPackRemote((PORemoteTransform){1234,2,2,1.25,20,-10});
        if(notify_set_state(et,msg)||notify_post(event))_exit(5);
        notify_cancel(st);notify_cancel(et);_exit(0);
    }
    close(pipes[0]);int st,et;assert(!notify_register_check(state,&st));assert(!notify_register_check(event,&et));
    assert(!notify_set_state(st,POPackHost((POHostGeometry){1234,0.5,100,120})));
    assert(!notify_post(state));assert(write(pipes[1],"x",1)==1);close(pipes[1]);
    int status;assert(waitpid(child,&status,0)==child);assert(WIFEXITED(status)&&WEXITSTATUS(status)==0);
    uint64_t raw;assert(!notify_get_state(et,&raw));PORemoteTransform e=POUnpackRemote(raw);
    assert(e.session==1234&&e.gesture==2&&e.phase==2&&e.ratio==1.25&&e.dx==20&&e.dy==-10);
    assert(!notify_set_state(st,0));assert(!notify_post(state));assert(!notify_cancel(st));assert(!notify_cancel(et));
    puts("PASS: local macOS interprocess notify state round trip; this does not validate the iOS sandbox.");
}
