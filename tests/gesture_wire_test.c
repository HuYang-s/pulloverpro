#include "../Shared/POGestureWire.h"
#include <assert.h>
#include <stdio.h>
static unsigned n;
static void ck(int ok){assert(ok);++n;}
int main(void) {
    ck(POPackHost((POHostGeometry){0,1,0,0})==0);
    ck(POPackHost((POHostGeometry){1,NAN,0,0})==0);
    ck(POPackHost((POHostGeometry){1,0,0,0})==0);
    for(unsigned k=1;k<=10000;k++) {
        uint16_t session=(uint16_t)(k*73U%65535U+1);
        double scale=(k&1?-1:1)*(0.01+(k%700)*0.01);
        double x=(int)(k*137U%20001U)/10.0-1000;
        double y=(int)(k*79U%20001U)/10.0-1000;
        POHostGeometry h=POUnpackHost(POPackHost((POHostGeometry){session,scale,x,y}));
        ck(h.session==session);ck(fabs(h.scale-scale)<=1.0/4096);ck(fabs(h.x-x)<=1.0/16);ck(fabs(h.y-y)<=1.0/16);
        double ratio=0.125+(k%750)*0.01;
        uint8_t gesture=(uint8_t)(k%255+1),phase=(uint8_t)(k%3+1);
        PORemoteTransform e=POUnpackRemote(POPackRemote((PORemoteTransform){session,gesture,phase,ratio,x,y}));
        ck(e.session==session);ck(e.gesture==gesture);ck(e.phase==phase);
        ck(fabs(e.ratio-ratio)<=1.0/128);ck(fabs(e.dx-x)<=0.25);ck(fabs(e.dy-y)<=0.25);
    }
    PORemoteTransform extreme=POUnpackRemote(POPackRemote((PORemoteTransform){65535,255,3,999,99999,-99999}));
    ck(extreme.session==65535);ck(extreme.gesture==255);ck(extreme.phase==3);ck(extreme.ratio<8);ck(extreme.dx<2048);ck(extreme.dy>-2048);
    puts("PASS: gesture wire round-trip and boundary tests");
    printf("Assertions: %u\n",n);
}
