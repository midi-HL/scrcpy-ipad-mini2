/**
 * adb_full.h
 *
 * Complete ADB protocol implementation for iOS.
 * Supports connection, shell, push, and port forwarding.
 */

#ifndef ADB_FULL_H
#define ADB_FULL_H

#include <stdint.h>
#include <stddef.h>

// ADB protocol version
#define ADB_PROTOCOL_VERSION 0x01000000
#define ADB_MAX_PAYLOAD 1024 * 1024

// ADB message commands (4 bytes, little-endian)
#define ADB_CMD_CNXN 0x4e584e43  // CNXN - connection
#define ADB_CMD_OPEN 0x4e544548  // OPEN - open channel
#define ADB_CMD_OKAY 0x59414b4f  // OKAY - success
#define ADB_CMD_CLSE 0x45534c43  // CLSE - close channel
#define ADB_CMD_WRTE 0x45545257  // WRTE - write data
#define ADB_CMD_SYNC 0x434e5953  // SYNC - file transfer
#define ADB_CMD_STAT 0x54415453  // STAT - file status
#define ADB_CMD_RECV 0x56434552  // RECV - receive file
#define ADB_CMD_SEND 0x444e4553  // SEND - send file
#define ADB_CMD_QUIT 0x54495551  // QUIT - quit

// ADB message structure (24 bytes)
typedef struct adb_message {
    uint32_t command;       // Command identifier
    uint32_t arg0;          // Argument 0
    uint32_t arg1;          // Argument 1
    uint32_t data_length;   // Payload length
    uint32_t data_crc32;    // CRC32 of payload
    uint32_t magic;         // command ^ 0xFFFFFFFF
} adb_message_t;

// ADB connection handle
typedef struct adb_handle {
    int socket;
    uint32_t local_id;
    uint32_t remote_id;
    char *serial;
    int connected;
} adb_handle_t;

// Sync message structures
typedef struct {
    uint32_t id;            // ID_STAT, ID_LIST, ID_SEND, ID_RECV, ID_DONE
    uint32_t mode;          // File mode
    uint32_t size;          // File size
    uint32_t time;          // Modification time
} sync_stat_t;

// Sync IDs
#define ID_STAT 0x54415453
#define ID_LIST 0x5453494c
#define ID_SEND 0x444e4553
#define ID_RECV 0x56434552
#define ID_DONE 0x454e4f44
#define ID_FAIL 0x4c494146

// Initialize ADB library
int adb_init(void);

// Cleanup ADB library
void adb_cleanup(void);

// Connect to ADB daemon
adb_handle_t* adb_connect(const char *host, int port);

// Disconnect
void adb_disconnect(adb_handle_t *handle);

// Execute shell command
int adb_shell(adb_handle_t *handle, const char *command,
              char *output, size_t output_size);

// Push file to device
int adb_push(adb_handle_t *handle, const char *local_path, const char *remote_path);

// Pull file from device
int adb_pull(adb_handle_t *handle, const char *remote_path, const char *local_path);

// Forward port
int adb_forward(adb_handle_t *handle, int local_port, int remote_port);

// Get connection state
int adb_is_connected(adb_handle_t *handle);

#endif // ADB_FULL_H
