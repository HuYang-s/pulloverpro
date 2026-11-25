#include "../Tweak/POTransformMath.h"
#include <assert.h>
#include <stdio.h>
static int checks = 0;
static void eq(double a,double b){assert(fabs(a-b)<1e-8); checks++;}
int main(void){
    eq(POTransformScale(0),0.5); eq(POTransformScale(4),3); eq(POTransformScale(NAN),1);
    eq(POTransformScale(1.5),1.5);
    eq(POClampCenter(-100,300,100),50); eq(POClampCenter(1000,300,100),250);
    eq(POClampCenter(-100,300,500),50); eq(POClampCenter(1000,300,500),250);
    eq(POClampCenter(300,300,300),150); eq(POClampCenter(NAN,300,100),150);
    eq(POClampCenter(5,0,100),0); eq(POClampCenter(5,100,NAN),0);
    POPoint c=POTransformCenter((POPoint){100,80},(POPoint){50,40},(POPoint){10,-5},2);
    eq(c.x,160); eq(c.y,115);
    c=POTransformCenter((POPoint){50,40},(POPoint){50,40},(POPoint){0,0},3);
    eq(c.x,50); eq(c.y,40);
    c=POTransformCenter((POPoint){100,80},(POPoint){50,40},(POPoint){10,-5},1);
    eq(c.x,110); eq(c.y,75);
    for(int viewport=1;viewport<=500;viewport+=13) for(int rendered=1;rendered<=900;rendered+=17) {
        for(int center=-1000;center<=1000;center+=127) {
            double v=POClampCenter(center,viewport,rendered);
            double left=v-rendered/2.0,right=v+rendered/2.0;
            if(rendered<=viewport) {assert(left>=-1e-8 && right<=viewport+1e-8);}
            else {assert(left<=1e-8 && right>=viewport-1e-8);}
            checks++;
        }
    }
    printf("PASS: %d geometry assertions\n",checks);
}
