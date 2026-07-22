/**
 * adb_full.c
 *
 * Complete ADB protocol implementation for iOS.
 * Based on Android ADB protocol specification.
 */

#include "adb_full.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>

// CRC32 calculation
static uint32_t crc32(const uint8_t *data, size_t length) {
    uint32_t crc = 0xFFFFFFFF;
    for (size_t i = 0; i < length; i++) {
        crc ^= data[i];
        for (int j = 0; j < 8; j++) {
            crc = (crc >> 1) ^ (0xEDB88320 & (-(crc & 1)));
        }
    }
    return crc ^ 0xFFFFFFFF;
}

// Create ADB message
static void create_message(adb_message_t *msg, uint32_t command,
                           uint32_t arg0, uint32_t arg1,
                           const void *data, uint32_t data_length) {
    msg->command = command;
    msg->arg0 = arg0;
    msg->arg1 = arg1;
    msg->data_length = data_length;
    msg->data_crc32 = data ? crc32(data, data_length) : 0;
    msg->magic = command ^ 0xFFFFFFFF;
}

// Validate message
static int validate_message(const adb_message_t *msg) {
    if (msg->magic != (msg->command ^ 0xFFFFFFFF)) {
        return 0;
    }
    return 1;
}

// Send message header
static int send_header(int sock, const adb_message_t *msg) {
    uint8_t buf[24];
    *(uint32_t *)(buf + 0) = htonl(msg->command);
    *(uint32_t *)(buf + 4) = htonl(msg->arg0);
    *(uint32_t *)(buf + 8) = htonl(msg->arg1);
    *(uint32_t *)(buf + 12) = htonl(msg->data_length);
    *(uint32_t *)(buf + 16) = htonl(msg->data_crc32);
    *(uint32_t *)(buf + 20) = htonl(msg->magic);

    ssize_t sent = send(sock, buf, 24, 0);
    return (sent == 24) ? 0 : -1;
}

// Receive message header
static int recv_header(int sock, adb_message_t *msg) {
    uint8_t buf[24];
    ssize_t received = recv(sock, buf, 24, MSG_WAITALL);
    if (received != 24) return -1;

    msg->command = ntohl(*(uint32_t *)(buf + 0));
    msg->arg0 = ntohl(*(uint32_t *)(buf + 4));
    msg->arg1 = ntohl(*(uint32_t *)(buf + 8));
    msg->data_length = ntohl(*(uint32_t *)(buf + 12));
    msg->data_crc32 = ntohl(*(uint32_t *)(buf + 16));
    msg->magic = ntohl(*(uint32_t *)(buf + 20));

    if (!validate_message(msg)) {
        printf("[ADB] Invalid message magic\n");
        return -1;
    }

    return 0;
}

// Send data
static int send_data(int sock, const void *data, uint32_t length) {
    const uint8_t *ptr = data;
    uint32_t sent = 0;

    while (sent < length) {
        ssize_t n = send(sock, ptr + sent, length - sent, 0);
        if (n <= 0) return -1;
        sent += n;
    }

    return 0;
}

// Receive data
static int recv_data(int sock, void *data, uint32_t length) {
    uint8_t *ptr = data;
    uint32_t received = 0;

    while (received < length) {
        ssize_t n = recv(sock, ptr + received, length - received, MSG_WAITALL);
        if (n <= 0) return -1;
        received += n;
    }

    return 0;
}

// Send message with payload
static int send_message(int sock, const adb_message_t *msg, const void *data) {
    if (send_header(sock, msg) < 0) return -1;
    if (msg->data_length > 0 && data) {
        if (send_data(sock, data, msg->data_length) < 0) return -1;
    }
    return 0;
}

// Receive message with payload
static int recv_message(int sock, adb_message_t *msg, void *data, uint32_t max_size) {
    if (recv_header(sock, msg) < 0) return -1;

    if (msg->data_length > 0) {
        uint32_t to_read = (msg->data_length < max_size) ? msg->data_length : max_size;
        if (recv_data(sock, data, to_read) < 0) return -1;

        // Skip remaining data if buffer too small
        if (msg->data_length > to_read) {
            uint8_t *skip = malloc(msg->data_length - to_read);
            if (skip) {
                recv_data(sock, skip, msg->data_length - to_read);
                free(skip);
            }
        }
    }

    return 0;
}

// Wait for specific command
static int wait_command(int sock, uint32_t expected_cmd, adb_message_t *msg) {
    while (1) {
        if (recv_header(sock, msg) < 0) return -1;

        if (msg->command == expected_cmd) {
            return 0;
        }

        // Handle unexpected commands
        printf("[ADB] Unexpected command: 0x%08x\n", msg->command);
    }
}

// Initialize
int adb_init(void) {
    printf("[ADB] Library initialized\n");
    return 0;
}

// Cleanup
void adb_cleanup(void) {
    printf("[ADB] Library cleaned up\n");
}

// Connect to ADB daemon
adb_handle_t* adb_connect(const char *host, int port) {
    printf("[ADB] Connecting to %s:%d\n", host, port);

    // Create socket
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        printf("[ADB] Socket creation failed: %s\n", strerror(errno));
        return NULL;
    }

    // Set socket options
    int reuse = 1;
    setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse));

    // Resolve host
    struct hostent *server = gethostbyname(host);
    if (!server) {
        printf("[ADB] Host resolution failed: %s\n", host);
        close(sock);
        return NULL;
    }

    // Connect
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    memcpy(&addr.sin_addr.s_addr, server->h_addr, server->h_length);

    if (connect(sock, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        printf("[ADB] Connection failed: %s\n", strerror(errno));
        close(sock);
        return NULL;
    }

    printf("[ADB] TCP connected\n");

    // Create handle
    adb_handle_t *handle = calloc(1, sizeof(adb_message_t));
    if (!handle) {
        close(sock);
        return NULL;
    }

    handle->socket = sock;
    handle->local_id = 1;
    handle->serial = strdup(host);
    handle->connected = 0;

    // Send CNXN message
    adb_message_t msg;
    const char *system_identity = "host::";
    create_message(&msg, ADB_CMD_CNXN, ADB_PROTOCOL_VERSION,
                   ADB_MAX_PAYLOAD, system_identity, strlen(system_identity));

    if (send_message(sock, &msg, system_identity) < 0) {
        printf("[ADB] Failed to send CNXN\n");
        close(sock);
        free(handle->serial);
        free(handle);
        return NULL;
    }

    // Wait for CNXN response
    uint8_t response[256];
    if (recv_message(sock, &msg, response, sizeof(response)) < 0) {
        printf("[ADB] Failed to receive CNXN response\n");
        close(sock);
        free(handle->serial);
        free(handle);
        return NULL;
    }

    if (msg.command != ADB_CMD_CNXN) {
        printf("[ADB] Unexpected response: 0x%08x\n", msg.command);
        close(sock);
        free(handle->serial);
        free(handle);
        return NULL;
    }

    // Parse device info from response
    printf("[ADB] Connected to device: %s\n", response);

    // Extract device serial from response
    if (handle->serial) free(handle->serial);
    handle->serial = strdup((char *)response);

    handle->connected = 1;
    printf("[ADB] ADB connection established\n");

    return handle;
}

// Disconnect
void adb_disconnect(adb_handle_t *handle) {
    if (!handle) return;

    if (handle->socket >= 0) {
        close(handle->socket);
    }

    if (handle->serial) {
        free(handle->serial);
    }

    free(handle);
    printf("[ADB] Disconnected\n");
}

// Execute shell command
int adb_shell(adb_handle_t *handle, const char *command,
              char *output, size_t output_size) {
    if (!handle || !handle->connected) return -1;

    printf("[ADB] Executing: %s\n", command);

    // Open shell service
    adb_message_t msg;
    char service[256];
    snprintf(service, sizeof(service), "shell:%s", command);

    create_message(&msg, ADB_CMD_OPEN, handle->local_id, 0,
                   service, strlen(service));

    if (send_message(handle->socket, &msg, service) < 0) {
        printf("[ADB] Failed to send OPEN\n");
        return -1;
    }

    // Wait for OKAY
    if (wait_command(handle->socket, ADB_CMD_OKAY, &msg) < 0) {
        printf("[ADB] Failed to receive OKAY\n");
        return -1;
    }

    handle->remote_id = msg.arg0;
    printf("[ADB] Shell channel opened, remote_id=%u\n", handle->remote_id);

    // Receive output
    size_t total = 0;

    while (1) {
        if (recv_header(handle->socket, &msg) < 0) break;

        if (msg.command == ADB_CMD_WRTE) {
            // Receive data
            if (msg.data_length > 0) {
                size_t remaining = output_size - total - 1;
                size_t to_read = (msg.data_length < remaining) ? msg.data_length : remaining;

                if (to_read > 0 && output) {
                    if (recv_data(handle->socket, output + total, to_read) < 0) break;
                    total += to_read;
                } else {
                    // Skip data
                    uint8_t *skip = malloc(msg.data_length);
                    if (skip) {
                        recv_data(handle->socket, skip, msg.data_length);
                        free(skip);
                    }
                }
            }

            // Send OKAY
            create_message(&msg, ADB_CMD_OKAY, handle->local_id, handle->remote_id, NULL, 0);
            send_header(handle->socket, &msg);

        } else if (msg.command == ADB_CMD_CLSE) {
            break;
        }
    }

    // Null terminate output
    if (output && output_size > 0) {
        output[total] = '\0';
    }

    // Send CLSE
    create_message(&msg, ADB_CMD_CLSE, handle->local_id, handle->remote_id, NULL, 0);
    send_header(handle->socket, &msg);

    printf("[ADB] Shell output: %zu bytes\n", total);
    return (int)total;
}

// Push file
int adb_push(adb_handle_t *handle, const char *local_path, const char *remote_path) {
    if (!handle || !handle->connected) return -1;

    printf("[ADB] Pushing %s -> %s\n", local_path, remote_path);

    // Open file
    FILE *fp = fopen(local_path, "rb");
    if (!fp) {
        printf("[ADB] Failed to open file: %s\n", local_path);
        return -1;
    }

    // Get file size
    fseek(fp, 0, SEEK_END);
    long file_size = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    printf("[ADB] File size: %ld bytes\n", file_size);

    // Open sync service
    adb_message_t msg;
    create_message(&msg, ADB_CMD_OPEN, handle->local_id, 0, "sync:", 5);

    if (send_message(handle->socket, &msg, "sync:") < 0) {
        fclose(fp);
        return -1;
    }

    // Wait for OKAY
    if (wait_command(handle->socket, ADB_CMD_OKAY, &msg) < 0) {
        fclose(fp);
        return -1;
    }

    handle->remote_id = msg.arg0;
    printf("[ADB] Sync channel opened\n");

    // Send ID_SEND
    uint32_t id_send = ID_SEND;
    uint32_t path_len = strlen(remote_path);
    uint32_t mode = 0644;

    // Send stat + path
    uint8_t *send_buf = malloc(12 + path_len);
    memcpy(send_buf, &id_send, 4);
    memcpy(send_buf + 4, &mode, 4);
    memcpy(send_buf + 8, &path_len, 4);
    memcpy(send_buf + 12, remote_path, path_len);

    create_message(&msg, ADB_CMD_WRTE, handle->local_id, handle->remote_id, NULL, 12 + path_len);
    send_header(handle->socket, &msg);
    send_data(handle->socket, send_buf, 12 + path_len);
    free(send_buf);

    // Wait for OKAY
    wait_command(handle->socket, ADB_CMD_OKAY, &msg);

    // Send file data in chunks
    uint8_t chunk[65536];
    size_t remaining = file_size;

    while (remaining > 0) {
        size_t to_read = (remaining < sizeof(chunk)) ? remaining : sizeof(chunk);
        size_t bytes_read = fread(chunk, 1, to_read, fp);

        if (bytes_read <= 0) break;

        // Send DATA
        uint8_t data_header[8];
        uint32_t data_id = 0x41544144; // DATA
        uint32_t data_len = bytes_read;
        memcpy(data_header, &data_id, 4);
        memcpy(data_header + 4, &data_len, 4);

        create_message(&msg, ADB_CMD_WRTE, handle->local_id, handle->remote_id, NULL, 8 + bytes_read);
        send_header(handle->socket, &msg);
        send_data(handle->socket, data_header, 8);
        send_data(handle->socket, chunk, bytes_read);

        // Wait for OKAY
        wait_command(handle->socket, ADB_CMD_OKAY, &msg);

        remaining -= bytes_read;
    }

    fclose(fp);

    // Send ID_DONE
    uint32_t id_done = ID_DONE;
    uint32_t timestamp = 0;

    create_message(&msg, ADB_CMD_WRTE, handle->local_id, handle->remote_id, NULL, 8);
    send_header(handle->socket, &msg);
    send_data(handle->socket, &id_done, 4);
    send_data(handle->socket, &timestamp, 4);

    // Wait for OKAY
    wait_command(handle->socket, ADB_CMD_OKAY, &msg);

    // Close channel
    create_message(&msg, ADB_CMD_CLSE, handle->local_id, handle->remote_id, NULL, 0);
    send_header(handle->socket, &msg);

    printf("[ADB] Push completed: %ld bytes\n", file_size);
    return 0;
}

// Pull file
int adb_pull(adb_handle_t *handle, const char *remote_path, const char *local_path) {
    if (!handle || !handle->connected) return -1;

    printf("[ADB] Pulling %s -> %s\n", remote_path, local_path);

    // Open sync service
    adb_message_t msg;
    create_message(&msg, ADB_CMD_OPEN, handle->local_id, 0, "sync:", 5);

    if (send_message(handle->socket, &msg, "sync:") < 0) {
        return -1;
    }

    // Wait for OKAY
    if (wait_command(handle->socket, ADB_CMD_OKAY, &msg) < 0) {
        return -1;
    }

    handle->remote_id = msg.arg0;

    // Send ID_RECV
    uint32_t id_recv = ID_RECV;
    uint32_t path_len = strlen(remote_path);

    uint8_t *recv_buf = malloc(8 + path_len);
    memcpy(recv_buf, &id_recv, 4);
    memcpy(recv_buf + 4, &path_len, 4);
    memcpy(recv_buf + 8, remote_path, path_len);

    create_message(&msg, ADB_CMD_WRTE, handle->local_id, handle->remote_id, NULL, 8 + path_len);
    send_header(handle->socket, &msg);
    send_data(handle->socket, recv_buf, 8 + path_len);
    free(recv_buf);

    // Wait for OKAY
    wait_command(handle->socket, ADB_CMD_OKAY, &msg);

    // Open local file
    FILE *fp = fopen(local_path, "wb");
    if (!fp) {
        printf("[ADB] Failed to create local file: %s\n", local_path);
        return -1;
    }

    // Receive data
    while (1) {
        if (recv_header(handle->socket, &msg) < 0) break;

        if (msg.command == ADB_CMD_WRTE) {
            if (msg.data_length > 0) {
                uint8_t *data = malloc(msg.data_length);
                recv_data(handle->socket, data, msg.data_length);

                // Check for DATA header
                uint32_t data_id;
                memcpy(&data_id, data, 4);

                if (data_id == 0x41544144) { // DATA
                    fwrite(data + 8, 1, msg.data_length - 8, fp);
                }

                free(data);
            }

            // Send OKAY
            create_message(&msg, ADB_CMD_OKAY, handle->local_id, handle->remote_id, NULL, 0);
            send_header(handle->socket, &msg);

        } else if (msg.command == ADB_CMD_CLSE) {
            break;
        }
    }

    fclose(fp);

    printf("[ADB] Pull completed\n");
    return 0;
}

// Forward port
int adb_forward(adb_handle_t *handle, int local_port, int remote_port) {
    if (!handle || !handle->connected) return -1;

    printf("[ADB] Forwarding tcp:%d -> tcp:%d\n", local_port, remote_port);

    char forward_cmd[64];
    snprintf(forward_cmd, sizeof(forward_cmd), "forward:tcp:%d;tcp:%d", local_port, remote_port);

    adb_message_t msg;
    create_message(&msg, ADB_CMD_OPEN, handle->local_id, 0,
                   forward_cmd, strlen(forward_cmd));

    if (send_message(handle->socket, &msg, forward_cmd) < 0) {
        return -1;
    }

    // Wait for OKAY
    if (wait_command(handle->socket, ADB_CMD_OKAY, &msg) < 0) {
        return -1;
    }

    handle->remote_id = msg.arg0;
    printf("[ADB] Port forwarding set up\n");

    return 0;
}

// Check connection
int adb_is_connected(adb_handle_t *handle) {
    return (handle && handle->connected);
}
