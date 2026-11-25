#pragma once
#include <math.h>
#include <stdbool.h>
typedef struct { double ratio, dx, dy; } POStableSample;
static inline double POStableClamp(double v,double a,double b) {return fmin(b,fmax(a,v));}
// Never use host output as the input multiplier during a live gesture.
static inline POStableSample POFrozenGestureSample(double scale,double dx,double dy,double initialHostScale) {
    if (!isfinite(scale)||!isfinite(dx)||!isfinite(dy)||!isfinite(initialHostScale)) return (POStableSample){1,0,0};
    return (POStableSample){POStableClamp(scale,0.125,7.99),dx*initialHostScale,dy*fabs(initialHostScale)};
}
// Time-based logarithmic scale filtering, translation deadband, and velocity limits.
static inline POStableSample POFilterGesture(POStableSample old,POStableSample next,double dt) {
    dt=POStableClamp(dt,1.0/120.0,1.0/15.0);
    const double a=1-exp(-dt/0.085);
    double ds=log(POStableClamp(next.ratio,0.125,7.99)/POStableClamp(old.ratio,0.125,7.99));
    double dx=next.dx-old.dx,dy=next.dy-old.dy;
    if (fabs(ds)<0.012) ds=0;
    if (hypot(dx,dy)<1.0) dx=dy=0;
    return (POStableSample){POStableClamp(old.ratio*exp(POStableClamp(a*ds,-3.0*dt,3.0*dt)),0.125,7.99),
        old.dx+POStableClamp(a*dx,-450*dt,450*dt),old.dy+POStableClamp(a*dy,-450*dt,450*dt)};
}
