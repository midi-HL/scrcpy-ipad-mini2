/**
 * adb_protocol.h
 *
 * ADB protocol implementation for iOS.
 * Based on Android ADB protocol specification.
 */

#ifndef ADB_PROTOCOL_H
#define ADB_PROTOCOL_H

#include <stdint.h>
#include <stddef.h>

// ADB message commands
#define ADB_C_OPEN   0x4e544548  // OPEN
#define ADB_C_CLSE   0x45534c43  // CLSE
#define ADB_C_WRTE   0x45545257  // WRTE
#define ADB_C_OKAY   0x59414b4f  // OKAY
#define ADB_C_FAIL   0x4c494146  // FAIL
#define ADB_C_SYNC   0x434e5953  // SYNC
#define ADB_C_QUIT   0x54495551  // QUIT

// ADB message structure
typedef struct adb_msg {
    uint32_t command;
    uint32_t arg0;
    uint32_t arg1;
    uint32_t data_length;
    uint32_t data_crc32;
    uint32_t magic;
} adb_msg_t;

// ADB connection
typedef struct adb_connection {
    int socket;
    int local_id;
    int remote_id;
    char *serial;
    int state;
} adb_connection_t;

// ADB states
#define ADB_STATE_CLOSED    0
#define ADB_STATE_OPEN      1
#define ADB_STATE_CONNECT   2
#define ADB_STATE_WRITE     3

// Initialize ADB connection
adb_connection_t* adb_connect(const char *host, int port);

// Disconnect ADB
void adb_disconnect(adb_connection_t *connection);

// Execute command
int adb_shell(adb_connection_t *connection, const char *command,
              char *output, size_t output_size);

// Push file
int adb_push(adb_connection_t *connection, const char *local_path, const char *remote_path);

// Pull file
int adb_pull(adb_connection_t *connection, const char *remote_path, const char *local_path);

// Forward port
int adb_forward(adb_connection_t *connection, int local_port, int remote_port);

// Check if connected
int adb_is_connected(adb_connection_t *connection);

// Get device serial
const char* adb_get_serial(adb_connection_t *connection);

#endif // ADB_PROTOCOL_H
