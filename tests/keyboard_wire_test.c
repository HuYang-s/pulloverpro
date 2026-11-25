#include "../Shared/POKeyboardWire.h"
#include <assert.h>
#include <stdio.h>
int main(void){
 unsigned n=0;
 for(uint32_t s=1;s<10000;s++){
   uint32_t session=s*2654435761U;
   uint16_t serial=(uint16_t)(s*31U),key=(uint16_t)(32+s%96);
   uint64_t p=POKeyPacket(session,serial,key);
   assert(POKeySession(p)==session);assert(POKeySerial(p)==serial);assert(POKeyValue(p)==key);
   assert(POKeyMatches(p,session,serial));assert(!POKeyMatches(p,session^1,serial));
   assert(!POKeyMatches(p,session,(uint16_t)(serial^1)));assert(POKeyPermitted(key));n+=7;
 }
 assert(!POKeyPermitted(0));assert(!POKeyPermitted(10));assert(!POKeyPermitted(31));assert(!POKeyPermitted(128));assert(!POKeyMatches(0,0,0));n+=5;
 printf("PASS: %u keyboard wire assertions\n",n);
}
