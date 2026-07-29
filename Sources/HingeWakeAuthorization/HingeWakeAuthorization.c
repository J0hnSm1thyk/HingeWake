#include "HingeWakeAuthorization.h"

#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>

static void HWSetError(char *buffer, size_t size, const char *message, int value) {
    if (buffer == NULL || size == 0) {
        return;
    }
    snprintf(buffer, size, "%s%d", message, value);
}

int32_t HWSetDisableSleep(
    int32_t enabled,
    char *errorBuffer,
    size_t errorBufferSize
) {
    if (errorBuffer != NULL && errorBufferSize > 0) {
        errorBuffer[0] = '\0';
    }

    AuthorizationRef authorization = NULL;
    OSStatus status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, 0, &authorization);
    if (status != errAuthorizationSuccess) {
        HWSetError(errorBuffer, errorBufferSize, "AuthorizationCreate failed: ", status);
        return status;
    }

    AuthorizationItem item = {kAuthorizationRightExecute, 0, NULL, 0};
    AuthorizationRights rights = {1, &item};
    AuthorizationFlags flags = kAuthorizationFlagInteractionAllowed |
                               kAuthorizationFlagExtendRights |
                               kAuthorizationFlagPreAuthorize;
    status = AuthorizationCopyRights(authorization, &rights, NULL, flags, NULL);
    if (status != errAuthorizationSuccess) {
        HWSetError(errorBuffer, errorBufferSize, "Authorization was cancelled or failed: ", status);
        AuthorizationFree(authorization, kAuthorizationFlagDestroyRights);
        return status;
    }

    char *arguments[] = {
        "-a",
        "disablesleep",
        enabled ? "1" : "0",
        NULL
    };
    FILE *pipe = NULL;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    status = AuthorizationExecuteWithPrivileges(
        authorization,
        "/usr/bin/pmset",
        0,
        arguments,
        &pipe
    );
#pragma clang diagnostic pop

    if (status != errAuthorizationSuccess) {
        HWSetError(errorBuffer, errorBufferSize, "Unable to start pmset: ", status);
        AuthorizationFree(authorization, kAuthorizationFlagDestroyRights);
        return status;
    }

    if (pipe == NULL) {
        AuthorizationFree(authorization, kAuthorizationFlagDestroyRights);
        HWSetError(errorBuffer, errorBufferSize, "Authorization returned no communication pipe: ", EIO);
        return EIO;
    }

    char output[512];
    while (fgets(output, sizeof(output), pipe) != NULL) {
        if (errorBuffer != NULL && errorBufferSize > 1) {
            strlcpy(errorBuffer, output, errorBufferSize);
        }
    }
    fclose(pipe);

    OSStatus freeStatus = AuthorizationFree(authorization, kAuthorizationFlagDestroyRights);
    if (freeStatus != errAuthorizationSuccess) {
        HWSetError(errorBuffer, errorBufferSize, "Unable to destroy authorization rights: ", freeStatus);
        return freeStatus;
    }

    /* The caller verifies the resulting pmset state instead of attributing an
       unrelated child status returned by wait() to this deprecated API. */
    return 0;
}
