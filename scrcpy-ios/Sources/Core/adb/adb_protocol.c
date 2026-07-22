/**
 * adb_protocol.c
 *
 * ADB protocol implementation for iOS.
 * Handles communication with ADB daemon over TCP/IP.
 */

#include "adb_protocol.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <errno.h>

// CRC32 for ADB protocol
static uint32_t adb_crc32(const uint8_t *data, size_t size) {
    uint32_t crc = 0xFFFFFFFF;
    for (size_t i = 0; i < size; i++) {
        crc ^= data[i];
        for (int j = 0; j < 8; j++) {
            crc = (crc >> 1) ^ (0xEDB88320 & -(crc & 1));
        }
    }
    return crc ^ 0xFFFFFFFF;
}

// Calculate message checksum
static uint32_t adb_calculate_checksum(const adb_msg_t *msg) {
    // Sum of all words in message header
    return msg->command + msg->arg0 + msg->arg1 + msg->data_length + msg->data_crc32;
}

// Create ADB message
static void adb_create_msg(adb_msg_t *msg, uint32_t command,
                           uint32_t arg0, uint32_t arg1,
                           const void *data, uint32_t data_length) {
    msg->command = command;
    msg->arg0 = arg0;
    msg->arg1 = arg1;
    msg->data_length = data_length;

    if (data && data_length > 0) {
        msg->data_crc32 = adb_crc32((const uint8_t *)data, data_length);
    } else {
        msg->data_crc32 = 0;
    }

    msg->magic = msg->command ^ 0xFFFFFFFF;
}

// Send message
static int adb_send_msg(int socket, const adb_msg_t *msg) {
    ssize_t sent = send(socket, msg, sizeof(adb_msg_t), 0);
    return (sent == sizeof(adb_msg_t)) ? 0 : -1;
}

// Receive message
static int adb_recv_msg(int socket, adb_msg_t *msg) {
    ssize_t received = recv(socket, msg, sizeof(adb_msg_t), MSG_WAITALL);
    return (received == sizeof(adb_msg_t)) ? 0 : -1;
}

// Send data
static int adb_send_data(int socket, const void *data, uint32_t size) {
    const uint8_t *ptr = (const uint8_t *)data;
    uint32_t sent = 0;

    while (sent < size) {
        ssize_t n = send(socket, ptr + sent, size - sent, 0);
        if (n <= 0) return -1;
        sent += n;
    }

    return 0;
}

// Receive data
static int adb_recv_data(int socket, void *data, uint32_t size) {
    uint8_t *ptr = (uint8_t *)data;
    uint32_t received = 0;

    while (received < size) {
        ssize_t n = recv(socket, ptr + received, size - received, MSG_WAITALL);
        if (n <= 0) return -1;
        received += n;
    }

    return 0;
}

// Connect to ADB server
adb_connection_t* adb_connect(const char *host, int port) {
    printf("[ADB] Connecting to %s:%d\n", host, port);

    // Create socket
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        printf("[ADB] Failed to create socket: %s\n", strerror(errno));
        return NULL;
    }

    // Resolve host
    struct hostent *server = gethostbyname(host);
    if (!server) {
        printf("[ADB] Failed to resolve host: %s\n", host);
        close(sock);
        return NULL;
    }

    // Connect
    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    memcpy(&server_addr.sin_addr.s_addr, server->h_addr, server->h_length);

    if (connect(sock, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
        printf("[ADB] Failed to connect: %s\n", strerror(errno));
        close(sock);
        return NULL;
    }

    // Create connection structure
    adb_connection_t *conn = (adb_connection_t *)malloc(sizeof(adb_connection_t));
    if (!conn) {
        close(sock);
        return NULL;
    }

    conn->socket = sock;
    conn->local_id = 1;
    conn->remote_id = 0;
    conn->serial = strdup(host);
    conn->state = ADB_STATE_OPEN;

    printf("[ADB] Connected successfully\n");
    return conn;
}

// Disconnect ADB
void adb_disconnect(adb_connection_t *connection) {
    if (!connection) return;

    if (connection->socket >= 0) {
        // Send close message
        adb_msg_t msg;
        adb_create_msg(&msg, ADB_C_CLSE, connection->local_id, connection->remote_id, NULL, 0);
        adb_send_msg(connection->socket, &msg);

        close(connection->socket);
    }

    if (connection->serial) {
        free(connection->serial);
    }

    free(connection);
    printf("[ADB] Disconnected\n");
}

// Execute shell command
int adb_shell(adb_connection_t *connection, const char *command,
              char *output, size_t output_size) {
    if (!connection || connection->state != ADB_STATE_OPEN) {
        return -1;
    }

    printf("[ADB] Executing shell: %s\n", command);

    // Send open message for shell
    adb_msg_t msg;
    char service[64];
    snprintf(service, sizeof(service), "shell:%s", command);

    adb_create_msg(&msg, ADB_C_OPEN, connection->local_id, 0,
                   service, strlen(service));

    if (adb_send_msg(connection->socket, &msg) < 0) {
        printf("[ADB] Failed to send open message\n");
        return -1;
    }

    // Wait for OKAY
    if (adb_recv_msg(connection->socket, &msg) < 0) {
        printf("[ADB] Failed to receive response\n");
        return -1;
    }

    if (msg.command != ADB_C_OKAY) {
        printf("[ADB] Shell command rejected\n");
        return -1;
    }

    connection->remote_id = msg.arg0;

    // Receive output
    size_t total_received = 0;
    int result = 0;

    while (1) {
        if (adb_recv_msg(connection->socket, &msg) < 0) {
            break;
        }

        if (msg.command == ADB_C_WRTE) {
            // Receive data
            if (msg.data_length > 0) {
                size_t remaining = output_size - total_received - 1;
                size_t to_read = (msg.data_length < remaining) ? msg.data_length : remaining;

                if (to_read > 0) {
                    if (adb_recv_data(connection->socket, output + total_received, to_read) < 0) {
                        result = -1;
                        break;
                    }
                    total_received += to_read;
                }

                // Skip remaining data if buffer is full
                if (msg.data_length > to_read) {
                    uint8_t *skip = (uint8_t *)malloc(msg.data_length - to_read);
                    adb_recv_data(connection->socket, skip, msg.data_length - to_read);
                    free(skip);
                }
            }

            // Send OKAY
            adb_create_msg(&msg, ADB_C_OKAY, connection->local_id, connection->remote_id, NULL, 0);
            adb_send_msg(connection->socket, &msg);
        } else if (msg.command == ADB_C_CLSE) {
            break;
        }
    }

    // Null terminate output
    if (output && output_size > 0) {
        output[total_received] = '\0';
    }

    // Send close
    adb_create_msg(&msg, ADB_C_CLSE, connection->local_id, connection->remote_id, NULL, 0);
    adb_send_msg(connection->socket, &msg);

    printf("[ADB] Shell output: %zu bytes\n", total_received);
    return (int)total_received;
}

// Push file
int adb_push(adb_connection_t *connection, const char *local_path, const char *remote_path) {
    if (!connection || connection->state != ADB_STATE_OPEN) {
        return -1;
    }

    printf("[ADB] Pushing %s to %s\n", local_path, remote_path);

    // Open file
    FILE *fp = fopen(local_path, "rb");
    if (!fp) {
        printf("[ADB] Failed to open local file: %s\n", local_path);
        return -1;
    }

    // Get file size
    fseek(fp, 0, SEEK_END);
    long file_size = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    // Send open message for sync
    adb_msg_t msg;
    char service[256];
    snprintf(service, sizeof(service), "sync:");

    adb_create_msg(&msg, ADB_C_OPEN, connection->local_id, 0,
                   service, strlen(service));

    if (adb_send_msg(connection->socket, &msg) < 0) {
        fclose(fp);
        return -1;
    }

    // Wait for OKAY
    if (adb_recv_msg(connection->socket, &msg) < 0 || msg.command != ADB_C_OKAY) {
        fclose(fp);
        return -1;
    }

    connection->remote_id = msg.arg0;

    // Send SEND command
    uint32_t mode = 0644;
    char send_msg[8 + 256 + 4];
    uint32_t path_len = strlen(remote_path);

    memcpy(send_msg, "SEND", 4);
    memcpy(send_msg + 4, &path_len, 4);
    memcpy(send_msg + 8, remote_path, path_len);
    memcpy(send_msg + 8 + path_len, &mode, 4);

    adb_create_msg(&msg, ADB_C_WRTE, connection->local_id, connection->remote_id,
                   send_msg, 8 + path_len + 4);
    adb_send_msg(connection->socket, &msg);

    // Wait for OKAY
    adb_recv_msg(connection->socket, &msg);

    // Send file data in chunks
    uint8_t chunk[4096];
    size_t remaining = file_size;

    while (remaining > 0) {
        size_t to_read = (remaining < sizeof(chunk)) ? remaining : sizeof(chunk);
        size_t read = fread(chunk, 1, to_read, fp);

        // Send DATA command
        memcpy(send_msg, "DATA", 4);
        uint32_t data_len = read;
        memcpy(send_msg + 4, &data_len, 4);

        // Create message with data
        uint8_t *full_msg = (uint8_t *)malloc(8 + data_len);
        memcpy(full_msg, send_msg, 8);
        memcpy(full_msg + 8, chunk, data_len);

        adb_create_msg(&msg, ADB_C_WRTE, connection->local_id, connection->remote_id,
                       full_msg, 8 + data_len);
        adb_send_msg(connection->socket, &msg);
        free(full_msg);

        // Wait for OKAY
        adb_recv_msg(connection->socket, &msg);

        remaining -= read;
    }

    fclose(fp);

    // Send DONE command
    uint32_t timestamp = 0;
    memcpy(send_msg, "DONE", 4);
    memcpy(send_msg + 4, &timestamp, 4);

    adb_create_msg(&msg, ADB_C_WRTE, connection->local_id, connection->remote_id,
                   send_msg, 8);
    adb_send_msg(connection->socket, &msg);

    // Wait for OKAY
    adb_recv_msg(connection->socket, &msg);

    // Send close
    adb_create_msg(&msg, ADB_C_CLSE, connection->local_id, connection->remote_id, NULL, 0);
    adb_send_msg(connection->socket, &msg);

    printf("[ADB] Push completed: %ld bytes\n", file_size);
    return 0;
}

// Pull file
int adb_pull(adb_connection_t *connection, const char *remote_path, const char *local_path) {
    // TODO: Implement pull functionality
    printf("[ADB] Pull not implemented yet\n");
    return -1;
}

// Forward port
int adb_forward(adb_connection_t *connection, int local_port, int remote_port) {
    if (!connection || connection->state != ADB_STATE_OPEN) {
        return -1;
    }

    printf("[ADB] Forwarding TCP:%d to TCP:%d\n", local_port, remote_port);

    // Send forward command
    char command[64];
    snprintf(command, sizeof(command), "tcp:%d", local_port);

    adb_msg_t msg;
    adb_create_msg(&msg, ADB_C_OPEN, connection->local_id, 0,
                   command, strlen(command));

    if (adb_send_msg(connection->socket, &msg) < 0) {
        return -1;
    }

    // Wait for OKAY
    if (adb_recv_msg(connection->socket, &msg) < 0 || msg.command != ADB_C_OKAY) {
        return -1;
    }

    connection->remote_id = msg.arg0;
    connection->state = ADB_STATE_CONNECT;

    return 0;
}

// Check if connected
int adb_is_connected(adb_connection_t *connection) {
    return (connection && connection->state != ADB_STATE_CLOSED);
}

// Get device serial
const char* adb_get_serial(adb_connection_t *connection) {
    return connection ? connection->serial : NULL;
}
