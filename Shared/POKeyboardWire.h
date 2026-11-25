#pragma once
#include <stdint.h>
#include <stdbool.h>
typedef enum {
    POKeyConnecting=0, POKeyReady=1, POKeyNoFocus=2, POKeySecure=3,
    POKeyUnsupported=4, POKeyAccepted=5, POKeyTimeout=6, POKeyBusy=7
} POKeyStatus;
static inline uint64_t POKeyPacket(uint32_t session,uint16_t serial,uint16_t value) {
    return ((uint64_t)session<<32)|((uint64_t)serial<<16)|value;
}
static inline uint32_t POKeySession(uint64_t raw){return (uint32_t)(raw>>32);}
static inline uint16_t POKeySerial(uint64_t raw){return (uint16_t)(raw>>16);}
static inline uint16_t POKeyValue(uint64_t raw){return (uint16_t)raw;}
static inline bool POKeyPermitted(uint16_t key){return key>=32 && key<=127;}
static inline bool POKeyMatches(uint64_t raw,uint32_t session,uint16_t serial){
    return session && POKeySession(raw)==session && POKeySerial(raw)==serial;
}
