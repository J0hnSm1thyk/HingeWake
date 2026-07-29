#ifndef HINGE_WAKE_AUTHORIZATION_H
#define HINGE_WAKE_AUTHORIZATION_H

#include <stddef.h>
#include <stdint.h>

int32_t HWSetDisableSleep(
    int32_t enabled,
    char *errorBuffer,
    size_t errorBufferSize
);

#endif
