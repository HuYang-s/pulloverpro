#pragma once
#include <stdint.h>
#include <math.h>

// Fixed-size local protocol: session, phase, gesture number, relative zoom and movement.
// No raw contact positions, text, keyboard events, or app content are transmitted.
typedef struct { uint16_t session; double scale, x, y; } POHostGeometry;
typedef struct { uint16_t session; uint8_t gesture, phase; double ratio, dx, dy; } PORemoteTransform;
static inline double POWireClamp(double n,double lo,double hi) {
    return isfinite(n) ? fmax(lo,fmin(hi,n)) : 0;
}
static inline uint64_t POPackHost(POHostGeometry a) {
    if (!a.session || !isfinite(a.scale) || fabs(a.scale)<0.001) return 0;
    int16_t s=(int16_t)lround(POWireClamp(a.scale*4096,-32767,32767));
    int16_t x=(int16_t)lround(POWireClamp(a.x*16,-32767,32767));
    int16_t y=(int16_t)lround(POWireClamp(a.y*16,-32767,32767));
    return ((uint64_t)a.session<<48)|((uint64_t)(uint16_t)s<<32)|((uint64_t)(uint16_t)x<<16)|(uint16_t)y;
}
static inline POHostGeometry POUnpackHost(uint64_t p) {
    return (POHostGeometry){(uint16_t)(p>>48),(int16_t)(p>>32)/4096.0,(int16_t)(p>>16)/16.0,(int16_t)p/16.0};
}
static inline uint64_t POPackRemote(PORemoteTransform a) {
    unsigned r=(unsigned)lround(POWireClamp(a.ratio*128,1,1023));
    unsigned x=(unsigned)lround(POWireClamp(a.dx*4,-8191,8191)+8192);
    unsigned y=(unsigned)lround(POWireClamp(a.dy*4,-8191,8191)+8192);
    return ((uint64_t)a.session<<48)|((uint64_t)a.gesture<<40)|((uint64_t)(a.phase&3)<<38)|((uint64_t)r<<28)|((uint64_t)x<<14)|y;
}
static inline PORemoteTransform POUnpackRemote(uint64_t p) {
    return (PORemoteTransform){(uint16_t)(p>>48),(uint8_t)(p>>40),(uint8_t)((p>>38)&3),
        ((p>>28)&1023)/128.0,((int)((p>>14)&16383)-8192)/4.0,((int)(p&16383)-8192)/4.0};
}
