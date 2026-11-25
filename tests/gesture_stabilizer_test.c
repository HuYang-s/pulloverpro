#include "../Shared/POGestureStabilizer.h"
#include <assert.h>
#include <stdio.h>
int main(void) {
 unsigned n=0;
 for (int i=1;i<=3000;i++) {
   double scale=(i%290+13)/100.0;
   POStableSample s=POFrozenGestureSample(scale,20,-30,0.4);
   assert(fabs(s.ratio-scale)<1e-8 && fabs(s.dx-8)<1e-8 && fabs(s.dy+12)<1e-8);n+=3;
   POStableSample mirror=POFrozenGestureSample(scale,20,-30,-0.4);
   assert(fabs(mirror.dx+8)<1e-8 && fabs(mirror.dy+12)<1e-8);n+=2;
 }
 POStableSample s={1,0,0};
 for(int i=0;i<300;i++) {
    double sign=i%2?1:-1;
    s=POFilterGesture(s,(POStableSample){1+sign*.008,sign*.5,0},1.0/30);
    assert(s.ratio==1&&s.dx==0&&s.dy==0);n++;
 }
 for(int i=0;i<90;i++) {
    POStableSample old=s;s=POFilterGesture(s,(POStableSample){2,100,-60},1.0/30);
    assert(s.ratio>=old.ratio&&s.ratio<=2&&s.dx>=old.dx&&s.dx<=100&&s.dy<=old.dy&&s.dy>=-60);n+=5;
    assert(log(s.ratio/old.ratio)<=0.100001&&s.dx-old.dx<=15.0001);n+=2;
 }
 assert(s.ratio>1.97&&s.dx>99&&s.dy<-59);n+=3;
 for(int i=0;i<90;i++){
    POStableSample old=s;s=POFilterGesture(s,(POStableSample){.6,-50,40},1.0/30);
    assert(s.ratio<=old.ratio&&s.ratio>=.6&&s.dx<=old.dx&&s.dy>=old.dy);n+=4;
 }
 assert(s.ratio<.61&&s.dx<-49&&s.dy>39);n+=3;
 printf("PASS: %u stabilizer assertions\n",n);
}
