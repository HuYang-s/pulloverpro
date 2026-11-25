#pragma once
#include <math.h>

typedef struct { double x, y; } POPoint;
static inline double POClamp(double value, double low, double high) {
    return fmin(high, fmax(low, value));
}
static inline double POTransformScale(double value) {
    return isfinite(value) ? POClamp(value, 0.5, 3.0) : 1.0;
}
// If the content is smaller than the viewport, keep it completely inside;
// if larger, keep the viewport covered while allowing every edge to be reached.
static inline double POClampCenter(double center, double viewport, double rendered) {
    if (!isfinite(viewport) || !isfinite(rendered) || viewport <= 0 || rendered <= 0) return 0;
    if (!isfinite(center)) center = viewport / 2;
    double a = rendered / 2, b = viewport - a;
    return POClamp(center, fmin(a,b), fmax(a,b));
}
static inline POPoint POTransformCenter(POPoint start, POPoint pivot, POPoint delta, double ratio) {
    return (POPoint){pivot.x + (start.x-pivot.x)*ratio + delta.x,
                     pivot.y + (start.y-pivot.y)*ratio + delta.y};
}
