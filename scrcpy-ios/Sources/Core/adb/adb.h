/**
 * adb.h
 *
 * ADB communication interface.
 * This is a placeholder for the official scrcpy ADB module.
 */

#ifndef ADB_H
#define ADB_H

#include <stdint.h>
#include <stddef.h>

// ADB connection handle
typedef struct adb_connection adb_connection_t;

// Connect to ADB device
adb_connection_t* adb_connect(const char *host, int port);

// Disconnect from ADB
void adb_disconnect(adb_connection_t *connection);

// Execute ADB command
int adb_execute(adb_connection_t *connection, const char *command, char *output, size_t output_size);

// Push file to device
int adb_push(adb_connection_t *connection, const char *local_path, const char *remote_path);

// Check if connected
int adb_is_connected(adb_connection_t *connection);

#endif // ADB_H
